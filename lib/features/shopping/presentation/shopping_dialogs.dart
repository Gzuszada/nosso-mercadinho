import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../data/app_database.dart';
import '../../catalog/data/catalog_import.dart';
import '../domain/shopping_calculations.dart';

class PlanDraft {
  const PlanDraft({required this.monthKey, required this.name});

  final String monthKey;
  final String name;
}

class PlannedItemDraft {
  const PlannedItemDraft({
    required this.productId,
    required this.mode,
    required this.quantity,
  });

  final int productId;
  final MeasurementMode mode;
  final int quantity;
}

class TripDraft {
  const TripDraft({required this.purchaseDate, required this.marketName});

  final DateTime purchaseDate;
  final String? marketName;
}

class PurchaseLineDraft {
  const PurchaseLineDraft({
    required this.productId,
    required this.plannedItemId,
    required this.mode,
    required this.quantity,
    required this.unitPriceCents,
    this.labelTotalCents,
  });

  final int productId;
  final int? plannedItemId;
  final MeasurementMode mode;
  final int quantity;
  final int? unitPriceCents;
  final int? labelTotalCents;

  bool get usesLabelTotal => labelTotalCents != null;
}

enum PurchaseLineSelection { all, planned, outsidePlan }

Future<PlanDraft?> showCreatePlanDialog(BuildContext context) async {
  final formKey = GlobalKey<FormState>();
  var selectedMonth = DateTime.now();
  String defaultMonthName(DateTime month) {
    final raw = DateFormat('MMMM y', 'pt_BR').format(month);
    return raw[0].toUpperCase() + raw.substring(1);
  }

  final nameController = TextEditingController(
    text: defaultMonthName(selectedMonth),
  );
  var nameEditedManually = false;

  final result = await showDialog<PlanDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Nova lista'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        selectedMonth = DateTime(
                          selectedMonth.year,
                          selectedMonth.month - 1,
                        );
                        if (!nameEditedManually) {
                          nameController.text = defaultMonthName(selectedMonth);
                        }
                      });
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        defaultMonthName(selectedMonth),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        selectedMonth = DateTime(
                          selectedMonth.year,
                          selectedMonth.month + 1,
                        );
                        if (!nameEditedManually) {
                          nameController.text = defaultMonthName(selectedMonth);
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: nameController,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Nome da lista'),
                onChanged: (value) {
                  nameEditedManually = true;
                },
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe um nome.'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }
              Navigator.pop(
                dialogContext,
                PlanDraft(
                  monthKey:
                      '${selectedMonth.year.toString().padLeft(4, '0')}-'
                      '${selectedMonth.month.toString().padLeft(2, '0')}',
                  name: nameController.text.trim(),
                ),
              );
            },
            child: const Text('Criar lista'),
          ),
        ],
      ),
    ),
  );
  nameController.dispose();
  return result;
}

