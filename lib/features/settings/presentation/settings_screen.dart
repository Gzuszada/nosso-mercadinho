import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_providers.dart';
import '../../cloud/presentation/cloud_sync_screen.dart';
import '../data/reset_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          darkMode.when(
            loading: () => const ListTile(
              leading: Icon(Icons.dark_mode_outlined),
              title: Text('Modo escuro'),
              subtitle: Text('Carregando preferência…'),
            ),
            error: (error, _) => ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('Não foi possível carregar a preferência'),
              subtitle: Text('$error'),
            ),
            data: (enabled) => SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Modo escuro'),
              subtitle: const Text('Aplicar tema escuro em todo o aplicativo.'),
              value: enabled,
              onChanged: (value) => _setDarkMode(context, ref, value),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_sync_outlined),
            title: const Text('Conta e sincronização'),
            subtitle: Text(
              ref.watch(selectedCloudHouseholdProvider).asData?.value?.name ?? 'Gerenciar a conta, criar uma casa ou compartilhar os dados com outra pessoa.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CloudSyncScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Resetar base'),
            subtitle: const Text(
              'Limpe áreas específicas ou todos os dados do aplicativo.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ResetDatabaseScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setDarkMode(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    try {
      await ref.read(settingsRepositoryProvider).setDarkMode(enabled);
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível salvar o tema: $error')),
        );
      }
    }
  }
}

enum _ResetArea { lists, unfinishedPurchases, history, products, categories }

class ResetDatabaseScreen extends ConsumerStatefulWidget {
  const ResetDatabaseScreen({super.key});

  @override
  ConsumerState<ResetDatabaseScreen> createState() =>
      _ResetDatabaseScreenState();
}

