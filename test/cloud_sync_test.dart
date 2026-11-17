import 'package:flutter_test/flutter_test.dart';
import 'package:mercado/features/cloud/data/cloud_models.dart';
import 'package:mercado/features/cloud/data/cloud_sync_service.dart';

void main() {
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
}
