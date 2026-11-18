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
            localCounts: CloudAreaCounts({'itens': 2}),
            remoteCounts: CloudAreaCounts({'itens': 1}),
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
    expect(
      find.text('Estado da sincronização · 2026-11-18-sync-v2'),
      findsOneWidget,
    );
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
  });
}
