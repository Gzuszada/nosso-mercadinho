import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercado/data/app_database.dart';
import 'package:mercado/features/cloud/data/cloud_auth_service.dart';
import 'package:mercado/features/cloud/data/cloud_models.dart';
import 'package:mercado/features/cloud/data/cloud_sync_service.dart';
import 'package:mercado/features/settings/data/settings_repository.dart';

void main() {
  group('nome de usuário', () {
    test('usa a parte do e-mail antes do arroba como nome padrão', () {
      expect(
        CloudAuthService.defaultDisplayName('  pessoa@exemplo.com  '),
        'pessoa',
      );
    });

    test('sanitiza e limita o nome padrão', () {
      expect(
        CloudAuthService.defaultDisplayName('${'a' * 50}@exemplo.com'),
        'a' * 40,
      );
      expect(
        CloudAuthService.defaultDisplayName(
          '  nome  com   espacos@exemplo.com ',
        ),
        'nome com espacos',
      );
    });

    test('usa fallback quando o e-mail não tem parte local utilizável', () {
      expect(CloudAuthService.defaultDisplayName('@exemplo.com'), 'Usuário');
      expect(CloudAuthService.defaultDisplayName('a@exemplo.com'), 'Usuário');
      expect(CloudAuthService.defaultDisplayName(null), 'Usuário');
    });

    test('valida o tamanho do nome de usuário', () {
      expect(
        CloudAuthService.validateDisplayName('  Igor Munhoz  '),
        'Igor Munhoz',
      );
      expect(
        () => CloudAuthService.validateDisplayName('a'),
        throwsArgumentError,
      );
      expect(
        () => CloudAuthService.validateDisplayName('a' * 41),
        throwsArgumentError,
      );
    });

    test('recusa caracteres de controle no nome de usuário', () {
      expect(
        () => CloudAuthService.validateDisplayName('Igor\nMunhoz'),
        throwsArgumentError,
      );
    });
  });

  group('CloudSnapshot', () {
    test('hash independe da ordem das chaves em mapas aninhados', () {
      final first = <String, dynamic>{
        'products': [
          {
            'id': 1,
            'details': {'color': 'azul', 'size': 'M'},
          },
        ],
        'categories': [],
      };
      final second = <String, dynamic>{
        'categories': [],
        'products': [
          {
            'details': {'size': 'M', 'color': 'azul'},
            'id': 1,
          },
        ],
      };

      expect(
        CloudSnapshot.hashPayload(first),
        CloudSnapshot.hashPayload(second),
      );
    });

    test('hash muda quando o conteúdo muda', () {
      expect(
        CloudSnapshot.hashPayload({'products': []}),
        isNot(
          CloudSnapshot.hashPayload({
            'products': [1],
          }),
        ),
      );
    });
  });

  group('áreas de sincronização', () {
    test('cada tabela pertence a exatamente uma área', () {
      final areas = CloudSyncConflictArea.values;
      final keys = areas.expand(CloudSyncService.areaKeys).toList();

      expect(keys.toSet().length, keys.length);
      expect(
        keys,
        containsAll([
          'categories',
          'subcategories',
          'products',
          'importBatches',
          'importEntries',
          'shoppingPlans',
          'plannedItems',
          'shoppingTrips',
          'purchaseLines',
        ]),
      );
    });

    test('seleção de área não inclui tabelas de outra área', () {
      final payload = <String, dynamic>{
        'categories': [1],
        'products': [2],
        'importBatches': [3],
        'shoppingPlans': [4],
        'formatVersion': 6,
      };

      final catalog = CloudSyncService.selectArea(
        payload,
        CloudSyncConflictArea.catalog,
      );

      expect(catalog.keys, containsAll(['categories', 'products']));
      expect(catalog.keys, isNot(contains('importBatches')));
      expect(catalog.keys, isNot(contains('shoppingPlans')));
    });

    test('mesclagem substitui somente as tabelas da área remota', () {
      final merged = CloudSyncService.mergeArea(
        {
          'categories': ['local'],
          'products': ['local'],
          'shoppingPlans': ['preservado'],
          'formatVersion': 6,
        },
        CloudSyncConflictArea.catalog,
        {
          'categories': ['remoto'],
          'products': ['remoto'],
          'formatVersion': 6,
        },
      );

      expect(merged['categories'], ['remoto']);
      expect(merged['products'], ['remoto']);
      expect(merged['shoppingPlans'], ['preservado']);
    });
  });

  test('conflito preserva as duas versões e a revisão remota', () {
    final conflict = CloudSyncConflict(
      area: CloudSyncConflictArea.imports,
      localPayload: {
        'importEntries': ['local'],
      },
      remotePayload: {
        'importEntries': ['remoto'],
      },
      remoteRevision: 7,
    );

    expect(conflict.area.label, 'importações');
    expect(conflict.localPayload['importEntries'], ['local']);
    expect(conflict.remotePayload['importEntries'], ['remoto']);
    expect(conflict.remoteRevision, 7);
  });

  group('seleção da casa de sincronização', () {
    late AppDatabase database;
    late SettingsRepository settings;
    late bool previousMultipleDatabaseWarning;

    setUpAll(() {
      previousMultipleDatabaseWarning =
          driftRuntimeOptions.dontWarnAboutMultipleDatabases;
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    });

    tearDownAll(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases =
          previousMultipleDatabaseWarning;
    });

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      settings = SettingsRepository(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('trocar de casa zera o estado base da sincronização', () async {
      await settings.saveCloudSyncSettings(
        householdId: 'casa-antiga',
        remoteRevision: 12,
        lastSyncedHash: 'hash-antigo',
      );

      await settings.selectCloudHousehold('casa-nova');

      final selected = await settings.getCloudSyncSettings();
      expect(selected?.householdId, 'casa-nova');
      expect(selected?.remoteRevision, 0);
      expect(selected?.lastSyncedHash, isNull);
    });

    test('manter a mesma casa preserva o estado base', () async {
      await settings.saveCloudSyncSettings(
        householdId: 'casa-atual',
        remoteRevision: 8,
        lastSyncedHash: 'hash-atual',
      );

      await settings.selectCloudHousehold('casa-atual');

      final selected = await settings.getCloudSyncSettings();
      expect(selected?.householdId, 'casa-atual');
      expect(selected?.remoteRevision, 8);
      expect(selected?.lastSyncedHash, 'hash-atual');
    });
  });
}
