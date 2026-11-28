import 'package:flutter_test/flutter_test.dart';
import 'package:mercado/features/cloud/data/sync_diagnostics.dart';

void main() {
  group('diagnóstico de sincronização', () {
    test('serializa e recupera datas, origem, resultado e erro', () {
      final diagnostics = CloudSyncDiagnostics(
        lastAttemptAt: DateTime.utc(2026, 11, 27, 10),
        lastSuccessfulAt: DateTime.utc(2026, 11, 27, 9),
        lastOrigin: 'android-pilot',
        lastOriginAt: DateTime.utc(2026, 11, 27, 9),
        lastOriginAuthor: 'Piloto',
        outcome: CloudSyncAttemptOutcome.failure,
        failureKind: CloudSyncFailureKind.network,
        failedArea: 'catalog',
        message: 'Não foi possível acessar a internet.',
        areaResults: const {'catalog': 'divergent', 'shopping': 'inSync'},
      );

      final decoded = CloudSyncDiagnostics.decode(diagnostics.encode());

      expect(decoded.lastAttemptAt, diagnostics.lastAttemptAt);
      expect(decoded.lastSuccessfulAt, diagnostics.lastSuccessfulAt);
      expect(decoded.lastOrigin, 'android-pilot');
      expect(decoded.lastOriginAt, diagnostics.lastOriginAt);
      expect(decoded.lastOriginAuthor, 'Piloto');
      expect(decoded.outcome, CloudSyncAttemptOutcome.failure);
      expect(decoded.failureKind, CloudSyncFailureKind.network);
      expect(decoded.failedArea, 'catalog');
      expect(decoded.message, 'Não foi possível acessar a internet.');
      expect(decoded.areaResults, diagnostics.areaResults);
      expect(decoded.synchronizedAreaCount, 1);
    });

    test('JSON inválido ou de versão futura não quebra a leitura', () {
      expect(CloudSyncDiagnostics.decode('não é json').lastAttemptAt, isNull);
      expect(
        CloudSyncDiagnostics.decode('{"version":999,"outcome":"success"}')
            .outcome,
        CloudSyncAttemptOutcome.success,
      );
    });

    test('classifica falhas comuns de rede, permissão e dados', () {
      expect(
        classifyCloudSyncFailure(Exception('NetworkRequestFailedException')),
        CloudSyncFailureKind.network,
      );
      expect(
        classifyCloudSyncFailure(Exception('PERMISSION_DENIED')),
        CloudSyncFailureKind.permission,
      );
      expect(
        classifyCloudSyncFailure(const FormatException('json inválido')),
        CloudSyncFailureKind.invalidData,
      );
      expect(
        classifyCloudSyncFailure(Exception('Conflito de sincronização')),
        CloudSyncFailureKind.conflict,
      );
    });
  });
}
