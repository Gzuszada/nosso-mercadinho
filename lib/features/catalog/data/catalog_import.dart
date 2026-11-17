import 'dart:convert';

enum MeasurementMode {
  pending,
  unit,
  package,
  weight;

  String get label => switch (this) {
    MeasurementMode.pending => 'Revisar forma de compra',
    MeasurementMode.unit => 'Por unidade',
    MeasurementMode.package => 'Por pacote',
    MeasurementMode.weight => 'Por peso',
  };

  String get quantityUnit => switch (this) {
    MeasurementMode.unit => 'un.',
    MeasurementMode.package => 'pacotes',
    MeasurementMode.weight => 'g',
    MeasurementMode.pending => 'unidade pendente',
  };

  String get priceUnit => switch (this) {
    MeasurementMode.unit => 'un.',
    MeasurementMode.package => 'pacote',
    MeasurementMode.weight => 'kg',
    MeasurementMode.pending => '',
  };

  String formatQuantity(int quantity) => switch (this) {
    MeasurementMode.unit => '$quantity un.',
    MeasurementMode.package =>
      '$quantity ${quantity == 1 ? 'pacote' : 'pacotes'}',
    MeasurementMode.weight => '$quantity g',
    MeasurementMode.pending => '$quantity (unidade pendente)',
  };
}

class CatalogImportItem {
  const CatalogImportItem({
    required this.sourceSheet,
    required this.sourceRow,
    required this.sourceNumber,
    required this.name,
    required this.suggestedCategory,
    required this.needsCategoryReview,
    required this.measurementMode,
  });

  final String sourceSheet;
  final int sourceRow;
  final int sourceNumber;
  final String name;
  final String? suggestedCategory;
  final bool needsCategoryReview;
  final MeasurementMode measurementMode;
}

class CatalogImport {
  const CatalogImport({
    required this.source,
    required this.warning,
    required this.items,
  });

  final String source;
  final String warning;
  final List<CatalogImportItem> items;

  int get productsWithoutCategory =>
      items.where((item) => item.needsCategoryReview).length;

  factory CatalogImport.fromJson(String contents) {
    final decoded = jsonDecode(contents);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('O arquivo deve conter um objeto JSON.');
    }

    final source = decoded['source'];
    final mode = decoded['import_mode'];
    final warning = decoded['warning'];
    final rawItems = decoded['items'];
    if (source is! String || source.trim().isEmpty) {
      throw const FormatException('A origem do catálogo está ausente.');
    }
    if (mode != 'catalog_only') {
      throw const FormatException(
        'O arquivo não está identificado como catálogo sem histórico.',
      );
    }
    if (warning is! String || rawItems is! List<dynamic>) {
      throw const FormatException('Estrutura do catálogo inválida.');
    }

    final items = <CatalogImportItem>[];
    final sourceRows = <String>{};
    for (var index = 0; index < rawItems.length; index++) {
      final rawItem = rawItems[index];
      if (rawItem is! Map<String, dynamic>) {
        throw FormatException('O produto ${index + 1} não é um objeto.');
      }

      final sheet = rawItem['source_sheet'];
      final row = rawItem['source_row'];
      final number = rawItem['source_number'];
      final name = rawItem['name'];
      final category = rawItem['suggested_category'];
      final needsReview = rawItem['needs_category_review'];
      final rawMode = rawItem['measurement_mode'];

      if (sheet is! String ||
          row is! int ||
          number is! int ||
          name is! String ||
          name.trim().isEmpty ||
          (category != null && category is! String) ||
          needsReview is! bool ||
          (rawMode != null && rawMode is! String)) {
        throw FormatException('Dados inválidos no produto ${index + 1}.');
      }

      final identity = '$sheet:$row';
      if (!sourceRows.add(identity)) {
        throw FormatException('Linha de origem repetida: $identity.');
      }

      final measurementMode = switch (rawMode) {
        null || 'pending' => MeasurementMode.pending,
        'unit' => MeasurementMode.unit,
        'package' => MeasurementMode.package,
        'weight' => MeasurementMode.weight,
        _ => throw FormatException(
          'Forma de compra desconhecida no produto ${index + 1}.',
        ),
      };

      items.add(
        CatalogImportItem(
          sourceSheet: sheet,
          sourceRow: row,
          sourceNumber: number,
          name: name.trim(),
          suggestedCategory: category is String && category.trim().isNotEmpty
              ? category.trim()
              : null,
          needsCategoryReview:
              needsReview ||
              category == null ||
              (category is String && category.trim().isEmpty),
          measurementMode: measurementMode,
        ),
      );
    }

    if (items.isEmpty) {
      throw const FormatException('O catálogo não contém produtos nomeados.');
    }

    return CatalogImport(source: source, warning: warning, items: items);
  }
}
