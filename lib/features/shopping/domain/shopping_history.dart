import '../../catalog/data/catalog_import.dart';

class ShoppingHistoryCalculations {
  const ShoppingHistoryCalculations._();

  static int estimateTotalCents({
    required int quantity,
    required int amountCents,
    required int quantityBasis,
  }) {
    if (quantity < 0 || amountCents < 0 || quantityBasis <= 0) {
      throw const FormatException('Dados da estimativa inválidos.');
    }
    final numerator = BigInt.from(quantity) * BigInt.from(amountCents);
    final divisor = BigInt.from(quantityBasis);
    final total = (numerator + divisor ~/ BigInt.two) ~/ divisor;
    return _checkedInteger(total);
  }

  static int displayUnitPriceCents({
    required MeasurementMode mode,
    required int amountCents,
    required int quantityBasis,
  }) {
    if (mode == MeasurementMode.pending || amountCents < 0) {
      throw const FormatException('Forma ou preço de referência inválido.');
    }
    final standardQuantity = mode == MeasurementMode.weight ? 1000 : 1;
    return estimateTotalCents(
      quantity: standardQuantity,
      amountCents: amountCents,
      quantityBasis: quantityBasis,
    );
  }

  static int? medianIntervalDays(Iterable<DateTime> purchaseDates) {
    final dates = purchaseDates.map(civilDateOnly).toSet().toList()..sort();
    if (dates.length < 3) {
      return null;
    }
    final intervals = [
      for (var index = 1; index < dates.length; index++)
        dates[index].difference(dates[index - 1]).inDays,
    ]..sort();
    final middle = intervals.length ~/ 2;
    if (intervals.length.isOdd) {
      return intervals[middle];
    }
    return (intervals[middle - 1] + intervals[middle] + 1) ~/ 2;
  }

  static String civilDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String monthKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}';

  static String previousMonthKey(String monthKey) {
    final parts = parseMonthKey(monthKey);
    final previous = DateTime(parts.$1, parts.$2 - 1);
    return monthKeyFor(previous);
  }

  static DateTime firstDayOfMonth(String monthKey) {
    final parts = parseMonthKey(monthKey);
    return DateTime(parts.$1, parts.$2);
  }

  static DateTime firstDayOfNextMonth(String monthKey) {
    final parts = parseMonthKey(monthKey);
    return DateTime(parts.$1, parts.$2 + 1);
  }

  static DateTime civilDateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String monthKeyFor(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}';

  static (int, int) parseMonthKey(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw const FormatException('Mês inválido.');
    }
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    if (month < 1 || month > 12) {
      throw const FormatException('Mês inválido.');
    }
    return (year, month);
  }

  static int _checkedInteger(BigInt value) {
    if (value < BigInt.zero || value > BigInt.from(9007199254740991)) {
      throw const FormatException('Valor acima do limite aceito pelo banco.');
    }
    return value.toInt();
  }
}
