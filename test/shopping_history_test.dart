import 'package:flutter_test/flutter_test.dart';
import 'package:mercado/features/shopping/domain/shopping_history.dart';
import 'package:mercado/features/catalog/data/catalog_import.dart';

void main() {
  test('weighted estimates retain the exact rate until final rounding', () {
    expect(
      ShoppingHistoryCalculations.displayUnitPriceCents(
        mode: MeasurementMode.unit,
        amountCents: 3850,
        quantityBasis: 5,
      ),
      770,
    );
    expect(
      ShoppingHistoryCalculations.estimateTotalCents(
        quantity: 3,
        amountCents: 3850,
        quantityBasis: 5,
      ),
      2310,
    );
    expect(
      ShoppingHistoryCalculations.estimateTotalCents(
        quantity: 750,
        amountCents: 8141,
        quantityBasis: 1950,
      ),
      3131,
    );
    expect(
      ShoppingHistoryCalculations.estimateTotalCents(
        quantity: 1,
        amountCents: 1,
        quantityBasis: 2,
      ),
      1,
    );
  });

  test('mês anterior atravessa ano e valida limites civis', () {
    expect(ShoppingHistoryCalculations.previousMonthKey('2026-01'), '2025-12');
    expect(ShoppingHistoryCalculations.previousMonthKey('2026-12'), '2026-11');
    expect(
      ShoppingHistoryCalculations.firstDayOfNextMonth('2026-12'),
      DateTime(2027, 1),
    );
    expect(
      () => ShoppingHistoryCalculations.previousMonthKey('2026-13'),
      throwsFormatException,
    );
  });

  test('frequência ignora horas e exige três datas distintas', () {
    expect(
      ShoppingHistoryCalculations.medianIntervalDays([
        DateTime(2026, 1, 1, 8),
        DateTime(2026, 1, 1, 20),
        DateTime(2026, 1, 11),
      ]),
      isNull,
    );
    expect(
      ShoppingHistoryCalculations.medianIntervalDays([
        DateTime(2026, 1, 1, 8),
        DateTime(2026, 1, 11),
        DateTime(2026, 1, 31),
      ]),
      15,
    );
  });
}