class _ResetDatabaseScreenState extends ConsumerState<ResetDatabaseScreen> {
  final Set<_ResetArea> _selected = {};
  bool _clearAll = false;
  bool _isClearing = false;

  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(resetPreviewProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Resetar base')),
      body: preview.when(
        loading: () => const Center(child: Text('Carregando os dados…')),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Não foi possível ler os dados atuais: $error'),
          ),
        ),
        data: (counts) => ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          children: [
            const Card(
              child: ListTile(
                leading: Icon(Icons.warning_amber_outlined),
                title: Text('A limpeza é permanente'),
                subtitle: Text(
                  'Exporte e verifique um backup antes de apagar dados.',
                ),
              ),
            ),
            CheckboxListTile(
              value: _selected.contains(_ResetArea.lists),
              onChanged: _isClearing
                  ? null
                  : (value) => _toggle(_ResetArea.lists, value ?? false),
              title: const Text('Listas'),
              subtitle: Text(
                '${_count(counts.lists, 'lista', 'listas')} e ${_count(counts.plannedItems, 'item planejado', 'itens planejados')}. Compras e histórico serão preservados, sem vínculo com as listas removidas.',
              ),
            ),
            CheckboxListTile(
              value: _selected.contains(_ResetArea.unfinishedPurchases),
              onChanged: _isClearing
                  ? null
                  : (value) =>
                        _toggle(_ResetArea.unfinishedPurchases, value ?? false),
              title: const Text('Carrinhos em andamento e cancelados'),
              subtitle: Text(
                '${counts.inProgressPurchases} em andamento e ${_count(counts.canceledPurchases, 'cancelado', 'cancelados')}; compras concluídas ficam preservadas.',
              ),
            ),
            CheckboxListTile(
              value: _selected.contains(_ResetArea.history),
              onChanged: _isClearing
                  ? null
                  : (value) => _toggle(_ResetArea.history, value ?? false),
              title: const Text('Histórico (compras concluídas)'),
              subtitle: Text(
                '${_count(counts.completedPurchases, 'compra concluída', 'compras concluídas')}. Estimativas históricas que dependem delas também serão removidas.',
              ),
            ),
            CheckboxListTile(
              value: _selected.contains(_ResetArea.products),
              onChanged: _isClearing
                  ? null
                  : (value) => _toggle(_ResetArea.products, value ?? false),
              title: const Text('Produtos'),
              subtitle: Text(
                '${_count(counts.products, 'produto', 'produtos')}: ${counts.referencedProducts} com vínculos serão arquivados para preservar listas e histórico; ${counts.products - counts.referencedProducts} sem vínculos serão excluídos.',
              ),
            ),
            CheckboxListTile(
              value: _selected.contains(_ResetArea.categories),
              onChanged: _isClearing
                  ? null
                  : (value) => _toggle(_ResetArea.categories, value ?? false),
              title: const Text('Categorias'),
              subtitle: Text(
                '${_count(counts.categories, 'categoria', 'categorias')} e ${_count(counts.subcategories, 'subcategoria', 'subcategorias')}. Produtos permanecem sem classificação.',
              ),
            ),
            const Divider(),
            CheckboxListTile(
              value: _clearAll,
              onChanged: _isClearing
                  ? null
                  : (value) => setState(() {
                      _clearAll = value ?? false;
                      _selected.clear();
                    }),
              title: const Text('Limpar tudo'),
              subtitle: Text(
                'Remove ${_count(counts.products, 'produto', 'produtos')}, categorias, listas, ${_count(counts.totalPurchases, 'compra', 'compras')} e ${_count(counts.importBatches, 'importação', 'importações')} (${_count(counts.importEntries, 'item de origem', 'itens de origem')}). O tema será mantido.',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isClearing || (!_clearAll && _selected.isEmpty)
                  ? null
                  : () => _confirmAndClear(counts),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Continuar para confirmação'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggle(_ResetArea area, bool selected) {
    setState(() {
      _clearAll = false;
      if (selected) {
        _selected.add(area);
      } else {
        _selected.remove(area);
      }
    });
  }

  Future<void> _confirmAndClear(ResetPreview counts) async {
    final selection = ResetSelection(
      lists: _selected.contains(_ResetArea.lists),
      unfinishedPurchases: _selected.contains(_ResetArea.unfinishedPurchases),
      history: _selected.contains(_ResetArea.history),
      products: _selected.contains(_ResetArea.products),
      categories: _selected.contains(_ResetArea.categories),
      all: _clearAll,
    );
    final details = _confirmationDetails(selection, counts);
    final approvedSummary = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confira o que será apagado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final detail in details)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $detail'),
                ),
              if (!selection.all && selection.history)
                const Text(
                  'Estimativas históricas ligadas às compras removidas também serão apagadas; estimativas manuais permanecem.',
                ),
              const SizedBox(height: 12),
              const Text(
                'Essa ação é permanente. Tenha um backup verificado antes de continuar.',
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
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (approvedSummary != true || !mounted) {
      return;
    }

    final phrase = selection.confirmationPhrase;
    final typedPhrase = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        var input = '';
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Tem certeza mesmo?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Para confirmar, digite exatamente:'),
                const SizedBox(height: 8),
                SelectableText(
                  phrase,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  autofocus: true,
                  onChanged: (value) => setDialogState(() => input = value),
                  decoration: const InputDecoration(
                    labelText: 'Confirmação',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: input.trim().toUpperCase() == phrase
                    ? () => Navigator.pop(dialogContext, true)
                    : null,
                child: const Text('Apagar dados'),
              ),
            ],
          ),
        );
      },
    );
    if (typedPhrase != true || !mounted) {
      return;
    }

    setState(() => _isClearing = true);
    try {
      await ref.read(resetServiceProvider).clear(selection);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Limpeza concluída.')));
      Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível limpar os dados: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  List<String> _confirmationDetails(
    ResetSelection selection,
    ResetPreview counts,
  ) {
    if (selection.all) {
      return [
        '${counts.products} produtos',
        '${counts.categories} categorias e ${counts.subcategories} subcategorias',
        '${counts.lists} listas e ${counts.plannedItems} itens planejados',
        '${counts.inProgressPurchases} carrinhos em andamento, ${counts.canceledPurchases} cancelados e ${counts.completedPurchases} compras concluídas',
        '${counts.importBatches} importações e ${counts.importEntries} itens de origem',
        'A preferência de tema será mantida',
      ];
    }

    return [
      if (selection.lists)
        '${counts.lists} listas e ${counts.plannedItems} itens planejados serão apagados; compras e histórico serão preservados sem vínculo com as listas.',
      if (selection.unfinishedPurchases)
        '${counts.inProgressPurchases} carrinhos em andamento e ${counts.canceledPurchases} cancelados serão apagados.',
      if (selection.history)
        '${counts.completedPurchases} compras concluídas e o histórico correspondente serão apagados.',
      if (selection.products)
        '${counts.referencedProducts} produtos com vínculos serão arquivados; ${counts.products - counts.referencedProducts} sem vínculos serão excluídos.',
      if (selection.categories)
        '${counts.categories} categorias e ${counts.subcategories} subcategorias serão apagadas; produtos ficarão sem classificação.',
    ];
  }

  String _count(int quantity, String singular, String plural) =>
      '$quantity ${quantity == 1 ? singular : plural}';
}
