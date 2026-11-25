import 'package:drift/drift.dart';

import '../../../data/app_database.dart';
import 'collaboration.dart';

class CollaborationService {
  const CollaborationService(this._database, {this.actorResolver});

  final AppDatabase _database;
  final CollaborationActorResolver? actorResolver;

  Future<void> reviewItem({
    required CollaborativeItemType type,
    required int id,
    required CollaborativeReviewState state,
  }) async {
    final actor = await actorResolver?.call();
    if (actor == null || !actor.isOwner) {
      throw const FormatException('Somente o owner pode revisar itens.');
    }
    final now = DateTime.now();
    final reviewState = state == CollaborativeReviewState.approved
        ? CollaborationMetadata.approved
        : CollaborationMetadata.rejected;

    switch (type) {
      case CollaborativeItemType.product:
        final row = await _requireProduct(id);
        await (_database.update(
          _database.products,
        )..where((item) => item.id.equals(id))).write(
          ProductsCompanion(
            reviewState: Value(reviewState),
            reviewedByUid: Value(actor.uid),
            reviewedByName: Value(actor.displayName),
            reviewedAt: Value(now),
            syncRevision: Value(row.syncRevision + 1),
            updatedAt: Value(now),
          ),
        );
        return;
      case CollaborativeItemType.shoppingPlan:
        final row = await _requirePlan(id);
        await (_database.update(
          _database.shoppingPlans,
        )..where((item) => item.id.equals(id))).write(
          ShoppingPlansCompanion(
            reviewState: Value(reviewState),
            reviewedByUid: Value(actor.uid),
            reviewedByName: Value(actor.displayName),
            reviewedAt: Value(now),
            syncRevision: Value(row.syncRevision + 1),
            updatedAt: Value(now),
          ),
        );
        return;
      case CollaborativeItemType.plannedItem:
        final row = await _requirePlannedItem(id);
        await (_database.update(
          _database.plannedItems,
        )..where((item) => item.id.equals(id))).write(
          PlannedItemsCompanion(
            reviewState: Value(reviewState),
            reviewedByUid: Value(actor.uid),
            reviewedByName: Value(actor.displayName),
            reviewedAt: Value(now),
            syncRevision: Value(row.syncRevision + 1),
            updatedAt: Value(now),
          ),
        );
        return;
    }
  }

  Future<Product> _requireProduct(int id) async {
    final row = await (_database.select(
      _database.products,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
    if (row == null) throw StateError('O produto não existe mais.');
    return row;
  }

  Future<ShoppingPlan> _requirePlan(int id) async {
    final row = await (_database.select(
      _database.shoppingPlans,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
    if (row == null) throw StateError('A lista não existe mais.');
    return row;
  }

  Future<PlannedItem> _requirePlannedItem(int id) async {
    final row = await (_database.select(
      _database.plannedItems,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
    if (row == null) throw StateError('O item planejado não existe mais.');
    return row;
  }
}
