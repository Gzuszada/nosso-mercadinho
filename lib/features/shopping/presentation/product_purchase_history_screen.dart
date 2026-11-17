import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app_providers.dart';
import '../../catalog/data/catalog_import.dart';
import '../data/shopping_repository.dart';
import '../domain/shopping_calculations.dart';

class ProductPurchaseHistoryScreen extends ConsumerStatefulWidget {
  const ProductPurchaseHistoryScreen({
    required this.productId,
    this.asOfDate,
    super.key,
  });

  final int productId;
  final DateTime? asOfDate;

  @override
  ConsumerState<ProductPurchaseHistoryScreen> createState() =>
      _ProductPurchaseHistoryScreenState();
}

class _ProductPurchaseHistoryScreenState
    extends ConsumerState<ProductPurchaseHistoryScreen> {
  late final DateTime _asOfDate;

  @override
  void initState() {
    super.initState();
    _asOfDate = widget.asOfDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(
      productPurchaseHistoryProvider((widget.productId, _asOfDate)),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico do produto')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Não foi possível carregar o histórico: $error'),
          ),
        ),
        data: (value) => _buildHistory(context, value),
      ),
    );
  }

  Widget _buildHistory(BuildContext context, ProductPurchaseHistory history) {
    final lastPurchase = history.events.firstOrNull;
    final unit = history.mode.priceUnit;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(history.productName),
            subtitle: Text(
              history.mode == MeasurementMode.pending
                  ? 'Forma de compra pendente de revisão.'
                  : history.mode == MeasurementMode.weight
                  ? 'Preço histórico por kg'
                  : history.mode == MeasurementMode.package
                  ? 'Preço histórico por pacote'
                  : 'Preço histórico por unidade',
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Frequência observada',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (lastPurchase == null)
                  const Text(
                    'Sem compras concluídas registradas para este produto.',
                  )
                else ...[
                  Text(
                    'Última compra: ${_formatDate(lastPurchase.trip.purchaseDate)}'
                    ' · ${history.daysSinceLastPurchase} dia(s) atrás',
                  ),
                  Text(
                    'Datas de compra distintas: ${history.events.map((event) => event.trip.purchaseDate).toSet().length}.',
                  ),
                  if (history.medianIntervalDays case final interval?)
                    Text(
                      'Intervalo observado aproximado: mediana de $interval dia(s).',
                    )
                  else
                    const Text(
                      'Ainda sem histórico suficiente para sugerir um intervalo (são necessárias ao menos três datas distintas).',
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Meses observados: ${history.observedMonths.map(_formatMonth).join(', ')}',
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
          child: Text(
            'Compras concluídas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (history.events.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.history),
              title: Text('Nenhuma compra histórica'),
              subtitle: Text(
                'Planejamentos, carrinhos e compras canceladas não contam como histórico.',
              ),
            ),
          )
        else
          for (final event in history.events)
            Card(
              child: ExpansionTile(
                title: Text(_formatDate(event.trip.purchaseDate)),
                subtitle: Text(
                  '${event.trip.marketName ?? 'Mercado não informado'} · '
                  '${ShoppingCalculations.formatQuantity(history.mode, event.quantity)}'
                  ' · ${ShoppingCalculations.formatMoney(event.totalCents)}'
                  ' · ${ShoppingCalculations.formatMoney(event.unitPriceCents)}/$unit',
                ),
                children: [
                  for (final line in event.lines)
                    ListTile(
                      dense: true,
                      title: Text(
                        line.productNameSnapshot ?? history.productName,
                      ),
                      subtitle: Text(
                        '${ShoppingCalculations.formatQuantity(history.mode, line.quantity)}'
                        ' · ${ShoppingCalculations.formatMoney(line.totalCents!)}'
                        ' · ${ShoppingCalculations.formatMoney(line.unitPriceCents!)}/$unit',
                      ),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

String _formatMonth(String monthKey) {
  final parts = monthKey.split('-').map(int.parse).toList();
  return DateFormat.yMMMM('pt_BR').format(DateTime(parts[0], parts[1]));
}

String _formatDate(String value) {
  final parts = value.split('-').map(int.parse).toList();
  return DateFormat.yMMMd('pt_BR')
      .format(DateTime(parts[0], parts[1], parts[2]));
}
