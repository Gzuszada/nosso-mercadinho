import 'package:flutter/material.dart';

import '../../../data/app_database.dart';
import '../data/catalog_import.dart';

class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.categoryId,
    required this.subcategoryId,
    required this.measurementMode,
    required this.needsCategoryReview,
    required this.description,
  });

  final String name;
  final int? categoryId;
  final int? subcategoryId;
  final MeasurementMode measurementMode;
  final bool needsCategoryReview;
  final String? description;
}

Future<ProductDraft?> showProductDialog({
  required BuildContext context,
  required List<Category> categories,
  required List<Subcategory> subcategories,
  Product? product,
}) async {
  return showDialog<ProductDraft>(
    context: context,
    builder: (_) => _ProductDialog(
      categories: categories,
      subcategories: subcategories,
      product: product,
    ),
  );
}

class _ProductDialog extends StatefulWidget {
  const _ProductDialog({
    required this.categories,
    required this.subcategories,
    required this.product,
  });

  final List<Category> categories;
  final List<Subcategory> subcategories;
  final Product? product;

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  final _formKey = GlobalKey<FormState>();
  late int _categoryId;
  late int _subcategoryId;
  late MeasurementMode _measurementMode;
  late bool _needsCategoryReview;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _categoryId = widget.product?.categoryId ?? 0;
    _subcategoryId = widget.product?.subcategoryId ?? 0;
    _measurementMode = MeasurementMode.values.firstWhere(
      (mode) => mode.name == widget.product?.measurementMode,
      orElse: () => MeasurementMode.pending,
    );
    _needsCategoryReview =
        widget.product?.needsCategoryReview ?? _categoryId == 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableCategories = widget.categories
        .where(
          (category) =>
              !category.isArchived || category.id == widget.product?.categoryId,
        )
        .toList();
    final availableSubcategories = widget.subcategories
        .where(
          (subcategory) =>
              subcategory.categoryId == _categoryId &&
              (!subcategory.isArchived ||
                  subcategory.id == widget.product?.subcategoryId),
        )
        .toList();

    return AlertDialog(
      title: Text(widget.product == null ? 'Novo produto' : 'Editar produto'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  maxLength: 160,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Informe o nome do produto.'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: [
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('A classificar'),
                    ),
                    for (final category in availableCategories)
                      DropdownMenuItem(
                        value: category.id,
                        child: Text(
                          category.isArchived
                              ? '${category.name} (arquivada)'
                              : category.name,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _categoryId = value ?? 0;
                      _subcategoryId = 0;
                      _needsCategoryReview = _categoryId == 0;
                    });
                  },
                ),
                if (_categoryId != 0) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue:
                        availableSubcategories.any(
                          (item) => item.id == _subcategoryId,
                        )
                        ? _subcategoryId
                        : 0,
                    decoration: const InputDecoration(
                      labelText: 'Subcategoria',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 0,
                        child: Text('Sem subcategoria'),
                      ),
                      for (final subcategory in availableSubcategories)
                        DropdownMenuItem(
                          value: subcategory.id,
                          child: Text(
                            subcategory.isArchived
                                ? '${subcategory.name} (arquivada)'
                                : subcategory.name,
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _subcategoryId = value ?? 0),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<MeasurementMode>(
                  initialValue: _measurementMode,
                  decoration: const InputDecoration(
                    labelText: 'Forma de compra',
                  ),
                  items: [
                    for (final mode in MeasurementMode.values)
                      DropdownMenuItem(value: mode, child: Text(mode.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _measurementMode = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLength: 500,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observação (opcional)',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Salvar')),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.pop(
      context,
      ProductDraft(
        name: _nameController.text.trim(),
        categoryId: _categoryId == 0 ? null : _categoryId,
        subcategoryId: _subcategoryId == 0 ? null : _subcategoryId,
        measurementMode: _measurementMode,
        needsCategoryReview: _needsCategoryReview,
        description: _descriptionController.text.trim(),
      ),
    );
  }
}

Future<String?> showNameDialog({
  required BuildContext context,
  required String title,
  String? initialName,
  int maxLength = 100,
}) async {
  final controller = TextEditingController(text: initialName ?? '');
  final formKey = GlobalKey<FormState>();
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          maxLength: maxLength,
          decoration: const InputDecoration(labelText: 'Nome'),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Informe um nome.' : null,
          onFieldSubmitted: (_) {
            if (formKey.currentState!.validate()) {
              Navigator.pop(dialogContext, controller.text.trim());
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
              Navigator.pop(dialogContext, controller.text.trim());
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

Future<bool> confirmArchive({
  required BuildContext context,
  required String itemName,
  required bool isArchived,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(isArchived ? 'Reativar item?' : 'Arquivar item?'),
      content: Text(
        isArchived
            ? '“$itemName” voltará a aparecer entre os itens ativos.'
            : '“$itemName” será ocultado dos itens ativos. O cadastro não será apagado.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(isArchived ? 'Reativar' : 'Arquivar'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

Future<bool> showCatalogImportPreview(
  BuildContext context,
  CatalogImport catalog,
) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Revisar catálogo inicial'),
      content: SizedBox(
        width: 480,
        height: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${catalog.items.length} produtos · '
              '${catalog.items.map((item) => item.suggestedCategory).whereType<String>().toSet().length} categorias sugeridas',
            ),
            if (catalog.productsWithoutCategory > 0)
              Text(
                '${catalog.productsWithoutCategory} sem categoria: ficarão como “A classificar”.',
              ),
            const SizedBox(height: 8),
            Text(
              'Todos os produtos ficarão com a forma de compra pendente. Nenhuma compra ou preço será importado.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(catalog.warning, style: Theme.of(context).textTheme.bodySmall),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: catalog.items.length,
                itemBuilder: (context, index) {
                  final item = catalog.items[index];
                  return ListTile(
                    dense: true,
                    title: Text(item.name),
                    subtitle: Text(item.suggestedCategory ?? 'A classificar'),
                    trailing: const Icon(
                      Icons.help_outline,
                      semanticLabel: 'Unidade ou peso pendente de revisão',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Voltar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text('Importar ${catalog.items.length} produtos'),
        ),
      ],
    ),
  );
  return accepted ?? false;
}