Future<PlannedItemDraft?> showPlannedItemDialog({
  required BuildContext context,
  required List<Product> products,
}) async {
  final availableProducts =
      products.where((product) => !product.isArchived).toList()
        ..sort((first, second) => compareNormalized(first.name, second.name));
  if (availableProducts.isEmpty) {
    return null;
  }
  final formKey = GlobalKey<FormState>();
  int? selectedProductId;
  var quantityText = '';
  var mode = MeasurementMode.pending;
  var weightUnit = WeightInputUnit.grams;
  final result = await showDialog<PlannedItemDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Adicionar à lista'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: selectedProductId,
                    decoration: const InputDecoration(labelText: 'Produto'),
                    items: [
                      for (final product in availableProducts)
                        DropdownMenuItem(
                          value: product.id,
                          child: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    validator: (value) => value == null
                        ? 'Escolha um produto.'
                        : mode == MeasurementMode.pending
                        ? 'Defina a forma de compra no cadastro do produto.'
                        : null,
                    onChanged: (value) {
                      final product = availableProducts
                          .where((row) => row.id == value)
                          .firstOrNull;
                      setState(() {
                        selectedProductId = value;
                        mode = _measurementMode(product?.measurementMode);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Forma de compra cadastrada',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      mode == MeasurementMode.pending
                          ? 'Pendente de definição'
                          : mode.label,
                    ),
                  ),
                  if (mode == MeasurementMode.pending)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Defina unidade, pacote ou peso no cadastro do produto antes de adicioná-lo.',
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (mode == MeasurementMode.weight)
                    _weightInputUnit(
                      value: weightUnit,
                      onChanged: (value) => setState(() => weightUnit = value),
                    ),
                  if (mode != MeasurementMode.pending)
                    TextFormField(
                      initialValue: quantityText,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal:
                            mode == MeasurementMode.weight &&
                            weightUnit == WeightInputUnit.kilograms,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(
                            mode == MeasurementMode.weight &&
                                    weightUnit == WeightInputUnit.kilograms
                                ? r'[0-9,.]'
                                : r'[0-9]',
                          ),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: mode == MeasurementMode.weight
                            ? 'Peso'
                            : mode == MeasurementMode.package
                            ? 'Quantidade de pacotes'
                            : 'Quantidade',
                        suffixText: mode == MeasurementMode.weight
                            ? weightUnit == WeightInputUnit.grams
                                  ? 'g'
                                  : 'kg'
                            : mode.quantityUnit,
                      ),
                      onChanged: (value) => quantityText = value,
                      validator: (value) =>
                          _quantityError(value ?? '', mode, weightUnit),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }
              Navigator.pop(
                dialogContext,
                PlannedItemDraft(
                  productId: selectedProductId!,
                  mode: mode,
                  quantity: _parseQuantity(quantityText, mode, weightUnit),
                ),
              );
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    ),
  );
  return result;
}

Future<TripDraft?> showCreateTripDialog(BuildContext context) async {
  var purchaseDate = DateTime.now();
  var marketName = '';
  final result = await showDialog<TripDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Iniciar compra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data real da compra'),
              subtitle: Text(DateFormat.yMMMd('pt_BR').format(purchaseDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate: purchaseDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  helpText: 'Data em que a compra acontece',
                );
                if (selected != null) {
                  setState(() => purchaseDate = selected);
                }
              },
            ),
            TextField(
              onChanged: (value) => marketName = value,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Mercado (opcional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              TripDraft(
                purchaseDate: purchaseDate,
                marketName: marketName.trim().isEmpty
                    ? null
                    : marketName.trim(),
              ),
            ),
            child: const Text('Iniciar'),
          ),
        ],
      ),
    ),
  );
  return result;
}

