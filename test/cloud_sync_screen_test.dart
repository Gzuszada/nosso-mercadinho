import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercado/features/cloud/data/cloud_models.dart';
import 'package:mercado/features/cloud/presentation/cloud_sync_status_panel.dart';

void main() {
  testWidgets('mostra o estado local e remoto de cada área', (tester) async {
    final status = CloudSyncStatus(
      householdId: 'casa',
      remoteRevision: 4,
      areas: {
        for (final area in CloudSyncConflictArea.values)
          area: CloudSyncAreaStatus(
            area: area,
            state: CloudSyncAreaState.divergent,
            localCounts: _localCounts(area),
            remoteCounts: _remoteCounts(area),
            localHash: 'local',
            remoteHash: 'remote',
          ),
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CloudSyncStatusPanel(
              status: status,
              busy: false,
              onCheck: () {},
              onSendAll: () {},
              onUseAll: () {},
              onSynchronize: () {},
              onDeleteHousehold: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('Estado da sincronização'), findsOneWidget);
    expect(find.textContaining('2026-11-18-sync-v2'), findsNothing);
    expect(
      find.text('Este dispositivo não está igual ao Firebase'),
      findsOneWidget,
    );
    expect(find.text('catálogo'), findsOneWidget);
    expect(find.text('importações'), findsOneWidget);
    expect(find.text('listas, compras e histórico'), findsOneWidget);
    expect(find.text('Verificar agora'), findsOneWidget);
    expect(
      find.text('Enviar todos os dados deste dispositivo'),
      findsOneWidget,
    );
    expect(find.text('Usar todos os dados da casa'), findsOneWidget);
    expect(find.text('Excluir casa do Firebase'), findsOneWidget);

    expect(
      find.textContaining('Aqui: 9 categorias, 25 subcategorias, 157 produtos'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Casa: 8 categorias, 24 subcategorias, 150 produtos'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Aqui: 1 importação, 2 itens importados'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Casa: 0 importações, 0 itens importados'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Aqui: 3 listas, 52 itens das listas, 57 compras, '
        '57 itens das compras',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Casa: 2 listas, 50 itens das listas, 55 compras, '
        '55 itens das compras',
      ),
      findsOneWidget,
    );

    for (final technicalTerm in [
      'shoppingPlans',
      'plannedItems',
      'shoppingTrips',
      'purchaseLines',
      'importBatches',
      'importEntries',
      'categories',
      'subcategories',
      'products',
    ]) {
      expect(find.textContaining(technicalTerm), findsNothing);
    }
  });
}

CloudAreaCounts _localCounts(CloudSyncConflictArea area) => switch (area) {
  CloudSyncConflictArea.catalog => const CloudAreaCounts({
    'categories': 9,
    'subcategories': 25,
    'products': 157,
  }),
  CloudSyncConflictArea.imports => const CloudAreaCounts({
    'importBatches': 1,
    'importEntries': 2,
  }),
  CloudSyncConflictArea.shopping => const CloudAreaCounts({
    'shoppingPlans': 3,
    'plannedItems': 52,
    'shoppingTrips': 57,
    'purchaseLines': 57,
  }),
};

CloudAreaCounts _remoteCounts(CloudSyncConflictArea area) => switch (area) {
  CloudSyncConflictArea.catalog => const CloudAreaCounts({
    'categories': 8,
    'subcategories': 24,
    'products': 150,
  }),
  CloudSyncConflictArea.imports => const CloudAreaCounts({
    'importBatches': 0,
    'importEntries': 0,
  }),
  CloudSyncConflictArea.shopping => const CloudAreaCounts({
    'shoppingPlans': 2,
    'plannedItems': 50,
    'shoppingTrips': 55,
    'purchaseLines': 55,
  }),
};
