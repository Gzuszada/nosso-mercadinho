import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app_providers.dart';
import '../data/shopping_repository.dart';
import '../domain/shopping_calculations.dart';
import '../domain/shopping_history.dart';
import 'product_purchase_history_screen.dart';
import 'shopping_trips_screen.dart';

class ShoppingHistoryScreen extends ConsumerStatefulWidget {
  const ShoppingHistoryScreen({this.initialMonth, super.key});

  final DateTime? initialMonth;

  @override
  ConsumerState<ShoppingHistoryScreen> createState() =>
      _ShoppingHistoryScreenState();
}

class _ShoppingHistoryScreenState extends ConsumerState<ShoppingHistoryScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = widget.initialMonth ?? DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final monthKey = ShoppingHistoryCalculations.monthKey(_selectedMonth);
    final report = ref.watch(monthlyHistoryProvider(monthKey));
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico mensal')),
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Não foi possível carregar o histórico: $error'),
          ),
        ),
        data: (value) => _buildReport(context, value),
      ),
    );
  }

  Widget _buildReport(BuildContext context, MonthlyHistoryReport report) {
    final previousMonthKey = ShoppingHistoryCalculations.previousMonthKey(
      report.monthKey,
    );
    final monthTitle = _formatMonth(report.monthKey);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        Card(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Mês anterior',
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: _chooseMonth,
                      child: Text(
                        monthTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Próximo mês',
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Gasto concluído no mês'),
                subtitle: Text(
                  report.trips.isEmpty
                      ? 'Nenhuma compra concluída em $monthTitle.'
                      : '${report.trips.length} compra(s) pela data real.',
                ),
                trailing: Text(
                  ShoppingCalculations.formatMoney(report.totalCents),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (report.products.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
            child: Text(
              'Produtos comprados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final product in report.products)
            _MonthlyProductCard(
              product: product,
              selectedMonth: report.monthKey,
              previousMonth: previousMonthKey,
            ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
          child: Text(
            'Compras do mês',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (report.trips.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.history),
              title: Text('Sem compras concluídas neste mês'),
              subtitle: Text(
                'Carrinhos em andamento e compras canceladas não aparecem como gasto.',
              ),
            ),
          )
        else
          for (final event in report.trips)
            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(_formatDate(event.trip.purchaseDate)),
                subtitle: Text(
                  [
                    if (event.trip.marketName != null) event.trip.marketName!,
                    '${event.lines.length} linha(s)',
                  ].join(' · '),
                ),
                trailing: Text(
                  ShoppingCalculations.formatMoney(event.totalCents),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ShoppingTripDetailScreen(tripId: event.trip.id),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  void _changeMonth(int delta) {
    setState(
      () => _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      ),
    );
  }

  Future<void> _chooseMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Escolha o mês do histórico',
    );
    if (selected != null && mounted) {
      setState(() => _selectedMonth = DateTime(selected.year, selected.month));
    }
  }
}

class _MonthlyProductCard extends StatelessWidget {
  const _MonthlyProductCard({
    required this.product,
    required this.selectedMonth,
    required this.previousMonth,
  });

  final MonthlyProductHistory product;
  final String selectedMonth;
  final String previousMonth;

  @override
  Widget build(BuildContext context) {
    final unit = product.mode.priceUnit;
    final currentAverage = ShoppingHistoryCalculations.displayUnitPriceCents(
      mode: product.mode,
      amountCents: product.totalCents,
      quantityBasis: product.quantity,
    );
    final previousAverage = product.previousMonthQuantity == 0
        ? null
        : ShoppingHistoryCalculations.displayUnitPriceCents(
            mode: product.mode,
            amountCents: product.previousMonthTotalCents,
            quantityBasis: product.previousMonthQuantity,
          );
    final latest = product.latestPurchase;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.shopping_basket_outlined),
        title: Text(product.productName),
        subtitle: Text(
          '${ShoppingCalculations.formatQuantity(product.mode, product.quantity)}'
          ' · ${ShoppingCalculations.formatMoney(product.totalCents)} em ${_formatMonth(selectedMonth)}'
          ' · média ponderada ${ShoppingCalculations.formatMoney(currentAverage)}/$unit'
          '\nMês anterior: ${product.previousMonthQuantity == 0 ? 'não comprado em ${_formatMonth(previousMonth)}' : '${ShoppingCalculations.formatQuantity(product.mode, product.previousMonthQuantity)} · ${ShoppingCalculations.formatMoney(product.previousMonthTotalCents)} · média ${ShoppingCalculations.formatMoney(previousAverage!)}/$unit'}'
          '\nÚltima compra disponível até ${_formatMonth(selectedMonth)}: ${latest == null ? 'nenhuma' : '${_formatDate(latest.trip.purchaseDate)} · ${ShoppingCalculations.formatMoney(latest.unitPriceCents)}/$unit'}',
        ),
        isThreeLine: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ProductPurchaseHistoryScreen(productId: product.productId),
          ),
        ),
      ),
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