Future<PurchaseLineDraft?> showPurchaseLineDialog({
  required BuildContext context,
  required List<Product> products,
  required List<PlannedItem> plannedItems,
  required List<Category> categories,
  required Map<int, int> quantitiesByPlannedItem,
  required int? planId,
  PurchaseLineSelection selection = PurchaseLineSelection.all,
  PurchaseLine? existingLine,
  int? initialProductId,
  int? initialPlannedItemId,
  int? initialQuantity,
}) async {
  final plannedProductIds = plannedItems.map((item) => item.productId).toSet();
  final availableProducts =
      products.where((product) {
          final availableBySelection = switch (selection) {
            PurchaseLineSelection.all => true,
            PurchaseLineSelection.planned => plannedProductIds.contains(
              product.id,
            ),
            PurchaseLineSelection.outsidePlan => !plannedProductIds.contains(
              product.id,
            ),
          };
          return availableBySelection &&
              (!product.isArchived ||
                  plannedProductIds.contains(product.id) ||
                  product.id == existingLine?.productId ||
                  product.id == initialProductId);
        }).toList()
        ..sort((first, second) => compareNormalized(first.name, second.name));
  var quantityText = existingLine == null ? '' : '${existingLine.quantity}';
  var priceText = existingLine?.unitPriceCents == null
      ? ''
      : _moneyForInput(existingLine!.unitPriceCents!);
  final formKey = GlobalKey<FormState>();
  int? selectedProductId = existingLine?.productId ?? initialProductId;
  int? selectedPlannedItemId =
      existingLine?.plannedItemId ?? initialPlannedItemId;
  var showPlannedSelectionError = false;
  var showMeasurementModeError = false;
  var mode = existingLine == null
      ? _measurementMode(
          availableProducts
              .where((product) => product.id == selectedProductId)
              .firstOrNull
              ?.measurementMode,
        )
      : _measurementMode(existingLine.measurementMode);
  var weightUnit = WeightInputUnit.grams;

  final result = await showDialog<PurchaseLineDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        final matchingPlannedItems = plannedItems.where((item) {
          return item.productId == selectedProductId &&
              item.measurementMode == mode.name &&
              !item.isRemoved;
        }).toList();
        final availablePlannedItems =
            plannedItems.where((item) {
              return !item.isRemoved &&
                  availableProducts.any(
                    (product) => product.id == item.productId,
                  );
            }).toList()..sort((first, second) {
              final firstName = availableProducts
                  .firstWhere((product) => product.id == first.productId)
                  .name;
              final secondName = availableProducts
                  .firstWhere((product) => product.id == second.productId)
                  .name;
              return compareNormalized(firstName, secondName);
            });
        final categoryById = {for (final row in categories) row.id: row};
        final alreadyInCartItems = availablePlannedItems
            .where(
              (item) =>
                  (quantitiesByPlannedItem[item.id] ?? 0) >= item.quantity,
            )
            .toList();
        final remainingPlannedItems = availablePlannedItems
            .where(
              (item) => (quantitiesByPlannedItem[item.id] ?? 0) < item.quantity,
            )
            .toList();
        List<Widget> categoryGroups(List<PlannedItem> items) {
          final itemsByCategory = <int?, List<PlannedItem>>{};
          for (final item in items) {
            final product = availableProducts.firstWhere(
              (row) => row.id == item.productId,
            );
            itemsByCategory.putIfAbsent(product.categoryId, () => []).add(item);
          }
          final categoryIds = itemsByCategory.keys.toList()
            ..sort((first, second) {
              if (first == null) {
                return second == null ? 0 : 1;
              }
              if (second == null) {
                return -1;
              }
              final firstCategory = categoryById[first];
              final secondCategory = categoryById[second];
              final orderComparison = (firstCategory?.sortOrder ?? 0).compareTo(
                secondCategory?.sortOrder ?? 0,
              );
              return orderComparison != 0
                  ? orderComparison
                  : compareNormalized(
                      firstCategory?.name ?? '',
                      secondCategory?.name ?? '',
                    );
            });
          return [
            for (final categoryId in categoryIds) ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    categoryById[categoryId]?.name ?? 'Sem categoria',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              for (final item in itemsByCategory[categoryId]!)
                _plannedItemCard(
                  context: context,
                  item: item,
                  product: availableProducts.firstWhere(
                    (product) => product.id == item.productId,
                  ),
                  selectedPlannedItemId: selectedPlannedItemId,
                  inCartQuantity: quantitiesByPlannedItem[item.id] ?? 0,
                  onTap: () {
                    setState(() {
                      selectedProductId = item.productId;
                      selectedPlannedItemId = item.id;
                      mode = _measurementMode(item.measurementMode);
                      showMeasurementModeError = false;
                    });
                  },
                ),
            ],
          ];
        }

        if (!matchingPlannedItems.any(
          (item) => item.id == selectedPlannedItemId,
        )) {
          selectedPlannedItemId = null;
        }
        if (selection == PurchaseLineSelection.planned &&
            selectedPlannedItemId == null) {
          selectedProductId = null;
        }
        return AlertDialog(
          title: Text(
            existingLine == null ? 'Adicionar ao carrinho' : 'Editar linha',
          ),
          content: SizedBox(
            width: 420,
            child: availableProducts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      selection == PurchaseLineSelection.planned
                          ? 'Esta lista não tem itens planejados disponíveis.'
                          : 'Não há produtos fora da lista para adicionar.',
                    ),
                  )
                : Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (existingLine == null &&
                              selection == PurchaseLineSelection.planned &&
                              availablePlannedItems.isNotEmpty) ...[
                            if (remainingPlannedItems.isNotEmpty) ...[
                              const Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text('Itens da lista'),
                              ),
                              ...categoryGroups(remainingPlannedItems),
                            ],
                            if (alreadyInCartItems.isNotEmpty) ...[
                              const Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: Text('Já inserido no carrinho'),
                                ),
                              ),
                              ...categoryGroups(alreadyInCartItems),
                            ],
                            if (showPlannedSelectionError)
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Selecione um item planejado.',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                          if (existingLine == null &&
                              selection == PurchaseLineSelection.all &&
                              availablePlannedItems.isNotEmpty) ...[
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                'Itens da lista',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                'Os produtos planejados estão destacados em azul. Informe abaixo a quantidade realmente comprada.',
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...categoryGroups(availablePlannedItems),
                            const SizedBox(height: 8),
                          ],
                          if (existingLine == null &&
                              selection != PurchaseLineSelection.planned)
                            DropdownButtonFormField<int>(
                              key: ValueKey(selectedProductId),
                              isExpanded: true,
                              initialValue: selectedProductId,
                              decoration: const InputDecoration(
                                labelText: 'Produto',
                              ),
                              items: [
                                for (final product in availableProducts)
                                  DropdownMenuItem(
                                    value: product.id,
                                    child: Text(
                                      product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              validator: (value) =>
                                  value == null ? 'Escolha um produto.' : null,
                              onChanged: (value) {
                                final product = availableProducts
                                    .where((row) => row.id == value)
                                    .firstOrNull;
                                setState(() {
                                  selectedProductId = value;
                                  selectedPlannedItemId = null;
                                  showMeasurementModeError = false;
                                  mode = _measurementMode(
                                    product?.measurementMode,
                                  );
                                });
                              },
                            )
                          else
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                availableProducts
                                        .where(
                                          (product) =>
                                              product.id ==
                                              existingLine?.productId,
                                        )
                                        .firstOrNull
                                        ?.name ??
                                    existingLine?.productNameSnapshot ??
                                    'Produto',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          if (mode == MeasurementMode.pending) ...[
                            const InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Forma de compra cadastrada',
                                border: OutlineInputBorder(),
                              ),
                              child: Text('Pendente de definição'),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Defina unidade, pacote ou peso no cadastro do produto antes de adicionar ao carrinho.',
                              ),
                            ),
                            if (showMeasurementModeError)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'A forma de compra só pode ser definida no cadastro do produto.',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                          ],
                          if (planId != null &&
                              existingLine == null &&
                              selection == PurchaseLineSelection.all)
                            DropdownButtonFormField<int>(
                              isExpanded: true,
                              initialValue: selectedPlannedItemId,
                              decoration: const InputDecoration(
                                labelText: 'Item planejado (opcional)',
                              ),
                              items: [
                                const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text('Compra fora do planejamento'),
                                ),
                                for (final item in matchingPlannedItems)
                                  DropdownMenuItem(
                                    value: item.id,
                                    child: Text(
                                      'Atender ${_quantityLabel(item.measurementMode, item.quantity)}',
                                    ),
                                  ),
                              ],
                              onChanged: (value) =>
                                  setState(() => selectedPlannedItemId = value),
                            ),
                          if (mode == MeasurementMode.weight)
                            _weightInputUnit(
                              value: weightUnit,
                              onChanged: (value) =>
                                  setState(() => weightUnit = value),
                            ),
                          TextFormField(
                            initialValue: quantityText,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal:
                                  mode == MeasurementMode.weight &&
                                  weightUnit == WeightInputUnit.kilograms,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(
                                  mode == MeasurementMode.weight &&
                                          weightUnit ==
                                              WeightInputUnit.kilograms
                                      ? r'[0-9,.]'
                                      : r'[0-9]',
                                ),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: mode == MeasurementMode.weight
                                  ? 'Peso'
                                  : mode == MeasurementMode.package
                                  ? 'Quantidade de pacotes'
                                  : 'Quantidade',
                              suffixText: mode == MeasurementMode.weight
                                  ? weightUnit == WeightInputUnit.grams
                                        ? 'g'
                                        : 'kg'
                                  : mode.quantityUnit,
                            ),
                            onChanged: (value) => quantityText = value,
                            validator: (value) =>
                                _quantityError(value ?? '', mode, weightUnit),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            initialValue: priceText,
                            keyboardType: TextInputType.number,
                            inputFormatters: const [CentsInputFormatter()],
                            decoration: InputDecoration(
                              labelText: mode == MeasurementMode.weight
                                  ? 'Preço real por kg'
                                  : mode == MeasurementMode.package
                                  ? 'Preço real por pacote'
                                  : 'Preço real por unidade',
                              prefixText: 'R\$ ',
                              helperText: 'Deixe vazio para marcar o preço como pendente.',
                            ),
                            onChanged: (value) => priceText = value,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }
                              try {
                                ShoppingCalculations.parseMoneyToCents(value);
                                return null;
                              } on FormatException catch (error) {
                                return error.message;
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: availableProducts.isEmpty
                  ? null
                  : () {
                      if (mode == MeasurementMode.pending) {
                        setState(() => showMeasurementModeError = true);
                        return;
                      }
                      if (selection == PurchaseLineSelection.planned &&
                          selectedPlannedItemId == null) {
                        setState(() => showPlannedSelectionError = true);
                        return;
                      }
                      if (!formKey.currentState!.validate()) {
                        return;
                      }
                      Navigator.pop(
                        dialogContext,
                        PurchaseLineDraft(
                          productId: selectedProductId!,
                          plannedItemId: selectedPlannedItemId,
                          mode: mode,
                          quantity: _parseQuantity(
                            quantityText,
                            mode,
                            weightUnit,
                          ),
                          unitPriceCents: priceText.trim().isEmpty
                              ? null
                              : ShoppingCalculations.parseMoneyToCents(
                                  priceText,
                                ),
                        ),
                      );
                    },
              child: const Text('Salvar linha'),
            ),
          ],
        );
      },
    ),
  );
  return result;
}

