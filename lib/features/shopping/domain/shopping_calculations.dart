import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../catalog/data/catalog_import.dart';

enum WeightInputUnit { grams, kilograms }

/// Remove acentos e converte para minúsculas para comparação insensível a acentuação.
String normalizeText(String input) {
  const withDia = 'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖØòóôõöøÙÚÛÜùúûüÇçÑñÝýÿ';
  const withoutDia = 'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOOooooooUUUUuuuuCcNnYyy';
  var result = input;
  for (var i = 0; i < withDia.length; i++) {
    result = result.replaceAll(withDia[i], withoutDia[i]);
  }
  return result.toLowerCase();
}

/// Compara duas strings ignorando acentos e maiúsculas/minúsculas.
int compareNormalized(String a, String b) {
  final normA = normalizeText(a);
  final normB = normalizeText(b);
  final comp = normA.compareTo(normB);
  if (comp != 0) return comp;
  return a.compareTo(b);
}

/// Formatador de centavos para campos monetários:
/// Digitar "1299" produz "12,99"; apagar tudo deixa o campo vazio.
class CentsInputFormatter extends TextInputFormatter {
  const CentsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final cents = int.tryParse(digitsOnly);
    if (cents == null) {
      return oldValue;
    }

    final whole = cents ~/ 100;
    final fraction = (cents % 100).toString().padLeft(2, '0');
    final formatted = '$whole,$fraction';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ShoppingCalculations {
  const ShoppingCalculations._();

  static int parseMoneyToCents(String input) {
    var value = input.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (value.isEmpty) {
      throw const FormatException('Informe o preço ou deixe o campo vazio.');
    }

    final brazilianPattern = RegExp(
      r'^(?:\d+|\d{1,3}(?:\.\d{3})+)(?:,\d{1,2})?$',
    );
    if (brazilianPattern.hasMatch(value)) {
      final parts = value.split(',');
      final whole = parts.first.replaceAll('.', '');
      final fraction = parts.length == 1 ? '' : parts[1].padRight(2, '0');
      return _checkedCents(
        BigInt.parse(whole) * BigInt.from(100) +
            BigInt.parse(fraction.isEmpty ? '0' : fraction),
      );
    }

    final decimalDotPattern = RegExp(r'^\d+\.\d{1,2}$');
    if (decimalDotPattern.hasMatch(value)) {
      value = value.replaceFirst('.', ',');
      return parseMoneyToCents(value);
    }

    throw const FormatException(
      'Preço inválido. Use, por exemplo, 12,34 ou 1.234,56.',
    );
  }

  static int parseUnitQuantity(String input) {
    final value = input.trim();
    final quantity = int.tryParse(value);
    if (quantity == null || quantity <= 0) {
      throw const FormatException(
        'Informe uma quantidade inteira maior que zero.',
      );
    }
    return quantity;
  }

  static int parseWeightGrams(String input, WeightInputUnit unit) {
    final value = input.trim();
    if (unit == WeightInputUnit.grams) {
      final grams = int.tryParse(value);
      if (grams == null || grams <= 0) {
        throw const FormatException(
          'Informe um peso inteiro em gramas, maior que zero.',
        );
      }
      return grams;
    }

    if (!RegExp(r'^\d+(?:[,.]\d{1,3})?$').hasMatch(value)) {
      throw const FormatException(
        'Informe kg com até três casas decimais ou use o campo em gramas.',
      );
    }
    final parts = value.replaceFirst(',', '.').split('.');
    final whole = BigInt.parse(parts.first);
    final fraction = parts.length == 1 ? '' : parts[1].padRight(3, '0');
    final grams =
        whole * BigInt.from(1000) +
        BigInt.parse(fraction.isEmpty ? '0' : fraction);
    if (grams <= BigInt.zero) {
      throw const FormatException('O peso precisa ser maior que zero.');
    }
    return _checkedCents(grams);
  }

  static int calculateLineTotalCents({
    required MeasurementMode mode,
    required int quantity,
    required int unitPriceCents,
  }) {
    if (mode == MeasurementMode.pending) {
      throw const FormatException(
        'Defina se o produto é comprado por unidade, pacote ou peso.',
      );
    }
    if (quantity <= 0 || unitPriceCents < 0) {
      throw const FormatException('Quantidade ou preço inválido.');
    }

    final numerator = BigInt.from(quantity) * BigInt.from(unitPriceCents);
    final divisor = mode == MeasurementMode.weight
        ? BigInt.from(1000)
        : BigInt.one;
    final rounded = (numerator + divisor ~/ BigInt.from(2)) ~/ divisor;
    return _checkedCents(rounded);
  }

  static int sumCents(Iterable<int> values) {
    var total = BigInt.zero;
    for (final value in values) {
      if (value < 0) {
        throw const FormatException('Um total não pode ser negativo.');
      }
      total += BigInt.from(value);
    }
    return _checkedCents(total);
  }

  static String formatMoney(int cents) {
    if (cents < 0) {
      throw const FormatException(
        'Um valor em centavos não pode ser negativo.',
      );
    }
    final whole = cents ~/ 100;
    final fraction = (cents % 100).toString().padLeft(2, '0');
    return 'R\$ ${NumberFormat.decimalPattern('pt_BR').format(whole)},$fraction';
  }

  static String formatQuantity(MeasurementMode mode, int quantity) {
    return mode.formatQuantity(quantity);
  }

  static int _checkedCents(BigInt value) {
    if (value < BigInt.zero || value > BigInt.from(9007199254740991)) {
      throw const FormatException('Valor acima do limite aceito pelo banco.');
    }
    return value.toInt();
  }
}
