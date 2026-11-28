import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercado/features/cloud/data/cloud_models.dart';
import 'package:mercado/features/cloud/data/sync_diagnostics.dart';
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
              onExportBackup: () {},
              onCheckInternet: () {},
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

  testWidgets('mostra diagnóstico e ações para falha de rede', (tester) async {
    final status = CloudSyncStatus(
      householdId: 'casa',
      remoteRevision: 4,
      areas: {
        for (final area in CloudSyncConflictArea.values)
          area: CloudSyncAreaStatus(
            area: area,
            state: CloudSyncAreaState.inSync,
            localCounts: _localCounts(area),
            remoteCounts: _localCounts(area),
            localHash: 'local',
            remoteHash: 'local',
          ),
      },
      diagnostics: CloudSyncDiagnostics(
        lastAttemptAt: DateTime.utc(2026, 11, 27, 10),
        lastSuccessfulAt: DateTime.utc(2026, 11, 27, 9),
        lastOrigin: 'android-pilot',
        outcome: CloudSyncAttemptOutcome.failure,
        failureKind: CloudSyncFailureKind.network,
        failedArea: 'all',
        message: 'Não foi possível acessar a internet.',
        areaResults: const {'catalog': 'inSync'},
      ),
      remoteOrigin: 'web-pilot',
      remoteOriginAt: DateTime.utc(2026, 11, 27, 8),
      remoteOriginAuthor: 'Piloto Web',
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
              onExportBackup: () {},
              onCheckInternet: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.text('A última sincronização não foi concluída'),
      findsOneWidget,
    );
    expect(find.textContaining('Última sincronização:'), findsOneWidget);
    expect(find.textContaining('Este dispositivo:'), findsOneWidget);
    expect(find.textContaining('Última origem: Web'), findsOneWidget);
    expect(find.textContaining('Publicada em:'), findsOneWidget);
    expect(find.textContaining('Publicado por: Piloto Web'), findsOneWidget);
    expect(find.text('Falha de rede'), findsOneWidget);
    expect(find.textContaining('Área: todas as áreas'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.text('Verificar internet'), findsOneWidget);
    expect(find.text('Exportar backup'), findsOneWidget);
  });

  testWidgets('mostra o que difere quando a área está divergente', (
    tester,
  ) async {
    final status = CloudSyncStatus(
      householdId: 'casa',
      remoteRevision: 4,
      areas: {
        for (final area in CloudSyncConflictArea.values)
          area: CloudSyncAreaStatus(
            area: area,
            state: area == CloudSyncConflictArea.shopping
                ? CloudSyncAreaState.divergent
                : CloudSyncAreaState.inSync,
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
              onExportBackup: () {},
              onCheckInternet: () {},
            ),
          ),
        ),
      ),
    );

    // A remoção vira tombstone: a contagem de linhas continua igual, então a
    // tela precisa dizer que a diferença está nos itens removidos.
    expect(find.textContaining('Removidos: aqui 1, casa 0'), findsOneWidget);
    expect(
      find.textContaining('Aguardando o owner: aqui 1, casa 0'),
      findsOneWidget,
    );
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
  CloudSyncConflictArea.shopping => const CloudAreaCounts(
    {
      'shoppingPlans': 3,
      'plannedItems': 52,
      'shoppingTrips': 57,
      'purchaseLines': 57,
    },
    removed: {'plannedItems': 1},
    pending: {'plannedItems': 1},
  ),
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
