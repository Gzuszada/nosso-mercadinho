import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercado/app_providers.dart';
import 'package:mercado/data/app_database.dart';
import 'package:mercado/features/cloud/data/cloud_auth_service.dart';
import 'package:mercado/main.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('exige autenticação antes de liberar o mercado', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const MercadoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nosso Mercado'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar conta autorizada'), findsOneWidget);
    expect(find.text('Listas'), findsNothing);
    expect(find.text('Compras'), findsNothing);
    expect(find.text('Produtos'), findsNothing);
    expect(find.text('Criar uma casa'), findsNothing);
    expect(find.text('Entrar na casa'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('libera o mercado somente depois de autenticar', (tester) async {
    final accounts = StreamController<AuthAccount?>();
    addTearDown(accounts.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          authStateProvider.overrideWith((ref) => accounts.stream),
        ],
        child: const MercadoApp(),
      ),
    );
    accounts.add(null);
    await tester.pump();

    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Listas'), findsNothing);

    accounts.add(
      const AuthAccount(uid: 'test-user'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsNothing);
    expect(find.text('Listas'), findsOneWidget);
    expect(find.text('Compras'), findsOneWidget);
    expect(find.text('Produtos'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}
