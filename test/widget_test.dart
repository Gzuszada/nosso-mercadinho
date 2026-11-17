import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mercado/app_providers.dart';
import 'package:mercado/data/app_database.dart';
import 'package:mercado/features/catalog/data/catalog_import.dart';
import 'package:mercado/features/catalog/data/catalog_repository.dart';
import 'package:mercado/features/shopping/data/shopping_repository.dart';
import 'package:mercado/features/shopping/presentation/product_purchase_history_screen.dart';
import 'package:mercado/features/shopping/presentation/shopping_plans_screen.dart';
import 'package:mercado/features/shopping/presentation/shopping_history_screen.dart';
import 'package:mercado/features/shopping/presentation/shopping_trips_screen.dart';
import 'package:mercado/main.dart';

void main() {
  late AppDatabase database;

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets(
    'exibe listas vazias e permite abrir catálogo sem compras fictícias',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: const MercadoApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma lista planejada'), findsOneWidget);
      await tester.tap(find.text('Produtos'));
      await tester.pumpAndSettle();
      expect(find.text('Seu catálogo está vazio'), findsOneWidget);
      expect(find.text('Importar catálogo inicial'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets('usa na lista a forma de compra cadastrada do produto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final productId = await CatalogRepository(database).saveProduct(
      name: 'TESTE - produto com nome longo para validar o espaço disponível no seletor',
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );
    await ShoppingRepository(database)
        .createPlan(monthKey: '2026-11', name: 'Lista de teste');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MercadoApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lista de teste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar produto'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.text(
        'TESTE - produto com nome longo para validar o espaço disponível no seletor',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField<MeasurementMode>), findsNothing);

    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text(
        'TESTE - produto com nome longo para validar o espaço disponível no seletor',
      ),
      findsOneWidget,
    );
    expect(
      (await database.select(database.plannedItems).get()).single.productId,
      productId,
    );
    expect(
      (await database.select(database.plannedItems).get())
          .single
          .measurementMode,
      MeasurementMode.unit.name,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('cancela e recolhe uma lista sem apagar seu conteúdo', (
    tester,
  ) async {
    final repository = ShoppingRepository(database);
    final productId = await CatalogRepository(database).saveProduct(
      name: 'Produto preservado',
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );
    final planId = await repository.createPlan(
      monthKey: '2026-11',
      name: 'Lista que será cancelada',
    );
    await repository.addPlannedItem(
      planId: planId,
      productId: productId,
      mode: MeasurementMode.unit,
      quantity: 2,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(home: ShoppingPlansScreen(onOpenTrip: (_) {})),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lista que será cancelada'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ações da lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar lista'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar lista'));
    await tester.pumpAndSettle();

    expect(find.text('Lista cancelada'), findsOneWidget);
    expect(find.text('Produto preservado'), findsOneWidget);
    expect(find.text('Adicionar produto'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Listas canceladas (1)'), findsOneWidget);
    expect(find.text('Lista que será cancelada'), findsNothing);
    await tester.tap(find.text('Listas canceladas (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Lista que será cancelada'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('listas mudam de nova para andamento e realizada', (
    tester,
  ) async {
    final repository = ShoppingRepository(database);
    final productId = await CatalogRepository(database).saveProduct(
      name: 'Produto para lista realizada',
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );
    final planId = await repository.createPlan(
      monthKey: '2026-11',
      name: 'Lista com ciclo completo',
    );
    await repository.addPlannedItem(
      planId: planId,
      productId: productId,
      mode: MeasurementMode.unit,
      quantity: 2,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(home: ShoppingPlansScreen(onOpenTrip: (_) {})),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Novas'), findsOneWidget);
    expect(find.textContaining('· Nova'), findsOneWidget);

    final tripId = await repository.createTrip(
      planId: planId,
      purchaseDate: DateTime(2026, 11, 1),
    );
    await tester.pumpAndSettle();
    expect(find.text('Em andamento'), findsWidgets);

    await repository.addPurchaseLine(
      tripId: tripId,
      productId: productId,
      plannedItemId: (await repository.getPlannedItems(planId)).single.id,
      mode: MeasurementMode.unit,
      quantity: 2,
      unitPriceCents: 500,
    );
    await repository.completeTrip(tripId);
    await tester.pumpAndSettle();

    expect(find.text('Listas realizadas (1)'), findsOneWidget);
    expect(find.textContaining('· Realizada'), findsNothing);
    await tester.tap(find.text('Listas realizadas (1)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('· Realizada'), findsOneWidget);
    await tester.tap(find.text('Lista com ciclo completo'));
    await tester.pumpAndSettle();
    expect(find.text('Lista realizada'), findsOneWidget);
    expect(find.text('Adicionar produto'), findsNothing);
    expect(find.text('Abrir / iniciar compra'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('adicionar item não sobrepõe conferir e concluir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tripId = await ShoppingRepository(database)
        .createTrip(purchaseDate: DateTime(2026, 11, 1));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(home: ShoppingTripDetailScreen(tripId: tripId)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Total no carrinho'));
    await tester.pumpAndSettle();

    final addButton = find.widgetWithText(OutlinedButton, 'Adicionar item');
    final completeButton = find.widgetWithText(
      FilledButton,
      'Conferir e concluir compra',
    );
    expect(addButton, findsOneWidget);
    expect(completeButton, findsOneWidget);
    expect(
      find.text('Adicione itens para calcular a projeção.'),
      findsOneWidget,
    );
    expect(
      tester.getRect(addButton).overlaps(tester.getRect(completeButton)),
      isFalse,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets(
    'itens planejados separam quantidades atendidas e excedentes por categoria',
    (tester) async {
      final repository = ShoppingRepository(database);
      final groceryCategory = await CatalogRepository(database)
          .saveCategory(name: 'Mercearia');
      final hygieneCategory = await CatalogRepository(database)
          .saveCategory(name: 'Higiene');
      final productId = await CatalogRepository(database).saveProduct(
        name: 'Produto planejado azul',
        categoryId: groceryCategory,
        measurementMode: MeasurementMode.unit,
        needsCategoryReview: false,
      );
      final secondProductId = await CatalogRepository(database).saveProduct(
        name: 'Produto de higiene planejado',
        categoryId: hygieneCategory,
        measurementMode: MeasurementMode.unit,
        needsCategoryReview: false,
      );
      final planId = await repository.createPlan(
        monthKey: '2026-11',
        name: 'Lista para compra',
      );
      final plannedItemId = await repository.addPlannedItem(
        planId: planId,
        productId: productId,
        mode: MeasurementMode.unit,
        quantity: 5,
      );
      final secondPlannedItemId = await repository.addPlannedItem(
        planId: planId,
        productId: secondProductId,
        mode: MeasurementMode.unit,
        quantity: 1,
      );
      final tripId = await repository.createTrip(
        planId: planId,
        purchaseDate: DateTime(2026, 11, 1),
      );
      await repository.addPurchaseLine(
        tripId: tripId,
        productId: secondProductId,
        plannedItemId: secondPlannedItemId,
        mode: MeasurementMode.unit,
        quantity: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: MaterialApp(home: ShoppingTripDetailScreen(tripId: tripId)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Total no carrinho'));
      await tester.pumpAndSettle();
      expect(find.text('Adicionar item da lista'), findsOneWidget);
      expect(find.text('Adicionar outro item'), findsOneWidget);
      await tester.tap(find.text('Adicionar item da lista'));
      await tester.pumpAndSettle();

      expect(find.text('Itens da lista'), findsOneWidget);
      expect(find.text('Já inserido no carrinho'), findsOneWidget);
      expect(find.text('Mercearia').last, findsOneWidget);
      expect(find.text('Higiene').last, findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Mercearia').last).dy,
        lessThan(tester.getTopLeft(find.text('Já inserido no carrinho')).dy),
      );
      expect(find.text('Na lista · planejado: 5 un.'), findsOneWidget);
      final plannedCard = find
          .ancestor(
            of: find.descendant(
              of: find.byType(AlertDialog),
              matching: find.text('Produto planejado azul'),
            ),
            matching: find.byType(Card),
          )
          .first;
      expect(
        tester.widget<Card>(plannedCard).color,
        Theme.of(tester.element(plannedCard)).colorScheme.surfaceContainerHigh,
      );

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Produto planejado azul'),
        ),
      );
      await tester.pumpAndSettle();
      final selectedPlannedCard = find
          .ancestor(
            of: find.descendant(
              of: find.byType(AlertDialog),
              matching: find.text('Produto planejado azul'),
            ),
            matching: find.byType(Card),
          )
          .first;
      expect(
        tester.widget<Card>(selectedPlannedCard).color,
        Theme.of(tester.element(selectedPlannedCard))
            .colorScheme
            .primaryContainer,
      );

      await tester.enterText(find.byType(TextFormField).first, '2');
      await tester.tap(find.text('Salvar linha'));
      await tester.pumpAndSettle();

      final line = (await database.select(database.purchaseLines).get())
          .firstWhere((row) => row.plannedItemId == plannedItemId);
      expect(line.productId, productId);
      expect(line.plannedItemId, plannedItemId);
      expect(line.quantity, 2);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Adicionar item da lista'));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.textSpan?.toPlainText().contains(
                    'No carrinho: 2 un. / 5 un.',
                  ) ==
                  true,
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Produto planejado azul'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '3');
      await tester.tap(find.text('Salvar linha'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adicionar item da lista'));
      await tester.pumpAndSettle();
      expect(find.text('Já inserido no carrinho'), findsOneWidget);
      final insertedCard = find
          .ancestor(
            of: find.descendant(
              of: find.byType(AlertDialog),
              matching: find.text('Produto planejado azul'),
            ),
            matching: find.byType(Card),
          )
          .first;
      expect(
        tester.widget<Card>(insertedCard).color,
        Theme.of(tester.element(insertedCard))
            .colorScheme
            .surfaceContainerHighest,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.textSpan?.toPlainText().contains(
                    'No carrinho: 5 un. / 5 un.',
                  ) ==
                  true,
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Produto planejado azul'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '1');
      await tester.tap(find.text('Salvar linha'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adicionar item da lista'));
      await tester.pumpAndSettle();
      final exceededQuantity = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.textSpan?.toPlainText().contains(
                  'No carrinho: 6 un. / 5 un.',
                ) ==
                true,
      );
      expect(exceededQuantity, findsOneWidget);
      final exceededText = tester.widget<Text>(exceededQuantity);
      final exceededSpan = exceededText.textSpan! as TextSpan;
      final overageSpan = exceededSpan.children!.cast<TextSpan>().firstWhere(
        (span) => span.text == '6 un.',
      );
      expect(
        overageSpan.style?.color,
        Theme.of(tester.element(exceededQuantity)).colorScheme.error,
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets('adicionar outro item não oferece produtos já planejados', (
    tester,
  ) async {
    final repository = ShoppingRepository(database);
    final plannedProductId = await CatalogRepository(database).saveProduct(
      name: 'Produto que já está na lista',
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );
    await CatalogRepository(database).saveProduct(
      name: 'Produto fora da lista',
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );
    final planId = await repository.createPlan(
      monthKey: '2026-11',
      name: 'Lista com produto',
    );
    await repository.addPlannedItem(
      planId: planId,
      productId: plannedProductId,
      mode: MeasurementMode.unit,
      quantity: 2,
    );
    final tripId = await repository.createTrip(
      planId: planId,
      purchaseDate: DateTime(2026, 11, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(home: ShoppingTripDetailScreen(tripId: tripId)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Total no carrinho'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar outro item'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();

    expect(find.text('Produto fora da lista'), findsOneWidget);
    expect(find.text('Produto que já está na lista'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('compras canceladas podem ser recolhidas', (tester) async {
    final repository = ShoppingRepository(database);
    final tripId = await repository.createTrip(
      purchaseDate: DateTime(2026, 11, 1),
      marketName: 'Mercado teste cancelado',
    );
    await repository.cancelTrip(tripId);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(home: ShoppingTripsScreen(onOpenTrip: (_) {})),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Compras canceladas (1)'), findsOneWidget);
    expect(find.textContaining('Mercado teste cancelado'), findsNothing);
    await tester.tapAt(tester.getCenter(find.text('Compras canceladas (1)')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Mercado teste cancelado'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('compras concluídas podem ser recolhidas', (tester) async {
    final catalog = CatalogRepository(database);
    final productId = await catalog.saveProduct(
      name: 'Produto de compra concluída',
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );
    final repository = ShoppingRepository(database);
    final tripId = await repository.createTrip(
      purchaseDate: DateTime(2026, 11, 1),
      marketName: 'Mercado concluído teste',
    );
    await repository.addPurchaseLine(
      tripId: tripId,
      productId: productId,
      mode: MeasurementMode.unit,
      quantity: 1,
      unitPriceCents: 500,
    );
    await repository.completeTrip(tripId);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(home: ShoppingTripsScreen(onOpenTrip: (_) {})),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Compras concluídas (1)'), findsOneWidget);
    expect(find.textContaining('Mercado concluído teste'), findsNothing);
    await tester.tapAt(tester.getCenter(find.text('Compras concluídas (1)')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mercado concluído teste'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('compras de lista têm selo colorido e compras avulsas não', (
    tester,
  ) async {
    final repository = ShoppingRepository(database);
    final planId = await repository.createPlan(
      monthKey: '2026-11',
      name: 'Lista de mercado',
    );
    await repository.createTrip(
      planId: planId,
      purchaseDate: DateTime(2026, 11, 1),
    );
    await repository.createTrip(purchaseDate: DateTime(2026, 11, 2));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(home: ShoppingTripsScreen(onOpenTrip: (_) {})),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Da lista · Lista de mercado'), findsOneWidget);
    expect(find.byType(Chip), findsOneWidget);
    expect(
      tester.widget<Chip>(find.byType(Chip)).backgroundColor,
      Colors.blue.shade100,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets(
    'carrinho agrupa por categoria e subcategoria e colore itens planejados',
    (tester) async {
      tester.view.physicalSize = const Size(393, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final catalog = CatalogRepository(database);
      final categoryId = await catalog.saveCategory(name: 'Mercearia teste');
      final subcategoryId = await catalog.saveSubcategory(
        categoryId: categoryId,
        name: 'Massas teste',
      );
      final plannedProductId = await catalog.saveProduct(
        name: 'Macarrão planejado',
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        measurementMode: MeasurementMode.unit,
        needsCategoryReview: false,
      );
      final outsideProductId = await catalog.saveProduct(
        name: 'Molho fora da lista',
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        measurementMode: MeasurementMode.unit,
        needsCategoryReview: false,
      );
      final repository = ShoppingRepository(database);
      final planId = await repository.createPlan(
        monthKey: '2026-11',
        name: 'Lista agrupada',
      );
      final plannedItemId = await repository.addPlannedItem(
        planId: planId,
        productId: plannedProductId,
        quantity: 1,
      );
      final tripId = await repository.createTrip(
        planId: planId,
        purchaseDate: DateTime(2026, 11, 1),
      );
      await repository.addPurchaseLine(
        tripId: tripId,
        productId: plannedProductId,
        plannedItemId: plannedItemId,
        mode: MeasurementMode.unit,
        quantity: 1,
        unitPriceCents: 500,
      );
      await repository.addPurchaseLine(
        tripId: tripId,
        productId: outsideProductId,
        mode: MeasurementMode.unit,
        quantity: 1,
        unitPriceCents: 300,
      );
      expect(
        (await (database.select(
          database.purchaseLines,
        )..where((line) => line.tripId.equals(tripId))).get()).map(
          (line) => line.productId,
        ),
        contains(outsideProductId),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(database)],
          child: MaterialApp(home: ShoppingTripDetailScreen(tripId: tripId)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Total no carrinho'));
      await tester.pumpAndSettle();

      expect(find.text('Mercearia teste'), findsOneWidget);
      expect(find.text('Massas teste'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text && widget.data?.endsWith('\nDa lista') == true,
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data?.endsWith('\nFora da lista') == true,
        ),
        findsOneWidget,
      );
      expect(find.text('Macarrão planejado'), findsOneWidget);
      expect(find.text('Molho fora da lista'), findsOneWidget);
      final plannedCard = tester.widget<Card>(
        find
            .ancestor(
              of: find.text('Macarrão planejado'),
              matching: find.byType(Card),
            )
            .first,
      );
      final outsideCard = tester.widget<Card>(
        find
            .ancestor(
              of: find.text('Molho fora da lista'),
              matching: find.byType(Card),
            )
            .first,
      );
      expect(
        plannedCard.color,
        Theme.of(tester.element(find.text('Macarrão planejado')))
            .colorScheme
            .primaryContainer,
      );
      expect(
        outsideCard.color,
        Theme.of(tester.element(find.text('Molho fora da lista')))
            .colorScheme
            .surface,
      );
      expect(find.textContaining('Total da lista: R\$ 5,00'), findsOneWidget);
      expect(
        find.textContaining('Fora da lista (preços conhecidos): R\$ 3,00'),
        findsOneWidget,
      );
      expect(find.textContaining('Projeção total: R\$ 8,00'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets('carrinho mantém ações acessíveis com fonte ampliada', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final catalog = CatalogRepository(database);
    final productId = await catalog.saveProduct(
      name: 'Produto para fonte ampliada',
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );
    final repository = ShoppingRepository(database);
    final planId = await repository.createPlan(
      monthKey: '2026-11',
      name: 'Lista com fonte ampliada',
    );
    final plannedItemId = await repository.addPlannedItem(
      planId: planId,
      productId: productId,
      quantity: 5,
    );
    final tripId = await repository.createTrip(
      planId: planId,
      purchaseDate: DateTime(2026, 11, 1),
    );
    await repository.addPurchaseLine(
      tripId: tripId,
      productId: productId,
      plannedItemId: plannedItemId,
      mode: MeasurementMode.unit,
      quantity: 2,
      unitPriceCents: 750,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: ShoppingTripDetailScreen(tripId: tripId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Total no carrinho'));
    await tester.pumpAndSettle();

    expect(find.text('Conferir e concluir compra'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Conferir e concluir compra'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('histórico mensal mostra gasto por data real e abre produto', (
    tester,
  ) async {
    final repository = ShoppingRepository(database);
    final productId = await CatalogRepository(database).saveProduct(
      name: 'Produto do relatório',
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );
    final tripId = await repository.createTrip(
      purchaseDate: DateTime(2026, 1, 31),
      marketName: 'Mercado histórico',
    );
    await repository.addPurchaseLine(
      tripId: tripId,
      productId: productId,
      mode: MeasurementMode.unit,
      quantity: 2,
      unitPriceCents: 800,
    );
    await repository.completeTrip(tripId);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          home: ShoppingHistoryScreen(initialMonth: DateTime(2026, 1)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gasto concluído no mês'), findsOneWidget);
    expect(find.text('R\$ 16,00'), findsNWidgets(2));
    expect(find.text('Produto do relatório'), findsOneWidget);
    expect(
      find.textContaining('não comprado em dezembro de 2025'),
      findsOneWidget,
    );
    await tester.tap(find.text('Produto do relatório'));
    await tester.pumpAndSettle();
    expect(find.text('Histórico do produto'), findsOneWidget);
    expect(find.text('Datas de compra distintas: 1.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('detalhe do produto exibe frequência observada controlada', (
    tester,
  ) async {
    final repository = ShoppingRepository(database);
    final productId = await CatalogRepository(database).saveProduct(
      name: 'Produto de frequência',
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );
    for (final date in [
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 11),
      DateTime(2026, 1, 31),
    ]) {
      final tripId = await repository.createTrip(purchaseDate: date);
      await repository.addPurchaseLine(
        tripId: tripId,
        productId: productId,
        mode: MeasurementMode.unit,
        quantity: 1,
        unitPriceCents: 100,
      );
      await repository.completeTrip(tripId);
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          home: ProductPurchaseHistoryScreen(
            productId: productId,
            asOfDate: DateTime(2026, 2, 10),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('10 dia(s) atrás'), findsOneWidget);
    expect(find.textContaining('mediana de 15 dia(s)'), findsOneWidget);
    expect(find.textContaining('janeiro de 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('planejamento salva estimativa manual sem criar compra', (
    tester,
  ) async {
    final repository = ShoppingRepository(database);
    final productId = await CatalogRepository(database).saveProduct(
      name: 'Produto com estimativa manual',
      measurementMode: MeasurementMode.unit,
      needsCategoryReview: false,
    );
    final planId = await repository.createPlan(
      monthKey: '2026-11',
      name: 'Plano estimado',
    );
    await repository.addPlannedItem(
      planId: planId,
      productId: productId,
      mode: MeasurementMode.unit,
      quantity: 2,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          home: ShoppingPlanDetailScreen(planId: planId, onOpenTrip: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ações do item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Definir preço estimado'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '12,34');
    await tester.tap(find.text('Salvar estimativa'));
    await tester.pumpAndSettle();

    final item = (await database.select(database.plannedItems).get()).single;
    expect(item.estimateSource, 'manual');
    expect(item.estimatePriceNumeratorCents, 1234);
    expect(await database.select(database.shoppingTrips).get(), isEmpty);
    expect(find.text('Estimativa planejada: R\$ 24,68'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