Future<bool> confirmCompleteTrip({
  required BuildContext context,
  required int totalCents,
  required int lineCount,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Concluir compra?'),
          content: Text(
            'Serão registradas $lineCount linhas como compra concluída, '
            'com total de ${ShoppingCalculations.formatMoney(totalCents)}. '
            'Essa confirmação grava o histórico e não pode ser desfeita nesta etapa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Concluir compra'),
            ),
          ],
        ),
      ) ??
      false;
}

Future<int?> showManualEstimateDialog({
  required BuildContext context,
  required MeasurementMode mode,
}) async {
  final formKey = GlobalKey<FormState>();
  var priceText = '';
  return showDialog<int>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Definir preço estimado'),
      content: Form(
        key: formKey,
        child: TextFormField(
          initialValue: priceText,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: const [CentsInputFormatter()],
          decoration: InputDecoration(
            labelText: mode == MeasurementMode.weight
                ? 'Estimativa por kg'
                : mode == MeasurementMode.package
                ? 'Estimativa por pacote'
                : 'Estimativa por unidade',
            prefixText: 'R\$ ',
            helperText: 'Este valor será marcado como estimativa manual.',
          ),
          onChanged: (value) => priceText = value,
          validator: (value) {
            try {
              ShoppingCalculations.parseMoneyToCents(value ?? '');
              return null;
            } on FormatException catch (error) {
              return error.message;
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(
                dialogContext,
                ShoppingCalculations.parseMoneyToCents(priceText),
              );
            }
          },
          child: const Text('Salvar estimativa'),
        ),
      ],
    ),
  );
}

Future<bool> confirmRemoveLine(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Remover linha?'),
          content: const Text('A linha será removida do carrinho atual.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remover'),
            ),
          ],
        ),
      ) ??
      false;
}

Widget _weightInputUnit({
  required WeightInputUnit value,
  required ValueChanged<WeightInputUnit> onChanged,
}) {
  return SegmentedButton<WeightInputUnit>(
    segments: const [
      ButtonSegment(value: WeightInputUnit.grams, label: Text('Gramas')),
      ButtonSegment(value: WeightInputUnit.kilograms, label: Text('Quilos')),
    ],
    selected: {value},
    onSelectionChanged: (selection) => onChanged(selection.single),
  );
}

String? _quantityError(
  String input,
  MeasurementMode mode,
  WeightInputUnit weightUnit,
) {
  if (mode == MeasurementMode.pending) {
    return 'Defina unidade, pacote ou peso.';
  }
  try {
    _parseQuantity(input, mode, weightUnit);
    return null;
  } on FormatException catch (error) {
    return error.message;
  }
}

int _parseQuantity(
  String input,
  MeasurementMode mode,
  WeightInputUnit weightUnit,
) {
  return mode == MeasurementMode.weight
      ? ShoppingCalculations.parseWeightGrams(input, weightUnit)
      : ShoppingCalculations.parseUnitQuantity(input);
}

MeasurementMode _measurementMode(String? value) {
  return MeasurementMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => MeasurementMode.pending,
  );
}

String _quantityLabel(String mode, int quantity) {
  final measurementMode = _measurementMode(mode);
  return ShoppingCalculations.formatQuantity(measurementMode, quantity);
}

String _moneyForInput(int cents) {
  final whole = cents ~/ 100;
  final fraction = (cents % 100).toString().padLeft(2, '0');
  return '$whole,$fraction';
}

Widget _plannedItemCard({
  required BuildContext context,
  required PlannedItem item,
  required Product product,
  required int? selectedPlannedItemId,
  required int inCartQuantity,
  required VoidCallback onTap,
}) {
  final selected = item.id == selectedPlannedItemId;
  final inserted = inCartQuantity >= item.quantity;
  final exceeded = inCartQuantity > item.quantity;
  final mode = _measurementMode(item.measurementMode);
  return Card(
    color: inserted
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : selected
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceContainerHigh,
    child: ListTile(
      dense: true,
      leading: Icon(
        inserted
            ? Icons.check_circle
            : selected
            ? Icons.check_circle
            : Icons.playlist_add_check,
        color: inserted
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        product.name,
        style: inserted
            ? TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)
            : null,
      ),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text:
                  'Na lista · planejado: ${_quantityLabel(item.measurementMode, item.quantity)}',
            ),
            if (inCartQuantity > 0) ...[
              const TextSpan(text: '\nNo carrinho: '),
              TextSpan(
                text: ShoppingCalculations.formatQuantity(mode, inCartQuantity),
                style: exceeded
                    ? TextStyle(color: Theme.of(context).colorScheme.error)
                    : null,
              ),
              TextSpan(
                text:
                    ' / ${ShoppingCalculations.formatQuantity(mode, item.quantity)}',
              ),
            ],
          ],
        ),
      ),
      onTap: onTap,
    ),
  );
}

Future<PurchaseLineDraft?> showQuickAddToCartSheet({
  required BuildContext context,
  required Product product,
  required PlannedItem? plannedItem,
  required int initialQuantity,
  required MeasurementMode mode,
  String? lastPricePaidText,
  PurchaseLine? existingLine,
}) async {
  var quantityText = '$initialQuantity';
  var isLabelTotal = existingLine?.isLabelTotal ?? false;
  var priceText = existingLine == null
      ? ''
      : _moneyForInput(
          isLabelTotal
              ? existingLine.totalCents ?? 0
              : existingLine.unitPriceCents ?? 0,
        );
  var weightUnit = WeightInputUnit.grams;
  final formKey = GlobalKey<FormState>();

  return showModalBottomSheet<PurchaseLineDraft>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (lastPricePaidText != null)
                          Text(
                            'Último pago: $lastPricePaidText',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (mode == MeasurementMode.weight) ...[
                Row(
                  children: [
                    Expanded(
                      child: _weightInputUnit(
                        value: weightUnit,
                        onChanged: (u) => setState(() => weightUnit = u),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              TextFormField(
                initialValue: quantityText,
                autofocus: false,
                keyboardType: TextInputType.numberWithOptions(
                  decimal:
                      mode == MeasurementMode.weight &&
                      weightUnit == WeightInputUnit.kilograms,
                ),
                decoration: InputDecoration(
                  labelText: mode == MeasurementMode.weight
                      ? 'Peso a comprar'
                      : 'Quantidade a comprar',
                  suffixText: mode == MeasurementMode.weight
                      ? (weightUnit == WeightInputUnit.grams ? 'g' : 'kg')
                      : mode.quantityUnit,
                ),
                onChanged: (val) => quantityText = val,
                validator: (val) => _quantityError(val ?? '', mode, weightUnit),
              ),
              const SizedBox(height: 12),
              if (mode == MeasurementMode.weight) ...[
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Preço por kg'),
                      selected: !isLabelTotal,
                      onSelected: (val) => setState(() => isLabelTotal = !val),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Total da etiqueta'),
                      selected: isLabelTotal,
                      onSelected: (val) => setState(() => isLabelTotal = val),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              TextFormField(
                initialValue: priceText,
                keyboardType: TextInputType.number,
                inputFormatters: const [CentsInputFormatter()],
                decoration: InputDecoration(
                  labelText: isLabelTotal
                      ? 'Valor total na etiqueta'
                      : mode == MeasurementMode.weight
                      ? 'Preço real por kg'
                      : mode == MeasurementMode.package
                      ? 'Preço real por pacote'
                      : 'Preço real por unidade',
                  prefixText: 'R\$ ',
                  helperText: 'Deixe vazio se não quiser informar agora.',
                ),
                onChanged: (val) => priceText = val,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: Icon(
                  existingLine == null
                      ? Icons.add_shopping_cart
                      : Icons.save_outlined,
                ),
                label: Text(
                  existingLine == null ? 'Colocar no carrinho' : 'Salvar linha',
                ),
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  final parsedQuantity = _parseQuantity(
                    quantityText,
                    mode,
                    weightUnit,
                  );

                  int? unitPriceCents;
                  int? labelTotalCents;
                  if (priceText.trim().isNotEmpty) {
                    final rawCents = ShoppingCalculations.parseMoneyToCents(
                      priceText,
                    );
                    if (isLabelTotal && mode == MeasurementMode.weight) {
                      labelTotalCents = rawCents;
                      if (parsedQuantity > 0) {
                        unitPriceCents = (rawCents * 1000) ~/ parsedQuantity;
                      }
                    } else {
                      unitPriceCents = rawCents;
                    }
                  }

                  Navigator.pop(
                    sheetContext,
                    PurchaseLineDraft(
                      productId: product.id,
                      plannedItemId: plannedItem?.id,
                      mode: mode,
                      quantity: parsedQuantity,
                      unitPriceCents: unitPriceCents,
                      labelTotalCents: labelTotalCents,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
