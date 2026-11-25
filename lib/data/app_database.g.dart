// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    sortOrder,
    isArchived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String name;
  final int sortOrder;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Category({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Category copyWith({
    int? id,
    String? name,
    int? sortOrder,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, sortOrder, isArchived, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<bool>? isArchived,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SubcategoriesTable extends Subcategories
    with TableInfo<$SubcategoriesTable, Subcategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubcategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    name,
    sortOrder,
    isArchived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subcategories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subcategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subcategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subcategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SubcategoriesTable createAlias(String alias) {
    return $SubcategoriesTable(attachedDatabase, alias);
  }
}

class Subcategory extends DataClass implements Insertable<Subcategory> {
  final int id;
  final int categoryId;
  final String name;
  final int sortOrder;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Subcategory({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.sortOrder,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category_id'] = Variable<int>(categoryId);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SubcategoriesCompanion toCompanion(bool nullToAbsent) {
    return SubcategoriesCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      name: Value(name),
      sortOrder: Value(sortOrder),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Subcategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subcategory(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<int>(categoryId),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Subcategory copyWith({
    int? id,
    int? categoryId,
    String? name,
    int? sortOrder,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Subcategory(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Subcategory copyWithCompanion(SubcategoriesCompanion data) {
    return Subcategory(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subcategory(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    name,
    sortOrder,
    isArchived,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subcategory &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SubcategoriesCompanion extends UpdateCompanion<Subcategory> {
  final Value<int> id;
  final Value<int> categoryId;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SubcategoriesCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SubcategoriesCompanion.insert({
    this.id = const Value.absent(),
    required int categoryId,
    required String name,
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : categoryId = Value(categoryId),
       name = Value(name);
  static Insertable<Subcategory> custom({
    Expression<int>? id,
    Expression<int>? categoryId,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SubcategoriesCompanion copyWith({
    Value<int>? id,
    Value<int>? categoryId,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<bool>? isArchived,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SubcategoriesCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubcategoriesCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 160,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subcategoryIdMeta = const VerificationMeta(
    'subcategoryId',
  );
  @override
  late final GeneratedColumn<int> subcategoryId = GeneratedColumn<int>(
    'subcategory_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _measurementModeMeta = const VerificationMeta(
    'measurementMode',
  );
  @override
  late final GeneratedColumn<String> measurementMode = GeneratedColumn<String>(
    'measurement_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _needsCategoryReviewMeta =
      const VerificationMeta('needsCategoryReview');
  @override
  late final GeneratedColumn<bool> needsCategoryReview = GeneratedColumn<bool>(
    'needs_category_review',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_category_review" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logicalKeyMeta = const VerificationMeta(
    'logicalKey',
  );
  @override
  late final GeneratedColumn<String> logicalKey = GeneratedColumn<String>(
    'logical_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorUidMeta = const VerificationMeta(
    'authorUid',
  );
  @override
  late final GeneratedColumn<String> authorUid = GeneratedColumn<String>(
    'author_uid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorNameMeta = const VerificationMeta(
    'authorName',
  );
  @override
  late final GeneratedColumn<String> authorName = GeneratedColumn<String>(
    'author_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewStateMeta = const VerificationMeta(
    'reviewState',
  );
  @override
  late final GeneratedColumn<String> reviewState = GeneratedColumn<String>(
    'review_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('approved'),
  );
  static const VerificationMeta _reviewedByUidMeta = const VerificationMeta(
    'reviewedByUid',
  );
  @override
  late final GeneratedColumn<String> reviewedByUid = GeneratedColumn<String>(
    'reviewed_by_uid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewedByNameMeta = const VerificationMeta(
    'reviewedByName',
  );
  @override
  late final GeneratedColumn<String> reviewedByName = GeneratedColumn<String>(
    'reviewed_by_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncRevisionMeta = const VerificationMeta(
    'syncRevision',
  );
  @override
  late final GeneratedColumn<int> syncRevision = GeneratedColumn<int>(
    'sync_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    categoryId,
    subcategoryId,
    measurementMode,
    needsCategoryReview,
    description,
    isArchived,
    syncId,
    logicalKey,
    authorUid,
    authorName,
    reviewState,
    reviewedByUid,
    reviewedByName,
    reviewedAt,
    deletedAt,
    syncRevision,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('subcategory_id')) {
      context.handle(
        _subcategoryIdMeta,
        subcategoryId.isAcceptableOrUnknown(
          data['subcategory_id']!,
          _subcategoryIdMeta,
        ),
      );
    }
    if (data.containsKey('measurement_mode')) {
      context.handle(
        _measurementModeMeta,
        measurementMode.isAcceptableOrUnknown(
          data['measurement_mode']!,
          _measurementModeMeta,
        ),
      );
    }
    if (data.containsKey('needs_category_review')) {
      context.handle(
        _needsCategoryReviewMeta,
        needsCategoryReview.isAcceptableOrUnknown(
          data['needs_category_review']!,
          _needsCategoryReviewMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('logical_key')) {
      context.handle(
        _logicalKeyMeta,
        logicalKey.isAcceptableOrUnknown(data['logical_key']!, _logicalKeyMeta),
      );
    }
    if (data.containsKey('author_uid')) {
      context.handle(
        _authorUidMeta,
        authorUid.isAcceptableOrUnknown(data['author_uid']!, _authorUidMeta),
      );
    }
    if (data.containsKey('author_name')) {
      context.handle(
        _authorNameMeta,
        authorName.isAcceptableOrUnknown(data['author_name']!, _authorNameMeta),
      );
    }
    if (data.containsKey('review_state')) {
      context.handle(
        _reviewStateMeta,
        reviewState.isAcceptableOrUnknown(
          data['review_state']!,
          _reviewStateMeta,
        ),
      );
    }
    if (data.containsKey('reviewed_by_uid')) {
      context.handle(
        _reviewedByUidMeta,
        reviewedByUid.isAcceptableOrUnknown(
          data['reviewed_by_uid']!,
          _reviewedByUidMeta,
        ),
      );
    }
    if (data.containsKey('reviewed_by_name')) {
      context.handle(
        _reviewedByNameMeta,
        reviewedByName.isAcceptableOrUnknown(
          data['reviewed_by_name']!,
          _reviewedByNameMeta,
        ),
      );
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_revision')) {
      context.handle(
        _syncRevisionMeta,
        syncRevision.isAcceptableOrUnknown(
          data['sync_revision']!,
          _syncRevisionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      subcategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subcategory_id'],
      ),
      measurementMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measurement_mode'],
      )!,
      needsCategoryReview: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_category_review'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      ),
      logicalKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logical_key'],
      ),
      authorUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_uid'],
      ),
      authorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_name'],
      ),
      reviewState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_state'],
      )!,
      reviewedByUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reviewed_by_uid'],
      ),
      reviewedByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reviewed_by_name'],
      ),
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_revision'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final int id;
  final String name;
  final int? categoryId;
  final int? subcategoryId;
  final String measurementMode;
  final bool needsCategoryReview;
  final String? description;
  final bool isArchived;
  final String? syncId;
  final String? logicalKey;
  final String? authorUid;
  final String? authorName;
  final String reviewState;
  final String? reviewedByUid;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final DateTime? deletedAt;
  final int syncRevision;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Product({
    required this.id,
    required this.name,
    this.categoryId,
    this.subcategoryId,
    required this.measurementMode,
    required this.needsCategoryReview,
    this.description,
    required this.isArchived,
    this.syncId,
    this.logicalKey,
    this.authorUid,
    this.authorName,
    required this.reviewState,
    this.reviewedByUid,
    this.reviewedByName,
    this.reviewedAt,
    this.deletedAt,
    required this.syncRevision,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || subcategoryId != null) {
      map['subcategory_id'] = Variable<int>(subcategoryId);
    }
    map['measurement_mode'] = Variable<String>(measurementMode);
    map['needs_category_review'] = Variable<bool>(needsCategoryReview);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || syncId != null) {
      map['sync_id'] = Variable<String>(syncId);
    }
    if (!nullToAbsent || logicalKey != null) {
      map['logical_key'] = Variable<String>(logicalKey);
    }
    if (!nullToAbsent || authorUid != null) {
      map['author_uid'] = Variable<String>(authorUid);
    }
    if (!nullToAbsent || authorName != null) {
      map['author_name'] = Variable<String>(authorName);
    }
    map['review_state'] = Variable<String>(reviewState);
    if (!nullToAbsent || reviewedByUid != null) {
      map['reviewed_by_uid'] = Variable<String>(reviewedByUid);
    }
    if (!nullToAbsent || reviewedByName != null) {
      map['reviewed_by_name'] = Variable<String>(reviewedByName);
    }
    if (!nullToAbsent || reviewedAt != null) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_revision'] = Variable<int>(syncRevision);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      subcategoryId: subcategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(subcategoryId),
      measurementMode: Value(measurementMode),
      needsCategoryReview: Value(needsCategoryReview),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isArchived: Value(isArchived),
      syncId: syncId == null && nullToAbsent
          ? const Value.absent()
          : Value(syncId),
      logicalKey: logicalKey == null && nullToAbsent
          ? const Value.absent()
          : Value(logicalKey),
      authorUid: authorUid == null && nullToAbsent
          ? const Value.absent()
          : Value(authorUid),
      authorName: authorName == null && nullToAbsent
          ? const Value.absent()
          : Value(authorName),
      reviewState: Value(reviewState),
      reviewedByUid: reviewedByUid == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedByUid),
      reviewedByName: reviewedByName == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedByName),
      reviewedAt: reviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncRevision: Value(syncRevision),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      subcategoryId: serializer.fromJson<int?>(json['subcategoryId']),
      measurementMode: serializer.fromJson<String>(json['measurementMode']),
      needsCategoryReview: serializer.fromJson<bool>(
        json['needsCategoryReview'],
      ),
      description: serializer.fromJson<String?>(json['description']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      syncId: serializer.fromJson<String?>(json['syncId']),
      logicalKey: serializer.fromJson<String?>(json['logicalKey']),
      authorUid: serializer.fromJson<String?>(json['authorUid']),
      authorName: serializer.fromJson<String?>(json['authorName']),
      reviewState: serializer.fromJson<String>(json['reviewState']),
      reviewedByUid: serializer.fromJson<String?>(json['reviewedByUid']),
      reviewedByName: serializer.fromJson<String?>(json['reviewedByName']),
      reviewedAt: serializer.fromJson<DateTime?>(json['reviewedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncRevision: serializer.fromJson<int>(json['syncRevision']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'categoryId': serializer.toJson<int?>(categoryId),
      'subcategoryId': serializer.toJson<int?>(subcategoryId),
      'measurementMode': serializer.toJson<String>(measurementMode),
      'needsCategoryReview': serializer.toJson<bool>(needsCategoryReview),
      'description': serializer.toJson<String?>(description),
      'isArchived': serializer.toJson<bool>(isArchived),
      'syncId': serializer.toJson<String?>(syncId),
      'logicalKey': serializer.toJson<String?>(logicalKey),
      'authorUid': serializer.toJson<String?>(authorUid),
      'authorName': serializer.toJson<String?>(authorName),
      'reviewState': serializer.toJson<String>(reviewState),
      'reviewedByUid': serializer.toJson<String?>(reviewedByUid),
      'reviewedByName': serializer.toJson<String?>(reviewedByName),
      'reviewedAt': serializer.toJson<DateTime?>(reviewedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncRevision': serializer.toJson<int>(syncRevision),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Product copyWith({
    int? id,
    String? name,
    Value<int?> categoryId = const Value.absent(),
    Value<int?> subcategoryId = const Value.absent(),
    String? measurementMode,
    bool? needsCategoryReview,
    Value<String?> description = const Value.absent(),
    bool? isArchived,
    Value<String?> syncId = const Value.absent(),
    Value<String?> logicalKey = const Value.absent(),
    Value<String?> authorUid = const Value.absent(),
    Value<String?> authorName = const Value.absent(),
    String? reviewState,
    Value<String?> reviewedByUid = const Value.absent(),
    Value<String?> reviewedByName = const Value.absent(),
    Value<DateTime?> reviewedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    int? syncRevision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    subcategoryId: subcategoryId.present
        ? subcategoryId.value
        : this.subcategoryId,
    measurementMode: measurementMode ?? this.measurementMode,
    needsCategoryReview: needsCategoryReview ?? this.needsCategoryReview,
    description: description.present ? description.value : this.description,
    isArchived: isArchived ?? this.isArchived,
    syncId: syncId.present ? syncId.value : this.syncId,
    logicalKey: logicalKey.present ? logicalKey.value : this.logicalKey,
    authorUid: authorUid.present ? authorUid.value : this.authorUid,
    authorName: authorName.present ? authorName.value : this.authorName,
    reviewState: reviewState ?? this.reviewState,
    reviewedByUid: reviewedByUid.present
        ? reviewedByUid.value
        : this.reviewedByUid,
    reviewedByName: reviewedByName.present
        ? reviewedByName.value
        : this.reviewedByName,
    reviewedAt: reviewedAt.present ? reviewedAt.value : this.reviewedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncRevision: syncRevision ?? this.syncRevision,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      subcategoryId: data.subcategoryId.present
          ? data.subcategoryId.value
          : this.subcategoryId,
      measurementMode: data.measurementMode.present
          ? data.measurementMode.value
          : this.measurementMode,
      needsCategoryReview: data.needsCategoryReview.present
          ? data.needsCategoryReview.value
          : this.needsCategoryReview,
      description: data.description.present
          ? data.description.value
          : this.description,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      logicalKey: data.logicalKey.present
          ? data.logicalKey.value
          : this.logicalKey,
      authorUid: data.authorUid.present ? data.authorUid.value : this.authorUid,
      authorName: data.authorName.present
          ? data.authorName.value
          : this.authorName,
      reviewState: data.reviewState.present
          ? data.reviewState.value
          : this.reviewState,
      reviewedByUid: data.reviewedByUid.present
          ? data.reviewedByUid.value
          : this.reviewedByUid,
      reviewedByName: data.reviewedByName.present
          ? data.reviewedByName.value
          : this.reviewedByName,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncRevision: data.syncRevision.present
          ? data.syncRevision.value
          : this.syncRevision,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('subcategoryId: $subcategoryId, ')
          ..write('measurementMode: $measurementMode, ')
          ..write('needsCategoryReview: $needsCategoryReview, ')
          ..write('description: $description, ')
          ..write('isArchived: $isArchived, ')
          ..write('syncId: $syncId, ')
          ..write('logicalKey: $logicalKey, ')
          ..write('authorUid: $authorUid, ')
          ..write('authorName: $authorName, ')
          ..write('reviewState: $reviewState, ')
          ..write('reviewedByUid: $reviewedByUid, ')
          ..write('reviewedByName: $reviewedByName, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncRevision: $syncRevision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    categoryId,
    subcategoryId,
    measurementMode,
    needsCategoryReview,
    description,
    isArchived,
    syncId,
    logicalKey,
    authorUid,
    authorName,
    reviewState,
    reviewedByUid,
    reviewedByName,
    reviewedAt,
    deletedAt,
    syncRevision,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.name == this.name &&
          other.categoryId == this.categoryId &&
          other.subcategoryId == this.subcategoryId &&
          other.measurementMode == this.measurementMode &&
          other.needsCategoryReview == this.needsCategoryReview &&
          other.description == this.description &&
          other.isArchived == this.isArchived &&
          other.syncId == this.syncId &&
          other.logicalKey == this.logicalKey &&
          other.authorUid == this.authorUid &&
          other.authorName == this.authorName &&
          other.reviewState == this.reviewState &&
          other.reviewedByUid == this.reviewedByUid &&
          other.reviewedByName == this.reviewedByName &&
          other.reviewedAt == this.reviewedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncRevision == this.syncRevision &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<int> id;
  final Value<String> name;
  final Value<int?> categoryId;
  final Value<int?> subcategoryId;
  final Value<String> measurementMode;
  final Value<bool> needsCategoryReview;
  final Value<String?> description;
  final Value<bool> isArchived;
  final Value<String?> syncId;
  final Value<String?> logicalKey;
  final Value<String?> authorUid;
  final Value<String?> authorName;
  final Value<String> reviewState;
  final Value<String?> reviewedByUid;
  final Value<String?> reviewedByName;
  final Value<DateTime?> reviewedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> syncRevision;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.subcategoryId = const Value.absent(),
    this.measurementMode = const Value.absent(),
    this.needsCategoryReview = const Value.absent(),
    this.description = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.syncId = const Value.absent(),
    this.logicalKey = const Value.absent(),
    this.authorUid = const Value.absent(),
    this.authorName = const Value.absent(),
    this.reviewState = const Value.absent(),
    this.reviewedByUid = const Value.absent(),
    this.reviewedByName = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncRevision = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.categoryId = const Value.absent(),
    this.subcategoryId = const Value.absent(),
    this.measurementMode = const Value.absent(),
    this.needsCategoryReview = const Value.absent(),
    this.description = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.syncId = const Value.absent(),
    this.logicalKey = const Value.absent(),
    this.authorUid = const Value.absent(),
    this.authorName = const Value.absent(),
    this.reviewState = const Value.absent(),
    this.reviewedByUid = const Value.absent(),
    this.reviewedByName = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncRevision = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Product> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? categoryId,
    Expression<int>? subcategoryId,
    Expression<String>? measurementMode,
    Expression<bool>? needsCategoryReview,
    Expression<String>? description,
    Expression<bool>? isArchived,
    Expression<String>? syncId,
    Expression<String>? logicalKey,
    Expression<String>? authorUid,
    Expression<String>? authorName,
    Expression<String>? reviewState,
    Expression<String>? reviewedByUid,
    Expression<String>? reviewedByName,
    Expression<DateTime>? reviewedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? syncRevision,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
      if (measurementMode != null) 'measurement_mode': measurementMode,
      if (needsCategoryReview != null)
        'needs_category_review': needsCategoryReview,
      if (description != null) 'description': description,
      if (isArchived != null) 'is_archived': isArchived,
      if (syncId != null) 'sync_id': syncId,
      if (logicalKey != null) 'logical_key': logicalKey,
      if (authorUid != null) 'author_uid': authorUid,
      if (authorName != null) 'author_name': authorName,
      if (reviewState != null) 'review_state': reviewState,
      if (reviewedByUid != null) 'reviewed_by_uid': reviewedByUid,
      if (reviewedByName != null) 'reviewed_by_name': reviewedByName,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncRevision != null) 'sync_revision': syncRevision,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProductsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int?>? categoryId,
    Value<int?>? subcategoryId,
    Value<String>? measurementMode,
    Value<bool>? needsCategoryReview,
    Value<String?>? description,
    Value<bool>? isArchived,
    Value<String?>? syncId,
    Value<String?>? logicalKey,
    Value<String?>? authorUid,
    Value<String?>? authorName,
    Value<String>? reviewState,
    Value<String?>? reviewedByUid,
    Value<String?>? reviewedByName,
    Value<DateTime?>? reviewedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? syncRevision,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      measurementMode: measurementMode ?? this.measurementMode,
      needsCategoryReview: needsCategoryReview ?? this.needsCategoryReview,
      description: description ?? this.description,
      isArchived: isArchived ?? this.isArchived,
      syncId: syncId ?? this.syncId,
      logicalKey: logicalKey ?? this.logicalKey,
      authorUid: authorUid ?? this.authorUid,
      authorName: authorName ?? this.authorName,
      reviewState: reviewState ?? this.reviewState,
      reviewedByUid: reviewedByUid ?? this.reviewedByUid,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncRevision: syncRevision ?? this.syncRevision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (subcategoryId.present) {
      map['subcategory_id'] = Variable<int>(subcategoryId.value);
    }
    if (measurementMode.present) {
      map['measurement_mode'] = Variable<String>(measurementMode.value);
    }
    if (needsCategoryReview.present) {
      map['needs_category_review'] = Variable<bool>(needsCategoryReview.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (logicalKey.present) {
      map['logical_key'] = Variable<String>(logicalKey.value);
    }
    if (authorUid.present) {
      map['author_uid'] = Variable<String>(authorUid.value);
    }
    if (authorName.present) {
      map['author_name'] = Variable<String>(authorName.value);
    }
    if (reviewState.present) {
      map['review_state'] = Variable<String>(reviewState.value);
    }
    if (reviewedByUid.present) {
      map['reviewed_by_uid'] = Variable<String>(reviewedByUid.value);
    }
    if (reviewedByName.present) {
      map['reviewed_by_name'] = Variable<String>(reviewedByName.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncRevision.present) {
      map['sync_revision'] = Variable<int>(syncRevision.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('subcategoryId: $subcategoryId, ')
          ..write('measurementMode: $measurementMode, ')
          ..write('needsCategoryReview: $needsCategoryReview, ')
          ..write('description: $description, ')
          ..write('isArchived: $isArchived, ')
          ..write('syncId: $syncId, ')
          ..write('logicalKey: $logicalKey, ')
          ..write('authorUid: $authorUid, ')
          ..write('authorName: $authorName, ')
          ..write('reviewState: $reviewState, ')
          ..write('reviewedByUid: $reviewedByUid, ')
          ..write('reviewedByName: $reviewedByName, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncRevision: $syncRevision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ImportBatchesTable extends ImportBatches
    with TableInfo<$ImportBatchesTable, ImportBatch> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportBatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceKeyMeta = const VerificationMeta(
    'sourceKey',
  );
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
    'source_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _sourceNameMeta = const VerificationMeta(
    'sourceName',
  );
  @override
  late final GeneratedColumn<String> sourceName = GeneratedColumn<String>(
    'source_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryCountMeta = const VerificationMeta(
    'entryCount',
  );
  @override
  late final GeneratedColumn<int> entryCount = GeneratedColumn<int>(
    'entry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceKey,
    sourceName,
    entryCount,
    importedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_batches';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportBatch> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_key')) {
      context.handle(
        _sourceKeyMeta,
        sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceKeyMeta);
    }
    if (data.containsKey('source_name')) {
      context.handle(
        _sourceNameMeta,
        sourceName.isAcceptableOrUnknown(data['source_name']!, _sourceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceNameMeta);
    }
    if (data.containsKey('entry_count')) {
      context.handle(
        _entryCountMeta,
        entryCount.isAcceptableOrUnknown(data['entry_count']!, _entryCountMeta),
      );
    } else if (isInserting) {
      context.missing(_entryCountMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImportBatch map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportBatch(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_key'],
      )!,
      sourceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_name'],
      )!,
      entryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_count'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
    );
  }

  @override
  $ImportBatchesTable createAlias(String alias) {
    return $ImportBatchesTable(attachedDatabase, alias);
  }
}

class ImportBatch extends DataClass implements Insertable<ImportBatch> {
  final int id;
  final String sourceKey;
  final String sourceName;
  final int entryCount;
  final DateTime importedAt;
  const ImportBatch({
    required this.id,
    required this.sourceKey,
    required this.sourceName,
    required this.entryCount,
    required this.importedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_key'] = Variable<String>(sourceKey);
    map['source_name'] = Variable<String>(sourceName);
    map['entry_count'] = Variable<int>(entryCount);
    map['imported_at'] = Variable<DateTime>(importedAt);
    return map;
  }

  ImportBatchesCompanion toCompanion(bool nullToAbsent) {
    return ImportBatchesCompanion(
      id: Value(id),
      sourceKey: Value(sourceKey),
      sourceName: Value(sourceName),
      entryCount: Value(entryCount),
      importedAt: Value(importedAt),
    );
  }

  factory ImportBatch.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportBatch(
      id: serializer.fromJson<int>(json['id']),
      sourceKey: serializer.fromJson<String>(json['sourceKey']),
      sourceName: serializer.fromJson<String>(json['sourceName']),
      entryCount: serializer.fromJson<int>(json['entryCount']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceKey': serializer.toJson<String>(sourceKey),
      'sourceName': serializer.toJson<String>(sourceName),
      'entryCount': serializer.toJson<int>(entryCount),
      'importedAt': serializer.toJson<DateTime>(importedAt),
    };
  }

  ImportBatch copyWith({
    int? id,
    String? sourceKey,
    String? sourceName,
    int? entryCount,
    DateTime? importedAt,
  }) => ImportBatch(
    id: id ?? this.id,
    sourceKey: sourceKey ?? this.sourceKey,
    sourceName: sourceName ?? this.sourceName,
    entryCount: entryCount ?? this.entryCount,
    importedAt: importedAt ?? this.importedAt,
  );
  ImportBatch copyWithCompanion(ImportBatchesCompanion data) {
    return ImportBatch(
      id: data.id.present ? data.id.value : this.id,
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
      sourceName: data.sourceName.present
          ? data.sourceName.value
          : this.sourceName,
      entryCount: data.entryCount.present
          ? data.entryCount.value
          : this.entryCount,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportBatch(')
          ..write('id: $id, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('sourceName: $sourceName, ')
          ..write('entryCount: $entryCount, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sourceKey, sourceName, entryCount, importedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportBatch &&
          other.id == this.id &&
          other.sourceKey == this.sourceKey &&
          other.sourceName == this.sourceName &&
          other.entryCount == this.entryCount &&
          other.importedAt == this.importedAt);
}

class ImportBatchesCompanion extends UpdateCompanion<ImportBatch> {
  final Value<int> id;
  final Value<String> sourceKey;
  final Value<String> sourceName;
  final Value<int> entryCount;
  final Value<DateTime> importedAt;
  const ImportBatchesCompanion({
    this.id = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.sourceName = const Value.absent(),
    this.entryCount = const Value.absent(),
    this.importedAt = const Value.absent(),
  });
  ImportBatchesCompanion.insert({
    this.id = const Value.absent(),
    required String sourceKey,
    required String sourceName,
    required int entryCount,
    this.importedAt = const Value.absent(),
  }) : sourceKey = Value(sourceKey),
       sourceName = Value(sourceName),
       entryCount = Value(entryCount);
  static Insertable<ImportBatch> custom({
    Expression<int>? id,
    Expression<String>? sourceKey,
    Expression<String>? sourceName,
    Expression<int>? entryCount,
    Expression<DateTime>? importedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceKey != null) 'source_key': sourceKey,
      if (sourceName != null) 'source_name': sourceName,
      if (entryCount != null) 'entry_count': entryCount,
      if (importedAt != null) 'imported_at': importedAt,
    });
  }

  ImportBatchesCompanion copyWith({
    Value<int>? id,
    Value<String>? sourceKey,
    Value<String>? sourceName,
    Value<int>? entryCount,
    Value<DateTime>? importedAt,
  }) {
    return ImportBatchesCompanion(
      id: id ?? this.id,
      sourceKey: sourceKey ?? this.sourceKey,
      sourceName: sourceName ?? this.sourceName,
      entryCount: entryCount ?? this.entryCount,
      importedAt: importedAt ?? this.importedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (sourceName.present) {
      map['source_name'] = Variable<String>(sourceName.value);
    }
    if (entryCount.present) {
      map['entry_count'] = Variable<int>(entryCount.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportBatchesCompanion(')
          ..write('id: $id, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('sourceName: $sourceName, ')
          ..write('entryCount: $entryCount, ')
          ..write('importedAt: $importedAt')
          ..write(')'))
        .toString();
  }
}

class $ImportEntriesTable extends ImportEntries
    with TableInfo<$ImportEntriesTable, ImportEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<int> batchId = GeneratedColumn<int>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceSheetMeta = const VerificationMeta(
    'sourceSheet',
  );
  @override
  late final GeneratedColumn<String> sourceSheet = GeneratedColumn<String>(
    'source_sheet',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRowMeta = const VerificationMeta(
    'sourceRow',
  );
  @override
  late final GeneratedColumn<int> sourceRow = GeneratedColumn<int>(
    'source_row',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNumberMeta = const VerificationMeta(
    'sourceNumber',
  );
  @override
  late final GeneratedColumn<int> sourceNumber = GeneratedColumn<int>(
    'source_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNameMeta = const VerificationMeta(
    'sourceName',
  );
  @override
  late final GeneratedColumn<String> sourceName = GeneratedColumn<String>(
    'source_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _suggestedCategoryMeta = const VerificationMeta(
    'suggestedCategory',
  );
  @override
  late final GeneratedColumn<String> suggestedCategory =
      GeneratedColumn<String>(
        'suggested_category',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _needsCategoryReviewMeta =
      const VerificationMeta('needsCategoryReview');
  @override
  late final GeneratedColumn<bool> needsCategoryReview = GeneratedColumn<bool>(
    'needs_category_review',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_category_review" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    batchId,
    sourceSheet,
    sourceRow,
    sourceNumber,
    sourceName,
    suggestedCategory,
    needsCategoryReview,
    status,
    productId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('source_sheet')) {
      context.handle(
        _sourceSheetMeta,
        sourceSheet.isAcceptableOrUnknown(
          data['source_sheet']!,
          _sourceSheetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceSheetMeta);
    }
    if (data.containsKey('source_row')) {
      context.handle(
        _sourceRowMeta,
        sourceRow.isAcceptableOrUnknown(data['source_row']!, _sourceRowMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceRowMeta);
    }
    if (data.containsKey('source_number')) {
      context.handle(
        _sourceNumberMeta,
        sourceNumber.isAcceptableOrUnknown(
          data['source_number']!,
          _sourceNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceNumberMeta);
    }
    if (data.containsKey('source_name')) {
      context.handle(
        _sourceNameMeta,
        sourceName.isAcceptableOrUnknown(data['source_name']!, _sourceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceNameMeta);
    }
    if (data.containsKey('suggested_category')) {
      context.handle(
        _suggestedCategoryMeta,
        suggestedCategory.isAcceptableOrUnknown(
          data['suggested_category']!,
          _suggestedCategoryMeta,
        ),
      );
    }
    if (data.containsKey('needs_category_review')) {
      context.handle(
        _needsCategoryReviewMeta,
        needsCategoryReview.isAcceptableOrUnknown(
          data['needs_category_review']!,
          _needsCategoryReviewMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {batchId, sourceSheet, sourceRow},
  ];
  @override
  ImportEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}batch_id'],
      )!,
      sourceSheet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_sheet'],
      )!,
      sourceRow: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_row'],
      )!,
      sourceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_number'],
      )!,
      sourceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_name'],
      )!,
      suggestedCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}suggested_category'],
      ),
      needsCategoryReview: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_category_review'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      ),
    );
  }

  @override
  $ImportEntriesTable createAlias(String alias) {
    return $ImportEntriesTable(attachedDatabase, alias);
  }
}

class ImportEntry extends DataClass implements Insertable<ImportEntry> {
  final int id;
  final int batchId;
  final String sourceSheet;
  final int sourceRow;
  final int sourceNumber;
  final String sourceName;
  final String? suggestedCategory;
  final bool needsCategoryReview;
  final String status;
  final int? productId;
  const ImportEntry({
    required this.id,
    required this.batchId,
    required this.sourceSheet,
    required this.sourceRow,
    required this.sourceNumber,
    required this.sourceName,
    this.suggestedCategory,
    required this.needsCategoryReview,
    required this.status,
    this.productId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['batch_id'] = Variable<int>(batchId);
    map['source_sheet'] = Variable<String>(sourceSheet);
    map['source_row'] = Variable<int>(sourceRow);
    map['source_number'] = Variable<int>(sourceNumber);
    map['source_name'] = Variable<String>(sourceName);
    if (!nullToAbsent || suggestedCategory != null) {
      map['suggested_category'] = Variable<String>(suggestedCategory);
    }
    map['needs_category_review'] = Variable<bool>(needsCategoryReview);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<int>(productId);
    }
    return map;
  }

  ImportEntriesCompanion toCompanion(bool nullToAbsent) {
    return ImportEntriesCompanion(
      id: Value(id),
      batchId: Value(batchId),
      sourceSheet: Value(sourceSheet),
      sourceRow: Value(sourceRow),
      sourceNumber: Value(sourceNumber),
      sourceName: Value(sourceName),
      suggestedCategory: suggestedCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(suggestedCategory),
      needsCategoryReview: Value(needsCategoryReview),
      status: Value(status),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
    );
  }

  factory ImportEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportEntry(
      id: serializer.fromJson<int>(json['id']),
      batchId: serializer.fromJson<int>(json['batchId']),
      sourceSheet: serializer.fromJson<String>(json['sourceSheet']),
      sourceRow: serializer.fromJson<int>(json['sourceRow']),
      sourceNumber: serializer.fromJson<int>(json['sourceNumber']),
      sourceName: serializer.fromJson<String>(json['sourceName']),
      suggestedCategory: serializer.fromJson<String?>(
        json['suggestedCategory'],
      ),
      needsCategoryReview: serializer.fromJson<bool>(
        json['needsCategoryReview'],
      ),
      status: serializer.fromJson<String>(json['status']),
      productId: serializer.fromJson<int?>(json['productId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'batchId': serializer.toJson<int>(batchId),
      'sourceSheet': serializer.toJson<String>(sourceSheet),
      'sourceRow': serializer.toJson<int>(sourceRow),
      'sourceNumber': serializer.toJson<int>(sourceNumber),
      'sourceName': serializer.toJson<String>(sourceName),
      'suggestedCategory': serializer.toJson<String?>(suggestedCategory),
      'needsCategoryReview': serializer.toJson<bool>(needsCategoryReview),
      'status': serializer.toJson<String>(status),
      'productId': serializer.toJson<int?>(productId),
    };
  }

  ImportEntry copyWith({
    int? id,
    int? batchId,
    String? sourceSheet,
    int? sourceRow,
    int? sourceNumber,
    String? sourceName,
    Value<String?> suggestedCategory = const Value.absent(),
    bool? needsCategoryReview,
    String? status,
    Value<int?> productId = const Value.absent(),
  }) => ImportEntry(
    id: id ?? this.id,
    batchId: batchId ?? this.batchId,
    sourceSheet: sourceSheet ?? this.sourceSheet,
    sourceRow: sourceRow ?? this.sourceRow,
    sourceNumber: sourceNumber ?? this.sourceNumber,
    sourceName: sourceName ?? this.sourceName,
    suggestedCategory: suggestedCategory.present
        ? suggestedCategory.value
        : this.suggestedCategory,
    needsCategoryReview: needsCategoryReview ?? this.needsCategoryReview,
    status: status ?? this.status,
    productId: productId.present ? productId.value : this.productId,
  );
  ImportEntry copyWithCompanion(ImportEntriesCompanion data) {
    return ImportEntry(
      id: data.id.present ? data.id.value : this.id,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      sourceSheet: data.sourceSheet.present
          ? data.sourceSheet.value
          : this.sourceSheet,
      sourceRow: data.sourceRow.present ? data.sourceRow.value : this.sourceRow,
      sourceNumber: data.sourceNumber.present
          ? data.sourceNumber.value
          : this.sourceNumber,
      sourceName: data.sourceName.present
          ? data.sourceName.value
          : this.sourceName,
      suggestedCategory: data.suggestedCategory.present
          ? data.suggestedCategory.value
          : this.suggestedCategory,
      needsCategoryReview: data.needsCategoryReview.present
          ? data.needsCategoryReview.value
          : this.needsCategoryReview,
      status: data.status.present ? data.status.value : this.status,
      productId: data.productId.present ? data.productId.value : this.productId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportEntry(')
          ..write('id: $id, ')
          ..write('batchId: $batchId, ')
          ..write('sourceSheet: $sourceSheet, ')
          ..write('sourceRow: $sourceRow, ')
          ..write('sourceNumber: $sourceNumber, ')
          ..write('sourceName: $sourceName, ')
          ..write('suggestedCategory: $suggestedCategory, ')
          ..write('needsCategoryReview: $needsCategoryReview, ')
          ..write('status: $status, ')
          ..write('productId: $productId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    batchId,
    sourceSheet,
    sourceRow,
    sourceNumber,
    sourceName,
    suggestedCategory,
    needsCategoryReview,
    status,
    productId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportEntry &&
          other.id == this.id &&
          other.batchId == this.batchId &&
          other.sourceSheet == this.sourceSheet &&
          other.sourceRow == this.sourceRow &&
          other.sourceNumber == this.sourceNumber &&
          other.sourceName == this.sourceName &&
          other.suggestedCategory == this.suggestedCategory &&
          other.needsCategoryReview == this.needsCategoryReview &&
          other.status == this.status &&
          other.productId == this.productId);
}

class ImportEntriesCompanion extends UpdateCompanion<ImportEntry> {
  final Value<int> id;
  final Value<int> batchId;
  final Value<String> sourceSheet;
  final Value<int> sourceRow;
  final Value<int> sourceNumber;
  final Value<String> sourceName;
  final Value<String?> suggestedCategory;
  final Value<bool> needsCategoryReview;
  final Value<String> status;
  final Value<int?> productId;
  const ImportEntriesCompanion({
    this.id = const Value.absent(),
    this.batchId = const Value.absent(),
    this.sourceSheet = const Value.absent(),
    this.sourceRow = const Value.absent(),
    this.sourceNumber = const Value.absent(),
    this.sourceName = const Value.absent(),
    this.suggestedCategory = const Value.absent(),
    this.needsCategoryReview = const Value.absent(),
    this.status = const Value.absent(),
    this.productId = const Value.absent(),
  });
  ImportEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int batchId,
    required String sourceSheet,
    required int sourceRow,
    required int sourceNumber,
    required String sourceName,
    this.suggestedCategory = const Value.absent(),
    this.needsCategoryReview = const Value.absent(),
    required String status,
    this.productId = const Value.absent(),
  }) : batchId = Value(batchId),
       sourceSheet = Value(sourceSheet),
       sourceRow = Value(sourceRow),
       sourceNumber = Value(sourceNumber),
       sourceName = Value(sourceName),
       status = Value(status);
  static Insertable<ImportEntry> custom({
    Expression<int>? id,
    Expression<int>? batchId,
    Expression<String>? sourceSheet,
    Expression<int>? sourceRow,
    Expression<int>? sourceNumber,
    Expression<String>? sourceName,
    Expression<String>? suggestedCategory,
    Expression<bool>? needsCategoryReview,
    Expression<String>? status,
    Expression<int>? productId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (batchId != null) 'batch_id': batchId,
      if (sourceSheet != null) 'source_sheet': sourceSheet,
      if (sourceRow != null) 'source_row': sourceRow,
      if (sourceNumber != null) 'source_number': sourceNumber,
      if (sourceName != null) 'source_name': sourceName,
      if (suggestedCategory != null) 'suggested_category': suggestedCategory,
      if (needsCategoryReview != null)
        'needs_category_review': needsCategoryReview,
      if (status != null) 'status': status,
      if (productId != null) 'product_id': productId,
    });
  }

  ImportEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? batchId,
    Value<String>? sourceSheet,
    Value<int>? sourceRow,
    Value<int>? sourceNumber,
    Value<String>? sourceName,
    Value<String?>? suggestedCategory,
    Value<bool>? needsCategoryReview,
    Value<String>? status,
    Value<int?>? productId,
  }) {
    return ImportEntriesCompanion(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      sourceSheet: sourceSheet ?? this.sourceSheet,
      sourceRow: sourceRow ?? this.sourceRow,
      sourceNumber: sourceNumber ?? this.sourceNumber,
      sourceName: sourceName ?? this.sourceName,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      needsCategoryReview: needsCategoryReview ?? this.needsCategoryReview,
      status: status ?? this.status,
      productId: productId ?? this.productId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<int>(batchId.value);
    }
    if (sourceSheet.present) {
      map['source_sheet'] = Variable<String>(sourceSheet.value);
    }
    if (sourceRow.present) {
      map['source_row'] = Variable<int>(sourceRow.value);
    }
    if (sourceNumber.present) {
      map['source_number'] = Variable<int>(sourceNumber.value);
    }
    if (sourceName.present) {
      map['source_name'] = Variable<String>(sourceName.value);
    }
    if (suggestedCategory.present) {
      map['suggested_category'] = Variable<String>(suggestedCategory.value);
    }
    if (needsCategoryReview.present) {
      map['needs_category_review'] = Variable<bool>(needsCategoryReview.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportEntriesCompanion(')
          ..write('id: $id, ')
          ..write('batchId: $batchId, ')
          ..write('sourceSheet: $sourceSheet, ')
          ..write('sourceRow: $sourceRow, ')
          ..write('sourceNumber: $sourceNumber, ')
          ..write('sourceName: $sourceName, ')
          ..write('suggestedCategory: $suggestedCategory, ')
          ..write('needsCategoryReview: $needsCategoryReview, ')
          ..write('status: $status, ')
          ..write('productId: $productId')
          ..write(')'))
        .toString();
  }
}

class $ShoppingPlansTable extends ShoppingPlans
    with TableInfo<$ShoppingPlansTable, ShoppingPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _monthKeyMeta = const VerificationMeta(
    'monthKey',
  );
  @override
  late final GeneratedColumn<String> monthKey = GeneratedColumn<String>(
    'month_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 7,
      maxTextLength: 7,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logicalKeyMeta = const VerificationMeta(
    'logicalKey',
  );
  @override
  late final GeneratedColumn<String> logicalKey = GeneratedColumn<String>(
    'logical_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorUidMeta = const VerificationMeta(
    'authorUid',
  );
  @override
  late final GeneratedColumn<String> authorUid = GeneratedColumn<String>(
    'author_uid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorNameMeta = const VerificationMeta(
    'authorName',
  );
  @override
  late final GeneratedColumn<String> authorName = GeneratedColumn<String>(
    'author_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewStateMeta = const VerificationMeta(
    'reviewState',
  );
  @override
  late final GeneratedColumn<String> reviewState = GeneratedColumn<String>(
    'review_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('approved'),
  );
  static const VerificationMeta _reviewedByUidMeta = const VerificationMeta(
    'reviewedByUid',
  );
  @override
  late final GeneratedColumn<String> reviewedByUid = GeneratedColumn<String>(
    'reviewed_by_uid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewedByNameMeta = const VerificationMeta(
    'reviewedByName',
  );
  @override
  late final GeneratedColumn<String> reviewedByName = GeneratedColumn<String>(
    'reviewed_by_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncRevisionMeta = const VerificationMeta(
    'syncRevision',
  );
  @override
  late final GeneratedColumn<int> syncRevision = GeneratedColumn<int>(
    'sync_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    monthKey,
    name,
    status,
    syncId,
    logicalKey,
    authorUid,
    authorName,
    reviewState,
    reviewedByUid,
    reviewedByName,
    reviewedAt,
    deletedAt,
    syncRevision,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShoppingPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('month_key')) {
      context.handle(
        _monthKeyMeta,
        monthKey.isAcceptableOrUnknown(data['month_key']!, _monthKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_monthKeyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('logical_key')) {
      context.handle(
        _logicalKeyMeta,
        logicalKey.isAcceptableOrUnknown(data['logical_key']!, _logicalKeyMeta),
      );
    }
    if (data.containsKey('author_uid')) {
      context.handle(
        _authorUidMeta,
        authorUid.isAcceptableOrUnknown(data['author_uid']!, _authorUidMeta),
      );
    }
    if (data.containsKey('author_name')) {
      context.handle(
        _authorNameMeta,
        authorName.isAcceptableOrUnknown(data['author_name']!, _authorNameMeta),
      );
    }
    if (data.containsKey('review_state')) {
      context.handle(
        _reviewStateMeta,
        reviewState.isAcceptableOrUnknown(
          data['review_state']!,
          _reviewStateMeta,
        ),
      );
    }
    if (data.containsKey('reviewed_by_uid')) {
      context.handle(
        _reviewedByUidMeta,
        reviewedByUid.isAcceptableOrUnknown(
          data['reviewed_by_uid']!,
          _reviewedByUidMeta,
        ),
      );
    }
    if (data.containsKey('reviewed_by_name')) {
      context.handle(
        _reviewedByNameMeta,
        reviewedByName.isAcceptableOrUnknown(
          data['reviewed_by_name']!,
          _reviewedByNameMeta,
        ),
      );
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_revision')) {
      context.handle(
        _syncRevisionMeta,
        syncRevision.isAcceptableOrUnknown(
          data['sync_revision']!,
          _syncRevisionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      monthKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month_key'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      ),
      logicalKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logical_key'],
      ),
      authorUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_uid'],
      ),
      authorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_name'],
      ),
      reviewState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_state'],
      )!,
      reviewedByUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reviewed_by_uid'],
      ),
      reviewedByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reviewed_by_name'],
      ),
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_revision'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ShoppingPlansTable createAlias(String alias) {
    return $ShoppingPlansTable(attachedDatabase, alias);
  }
}

class ShoppingPlan extends DataClass implements Insertable<ShoppingPlan> {
  final int id;
  final String monthKey;
  final String name;
  final String status;
  final String? syncId;
  final String? logicalKey;
  final String? authorUid;
  final String? authorName;
  final String reviewState;
  final String? reviewedByUid;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final DateTime? deletedAt;
  final int syncRevision;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ShoppingPlan({
    required this.id,
    required this.monthKey,
    required this.name,
    required this.status,
    this.syncId,
    this.logicalKey,
    this.authorUid,
    this.authorName,
    required this.reviewState,
    this.reviewedByUid,
    this.reviewedByName,
    this.reviewedAt,
    this.deletedAt,
    required this.syncRevision,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['month_key'] = Variable<String>(monthKey);
    map['name'] = Variable<String>(name);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || syncId != null) {
      map['sync_id'] = Variable<String>(syncId);
    }
    if (!nullToAbsent || logicalKey != null) {
      map['logical_key'] = Variable<String>(logicalKey);
    }
    if (!nullToAbsent || authorUid != null) {
      map['author_uid'] = Variable<String>(authorUid);
    }
    if (!nullToAbsent || authorName != null) {
      map['author_name'] = Variable<String>(authorName);
    }
    map['review_state'] = Variable<String>(reviewState);
    if (!nullToAbsent || reviewedByUid != null) {
      map['reviewed_by_uid'] = Variable<String>(reviewedByUid);
    }
    if (!nullToAbsent || reviewedByName != null) {
      map['reviewed_by_name'] = Variable<String>(reviewedByName);
    }
    if (!nullToAbsent || reviewedAt != null) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_revision'] = Variable<int>(syncRevision);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ShoppingPlansCompanion toCompanion(bool nullToAbsent) {
    return ShoppingPlansCompanion(
      id: Value(id),
      monthKey: Value(monthKey),
      name: Value(name),
      status: Value(status),
      syncId: syncId == null && nullToAbsent
          ? const Value.absent()
          : Value(syncId),
      logicalKey: logicalKey == null && nullToAbsent
          ? const Value.absent()
          : Value(logicalKey),
      authorUid: authorUid == null && nullToAbsent
          ? const Value.absent()
          : Value(authorUid),
      authorName: authorName == null && nullToAbsent
          ? const Value.absent()
          : Value(authorName),
      reviewState: Value(reviewState),
      reviewedByUid: reviewedByUid == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedByUid),
      reviewedByName: reviewedByName == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedByName),
      reviewedAt: reviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncRevision: Value(syncRevision),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ShoppingPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingPlan(
      id: serializer.fromJson<int>(json['id']),
      monthKey: serializer.fromJson<String>(json['monthKey']),
      name: serializer.fromJson<String>(json['name']),
      status: serializer.fromJson<String>(json['status']),
      syncId: serializer.fromJson<String?>(json['syncId']),
      logicalKey: serializer.fromJson<String?>(json['logicalKey']),
      authorUid: serializer.fromJson<String?>(json['authorUid']),
      authorName: serializer.fromJson<String?>(json['authorName']),
      reviewState: serializer.fromJson<String>(json['reviewState']),
      reviewedByUid: serializer.fromJson<String?>(json['reviewedByUid']),
      reviewedByName: serializer.fromJson<String?>(json['reviewedByName']),
      reviewedAt: serializer.fromJson<DateTime?>(json['reviewedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncRevision: serializer.fromJson<int>(json['syncRevision']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'monthKey': serializer.toJson<String>(monthKey),
      'name': serializer.toJson<String>(name),
      'status': serializer.toJson<String>(status),
      'syncId': serializer.toJson<String?>(syncId),
      'logicalKey': serializer.toJson<String?>(logicalKey),
      'authorUid': serializer.toJson<String?>(authorUid),
      'authorName': serializer.toJson<String?>(authorName),
      'reviewState': serializer.toJson<String>(reviewState),
      'reviewedByUid': serializer.toJson<String?>(reviewedByUid),
      'reviewedByName': serializer.toJson<String?>(reviewedByName),
      'reviewedAt': serializer.toJson<DateTime?>(reviewedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncRevision': serializer.toJson<int>(syncRevision),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ShoppingPlan copyWith({
    int? id,
    String? monthKey,
    String? name,
    String? status,
    Value<String?> syncId = const Value.absent(),
    Value<String?> logicalKey = const Value.absent(),
    Value<String?> authorUid = const Value.absent(),
    Value<String?> authorName = const Value.absent(),
    String? reviewState,
    Value<String?> reviewedByUid = const Value.absent(),
    Value<String?> reviewedByName = const Value.absent(),
    Value<DateTime?> reviewedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    int? syncRevision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ShoppingPlan(
    id: id ?? this.id,
    monthKey: monthKey ?? this.monthKey,
    name: name ?? this.name,
    status: status ?? this.status,
    syncId: syncId.present ? syncId.value : this.syncId,
    logicalKey: logicalKey.present ? logicalKey.value : this.logicalKey,
    authorUid: authorUid.present ? authorUid.value : this.authorUid,
    authorName: authorName.present ? authorName.value : this.authorName,
    reviewState: reviewState ?? this.reviewState,
    reviewedByUid: reviewedByUid.present
        ? reviewedByUid.value
        : this.reviewedByUid,
    reviewedByName: reviewedByName.present
        ? reviewedByName.value
        : this.reviewedByName,
    reviewedAt: reviewedAt.present ? reviewedAt.value : this.reviewedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncRevision: syncRevision ?? this.syncRevision,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ShoppingPlan copyWithCompanion(ShoppingPlansCompanion data) {
    return ShoppingPlan(
      id: data.id.present ? data.id.value : this.id,
      monthKey: data.monthKey.present ? data.monthKey.value : this.monthKey,
      name: data.name.present ? data.name.value : this.name,
      status: data.status.present ? data.status.value : this.status,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      logicalKey: data.logicalKey.present
          ? data.logicalKey.value
          : this.logicalKey,
      authorUid: data.authorUid.present ? data.authorUid.value : this.authorUid,
      authorName: data.authorName.present
          ? data.authorName.value
          : this.authorName,
      reviewState: data.reviewState.present
          ? data.reviewState.value
          : this.reviewState,
      reviewedByUid: data.reviewedByUid.present
          ? data.reviewedByUid.value
          : this.reviewedByUid,
      reviewedByName: data.reviewedByName.present
          ? data.reviewedByName.value
          : this.reviewedByName,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncRevision: data.syncRevision.present
          ? data.syncRevision.value
          : this.syncRevision,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingPlan(')
          ..write('id: $id, ')
          ..write('monthKey: $monthKey, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('syncId: $syncId, ')
          ..write('logicalKey: $logicalKey, ')
          ..write('authorUid: $authorUid, ')
          ..write('authorName: $authorName, ')
          ..write('reviewState: $reviewState, ')
          ..write('reviewedByUid: $reviewedByUid, ')
          ..write('reviewedByName: $reviewedByName, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncRevision: $syncRevision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    monthKey,
    name,
    status,
    syncId,
    logicalKey,
    authorUid,
    authorName,
    reviewState,
    reviewedByUid,
    reviewedByName,
    reviewedAt,
    deletedAt,
    syncRevision,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingPlan &&
          other.id == this.id &&
          other.monthKey == this.monthKey &&
          other.name == this.name &&
          other.status == this.status &&
          other.syncId == this.syncId &&
          other.logicalKey == this.logicalKey &&
          other.authorUid == this.authorUid &&
          other.authorName == this.authorName &&
          other.reviewState == this.reviewState &&
          other.reviewedByUid == this.reviewedByUid &&
          other.reviewedByName == this.reviewedByName &&
          other.reviewedAt == this.reviewedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncRevision == this.syncRevision &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ShoppingPlansCompanion extends UpdateCompanion<ShoppingPlan> {
  final Value<int> id;
  final Value<String> monthKey;
  final Value<String> name;
  final Value<String> status;
  final Value<String?> syncId;
  final Value<String?> logicalKey;
  final Value<String?> authorUid;
  final Value<String?> authorName;
  final Value<String> reviewState;
  final Value<String?> reviewedByUid;
  final Value<String?> reviewedByName;
  final Value<DateTime?> reviewedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> syncRevision;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ShoppingPlansCompanion({
    this.id = const Value.absent(),
    this.monthKey = const Value.absent(),
    this.name = const Value.absent(),
    this.status = const Value.absent(),
    this.syncId = const Value.absent(),
    this.logicalKey = const Value.absent(),
    this.authorUid = const Value.absent(),
    this.authorName = const Value.absent(),
    this.reviewState = const Value.absent(),
    this.reviewedByUid = const Value.absent(),
    this.reviewedByName = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncRevision = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ShoppingPlansCompanion.insert({
    this.id = const Value.absent(),
    required String monthKey,
    required String name,
    this.status = const Value.absent(),
    this.syncId = const Value.absent(),
    this.logicalKey = const Value.absent(),
    this.authorUid = const Value.absent(),
    this.authorName = const Value.absent(),
    this.reviewState = const Value.absent(),
    this.reviewedByUid = const Value.absent(),
    this.reviewedByName = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncRevision = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : monthKey = Value(monthKey),
       name = Value(name);
  static Insertable<ShoppingPlan> custom({
    Expression<int>? id,
    Expression<String>? monthKey,
    Expression<String>? name,
    Expression<String>? status,
    Expression<String>? syncId,
    Expression<String>? logicalKey,
    Expression<String>? authorUid,
    Expression<String>? authorName,
    Expression<String>? reviewState,
    Expression<String>? reviewedByUid,
    Expression<String>? reviewedByName,
    Expression<DateTime>? reviewedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? syncRevision,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (monthKey != null) 'month_key': monthKey,
      if (name != null) 'name': name,
      if (status != null) 'status': status,
      if (syncId != null) 'sync_id': syncId,
      if (logicalKey != null) 'logical_key': logicalKey,
      if (authorUid != null) 'author_uid': authorUid,
      if (authorName != null) 'author_name': authorName,
      if (reviewState != null) 'review_state': reviewState,
      if (reviewedByUid != null) 'reviewed_by_uid': reviewedByUid,
      if (reviewedByName != null) 'reviewed_by_name': reviewedByName,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncRevision != null) 'sync_revision': syncRevision,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ShoppingPlansCompanion copyWith({
    Value<int>? id,
    Value<String>? monthKey,
    Value<String>? name,
    Value<String>? status,
    Value<String?>? syncId,
    Value<String?>? logicalKey,
    Value<String?>? authorUid,
    Value<String?>? authorName,
    Value<String>? reviewState,
    Value<String?>? reviewedByUid,
    Value<String?>? reviewedByName,
    Value<DateTime?>? reviewedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? syncRevision,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ShoppingPlansCompanion(
      id: id ?? this.id,
      monthKey: monthKey ?? this.monthKey,
      name: name ?? this.name,
      status: status ?? this.status,
      syncId: syncId ?? this.syncId,
      logicalKey: logicalKey ?? this.logicalKey,
      authorUid: authorUid ?? this.authorUid,
      authorName: authorName ?? this.authorName,
      reviewState: reviewState ?? this.reviewState,
      reviewedByUid: reviewedByUid ?? this.reviewedByUid,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncRevision: syncRevision ?? this.syncRevision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (monthKey.present) {
      map['month_key'] = Variable<String>(monthKey.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (logicalKey.present) {
      map['logical_key'] = Variable<String>(logicalKey.value);
    }
    if (authorUid.present) {
      map['author_uid'] = Variable<String>(authorUid.value);
    }
    if (authorName.present) {
      map['author_name'] = Variable<String>(authorName.value);
    }
    if (reviewState.present) {
      map['review_state'] = Variable<String>(reviewState.value);
    }
    if (reviewedByUid.present) {
      map['reviewed_by_uid'] = Variable<String>(reviewedByUid.value);
    }
    if (reviewedByName.present) {
      map['reviewed_by_name'] = Variable<String>(reviewedByName.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncRevision.present) {
      map['sync_revision'] = Variable<int>(syncRevision.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingPlansCompanion(')
          ..write('id: $id, ')
          ..write('monthKey: $monthKey, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('syncId: $syncId, ')
          ..write('logicalKey: $logicalKey, ')
          ..write('authorUid: $authorUid, ')
          ..write('authorName: $authorName, ')
          ..write('reviewState: $reviewState, ')
          ..write('reviewedByUid: $reviewedByUid, ')
          ..write('reviewedByName: $reviewedByName, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncRevision: $syncRevision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PlannedItemsTable extends PlannedItems
    with TableInfo<$PlannedItemsTable, PlannedItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannedItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _measurementModeMeta = const VerificationMeta(
    'measurementMode',
  );
  @override
  late final GeneratedColumn<String> measurementMode = GeneratedColumn<String>(
    'measurement_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isRemovedMeta = const VerificationMeta(
    'isRemoved',
  );
  @override
  late final GeneratedColumn<bool> isRemoved = GeneratedColumn<bool>(
    'is_removed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_removed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _estimatePriceNumeratorCentsMeta =
      const VerificationMeta('estimatePriceNumeratorCents');
  @override
  late final GeneratedColumn<int> estimatePriceNumeratorCents =
      GeneratedColumn<int>(
        'estimate_price_numerator_cents',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _estimateQuantityDenominatorMeta =
      const VerificationMeta('estimateQuantityDenominator');
  @override
  late final GeneratedColumn<int> estimateQuantityDenominator =
      GeneratedColumn<int>(
        'estimate_quantity_denominator',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _estimateSourceMeta = const VerificationMeta(
    'estimateSource',
  );
  @override
  late final GeneratedColumn<String> estimateSource = GeneratedColumn<String>(
    'estimate_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estimateReferenceDateMeta =
      const VerificationMeta('estimateReferenceDate');
  @override
  late final GeneratedColumn<String> estimateReferenceDate =
      GeneratedColumn<String>(
        'estimate_reference_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _estimateReferenceTripIdMeta =
      const VerificationMeta('estimateReferenceTripId');
  @override
  late final GeneratedColumn<int> estimateReferenceTripId =
      GeneratedColumn<int>(
        'estimate_reference_trip_id',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logicalKeyMeta = const VerificationMeta(
    'logicalKey',
  );
  @override
  late final GeneratedColumn<String> logicalKey = GeneratedColumn<String>(
    'logical_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorUidMeta = const VerificationMeta(
    'authorUid',
  );
  @override
  late final GeneratedColumn<String> authorUid = GeneratedColumn<String>(
    'author_uid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorNameMeta = const VerificationMeta(
    'authorName',
  );
  @override
  late final GeneratedColumn<String> authorName = GeneratedColumn<String>(
    'author_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewStateMeta = const VerificationMeta(
    'reviewState',
  );
  @override
  late final GeneratedColumn<String> reviewState = GeneratedColumn<String>(
    'review_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('approved'),
  );
  static const VerificationMeta _reviewedByUidMeta = const VerificationMeta(
    'reviewedByUid',
  );
  @override
  late final GeneratedColumn<String> reviewedByUid = GeneratedColumn<String>(
    'reviewed_by_uid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewedByNameMeta = const VerificationMeta(
    'reviewedByName',
  );
  @override
  late final GeneratedColumn<String> reviewedByName = GeneratedColumn<String>(
    'reviewed_by_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncRevisionMeta = const VerificationMeta(
    'syncRevision',
  );
  @override
  late final GeneratedColumn<int> syncRevision = GeneratedColumn<int>(
    'sync_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    productId,
    measurementMode,
    quantity,
    isRemoved,
    estimatePriceNumeratorCents,
    estimateQuantityDenominator,
    estimateSource,
    estimateReferenceDate,
    estimateReferenceTripId,
    syncId,
    logicalKey,
    authorUid,
    authorName,
    reviewState,
    reviewedByUid,
    reviewedByName,
    reviewedAt,
    deletedAt,
    syncRevision,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planned_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannedItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('measurement_mode')) {
      context.handle(
        _measurementModeMeta,
        measurementMode.isAcceptableOrUnknown(
          data['measurement_mode']!,
          _measurementModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_measurementModeMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('is_removed')) {
      context.handle(
        _isRemovedMeta,
        isRemoved.isAcceptableOrUnknown(data['is_removed']!, _isRemovedMeta),
      );
    }
    if (data.containsKey('estimate_price_numerator_cents')) {
      context.handle(
        _estimatePriceNumeratorCentsMeta,
        estimatePriceNumeratorCents.isAcceptableOrUnknown(
          data['estimate_price_numerator_cents']!,
          _estimatePriceNumeratorCentsMeta,
        ),
      );
    }
    if (data.containsKey('estimate_quantity_denominator')) {
      context.handle(
        _estimateQuantityDenominatorMeta,
        estimateQuantityDenominator.isAcceptableOrUnknown(
          data['estimate_quantity_denominator']!,
          _estimateQuantityDenominatorMeta,
        ),
      );
    }
    if (data.containsKey('estimate_source')) {
      context.handle(
        _estimateSourceMeta,
        estimateSource.isAcceptableOrUnknown(
          data['estimate_source']!,
          _estimateSourceMeta,
        ),
      );
    }
    if (data.containsKey('estimate_reference_date')) {
      context.handle(
        _estimateReferenceDateMeta,
        estimateReferenceDate.isAcceptableOrUnknown(
          data['estimate_reference_date']!,
          _estimateReferenceDateMeta,
        ),
      );
    }
    if (data.containsKey('estimate_reference_trip_id')) {
      context.handle(
        _estimateReferenceTripIdMeta,
        estimateReferenceTripId.isAcceptableOrUnknown(
          data['estimate_reference_trip_id']!,
          _estimateReferenceTripIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('logical_key')) {
      context.handle(
        _logicalKeyMeta,
        logicalKey.isAcceptableOrUnknown(data['logical_key']!, _logicalKeyMeta),
      );
    }
    if (data.containsKey('author_uid')) {
      context.handle(
        _authorUidMeta,
        authorUid.isAcceptableOrUnknown(data['author_uid']!, _authorUidMeta),
      );
    }
    if (data.containsKey('author_name')) {
      context.handle(
        _authorNameMeta,
        authorName.isAcceptableOrUnknown(data['author_name']!, _authorNameMeta),
      );
    }
    if (data.containsKey('review_state')) {
      context.handle(
        _reviewStateMeta,
        reviewState.isAcceptableOrUnknown(
          data['review_state']!,
          _reviewStateMeta,
        ),
      );
    }
    if (data.containsKey('reviewed_by_uid')) {
      context.handle(
        _reviewedByUidMeta,
        reviewedByUid.isAcceptableOrUnknown(
          data['reviewed_by_uid']!,
          _reviewedByUidMeta,
        ),
      );
    }
    if (data.containsKey('reviewed_by_name')) {
      context.handle(
        _reviewedByNameMeta,
        reviewedByName.isAcceptableOrUnknown(
          data['reviewed_by_name']!,
          _reviewedByNameMeta,
        ),
      );
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('sync_revision')) {
      context.handle(
        _syncRevisionMeta,
        syncRevision.isAcceptableOrUnknown(
          data['sync_revision']!,
          _syncRevisionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlannedItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannedItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      measurementMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measurement_mode'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      isRemoved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_removed'],
      )!,
      estimatePriceNumeratorCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimate_price_numerator_cents'],
      ),
      estimateQuantityDenominator: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimate_quantity_denominator'],
      ),
      estimateSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estimate_source'],
      ),
      estimateReferenceDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estimate_reference_date'],
      ),
      estimateReferenceTripId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimate_reference_trip_id'],
      ),
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      ),
      logicalKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logical_key'],
      ),
      authorUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_uid'],
      ),
      authorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_name'],
      ),
      reviewState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_state'],
      )!,
      reviewedByUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reviewed_by_uid'],
      ),
      reviewedByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reviewed_by_name'],
      ),
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      syncRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_revision'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlannedItemsTable createAlias(String alias) {
    return $PlannedItemsTable(attachedDatabase, alias);
  }
}

class PlannedItem extends DataClass implements Insertable<PlannedItem> {
  final int id;
  final int planId;
  final int productId;
  final String measurementMode;
  final int quantity;
  final bool isRemoved;
  final int? estimatePriceNumeratorCents;
  final int? estimateQuantityDenominator;
  final String? estimateSource;
  final String? estimateReferenceDate;
  final int? estimateReferenceTripId;
  final String? syncId;
  final String? logicalKey;
  final String? authorUid;
  final String? authorName;
  final String reviewState;
  final String? reviewedByUid;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final DateTime? deletedAt;
  final int syncRevision;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PlannedItem({
    required this.id,
    required this.planId,
    required this.productId,
    required this.measurementMode,
    required this.quantity,
    required this.isRemoved,
    this.estimatePriceNumeratorCents,
    this.estimateQuantityDenominator,
    this.estimateSource,
    this.estimateReferenceDate,
    this.estimateReferenceTripId,
    this.syncId,
    this.logicalKey,
    this.authorUid,
    this.authorName,
    required this.reviewState,
    this.reviewedByUid,
    this.reviewedByName,
    this.reviewedAt,
    this.deletedAt,
    required this.syncRevision,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plan_id'] = Variable<int>(planId);
    map['product_id'] = Variable<int>(productId);
    map['measurement_mode'] = Variable<String>(measurementMode);
    map['quantity'] = Variable<int>(quantity);
    map['is_removed'] = Variable<bool>(isRemoved);
    if (!nullToAbsent || estimatePriceNumeratorCents != null) {
      map['estimate_price_numerator_cents'] = Variable<int>(
        estimatePriceNumeratorCents,
      );
    }
    if (!nullToAbsent || estimateQuantityDenominator != null) {
      map['estimate_quantity_denominator'] = Variable<int>(
        estimateQuantityDenominator,
      );
    }
    if (!nullToAbsent || estimateSource != null) {
      map['estimate_source'] = Variable<String>(estimateSource);
    }
    if (!nullToAbsent || estimateReferenceDate != null) {
      map['estimate_reference_date'] = Variable<String>(estimateReferenceDate);
    }
    if (!nullToAbsent || estimateReferenceTripId != null) {
      map['estimate_reference_trip_id'] = Variable<int>(
        estimateReferenceTripId,
      );
    }
    if (!nullToAbsent || syncId != null) {
      map['sync_id'] = Variable<String>(syncId);
    }
    if (!nullToAbsent || logicalKey != null) {
      map['logical_key'] = Variable<String>(logicalKey);
    }
    if (!nullToAbsent || authorUid != null) {
      map['author_uid'] = Variable<String>(authorUid);
    }
    if (!nullToAbsent || authorName != null) {
      map['author_name'] = Variable<String>(authorName);
    }
    map['review_state'] = Variable<String>(reviewState);
    if (!nullToAbsent || reviewedByUid != null) {
      map['reviewed_by_uid'] = Variable<String>(reviewedByUid);
    }
    if (!nullToAbsent || reviewedByName != null) {
      map['reviewed_by_name'] = Variable<String>(reviewedByName);
    }
    if (!nullToAbsent || reviewedAt != null) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['sync_revision'] = Variable<int>(syncRevision);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlannedItemsCompanion toCompanion(bool nullToAbsent) {
    return PlannedItemsCompanion(
      id: Value(id),
      planId: Value(planId),
      productId: Value(productId),
      measurementMode: Value(measurementMode),
      quantity: Value(quantity),
      isRemoved: Value(isRemoved),
      estimatePriceNumeratorCents:
          estimatePriceNumeratorCents == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatePriceNumeratorCents),
      estimateQuantityDenominator:
          estimateQuantityDenominator == null && nullToAbsent
          ? const Value.absent()
          : Value(estimateQuantityDenominator),
      estimateSource: estimateSource == null && nullToAbsent
          ? const Value.absent()
          : Value(estimateSource),
      estimateReferenceDate: estimateReferenceDate == null && nullToAbsent
          ? const Value.absent()
          : Value(estimateReferenceDate),
      estimateReferenceTripId: estimateReferenceTripId == null && nullToAbsent
          ? const Value.absent()
          : Value(estimateReferenceTripId),
      syncId: syncId == null && nullToAbsent
          ? const Value.absent()
          : Value(syncId),
      logicalKey: logicalKey == null && nullToAbsent
          ? const Value.absent()
          : Value(logicalKey),
      authorUid: authorUid == null && nullToAbsent
          ? const Value.absent()
          : Value(authorUid),
      authorName: authorName == null && nullToAbsent
          ? const Value.absent()
          : Value(authorName),
      reviewState: Value(reviewState),
      reviewedByUid: reviewedByUid == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedByUid),
      reviewedByName: reviewedByName == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedByName),
      reviewedAt: reviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      syncRevision: Value(syncRevision),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlannedItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannedItem(
      id: serializer.fromJson<int>(json['id']),
      planId: serializer.fromJson<int>(json['planId']),
      productId: serializer.fromJson<int>(json['productId']),
      measurementMode: serializer.fromJson<String>(json['measurementMode']),
      quantity: serializer.fromJson<int>(json['quantity']),
      isRemoved: serializer.fromJson<bool>(json['isRemoved']),
      estimatePriceNumeratorCents: serializer.fromJson<int?>(
        json['estimatePriceNumeratorCents'],
      ),
      estimateQuantityDenominator: serializer.fromJson<int?>(
        json['estimateQuantityDenominator'],
      ),
      estimateSource: serializer.fromJson<String?>(json['estimateSource']),
      estimateReferenceDate: serializer.fromJson<String?>(
        json['estimateReferenceDate'],
      ),
      estimateReferenceTripId: serializer.fromJson<int?>(
        json['estimateReferenceTripId'],
      ),
      syncId: serializer.fromJson<String?>(json['syncId']),
      logicalKey: serializer.fromJson<String?>(json['logicalKey']),
      authorUid: serializer.fromJson<String?>(json['authorUid']),
      authorName: serializer.fromJson<String?>(json['authorName']),
      reviewState: serializer.fromJson<String>(json['reviewState']),
      reviewedByUid: serializer.fromJson<String?>(json['reviewedByUid']),
      reviewedByName: serializer.fromJson<String?>(json['reviewedByName']),
      reviewedAt: serializer.fromJson<DateTime?>(json['reviewedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      syncRevision: serializer.fromJson<int>(json['syncRevision']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planId': serializer.toJson<int>(planId),
      'productId': serializer.toJson<int>(productId),
      'measurementMode': serializer.toJson<String>(measurementMode),
      'quantity': serializer.toJson<int>(quantity),
      'isRemoved': serializer.toJson<bool>(isRemoved),
      'estimatePriceNumeratorCents': serializer.toJson<int?>(
        estimatePriceNumeratorCents,
      ),
      'estimateQuantityDenominator': serializer.toJson<int?>(
        estimateQuantityDenominator,
      ),
      'estimateSource': serializer.toJson<String?>(estimateSource),
      'estimateReferenceDate': serializer.toJson<String?>(
        estimateReferenceDate,
      ),
      'estimateReferenceTripId': serializer.toJson<int?>(
        estimateReferenceTripId,
      ),
      'syncId': serializer.toJson<String?>(syncId),
      'logicalKey': serializer.toJson<String?>(logicalKey),
      'authorUid': serializer.toJson<String?>(authorUid),
      'authorName': serializer.toJson<String?>(authorName),
      'reviewState': serializer.toJson<String>(reviewState),
      'reviewedByUid': serializer.toJson<String?>(reviewedByUid),
      'reviewedByName': serializer.toJson<String?>(reviewedByName),
      'reviewedAt': serializer.toJson<DateTime?>(reviewedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'syncRevision': serializer.toJson<int>(syncRevision),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PlannedItem copyWith({
    int? id,
    int? planId,
    int? productId,
    String? measurementMode,
    int? quantity,
    bool? isRemoved,
    Value<int?> estimatePriceNumeratorCents = const Value.absent(),
    Value<int?> estimateQuantityDenominator = const Value.absent(),
    Value<String?> estimateSource = const Value.absent(),
    Value<String?> estimateReferenceDate = const Value.absent(),
    Value<int?> estimateReferenceTripId = const Value.absent(),
    Value<String?> syncId = const Value.absent(),
    Value<String?> logicalKey = const Value.absent(),
    Value<String?> authorUid = const Value.absent(),
    Value<String?> authorName = const Value.absent(),
    String? reviewState,
    Value<String?> reviewedByUid = const Value.absent(),
    Value<String?> reviewedByName = const Value.absent(),
    Value<DateTime?> reviewedAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
    int? syncRevision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PlannedItem(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    productId: productId ?? this.productId,
    measurementMode: measurementMode ?? this.measurementMode,
    quantity: quantity ?? this.quantity,
    isRemoved: isRemoved ?? this.isRemoved,
    estimatePriceNumeratorCents: estimatePriceNumeratorCents.present
        ? estimatePriceNumeratorCents.value
        : this.estimatePriceNumeratorCents,
    estimateQuantityDenominator: estimateQuantityDenominator.present
        ? estimateQuantityDenominator.value
        : this.estimateQuantityDenominator,
    estimateSource: estimateSource.present
        ? estimateSource.value
        : this.estimateSource,
    estimateReferenceDate: estimateReferenceDate.present
        ? estimateReferenceDate.value
        : this.estimateReferenceDate,
    estimateReferenceTripId: estimateReferenceTripId.present
        ? estimateReferenceTripId.value
        : this.estimateReferenceTripId,
    syncId: syncId.present ? syncId.value : this.syncId,
    logicalKey: logicalKey.present ? logicalKey.value : this.logicalKey,
    authorUid: authorUid.present ? authorUid.value : this.authorUid,
    authorName: authorName.present ? authorName.value : this.authorName,
    reviewState: reviewState ?? this.reviewState,
    reviewedByUid: reviewedByUid.present
        ? reviewedByUid.value
        : this.reviewedByUid,
    reviewedByName: reviewedByName.present
        ? reviewedByName.value
        : this.reviewedByName,
    reviewedAt: reviewedAt.present ? reviewedAt.value : this.reviewedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncRevision: syncRevision ?? this.syncRevision,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PlannedItem copyWithCompanion(PlannedItemsCompanion data) {
    return PlannedItem(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      productId: data.productId.present ? data.productId.value : this.productId,
      measurementMode: data.measurementMode.present
          ? data.measurementMode.value
          : this.measurementMode,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      isRemoved: data.isRemoved.present ? data.isRemoved.value : this.isRemoved,
      estimatePriceNumeratorCents: data.estimatePriceNumeratorCents.present
          ? data.estimatePriceNumeratorCents.value
          : this.estimatePriceNumeratorCents,
      estimateQuantityDenominator: data.estimateQuantityDenominator.present
          ? data.estimateQuantityDenominator.value
          : this.estimateQuantityDenominator,
      estimateSource: data.estimateSource.present
          ? data.estimateSource.value
          : this.estimateSource,
      estimateReferenceDate: data.estimateReferenceDate.present
          ? data.estimateReferenceDate.value
          : this.estimateReferenceDate,
      estimateReferenceTripId: data.estimateReferenceTripId.present
          ? data.estimateReferenceTripId.value
          : this.estimateReferenceTripId,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      logicalKey: data.logicalKey.present
          ? data.logicalKey.value
          : this.logicalKey,
      authorUid: data.authorUid.present ? data.authorUid.value : this.authorUid,
      authorName: data.authorName.present
          ? data.authorName.value
          : this.authorName,
      reviewState: data.reviewState.present
          ? data.reviewState.value
          : this.reviewState,
      reviewedByUid: data.reviewedByUid.present
          ? data.reviewedByUid.value
          : this.reviewedByUid,
      reviewedByName: data.reviewedByName.present
          ? data.reviewedByName.value
          : this.reviewedByName,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncRevision: data.syncRevision.present
          ? data.syncRevision.value
          : this.syncRevision,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannedItem(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('productId: $productId, ')
          ..write('measurementMode: $measurementMode, ')
          ..write('quantity: $quantity, ')
          ..write('isRemoved: $isRemoved, ')
          ..write('estimatePriceNumeratorCents: $estimatePriceNumeratorCents, ')
          ..write('estimateQuantityDenominator: $estimateQuantityDenominator, ')
          ..write('estimateSource: $estimateSource, ')
          ..write('estimateReferenceDate: $estimateReferenceDate, ')
          ..write('estimateReferenceTripId: $estimateReferenceTripId, ')
          ..write('syncId: $syncId, ')
          ..write('logicalKey: $logicalKey, ')
          ..write('authorUid: $authorUid, ')
          ..write('authorName: $authorName, ')
          ..write('reviewState: $reviewState, ')
          ..write('reviewedByUid: $reviewedByUid, ')
          ..write('reviewedByName: $reviewedByName, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncRevision: $syncRevision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    planId,
    productId,
    measurementMode,
    quantity,
    isRemoved,
    estimatePriceNumeratorCents,
    estimateQuantityDenominator,
    estimateSource,
    estimateReferenceDate,
    estimateReferenceTripId,
    syncId,
    logicalKey,
    authorUid,
    authorName,
    reviewState,
    reviewedByUid,
    reviewedByName,
    reviewedAt,
    deletedAt,
    syncRevision,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannedItem &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.productId == this.productId &&
          other.measurementMode == this.measurementMode &&
          other.quantity == this.quantity &&
          other.isRemoved == this.isRemoved &&
          other.estimatePriceNumeratorCents ==
              this.estimatePriceNumeratorCents &&
          other.estimateQuantityDenominator ==
              this.estimateQuantityDenominator &&
          other.estimateSource == this.estimateSource &&
          other.estimateReferenceDate == this.estimateReferenceDate &&
          other.estimateReferenceTripId == this.estimateReferenceTripId &&
          other.syncId == this.syncId &&
          other.logicalKey == this.logicalKey &&
          other.authorUid == this.authorUid &&
          other.authorName == this.authorName &&
          other.reviewState == this.reviewState &&
          other.reviewedByUid == this.reviewedByUid &&
          other.reviewedByName == this.reviewedByName &&
          other.reviewedAt == this.reviewedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncRevision == this.syncRevision &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PlannedItemsCompanion extends UpdateCompanion<PlannedItem> {
  final Value<int> id;
  final Value<int> planId;
  final Value<int> productId;
  final Value<String> measurementMode;
  final Value<int> quantity;
  final Value<bool> isRemoved;
  final Value<int?> estimatePriceNumeratorCents;
  final Value<int?> estimateQuantityDenominator;
  final Value<String?> estimateSource;
  final Value<String?> estimateReferenceDate;
  final Value<int?> estimateReferenceTripId;
  final Value<String?> syncId;
  final Value<String?> logicalKey;
  final Value<String?> authorUid;
  final Value<String?> authorName;
  final Value<String> reviewState;
  final Value<String?> reviewedByUid;
  final Value<String?> reviewedByName;
  final Value<DateTime?> reviewedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> syncRevision;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PlannedItemsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.productId = const Value.absent(),
    this.measurementMode = const Value.absent(),
    this.quantity = const Value.absent(),
    this.isRemoved = const Value.absent(),
    this.estimatePriceNumeratorCents = const Value.absent(),
    this.estimateQuantityDenominator = const Value.absent(),
    this.estimateSource = const Value.absent(),
    this.estimateReferenceDate = const Value.absent(),
    this.estimateReferenceTripId = const Value.absent(),
    this.syncId = const Value.absent(),
    this.logicalKey = const Value.absent(),
    this.authorUid = const Value.absent(),
    this.authorName = const Value.absent(),
    this.reviewState = const Value.absent(),
    this.reviewedByUid = const Value.absent(),
    this.reviewedByName = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncRevision = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PlannedItemsCompanion.insert({
    this.id = const Value.absent(),
    required int planId,
    required int productId,
    required String measurementMode,
    required int quantity,
    this.isRemoved = const Value.absent(),
    this.estimatePriceNumeratorCents = const Value.absent(),
    this.estimateQuantityDenominator = const Value.absent(),
    this.estimateSource = const Value.absent(),
    this.estimateReferenceDate = const Value.absent(),
    this.estimateReferenceTripId = const Value.absent(),
    this.syncId = const Value.absent(),
    this.logicalKey = const Value.absent(),
    this.authorUid = const Value.absent(),
    this.authorName = const Value.absent(),
    this.reviewState = const Value.absent(),
    this.reviewedByUid = const Value.absent(),
    this.reviewedByName = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncRevision = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : planId = Value(planId),
       productId = Value(productId),
       measurementMode = Value(measurementMode),
       quantity = Value(quantity);
  static Insertable<PlannedItem> custom({
    Expression<int>? id,
    Expression<int>? planId,
    Expression<int>? productId,
    Expression<String>? measurementMode,
    Expression<int>? quantity,
    Expression<bool>? isRemoved,
    Expression<int>? estimatePriceNumeratorCents,
    Expression<int>? estimateQuantityDenominator,
    Expression<String>? estimateSource,
    Expression<String>? estimateReferenceDate,
    Expression<int>? estimateReferenceTripId,
    Expression<String>? syncId,
    Expression<String>? logicalKey,
    Expression<String>? authorUid,
    Expression<String>? authorName,
    Expression<String>? reviewState,
    Expression<String>? reviewedByUid,
    Expression<String>? reviewedByName,
    Expression<DateTime>? reviewedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? syncRevision,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (productId != null) 'product_id': productId,
      if (measurementMode != null) 'measurement_mode': measurementMode,
      if (quantity != null) 'quantity': quantity,
      if (isRemoved != null) 'is_removed': isRemoved,
      if (estimatePriceNumeratorCents != null)
        'estimate_price_numerator_cents': estimatePriceNumeratorCents,
      if (estimateQuantityDenominator != null)
        'estimate_quantity_denominator': estimateQuantityDenominator,
      if (estimateSource != null) 'estimate_source': estimateSource,
      if (estimateReferenceDate != null)
        'estimate_reference_date': estimateReferenceDate,
      if (estimateReferenceTripId != null)
        'estimate_reference_trip_id': estimateReferenceTripId,
      if (syncId != null) 'sync_id': syncId,
      if (logicalKey != null) 'logical_key': logicalKey,
      if (authorUid != null) 'author_uid': authorUid,
      if (authorName != null) 'author_name': authorName,
      if (reviewState != null) 'review_state': reviewState,
      if (reviewedByUid != null) 'reviewed_by_uid': reviewedByUid,
      if (reviewedByName != null) 'reviewed_by_name': reviewedByName,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncRevision != null) 'sync_revision': syncRevision,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PlannedItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? planId,
    Value<int>? productId,
    Value<String>? measurementMode,
    Value<int>? quantity,
    Value<bool>? isRemoved,
    Value<int?>? estimatePriceNumeratorCents,
    Value<int?>? estimateQuantityDenominator,
    Value<String?>? estimateSource,
    Value<String?>? estimateReferenceDate,
    Value<int?>? estimateReferenceTripId,
    Value<String?>? syncId,
    Value<String?>? logicalKey,
    Value<String?>? authorUid,
    Value<String?>? authorName,
    Value<String>? reviewState,
    Value<String?>? reviewedByUid,
    Value<String?>? reviewedByName,
    Value<DateTime?>? reviewedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? syncRevision,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PlannedItemsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      productId: productId ?? this.productId,
      measurementMode: measurementMode ?? this.measurementMode,
      quantity: quantity ?? this.quantity,
      isRemoved: isRemoved ?? this.isRemoved,
      estimatePriceNumeratorCents:
          estimatePriceNumeratorCents ?? this.estimatePriceNumeratorCents,
      estimateQuantityDenominator:
          estimateQuantityDenominator ?? this.estimateQuantityDenominator,
      estimateSource: estimateSource ?? this.estimateSource,
      estimateReferenceDate:
          estimateReferenceDate ?? this.estimateReferenceDate,
      estimateReferenceTripId:
          estimateReferenceTripId ?? this.estimateReferenceTripId,
      syncId: syncId ?? this.syncId,
      logicalKey: logicalKey ?? this.logicalKey,
      authorUid: authorUid ?? this.authorUid,
      authorName: authorName ?? this.authorName,
      reviewState: reviewState ?? this.reviewState,
      reviewedByUid: reviewedByUid ?? this.reviewedByUid,
      reviewedByName: reviewedByName ?? this.reviewedByName,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncRevision: syncRevision ?? this.syncRevision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (measurementMode.present) {
      map['measurement_mode'] = Variable<String>(measurementMode.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (isRemoved.present) {
      map['is_removed'] = Variable<bool>(isRemoved.value);
    }
    if (estimatePriceNumeratorCents.present) {
      map['estimate_price_numerator_cents'] = Variable<int>(
        estimatePriceNumeratorCents.value,
      );
    }
    if (estimateQuantityDenominator.present) {
      map['estimate_quantity_denominator'] = Variable<int>(
        estimateQuantityDenominator.value,
      );
    }
    if (estimateSource.present) {
      map['estimate_source'] = Variable<String>(estimateSource.value);
    }
    if (estimateReferenceDate.present) {
      map['estimate_reference_date'] = Variable<String>(
        estimateReferenceDate.value,
      );
    }
    if (estimateReferenceTripId.present) {
      map['estimate_reference_trip_id'] = Variable<int>(
        estimateReferenceTripId.value,
      );
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (logicalKey.present) {
      map['logical_key'] = Variable<String>(logicalKey.value);
    }
    if (authorUid.present) {
      map['author_uid'] = Variable<String>(authorUid.value);
    }
    if (authorName.present) {
      map['author_name'] = Variable<String>(authorName.value);
    }
    if (reviewState.present) {
      map['review_state'] = Variable<String>(reviewState.value);
    }
    if (reviewedByUid.present) {
      map['reviewed_by_uid'] = Variable<String>(reviewedByUid.value);
    }
    if (reviewedByName.present) {
      map['reviewed_by_name'] = Variable<String>(reviewedByName.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (syncRevision.present) {
      map['sync_revision'] = Variable<int>(syncRevision.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannedItemsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('productId: $productId, ')
          ..write('measurementMode: $measurementMode, ')
          ..write('quantity: $quantity, ')
          ..write('isRemoved: $isRemoved, ')
          ..write('estimatePriceNumeratorCents: $estimatePriceNumeratorCents, ')
          ..write('estimateQuantityDenominator: $estimateQuantityDenominator, ')
          ..write('estimateSource: $estimateSource, ')
          ..write('estimateReferenceDate: $estimateReferenceDate, ')
          ..write('estimateReferenceTripId: $estimateReferenceTripId, ')
          ..write('syncId: $syncId, ')
          ..write('logicalKey: $logicalKey, ')
          ..write('authorUid: $authorUid, ')
          ..write('authorName: $authorName, ')
          ..write('reviewState: $reviewState, ')
          ..write('reviewedByUid: $reviewedByUid, ')
          ..write('reviewedByName: $reviewedByName, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncRevision: $syncRevision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ShoppingTripsTable extends ShoppingTrips
    with TableInfo<$ShoppingTripsTable, ShoppingTrip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingTripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<int> planId = GeneratedColumn<int>(
    'plan_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originPlanNameSnapshotMeta =
      const VerificationMeta('originPlanNameSnapshot');
  @override
  late final GeneratedColumn<String> originPlanNameSnapshot =
      GeneratedColumn<String>(
        'origin_plan_name_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<String> purchaseDate = GeneratedColumn<String>(
    'purchase_date',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _marketNameMeta = const VerificationMeta(
    'marketName',
  );
  @override
  late final GeneratedColumn<String> marketName = GeneratedColumn<String>(
    'market_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('in_progress'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    originPlanNameSnapshot,
    purchaseDate,
    marketName,
    status,
    createdAt,
    updatedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShoppingTrip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    }
    if (data.containsKey('origin_plan_name_snapshot')) {
      context.handle(
        _originPlanNameSnapshotMeta,
        originPlanNameSnapshot.isAcceptableOrUnknown(
          data['origin_plan_name_snapshot']!,
          _originPlanNameSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchaseDateMeta);
    }
    if (data.containsKey('market_name')) {
      context.handle(
        _marketNameMeta,
        marketName.isAcceptableOrUnknown(data['market_name']!, _marketNameMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingTrip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingTrip(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}plan_id'],
      ),
      originPlanNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_plan_name_snapshot'],
      ),
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_date'],
      )!,
      marketName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}market_name'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $ShoppingTripsTable createAlias(String alias) {
    return $ShoppingTripsTable(attachedDatabase, alias);
  }
}

class ShoppingTrip extends DataClass implements Insertable<ShoppingTrip> {
  final int id;
  final int? planId;
  final String? originPlanNameSnapshot;
  final String purchaseDate;
  final String? marketName;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  const ShoppingTrip({
    required this.id,
    this.planId,
    this.originPlanNameSnapshot,
    required this.purchaseDate,
    this.marketName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || planId != null) {
      map['plan_id'] = Variable<int>(planId);
    }
    if (!nullToAbsent || originPlanNameSnapshot != null) {
      map['origin_plan_name_snapshot'] = Variable<String>(
        originPlanNameSnapshot,
      );
    }
    map['purchase_date'] = Variable<String>(purchaseDate);
    if (!nullToAbsent || marketName != null) {
      map['market_name'] = Variable<String>(marketName);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  ShoppingTripsCompanion toCompanion(bool nullToAbsent) {
    return ShoppingTripsCompanion(
      id: Value(id),
      planId: planId == null && nullToAbsent
          ? const Value.absent()
          : Value(planId),
      originPlanNameSnapshot: originPlanNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(originPlanNameSnapshot),
      purchaseDate: Value(purchaseDate),
      marketName: marketName == null && nullToAbsent
          ? const Value.absent()
          : Value(marketName),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory ShoppingTrip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingTrip(
      id: serializer.fromJson<int>(json['id']),
      planId: serializer.fromJson<int?>(json['planId']),
      originPlanNameSnapshot: serializer.fromJson<String?>(
        json['originPlanNameSnapshot'],
      ),
      purchaseDate: serializer.fromJson<String>(json['purchaseDate']),
      marketName: serializer.fromJson<String?>(json['marketName']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planId': serializer.toJson<int?>(planId),
      'originPlanNameSnapshot': serializer.toJson<String?>(
        originPlanNameSnapshot,
      ),
      'purchaseDate': serializer.toJson<String>(purchaseDate),
      'marketName': serializer.toJson<String?>(marketName),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  ShoppingTrip copyWith({
    int? id,
    Value<int?> planId = const Value.absent(),
    Value<String?> originPlanNameSnapshot = const Value.absent(),
    String? purchaseDate,
    Value<String?> marketName = const Value.absent(),
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => ShoppingTrip(
    id: id ?? this.id,
    planId: planId.present ? planId.value : this.planId,
    originPlanNameSnapshot: originPlanNameSnapshot.present
        ? originPlanNameSnapshot.value
        : this.originPlanNameSnapshot,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    marketName: marketName.present ? marketName.value : this.marketName,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  ShoppingTrip copyWithCompanion(ShoppingTripsCompanion data) {
    return ShoppingTrip(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      originPlanNameSnapshot: data.originPlanNameSnapshot.present
          ? data.originPlanNameSnapshot.value
          : this.originPlanNameSnapshot,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      marketName: data.marketName.present
          ? data.marketName.value
          : this.marketName,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingTrip(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('originPlanNameSnapshot: $originPlanNameSnapshot, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('marketName: $marketName, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planId,
    originPlanNameSnapshot,
    purchaseDate,
    marketName,
    status,
    createdAt,
    updatedAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingTrip &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.originPlanNameSnapshot == this.originPlanNameSnapshot &&
          other.purchaseDate == this.purchaseDate &&
          other.marketName == this.marketName &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt);
}

class ShoppingTripsCompanion extends UpdateCompanion<ShoppingTrip> {
  final Value<int> id;
  final Value<int?> planId;
  final Value<String?> originPlanNameSnapshot;
  final Value<String> purchaseDate;
  final Value<String?> marketName;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> completedAt;
  const ShoppingTripsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.originPlanNameSnapshot = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.marketName = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  ShoppingTripsCompanion.insert({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.originPlanNameSnapshot = const Value.absent(),
    required String purchaseDate,
    this.marketName = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  }) : purchaseDate = Value(purchaseDate);
  static Insertable<ShoppingTrip> custom({
    Expression<int>? id,
    Expression<int>? planId,
    Expression<String>? originPlanNameSnapshot,
    Expression<String>? purchaseDate,
    Expression<String>? marketName,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (originPlanNameSnapshot != null)
        'origin_plan_name_snapshot': originPlanNameSnapshot,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (marketName != null) 'market_name': marketName,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  ShoppingTripsCompanion copyWith({
    Value<int>? id,
    Value<int?>? planId,
    Value<String?>? originPlanNameSnapshot,
    Value<String>? purchaseDate,
    Value<String?>? marketName,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? completedAt,
  }) {
    return ShoppingTripsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      originPlanNameSnapshot:
          originPlanNameSnapshot ?? this.originPlanNameSnapshot,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      marketName: marketName ?? this.marketName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<int>(planId.value);
    }
    if (originPlanNameSnapshot.present) {
      map['origin_plan_name_snapshot'] = Variable<String>(
        originPlanNameSnapshot.value,
      );
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<String>(purchaseDate.value);
    }
    if (marketName.present) {
      map['market_name'] = Variable<String>(marketName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingTripsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('originPlanNameSnapshot: $originPlanNameSnapshot, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('marketName: $marketName, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $PurchaseLinesTable extends PurchaseLines
    with TableInfo<$PurchaseLinesTable, PurchaseLine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchaseLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<int> tripId = GeneratedColumn<int>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedItemIdMeta = const VerificationMeta(
    'plannedItemId',
  );
  @override
  late final GeneratedColumn<int> plannedItemId = GeneratedColumn<int>(
    'planned_item_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _measurementModeMeta = const VerificationMeta(
    'measurementMode',
  );
  @override
  late final GeneratedColumn<String> measurementMode = GeneratedColumn<String>(
    'measurement_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceCentsMeta = const VerificationMeta(
    'unitPriceCents',
  );
  @override
  late final GeneratedColumn<int> unitPriceCents = GeneratedColumn<int>(
    'unit_price_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalCentsMeta = const VerificationMeta(
    'totalCents',
  );
  @override
  late final GeneratedColumn<int> totalCents = GeneratedColumn<int>(
    'total_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isLabelTotalMeta = const VerificationMeta(
    'isLabelTotal',
  );
  @override
  late final GeneratedColumn<bool> isLabelTotal = GeneratedColumn<bool>(
    'is_label_total',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_label_total" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending_price'),
  );
  static const VerificationMeta _productNameSnapshotMeta =
      const VerificationMeta('productNameSnapshot');
  @override
  late final GeneratedColumn<String> productNameSnapshot =
      GeneratedColumn<String>(
        'product_name_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _categoryNameSnapshotMeta =
      const VerificationMeta('categoryNameSnapshot');
  @override
  late final GeneratedColumn<String> categoryNameSnapshot =
      GeneratedColumn<String>(
        'category_name_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _subcategoryNameSnapshotMeta =
      const VerificationMeta('subcategoryNameSnapshot');
  @override
  late final GeneratedColumn<String> subcategoryNameSnapshot =
      GeneratedColumn<String>(
        'subcategory_name_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    productId,
    plannedItemId,
    measurementMode,
    quantity,
    unitPriceCents,
    totalCents,
    isLabelTotal,
    status,
    productNameSnapshot,
    categoryNameSnapshot,
    subcategoryNameSnapshot,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchase_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<PurchaseLine> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('planned_item_id')) {
      context.handle(
        _plannedItemIdMeta,
        plannedItemId.isAcceptableOrUnknown(
          data['planned_item_id']!,
          _plannedItemIdMeta,
        ),
      );
    }
    if (data.containsKey('measurement_mode')) {
      context.handle(
        _measurementModeMeta,
        measurementMode.isAcceptableOrUnknown(
          data['measurement_mode']!,
          _measurementModeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_measurementModeMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_price_cents')) {
      context.handle(
        _unitPriceCentsMeta,
        unitPriceCents.isAcceptableOrUnknown(
          data['unit_price_cents']!,
          _unitPriceCentsMeta,
        ),
      );
    }
    if (data.containsKey('total_cents')) {
      context.handle(
        _totalCentsMeta,
        totalCents.isAcceptableOrUnknown(data['total_cents']!, _totalCentsMeta),
      );
    }
    if (data.containsKey('is_label_total')) {
      context.handle(
        _isLabelTotalMeta,
        isLabelTotal.isAcceptableOrUnknown(
          data['is_label_total']!,
          _isLabelTotalMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('product_name_snapshot')) {
      context.handle(
        _productNameSnapshotMeta,
        productNameSnapshot.isAcceptableOrUnknown(
          data['product_name_snapshot']!,
          _productNameSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('category_name_snapshot')) {
      context.handle(
        _categoryNameSnapshotMeta,
        categoryNameSnapshot.isAcceptableOrUnknown(
          data['category_name_snapshot']!,
          _categoryNameSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('subcategory_name_snapshot')) {
      context.handle(
        _subcategoryNameSnapshotMeta,
        subcategoryNameSnapshot.isAcceptableOrUnknown(
          data['subcategory_name_snapshot']!,
          _subcategoryNameSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PurchaseLine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchaseLine(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trip_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      plannedItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_item_id'],
      ),
      measurementMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measurement_mode'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      unitPriceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price_cents'],
      ),
      totalCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_cents'],
      ),
      isLabelTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_label_total'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      productNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name_snapshot'],
      ),
      categoryNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name_snapshot'],
      ),
      subcategoryNameSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subcategory_name_snapshot'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PurchaseLinesTable createAlias(String alias) {
    return $PurchaseLinesTable(attachedDatabase, alias);
  }
}

class PurchaseLine extends DataClass implements Insertable<PurchaseLine> {
  final int id;
  final int tripId;
  final int productId;
  final int? plannedItemId;
  final String measurementMode;
  final int quantity;
  final int? unitPriceCents;
  final int? totalCents;
  final bool isLabelTotal;
  final String status;
  final String? productNameSnapshot;
  final String? categoryNameSnapshot;
  final String? subcategoryNameSnapshot;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PurchaseLine({
    required this.id,
    required this.tripId,
    required this.productId,
    this.plannedItemId,
    required this.measurementMode,
    required this.quantity,
    this.unitPriceCents,
    this.totalCents,
    required this.isLabelTotal,
    required this.status,
    this.productNameSnapshot,
    this.categoryNameSnapshot,
    this.subcategoryNameSnapshot,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trip_id'] = Variable<int>(tripId);
    map['product_id'] = Variable<int>(productId);
    if (!nullToAbsent || plannedItemId != null) {
      map['planned_item_id'] = Variable<int>(plannedItemId);
    }
    map['measurement_mode'] = Variable<String>(measurementMode);
    map['quantity'] = Variable<int>(quantity);
    if (!nullToAbsent || unitPriceCents != null) {
      map['unit_price_cents'] = Variable<int>(unitPriceCents);
    }
    if (!nullToAbsent || totalCents != null) {
      map['total_cents'] = Variable<int>(totalCents);
    }
    map['is_label_total'] = Variable<bool>(isLabelTotal);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || productNameSnapshot != null) {
      map['product_name_snapshot'] = Variable<String>(productNameSnapshot);
    }
    if (!nullToAbsent || categoryNameSnapshot != null) {
      map['category_name_snapshot'] = Variable<String>(categoryNameSnapshot);
    }
    if (!nullToAbsent || subcategoryNameSnapshot != null) {
      map['subcategory_name_snapshot'] = Variable<String>(
        subcategoryNameSnapshot,
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PurchaseLinesCompanion toCompanion(bool nullToAbsent) {
    return PurchaseLinesCompanion(
      id: Value(id),
      tripId: Value(tripId),
      productId: Value(productId),
      plannedItemId: plannedItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedItemId),
      measurementMode: Value(measurementMode),
      quantity: Value(quantity),
      unitPriceCents: unitPriceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(unitPriceCents),
      totalCents: totalCents == null && nullToAbsent
          ? const Value.absent()
          : Value(totalCents),
      isLabelTotal: Value(isLabelTotal),
      status: Value(status),
      productNameSnapshot: productNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(productNameSnapshot),
      categoryNameSnapshot: categoryNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryNameSnapshot),
      subcategoryNameSnapshot: subcategoryNameSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(subcategoryNameSnapshot),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PurchaseLine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchaseLine(
      id: serializer.fromJson<int>(json['id']),
      tripId: serializer.fromJson<int>(json['tripId']),
      productId: serializer.fromJson<int>(json['productId']),
      plannedItemId: serializer.fromJson<int?>(json['plannedItemId']),
      measurementMode: serializer.fromJson<String>(json['measurementMode']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unitPriceCents: serializer.fromJson<int?>(json['unitPriceCents']),
      totalCents: serializer.fromJson<int?>(json['totalCents']),
      isLabelTotal: serializer.fromJson<bool>(json['isLabelTotal']),
      status: serializer.fromJson<String>(json['status']),
      productNameSnapshot: serializer.fromJson<String?>(
        json['productNameSnapshot'],
      ),
      categoryNameSnapshot: serializer.fromJson<String?>(
        json['categoryNameSnapshot'],
      ),
      subcategoryNameSnapshot: serializer.fromJson<String?>(
        json['subcategoryNameSnapshot'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tripId': serializer.toJson<int>(tripId),
      'productId': serializer.toJson<int>(productId),
      'plannedItemId': serializer.toJson<int?>(plannedItemId),
      'measurementMode': serializer.toJson<String>(measurementMode),
      'quantity': serializer.toJson<int>(quantity),
      'unitPriceCents': serializer.toJson<int?>(unitPriceCents),
      'totalCents': serializer.toJson<int?>(totalCents),
      'isLabelTotal': serializer.toJson<bool>(isLabelTotal),
      'status': serializer.toJson<String>(status),
      'productNameSnapshot': serializer.toJson<String?>(productNameSnapshot),
      'categoryNameSnapshot': serializer.toJson<String?>(categoryNameSnapshot),
      'subcategoryNameSnapshot': serializer.toJson<String?>(
        subcategoryNameSnapshot,
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PurchaseLine copyWith({
    int? id,
    int? tripId,
    int? productId,
    Value<int?> plannedItemId = const Value.absent(),
    String? measurementMode,
    int? quantity,
    Value<int?> unitPriceCents = const Value.absent(),
    Value<int?> totalCents = const Value.absent(),
    bool? isLabelTotal,
    String? status,
    Value<String?> productNameSnapshot = const Value.absent(),
    Value<String?> categoryNameSnapshot = const Value.absent(),
    Value<String?> subcategoryNameSnapshot = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PurchaseLine(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    productId: productId ?? this.productId,
    plannedItemId: plannedItemId.present
        ? plannedItemId.value
        : this.plannedItemId,
    measurementMode: measurementMode ?? this.measurementMode,
    quantity: quantity ?? this.quantity,
    unitPriceCents: unitPriceCents.present
        ? unitPriceCents.value
        : this.unitPriceCents,
    totalCents: totalCents.present ? totalCents.value : this.totalCents,
    isLabelTotal: isLabelTotal ?? this.isLabelTotal,
    status: status ?? this.status,
    productNameSnapshot: productNameSnapshot.present
        ? productNameSnapshot.value
        : this.productNameSnapshot,
    categoryNameSnapshot: categoryNameSnapshot.present
        ? categoryNameSnapshot.value
        : this.categoryNameSnapshot,
    subcategoryNameSnapshot: subcategoryNameSnapshot.present
        ? subcategoryNameSnapshot.value
        : this.subcategoryNameSnapshot,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PurchaseLine copyWithCompanion(PurchaseLinesCompanion data) {
    return PurchaseLine(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      productId: data.productId.present ? data.productId.value : this.productId,
      plannedItemId: data.plannedItemId.present
          ? data.plannedItemId.value
          : this.plannedItemId,
      measurementMode: data.measurementMode.present
          ? data.measurementMode.value
          : this.measurementMode,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPriceCents: data.unitPriceCents.present
          ? data.unitPriceCents.value
          : this.unitPriceCents,
      totalCents: data.totalCents.present
          ? data.totalCents.value
          : this.totalCents,
      isLabelTotal: data.isLabelTotal.present
          ? data.isLabelTotal.value
          : this.isLabelTotal,
      status: data.status.present ? data.status.value : this.status,
      productNameSnapshot: data.productNameSnapshot.present
          ? data.productNameSnapshot.value
          : this.productNameSnapshot,
      categoryNameSnapshot: data.categoryNameSnapshot.present
          ? data.categoryNameSnapshot.value
          : this.categoryNameSnapshot,
      subcategoryNameSnapshot: data.subcategoryNameSnapshot.present
          ? data.subcategoryNameSnapshot.value
          : this.subcategoryNameSnapshot,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseLine(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('productId: $productId, ')
          ..write('plannedItemId: $plannedItemId, ')
          ..write('measurementMode: $measurementMode, ')
          ..write('quantity: $quantity, ')
          ..write('unitPriceCents: $unitPriceCents, ')
          ..write('totalCents: $totalCents, ')
          ..write('isLabelTotal: $isLabelTotal, ')
          ..write('status: $status, ')
          ..write('productNameSnapshot: $productNameSnapshot, ')
          ..write('categoryNameSnapshot: $categoryNameSnapshot, ')
          ..write('subcategoryNameSnapshot: $subcategoryNameSnapshot, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    productId,
    plannedItemId,
    measurementMode,
    quantity,
    unitPriceCents,
    totalCents,
    isLabelTotal,
    status,
    productNameSnapshot,
    categoryNameSnapshot,
    subcategoryNameSnapshot,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseLine &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.productId == this.productId &&
          other.plannedItemId == this.plannedItemId &&
          other.measurementMode == this.measurementMode &&
          other.quantity == this.quantity &&
          other.unitPriceCents == this.unitPriceCents &&
          other.totalCents == this.totalCents &&
          other.isLabelTotal == this.isLabelTotal &&
          other.status == this.status &&
          other.productNameSnapshot == this.productNameSnapshot &&
          other.categoryNameSnapshot == this.categoryNameSnapshot &&
          other.subcategoryNameSnapshot == this.subcategoryNameSnapshot &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PurchaseLinesCompanion extends UpdateCompanion<PurchaseLine> {
  final Value<int> id;
  final Value<int> tripId;
  final Value<int> productId;
  final Value<int?> plannedItemId;
  final Value<String> measurementMode;
  final Value<int> quantity;
  final Value<int?> unitPriceCents;
  final Value<int?> totalCents;
  final Value<bool> isLabelTotal;
  final Value<String> status;
  final Value<String?> productNameSnapshot;
  final Value<String?> categoryNameSnapshot;
  final Value<String?> subcategoryNameSnapshot;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PurchaseLinesCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.productId = const Value.absent(),
    this.plannedItemId = const Value.absent(),
    this.measurementMode = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPriceCents = const Value.absent(),
    this.totalCents = const Value.absent(),
    this.isLabelTotal = const Value.absent(),
    this.status = const Value.absent(),
    this.productNameSnapshot = const Value.absent(),
    this.categoryNameSnapshot = const Value.absent(),
    this.subcategoryNameSnapshot = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PurchaseLinesCompanion.insert({
    this.id = const Value.absent(),
    required int tripId,
    required int productId,
    this.plannedItemId = const Value.absent(),
    required String measurementMode,
    required int quantity,
    this.unitPriceCents = const Value.absent(),
    this.totalCents = const Value.absent(),
    this.isLabelTotal = const Value.absent(),
    this.status = const Value.absent(),
    this.productNameSnapshot = const Value.absent(),
    this.categoryNameSnapshot = const Value.absent(),
    this.subcategoryNameSnapshot = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : tripId = Value(tripId),
       productId = Value(productId),
       measurementMode = Value(measurementMode),
       quantity = Value(quantity);
  static Insertable<PurchaseLine> custom({
    Expression<int>? id,
    Expression<int>? tripId,
    Expression<int>? productId,
    Expression<int>? plannedItemId,
    Expression<String>? measurementMode,
    Expression<int>? quantity,
    Expression<int>? unitPriceCents,
    Expression<int>? totalCents,
    Expression<bool>? isLabelTotal,
    Expression<String>? status,
    Expression<String>? productNameSnapshot,
    Expression<String>? categoryNameSnapshot,
    Expression<String>? subcategoryNameSnapshot,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (productId != null) 'product_id': productId,
      if (plannedItemId != null) 'planned_item_id': plannedItemId,
      if (measurementMode != null) 'measurement_mode': measurementMode,
      if (quantity != null) 'quantity': quantity,
      if (unitPriceCents != null) 'unit_price_cents': unitPriceCents,
      if (totalCents != null) 'total_cents': totalCents,
      if (isLabelTotal != null) 'is_label_total': isLabelTotal,
      if (status != null) 'status': status,
      if (productNameSnapshot != null)
        'product_name_snapshot': productNameSnapshot,
      if (categoryNameSnapshot != null)
        'category_name_snapshot': categoryNameSnapshot,
      if (subcategoryNameSnapshot != null)
        'subcategory_name_snapshot': subcategoryNameSnapshot,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PurchaseLinesCompanion copyWith({
    Value<int>? id,
    Value<int>? tripId,
    Value<int>? productId,
    Value<int?>? plannedItemId,
    Value<String>? measurementMode,
    Value<int>? quantity,
    Value<int?>? unitPriceCents,
    Value<int?>? totalCents,
    Value<bool>? isLabelTotal,
    Value<String>? status,
    Value<String?>? productNameSnapshot,
    Value<String?>? categoryNameSnapshot,
    Value<String?>? subcategoryNameSnapshot,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PurchaseLinesCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      productId: productId ?? this.productId,
      plannedItemId: plannedItemId ?? this.plannedItemId,
      measurementMode: measurementMode ?? this.measurementMode,
      quantity: quantity ?? this.quantity,
      unitPriceCents: unitPriceCents ?? this.unitPriceCents,
      totalCents: totalCents ?? this.totalCents,
      isLabelTotal: isLabelTotal ?? this.isLabelTotal,
      status: status ?? this.status,
      productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
      categoryNameSnapshot: categoryNameSnapshot ?? this.categoryNameSnapshot,
      subcategoryNameSnapshot:
          subcategoryNameSnapshot ?? this.subcategoryNameSnapshot,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<int>(tripId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (plannedItemId.present) {
      map['planned_item_id'] = Variable<int>(plannedItemId.value);
    }
    if (measurementMode.present) {
      map['measurement_mode'] = Variable<String>(measurementMode.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unitPriceCents.present) {
      map['unit_price_cents'] = Variable<int>(unitPriceCents.value);
    }
    if (totalCents.present) {
      map['total_cents'] = Variable<int>(totalCents.value);
    }
    if (isLabelTotal.present) {
      map['is_label_total'] = Variable<bool>(isLabelTotal.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (productNameSnapshot.present) {
      map['product_name_snapshot'] = Variable<String>(
        productNameSnapshot.value,
      );
    }
    if (categoryNameSnapshot.present) {
      map['category_name_snapshot'] = Variable<String>(
        categoryNameSnapshot.value,
      );
    }
    if (subcategoryNameSnapshot.present) {
      map['subcategory_name_snapshot'] = Variable<String>(
        subcategoryNameSnapshot.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseLinesCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('productId: $productId, ')
          ..write('plannedItemId: $plannedItemId, ')
          ..write('measurementMode: $measurementMode, ')
          ..write('quantity: $quantity, ')
          ..write('unitPriceCents: $unitPriceCents, ')
          ..write('totalCents: $totalCents, ')
          ..write('isLabelTotal: $isLabelTotal, ')
          ..write('status: $status, ')
          ..write('productNameSnapshot: $productNameSnapshot, ')
          ..write('categoryNameSnapshot: $categoryNameSnapshot, ')
          ..write('subcategoryNameSnapshot: $subcategoryNameSnapshot, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AppPreferencesTable extends AppPreferences
    with TableInfo<$AppPreferencesTable, AppPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDarkModeMeta = const VerificationMeta(
    'isDarkMode',
  );
  @override
  late final GeneratedColumn<bool> isDarkMode = GeneratedColumn<bool>(
    'is_dark_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dark_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, isDarkMode];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('is_dark_mode')) {
      context.handle(
        _isDarkModeMeta,
        isDarkMode.isAcceptableOrUnknown(
          data['is_dark_mode']!,
          _isDarkModeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppPreference(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      isDarkMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dark_mode'],
      )!,
    );
  }

  @override
  $AppPreferencesTable createAlias(String alias) {
    return $AppPreferencesTable(attachedDatabase, alias);
  }
}

class AppPreference extends DataClass implements Insertable<AppPreference> {
  final int id;
  final bool isDarkMode;
  const AppPreference({required this.id, required this.isDarkMode});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['is_dark_mode'] = Variable<bool>(isDarkMode);
    return map;
  }

  AppPreferencesCompanion toCompanion(bool nullToAbsent) {
    return AppPreferencesCompanion(
      id: Value(id),
      isDarkMode: Value(isDarkMode),
    );
  }

  factory AppPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppPreference(
      id: serializer.fromJson<int>(json['id']),
      isDarkMode: serializer.fromJson<bool>(json['isDarkMode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'isDarkMode': serializer.toJson<bool>(isDarkMode),
    };
  }

  AppPreference copyWith({int? id, bool? isDarkMode}) => AppPreference(
    id: id ?? this.id,
    isDarkMode: isDarkMode ?? this.isDarkMode,
  );
  AppPreference copyWithCompanion(AppPreferencesCompanion data) {
    return AppPreference(
      id: data.id.present ? data.id.value : this.id,
      isDarkMode: data.isDarkMode.present
          ? data.isDarkMode.value
          : this.isDarkMode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppPreference(')
          ..write('id: $id, ')
          ..write('isDarkMode: $isDarkMode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, isDarkMode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppPreference &&
          other.id == this.id &&
          other.isDarkMode == this.isDarkMode);
}

class AppPreferencesCompanion extends UpdateCompanion<AppPreference> {
  final Value<int> id;
  final Value<bool> isDarkMode;
  const AppPreferencesCompanion({
    this.id = const Value.absent(),
    this.isDarkMode = const Value.absent(),
  });
  AppPreferencesCompanion.insert({
    this.id = const Value.absent(),
    this.isDarkMode = const Value.absent(),
  });
  static Insertable<AppPreference> custom({
    Expression<int>? id,
    Expression<bool>? isDarkMode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isDarkMode != null) 'is_dark_mode': isDarkMode,
    });
  }

  AppPreferencesCompanion copyWith({Value<int>? id, Value<bool>? isDarkMode}) {
    return AppPreferencesCompanion(
      id: id ?? this.id,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (isDarkMode.present) {
      map['is_dark_mode'] = Variable<bool>(isDarkMode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppPreferencesCompanion(')
          ..write('id: $id, ')
          ..write('isDarkMode: $isDarkMode')
          ..write(')'))
        .toString();
  }
}

class $CloudSyncSettingsTable extends CloudSyncSettings
    with TableInfo<$CloudSyncSettingsTable, CloudSyncSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CloudSyncSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteRevisionMeta = const VerificationMeta(
    'remoteRevision',
  );
  @override
  late final GeneratedColumn<int> remoteRevision = GeneratedColumn<int>(
    'remote_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastSyncedHashMeta = const VerificationMeta(
    'lastSyncedHash',
  );
  @override
  late final GeneratedColumn<String> lastSyncedHash = GeneratedColumn<String>(
    'last_synced_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    householdId,
    remoteRevision,
    lastSyncedHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cloud_sync_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<CloudSyncSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    }
    if (data.containsKey('remote_revision')) {
      context.handle(
        _remoteRevisionMeta,
        remoteRevision.isAcceptableOrUnknown(
          data['remote_revision']!,
          _remoteRevisionMeta,
        ),
      );
    }
    if (data.containsKey('last_synced_hash')) {
      context.handle(
        _lastSyncedHashMeta,
        lastSyncedHash.isAcceptableOrUnknown(
          data['last_synced_hash']!,
          _lastSyncedHashMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CloudSyncSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CloudSyncSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      ),
      remoteRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_revision'],
      )!,
      lastSyncedHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_synced_hash'],
      ),
    );
  }

  @override
  $CloudSyncSettingsTable createAlias(String alias) {
    return $CloudSyncSettingsTable(attachedDatabase, alias);
  }
}

class CloudSyncSetting extends DataClass
    implements Insertable<CloudSyncSetting> {
  final int id;
  final String? householdId;
  final int remoteRevision;
  final String? lastSyncedHash;
  const CloudSyncSetting({
    required this.id,
    this.householdId,
    required this.remoteRevision,
    this.lastSyncedHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || householdId != null) {
      map['household_id'] = Variable<String>(householdId);
    }
    map['remote_revision'] = Variable<int>(remoteRevision);
    if (!nullToAbsent || lastSyncedHash != null) {
      map['last_synced_hash'] = Variable<String>(lastSyncedHash);
    }
    return map;
  }

  CloudSyncSettingsCompanion toCompanion(bool nullToAbsent) {
    return CloudSyncSettingsCompanion(
      id: Value(id),
      householdId: householdId == null && nullToAbsent
          ? const Value.absent()
          : Value(householdId),
      remoteRevision: Value(remoteRevision),
      lastSyncedHash: lastSyncedHash == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedHash),
    );
  }

  factory CloudSyncSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CloudSyncSetting(
      id: serializer.fromJson<int>(json['id']),
      householdId: serializer.fromJson<String?>(json['householdId']),
      remoteRevision: serializer.fromJson<int>(json['remoteRevision']),
      lastSyncedHash: serializer.fromJson<String?>(json['lastSyncedHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'householdId': serializer.toJson<String?>(householdId),
      'remoteRevision': serializer.toJson<int>(remoteRevision),
      'lastSyncedHash': serializer.toJson<String?>(lastSyncedHash),
    };
  }

  CloudSyncSetting copyWith({
    int? id,
    Value<String?> householdId = const Value.absent(),
    int? remoteRevision,
    Value<String?> lastSyncedHash = const Value.absent(),
  }) => CloudSyncSetting(
    id: id ?? this.id,
    householdId: householdId.present ? householdId.value : this.householdId,
    remoteRevision: remoteRevision ?? this.remoteRevision,
    lastSyncedHash: lastSyncedHash.present
        ? lastSyncedHash.value
        : this.lastSyncedHash,
  );
  CloudSyncSetting copyWithCompanion(CloudSyncSettingsCompanion data) {
    return CloudSyncSetting(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      remoteRevision: data.remoteRevision.present
          ? data.remoteRevision.value
          : this.remoteRevision,
      lastSyncedHash: data.lastSyncedHash.present
          ? data.lastSyncedHash.value
          : this.lastSyncedHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CloudSyncSetting(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('remoteRevision: $remoteRevision, ')
          ..write('lastSyncedHash: $lastSyncedHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, householdId, remoteRevision, lastSyncedHash);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CloudSyncSetting &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.remoteRevision == this.remoteRevision &&
          other.lastSyncedHash == this.lastSyncedHash);
}

class CloudSyncSettingsCompanion extends UpdateCompanion<CloudSyncSetting> {
  final Value<int> id;
  final Value<String?> householdId;
  final Value<int> remoteRevision;
  final Value<String?> lastSyncedHash;
  const CloudSyncSettingsCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.remoteRevision = const Value.absent(),
    this.lastSyncedHash = const Value.absent(),
  });
  CloudSyncSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.remoteRevision = const Value.absent(),
    this.lastSyncedHash = const Value.absent(),
  });
  static Insertable<CloudSyncSetting> custom({
    Expression<int>? id,
    Expression<String>? householdId,
    Expression<int>? remoteRevision,
    Expression<String>? lastSyncedHash,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (remoteRevision != null) 'remote_revision': remoteRevision,
      if (lastSyncedHash != null) 'last_synced_hash': lastSyncedHash,
    });
  }

  CloudSyncSettingsCompanion copyWith({
    Value<int>? id,
    Value<String?>? householdId,
    Value<int>? remoteRevision,
    Value<String?>? lastSyncedHash,
  }) {
    return CloudSyncSettingsCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      remoteRevision: remoteRevision ?? this.remoteRevision,
      lastSyncedHash: lastSyncedHash ?? this.lastSyncedHash,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (remoteRevision.present) {
      map['remote_revision'] = Variable<int>(remoteRevision.value);
    }
    if (lastSyncedHash.present) {
      map['last_synced_hash'] = Variable<String>(lastSyncedHash.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CloudSyncSettingsCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('remoteRevision: $remoteRevision, ')
          ..write('lastSyncedHash: $lastSyncedHash')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $SubcategoriesTable subcategories = $SubcategoriesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $ImportBatchesTable importBatches = $ImportBatchesTable(this);
  late final $ImportEntriesTable importEntries = $ImportEntriesTable(this);
  late final $ShoppingPlansTable shoppingPlans = $ShoppingPlansTable(this);
  late final $PlannedItemsTable plannedItems = $PlannedItemsTable(this);
  late final $ShoppingTripsTable shoppingTrips = $ShoppingTripsTable(this);
  late final $PurchaseLinesTable purchaseLines = $PurchaseLinesTable(this);
  late final $AppPreferencesTable appPreferences = $AppPreferencesTable(this);
  late final $CloudSyncSettingsTable cloudSyncSettings =
      $CloudSyncSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    subcategories,
    products,
    importBatches,
    importEntries,
    shoppingPlans,
    plannedItems,
    shoppingTrips,
    purchaseLines,
    appPreferences,
    cloudSyncSettings,
  ];
}

typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String name,
  Value<int> sortOrder,
  Value<bool> isArchived,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> sortOrder,
  Value<bool> isArchived,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
          Category,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
      Category,
      PrefetchHooks Function()
    >;
typedef $$SubcategoriesTableCreateCompanionBuilder =
    SubcategoriesCompanion Function({
      Value<int> id,
      required int categoryId,
      required String name,
      Value<int> sortOrder,
      Value<bool> isArchived,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$SubcategoriesTableUpdateCompanionBuilder =
    SubcategoriesCompanion Function({
      Value<int> id,
      Value<int> categoryId,
      Value<String> name,
      Value<int> sortOrder,
      Value<bool> isArchived,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$SubcategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $SubcategoriesTable> {
  $$SubcategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubcategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SubcategoriesTable> {
  $$SubcategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubcategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubcategoriesTable> {
  $$SubcategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SubcategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubcategoriesTable,
          Subcategory,
          $$SubcategoriesTableFilterComposer,
          $$SubcategoriesTableOrderingComposer,
          $$SubcategoriesTableAnnotationComposer,
          $$SubcategoriesTableCreateCompanionBuilder,
          $$SubcategoriesTableUpdateCompanionBuilder,
          (
            Subcategory,
            BaseReferences<_$AppDatabase, $SubcategoriesTable, Subcategory>,
          ),
          Subcategory,
          PrefetchHooks Function()
        > {
  $$SubcategoriesTableTableManager(_$AppDatabase db, $SubcategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubcategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubcategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubcategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SubcategoriesCompanion(
                id: id,
                categoryId: categoryId,
                name: name,
                sortOrder: sortOrder,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int categoryId,
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SubcategoriesCompanion.insert(
                id: id,
                categoryId: categoryId,
                name: name,
                sortOrder: sortOrder,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubcategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubcategoriesTable,
      Subcategory,
      $$SubcategoriesTableFilterComposer,
      $$SubcategoriesTableOrderingComposer,
      $$SubcategoriesTableAnnotationComposer,
      $$SubcategoriesTableCreateCompanionBuilder,
      $$SubcategoriesTableUpdateCompanionBuilder,
      (
        Subcategory,
        BaseReferences<_$AppDatabase, $SubcategoriesTable, Subcategory>,
      ),
      Subcategory,
      PrefetchHooks Function()
    >;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  required String name,
  Value<int?> categoryId,
  Value<int?> subcategoryId,
  Value<String> measurementMode,
  Value<bool> needsCategoryReview,
  Value<String?> description,
  Value<bool> isArchived,
  Value<String?> syncId,
  Value<String?> logicalKey,
  Value<String?> authorUid,
  Value<String?> authorName,
  Value<String> reviewState,
  Value<String?> reviewedByUid,
  Value<String?> reviewedByName,
  Value<DateTime?> reviewedAt,
  Value<DateTime?> deletedAt,
  Value<int> syncRevision,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int?> categoryId,
  Value<int?> subcategoryId,
  Value<String> measurementMode,
  Value<bool> needsCategoryReview,
  Value<String?> description,
  Value<bool> isArchived,
  Value<String?> syncId,
  Value<String?> logicalKey,
  Value<String?> authorUid,
  Value<String?> authorName,
  Value<String> reviewState,
  Value<String?> reviewedByUid,
  Value<String?> reviewedByName,
  Value<DateTime?> reviewedAt,
  Value<DateTime?> deletedAt,
  Value<int> syncRevision,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subcategoryId => $composableBuilder(
    column: $table.subcategoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get measurementMode => $composableBuilder(
    column: $table.measurementMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsCategoryReview => $composableBuilder(
    column: $table.needsCategoryReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logicalKey => $composableBuilder(
    column: $table.logicalKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorUid => $composableBuilder(
    column: $table.authorUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewState => $composableBuilder(
    column: $table.reviewState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewedByUid => $composableBuilder(
    column: $table.reviewedByUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewedByName => $composableBuilder(
    column: $table.reviewedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subcategoryId => $composableBuilder(
    column: $table.subcategoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get measurementMode => $composableBuilder(
    column: $table.measurementMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsCategoryReview => $composableBuilder(
    column: $table.needsCategoryReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logicalKey => $composableBuilder(
    column: $table.logicalKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorUid => $composableBuilder(
    column: $table.authorUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewState => $composableBuilder(
    column: $table.reviewState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewedByUid => $composableBuilder(
    column: $table.reviewedByUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewedByName => $composableBuilder(
    column: $table.reviewedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get subcategoryId => $composableBuilder(
    column: $table.subcategoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get measurementMode => $composableBuilder(
    column: $table.measurementMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get needsCategoryReview => $composableBuilder(
    column: $table.needsCategoryReview,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<String> get logicalKey => $composableBuilder(
    column: $table.logicalKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorUid =>
      $composableBuilder(column: $table.authorUid, builder: (column) => column);

  GeneratedColumn<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewState => $composableBuilder(
    column: $table.reviewState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewedByUid => $composableBuilder(
    column: $table.reviewedByUid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewedByName => $composableBuilder(
    column: $table.reviewedByName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
          Product,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int?> subcategoryId = const Value.absent(),
                Value<String> measurementMode = const Value.absent(),
                Value<bool> needsCategoryReview = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<String?> logicalKey = const Value.absent(),
                Value<String?> authorUid = const Value.absent(),
                Value<String?> authorName = const Value.absent(),
                Value<String> reviewState = const Value.absent(),
                Value<String?> reviewedByUid = const Value.absent(),
                Value<String?> reviewedByName = const Value.absent(),
                Value<DateTime?> reviewedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncRevision = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                name: name,
                categoryId: categoryId,
                subcategoryId: subcategoryId,
                measurementMode: measurementMode,
                needsCategoryReview: needsCategoryReview,
                description: description,
                isArchived: isArchived,
                syncId: syncId,
                logicalKey: logicalKey,
                authorUid: authorUid,
                authorName: authorName,
                reviewState: reviewState,
                reviewedByUid: reviewedByUid,
                reviewedByName: reviewedByName,
                reviewedAt: reviewedAt,
                deletedAt: deletedAt,
                syncRevision: syncRevision,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int?> categoryId = const Value.absent(),
                Value<int?> subcategoryId = const Value.absent(),
                Value<String> measurementMode = const Value.absent(),
                Value<bool> needsCategoryReview = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<String?> logicalKey = const Value.absent(),
                Value<String?> authorUid = const Value.absent(),
                Value<String?> authorName = const Value.absent(),
                Value<String> reviewState = const Value.absent(),
                Value<String?> reviewedByUid = const Value.absent(),
                Value<String?> reviewedByName = const Value.absent(),
                Value<DateTime?> reviewedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncRevision = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                name: name,
                categoryId: categoryId,
                subcategoryId: subcategoryId,
                measurementMode: measurementMode,
                needsCategoryReview: needsCategoryReview,
                description: description,
                isArchived: isArchived,
                syncId: syncId,
                logicalKey: logicalKey,
                authorUid: authorUid,
                authorName: authorName,
                reviewState: reviewState,
                reviewedByUid: reviewedByUid,
                reviewedByName: reviewedByName,
                reviewedAt: reviewedAt,
                deletedAt: deletedAt,
                syncRevision: syncRevision,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
      Product,
      PrefetchHooks Function()
    >;
typedef $$ImportBatchesTableCreateCompanionBuilder =
    ImportBatchesCompanion Function({
      Value<int> id,
      required String sourceKey,
      required String sourceName,
      required int entryCount,
      Value<DateTime> importedAt,
    });
typedef $$ImportBatchesTableUpdateCompanionBuilder =
    ImportBatchesCompanion Function({
      Value<int> id,
      Value<String> sourceKey,
      Value<String> sourceName,
      Value<int> entryCount,
      Value<DateTime> importedAt,
    });

class $$ImportBatchesTableFilterComposer
    extends Composer<_$AppDatabase, $ImportBatchesTable> {
  $$ImportBatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get entryCount => $composableBuilder(
    column: $table.entryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportBatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportBatchesTable> {
  $$ImportBatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get entryCount => $composableBuilder(
    column: $table.entryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportBatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportBatchesTable> {
  $$ImportBatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceKey =>
      $composableBuilder(column: $table.sourceKey, builder: (column) => column);

  GeneratedColumn<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get entryCount => $composableBuilder(
    column: $table.entryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );
}

class $$ImportBatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportBatchesTable,
          ImportBatch,
          $$ImportBatchesTableFilterComposer,
          $$ImportBatchesTableOrderingComposer,
          $$ImportBatchesTableAnnotationComposer,
          $$ImportBatchesTableCreateCompanionBuilder,
          $$ImportBatchesTableUpdateCompanionBuilder,
          (
            ImportBatch,
            BaseReferences<_$AppDatabase, $ImportBatchesTable, ImportBatch>,
          ),
          ImportBatch,
          PrefetchHooks Function()
        > {
  $$ImportBatchesTableTableManager(_$AppDatabase db, $ImportBatchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportBatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportBatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportBatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sourceKey = const Value.absent(),
                Value<String> sourceName = const Value.absent(),
                Value<int> entryCount = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
              }) => ImportBatchesCompanion(
                id: id,
                sourceKey: sourceKey,
                sourceName: sourceName,
                entryCount: entryCount,
                importedAt: importedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sourceKey,
                required String sourceName,
                required int entryCount,
                Value<DateTime> importedAt = const Value.absent(),
              }) => ImportBatchesCompanion.insert(
                id: id,
                sourceKey: sourceKey,
                sourceName: sourceName,
                entryCount: entryCount,
                importedAt: importedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportBatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportBatchesTable,
      ImportBatch,
      $$ImportBatchesTableFilterComposer,
      $$ImportBatchesTableOrderingComposer,
      $$ImportBatchesTableAnnotationComposer,
      $$ImportBatchesTableCreateCompanionBuilder,
      $$ImportBatchesTableUpdateCompanionBuilder,
      (
        ImportBatch,
        BaseReferences<_$AppDatabase, $ImportBatchesTable, ImportBatch>,
      ),
      ImportBatch,
      PrefetchHooks Function()
    >;
typedef $$ImportEntriesTableCreateCompanionBuilder =
    ImportEntriesCompanion Function({
      Value<int> id,
      required int batchId,
      required String sourceSheet,
      required int sourceRow,
      required int sourceNumber,
      required String sourceName,
      Value<String?> suggestedCategory,
      Value<bool> needsCategoryReview,
      required String status,
      Value<int?> productId,
    });
typedef $$ImportEntriesTableUpdateCompanionBuilder =
    ImportEntriesCompanion Function({
      Value<int> id,
      Value<int> batchId,
      Value<String> sourceSheet,
      Value<int> sourceRow,
      Value<int> sourceNumber,
      Value<String> sourceName,
      Value<String?> suggestedCategory,
      Value<bool> needsCategoryReview,
      Value<String> status,
      Value<int?> productId,
    });

class $$ImportEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ImportEntriesTable> {
  $$ImportEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceSheet => $composableBuilder(
    column: $table.sourceSheet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceRow => $composableBuilder(
    column: $table.sourceRow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceNumber => $composableBuilder(
    column: $table.sourceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get suggestedCategory => $composableBuilder(
    column: $table.suggestedCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsCategoryReview => $composableBuilder(
    column: $table.needsCategoryReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportEntriesTable> {
  $$ImportEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceSheet => $composableBuilder(
    column: $table.sourceSheet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceRow => $composableBuilder(
    column: $table.sourceRow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceNumber => $composableBuilder(
    column: $table.sourceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get suggestedCategory => $composableBuilder(
    column: $table.suggestedCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsCategoryReview => $composableBuilder(
    column: $table.needsCategoryReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportEntriesTable> {
  $$ImportEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<String> get sourceSheet => $composableBuilder(
    column: $table.sourceSheet,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourceRow =>
      $composableBuilder(column: $table.sourceRow, builder: (column) => column);

  GeneratedColumn<int> get sourceNumber => $composableBuilder(
    column: $table.sourceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get suggestedCategory => $composableBuilder(
    column: $table.suggestedCategory,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get needsCategoryReview => $composableBuilder(
    column: $table.needsCategoryReview,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);
}

class $$ImportEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportEntriesTable,
          ImportEntry,
          $$ImportEntriesTableFilterComposer,
          $$ImportEntriesTableOrderingComposer,
          $$ImportEntriesTableAnnotationComposer,
          $$ImportEntriesTableCreateCompanionBuilder,
          $$ImportEntriesTableUpdateCompanionBuilder,
          (
            ImportEntry,
            BaseReferences<_$AppDatabase, $ImportEntriesTable, ImportEntry>,
          ),
          ImportEntry,
          PrefetchHooks Function()
        > {
  $$ImportEntriesTableTableManager(_$AppDatabase db, $ImportEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> batchId = const Value.absent(),
                Value<String> sourceSheet = const Value.absent(),
                Value<int> sourceRow = const Value.absent(),
                Value<int> sourceNumber = const Value.absent(),
                Value<String> sourceName = const Value.absent(),
                Value<String?> suggestedCategory = const Value.absent(),
                Value<bool> needsCategoryReview = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> productId = const Value.absent(),
              }) => ImportEntriesCompanion(
                id: id,
                batchId: batchId,
                sourceSheet: sourceSheet,
                sourceRow: sourceRow,
                sourceNumber: sourceNumber,
                sourceName: sourceName,
                suggestedCategory: suggestedCategory,
                needsCategoryReview: needsCategoryReview,
                status: status,
                productId: productId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int batchId,
                required String sourceSheet,
                required int sourceRow,
                required int sourceNumber,
                required String sourceName,
                Value<String?> suggestedCategory = const Value.absent(),
                Value<bool> needsCategoryReview = const Value.absent(),
                required String status,
                Value<int?> productId = const Value.absent(),
              }) => ImportEntriesCompanion.insert(
                id: id,
                batchId: batchId,
                sourceSheet: sourceSheet,
                sourceRow: sourceRow,
                sourceNumber: sourceNumber,
                sourceName: sourceName,
                suggestedCategory: suggestedCategory,
                needsCategoryReview: needsCategoryReview,
                status: status,
                productId: productId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ImportEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportEntriesTable,
      ImportEntry,
      $$ImportEntriesTableFilterComposer,
      $$ImportEntriesTableOrderingComposer,
      $$ImportEntriesTableAnnotationComposer,
      $$ImportEntriesTableCreateCompanionBuilder,
      $$ImportEntriesTableUpdateCompanionBuilder,
      (
        ImportEntry,
        BaseReferences<_$AppDatabase, $ImportEntriesTable, ImportEntry>,
      ),
      ImportEntry,
      PrefetchHooks Function()
    >;
typedef $$ShoppingPlansTableCreateCompanionBuilder =
    ShoppingPlansCompanion Function({
      Value<int> id,
      required String monthKey,
      required String name,
      Value<String> status,
      Value<String?> syncId,
      Value<String?> logicalKey,
      Value<String?> authorUid,
      Value<String?> authorName,
      Value<String> reviewState,
      Value<String?> reviewedByUid,
      Value<String?> reviewedByName,
      Value<DateTime?> reviewedAt,
      Value<DateTime?> deletedAt,
      Value<int> syncRevision,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$ShoppingPlansTableUpdateCompanionBuilder =
    ShoppingPlansCompanion Function({
      Value<int> id,
      Value<String> monthKey,
      Value<String> name,
      Value<String> status,
      Value<String?> syncId,
      Value<String?> logicalKey,
      Value<String?> authorUid,
      Value<String?> authorName,
      Value<String> reviewState,
      Value<String?> reviewedByUid,
      Value<String?> reviewedByName,
      Value<DateTime?> reviewedAt,
      Value<DateTime?> deletedAt,
      Value<int> syncRevision,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$ShoppingPlansTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingPlansTable> {
  $$ShoppingPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logicalKey => $composableBuilder(
    column: $table.logicalKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorUid => $composableBuilder(
    column: $table.authorUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewState => $composableBuilder(
    column: $table.reviewState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewedByUid => $composableBuilder(
    column: $table.reviewedByUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewedByName => $composableBuilder(
    column: $table.reviewedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShoppingPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingPlansTable> {
  $$ShoppingPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get monthKey => $composableBuilder(
    column: $table.monthKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logicalKey => $composableBuilder(
    column: $table.logicalKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorUid => $composableBuilder(
    column: $table.authorUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewState => $composableBuilder(
    column: $table.reviewState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewedByUid => $composableBuilder(
    column: $table.reviewedByUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewedByName => $composableBuilder(
    column: $table.reviewedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShoppingPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingPlansTable> {
  $$ShoppingPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get monthKey =>
      $composableBuilder(column: $table.monthKey, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<String> get logicalKey => $composableBuilder(
    column: $table.logicalKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorUid =>
      $composableBuilder(column: $table.authorUid, builder: (column) => column);

  GeneratedColumn<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewState => $composableBuilder(
    column: $table.reviewState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewedByUid => $composableBuilder(
    column: $table.reviewedByUid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewedByName => $composableBuilder(
    column: $table.reviewedByName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ShoppingPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoppingPlansTable,
          ShoppingPlan,
          $$ShoppingPlansTableFilterComposer,
          $$ShoppingPlansTableOrderingComposer,
          $$ShoppingPlansTableAnnotationComposer,
          $$ShoppingPlansTableCreateCompanionBuilder,
          $$ShoppingPlansTableUpdateCompanionBuilder,
          (
            ShoppingPlan,
            BaseReferences<_$AppDatabase, $ShoppingPlansTable, ShoppingPlan>,
          ),
          ShoppingPlan,
          PrefetchHooks Function()
        > {
  $$ShoppingPlansTableTableManager(_$AppDatabase db, $ShoppingPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> monthKey = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<String?> logicalKey = const Value.absent(),
                Value<String?> authorUid = const Value.absent(),
                Value<String?> authorName = const Value.absent(),
                Value<String> reviewState = const Value.absent(),
                Value<String?> reviewedByUid = const Value.absent(),
                Value<String?> reviewedByName = const Value.absent(),
                Value<DateTime?> reviewedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncRevision = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ShoppingPlansCompanion(
                id: id,
                monthKey: monthKey,
                name: name,
                status: status,
                syncId: syncId,
                logicalKey: logicalKey,
                authorUid: authorUid,
                authorName: authorName,
                reviewState: reviewState,
                reviewedByUid: reviewedByUid,
                reviewedByName: reviewedByName,
                reviewedAt: reviewedAt,
                deletedAt: deletedAt,
                syncRevision: syncRevision,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String monthKey,
                required String name,
                Value<String> status = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<String?> logicalKey = const Value.absent(),
                Value<String?> authorUid = const Value.absent(),
                Value<String?> authorName = const Value.absent(),
                Value<String> reviewState = const Value.absent(),
                Value<String?> reviewedByUid = const Value.absent(),
                Value<String?> reviewedByName = const Value.absent(),
                Value<DateTime?> reviewedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncRevision = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ShoppingPlansCompanion.insert(
                id: id,
                monthKey: monthKey,
                name: name,
                status: status,
                syncId: syncId,
                logicalKey: logicalKey,
                authorUid: authorUid,
                authorName: authorName,
                reviewState: reviewState,
                reviewedByUid: reviewedByUid,
                reviewedByName: reviewedByName,
                reviewedAt: reviewedAt,
                deletedAt: deletedAt,
                syncRevision: syncRevision,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShoppingPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoppingPlansTable,
      ShoppingPlan,
      $$ShoppingPlansTableFilterComposer,
      $$ShoppingPlansTableOrderingComposer,
      $$ShoppingPlansTableAnnotationComposer,
      $$ShoppingPlansTableCreateCompanionBuilder,
      $$ShoppingPlansTableUpdateCompanionBuilder,
      (
        ShoppingPlan,
        BaseReferences<_$AppDatabase, $ShoppingPlansTable, ShoppingPlan>,
      ),
      ShoppingPlan,
      PrefetchHooks Function()
    >;
typedef $$PlannedItemsTableCreateCompanionBuilder =
    PlannedItemsCompanion Function({
      Value<int> id,
      required int planId,
      required int productId,
      required String measurementMode,
      required int quantity,
      Value<bool> isRemoved,
      Value<int?> estimatePriceNumeratorCents,
      Value<int?> estimateQuantityDenominator,
      Value<String?> estimateSource,
      Value<String?> estimateReferenceDate,
      Value<int?> estimateReferenceTripId,
      Value<String?> syncId,
      Value<String?> logicalKey,
      Value<String?> authorUid,
      Value<String?> authorName,
      Value<String> reviewState,
      Value<String?> reviewedByUid,
      Value<String?> reviewedByName,
      Value<DateTime?> reviewedAt,
      Value<DateTime?> deletedAt,
      Value<int> syncRevision,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$PlannedItemsTableUpdateCompanionBuilder =
    PlannedItemsCompanion Function({
      Value<int> id,
      Value<int> planId,
      Value<int> productId,
      Value<String> measurementMode,
      Value<int> quantity,
      Value<bool> isRemoved,
      Value<int?> estimatePriceNumeratorCents,
      Value<int?> estimateQuantityDenominator,
      Value<String?> estimateSource,
      Value<String?> estimateReferenceDate,
      Value<int?> estimateReferenceTripId,
      Value<String?> syncId,
      Value<String?> logicalKey,
      Value<String?> authorUid,
      Value<String?> authorName,
      Value<String> reviewState,
      Value<String?> reviewedByUid,
      Value<String?> reviewedByName,
      Value<DateTime?> reviewedAt,
      Value<DateTime?> deletedAt,
      Value<int> syncRevision,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$PlannedItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PlannedItemsTable> {
  $$PlannedItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get measurementMode => $composableBuilder(
    column: $table.measurementMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRemoved => $composableBuilder(
    column: $table.isRemoved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimatePriceNumeratorCents => $composableBuilder(
    column: $table.estimatePriceNumeratorCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimateQuantityDenominator => $composableBuilder(
    column: $table.estimateQuantityDenominator,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estimateSource => $composableBuilder(
    column: $table.estimateSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estimateReferenceDate => $composableBuilder(
    column: $table.estimateReferenceDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimateReferenceTripId => $composableBuilder(
    column: $table.estimateReferenceTripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logicalKey => $composableBuilder(
    column: $table.logicalKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorUid => $composableBuilder(
    column: $table.authorUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewState => $composableBuilder(
    column: $table.reviewState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewedByUid => $composableBuilder(
    column: $table.reviewedByUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewedByName => $composableBuilder(
    column: $table.reviewedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlannedItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlannedItemsTable> {
  $$PlannedItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get measurementMode => $composableBuilder(
    column: $table.measurementMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRemoved => $composableBuilder(
    column: $table.isRemoved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatePriceNumeratorCents => $composableBuilder(
    column: $table.estimatePriceNumeratorCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimateQuantityDenominator => $composableBuilder(
    column: $table.estimateQuantityDenominator,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estimateSource => $composableBuilder(
    column: $table.estimateSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estimateReferenceDate => $composableBuilder(
    column: $table.estimateReferenceDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimateReferenceTripId => $composableBuilder(
    column: $table.estimateReferenceTripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logicalKey => $composableBuilder(
    column: $table.logicalKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorUid => $composableBuilder(
    column: $table.authorUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewState => $composableBuilder(
    column: $table.reviewState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewedByUid => $composableBuilder(
    column: $table.reviewedByUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewedByName => $composableBuilder(
    column: $table.reviewedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlannedItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlannedItemsTable> {
  $$PlannedItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<int> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get measurementMode => $composableBuilder(
    column: $table.measurementMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<bool> get isRemoved =>
      $composableBuilder(column: $table.isRemoved, builder: (column) => column);

  GeneratedColumn<int> get estimatePriceNumeratorCents => $composableBuilder(
    column: $table.estimatePriceNumeratorCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get estimateQuantityDenominator => $composableBuilder(
    column: $table.estimateQuantityDenominator,
    builder: (column) => column,
  );

  GeneratedColumn<String> get estimateSource => $composableBuilder(
    column: $table.estimateSource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get estimateReferenceDate => $composableBuilder(
    column: $table.estimateReferenceDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get estimateReferenceTripId => $composableBuilder(
    column: $table.estimateReferenceTripId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<String> get logicalKey => $composableBuilder(
    column: $table.logicalKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorUid =>
      $composableBuilder(column: $table.authorUid, builder: (column) => column);

  GeneratedColumn<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewState => $composableBuilder(
    column: $table.reviewState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewedByUid => $composableBuilder(
    column: $table.reviewedByUid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewedByName => $composableBuilder(
    column: $table.reviewedByName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncRevision => $composableBuilder(
    column: $table.syncRevision,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PlannedItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlannedItemsTable,
          PlannedItem,
          $$PlannedItemsTableFilterComposer,
          $$PlannedItemsTableOrderingComposer,
          $$PlannedItemsTableAnnotationComposer,
          $$PlannedItemsTableCreateCompanionBuilder,
          $$PlannedItemsTableUpdateCompanionBuilder,
          (
            PlannedItem,
            BaseReferences<_$AppDatabase, $PlannedItemsTable, PlannedItem>,
          ),
          PlannedItem,
          PrefetchHooks Function()
        > {
  $$PlannedItemsTableTableManager(_$AppDatabase db, $PlannedItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlannedItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlannedItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlannedItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> planId = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<String> measurementMode = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<bool> isRemoved = const Value.absent(),
                Value<int?> estimatePriceNumeratorCents = const Value.absent(),
                Value<int?> estimateQuantityDenominator = const Value.absent(),
                Value<String?> estimateSource = const Value.absent(),
                Value<String?> estimateReferenceDate = const Value.absent(),
                Value<int?> estimateReferenceTripId = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<String?> logicalKey = const Value.absent(),
                Value<String?> authorUid = const Value.absent(),
                Value<String?> authorName = const Value.absent(),
                Value<String> reviewState = const Value.absent(),
                Value<String?> reviewedByUid = const Value.absent(),
                Value<String?> reviewedByName = const Value.absent(),
                Value<DateTime?> reviewedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncRevision = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PlannedItemsCompanion(
                id: id,
                planId: planId,
                productId: productId,
                measurementMode: measurementMode,
                quantity: quantity,
                isRemoved: isRemoved,
                estimatePriceNumeratorCents: estimatePriceNumeratorCents,
                estimateQuantityDenominator: estimateQuantityDenominator,
                estimateSource: estimateSource,
                estimateReferenceDate: estimateReferenceDate,
                estimateReferenceTripId: estimateReferenceTripId,
                syncId: syncId,
                logicalKey: logicalKey,
                authorUid: authorUid,
                authorName: authorName,
                reviewState: reviewState,
                reviewedByUid: reviewedByUid,
                reviewedByName: reviewedByName,
                reviewedAt: reviewedAt,
                deletedAt: deletedAt,
                syncRevision: syncRevision,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int planId,
                required int productId,
                required String measurementMode,
                required int quantity,
                Value<bool> isRemoved = const Value.absent(),
                Value<int?> estimatePriceNumeratorCents = const Value.absent(),
                Value<int?> estimateQuantityDenominator = const Value.absent(),
                Value<String?> estimateSource = const Value.absent(),
                Value<String?> estimateReferenceDate = const Value.absent(),
                Value<int?> estimateReferenceTripId = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<String?> logicalKey = const Value.absent(),
                Value<String?> authorUid = const Value.absent(),
                Value<String?> authorName = const Value.absent(),
                Value<String> reviewState = const Value.absent(),
                Value<String?> reviewedByUid = const Value.absent(),
                Value<String?> reviewedByName = const Value.absent(),
                Value<DateTime?> reviewedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> syncRevision = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PlannedItemsCompanion.insert(
                id: id,
                planId: planId,
                productId: productId,
                measurementMode: measurementMode,
                quantity: quantity,
                isRemoved: isRemoved,
                estimatePriceNumeratorCents: estimatePriceNumeratorCents,
                estimateQuantityDenominator: estimateQuantityDenominator,
                estimateSource: estimateSource,
                estimateReferenceDate: estimateReferenceDate,
                estimateReferenceTripId: estimateReferenceTripId,
                syncId: syncId,
                logicalKey: logicalKey,
                authorUid: authorUid,
                authorName: authorName,
                reviewState: reviewState,
                reviewedByUid: reviewedByUid,
                reviewedByName: reviewedByName,
                reviewedAt: reviewedAt,
                deletedAt: deletedAt,
                syncRevision: syncRevision,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlannedItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlannedItemsTable,
      PlannedItem,
      $$PlannedItemsTableFilterComposer,
      $$PlannedItemsTableOrderingComposer,
      $$PlannedItemsTableAnnotationComposer,
      $$PlannedItemsTableCreateCompanionBuilder,
      $$PlannedItemsTableUpdateCompanionBuilder,
      (
        PlannedItem,
        BaseReferences<_$AppDatabase, $PlannedItemsTable, PlannedItem>,
      ),
      PlannedItem,
      PrefetchHooks Function()
    >;
typedef $$ShoppingTripsTableCreateCompanionBuilder =
    ShoppingTripsCompanion Function({
      Value<int> id,
      Value<int?> planId,
      Value<String?> originPlanNameSnapshot,
      required String purchaseDate,
      Value<String?> marketName,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> completedAt,
    });
typedef $$ShoppingTripsTableUpdateCompanionBuilder =
    ShoppingTripsCompanion Function({
      Value<int> id,
      Value<int?> planId,
      Value<String?> originPlanNameSnapshot,
      Value<String> purchaseDate,
      Value<String?> marketName,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> completedAt,
    });

class $$ShoppingTripsTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingTripsTable> {
  $$ShoppingTripsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originPlanNameSnapshot => $composableBuilder(
    column: $table.originPlanNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get marketName => $composableBuilder(
    column: $table.marketName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShoppingTripsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingTripsTable> {
  $$ShoppingTripsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get planId => $composableBuilder(
    column: $table.planId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originPlanNameSnapshot => $composableBuilder(
    column: $table.originPlanNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get marketName => $composableBuilder(
    column: $table.marketName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShoppingTripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingTripsTable> {
  $$ShoppingTripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get originPlanNameSnapshot => $composableBuilder(
    column: $table.originPlanNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get marketName => $composableBuilder(
    column: $table.marketName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$ShoppingTripsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoppingTripsTable,
          ShoppingTrip,
          $$ShoppingTripsTableFilterComposer,
          $$ShoppingTripsTableOrderingComposer,
          $$ShoppingTripsTableAnnotationComposer,
          $$ShoppingTripsTableCreateCompanionBuilder,
          $$ShoppingTripsTableUpdateCompanionBuilder,
          (
            ShoppingTrip,
            BaseReferences<_$AppDatabase, $ShoppingTripsTable, ShoppingTrip>,
          ),
          ShoppingTrip,
          PrefetchHooks Function()
        > {
  $$ShoppingTripsTableTableManager(_$AppDatabase db, $ShoppingTripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingTripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingTripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingTripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> planId = const Value.absent(),
                Value<String?> originPlanNameSnapshot = const Value.absent(),
                Value<String> purchaseDate = const Value.absent(),
                Value<String?> marketName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
              }) => ShoppingTripsCompanion(
                id: id,
                planId: planId,
                originPlanNameSnapshot: originPlanNameSnapshot,
                purchaseDate: purchaseDate,
                marketName: marketName,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> planId = const Value.absent(),
                Value<String?> originPlanNameSnapshot = const Value.absent(),
                required String purchaseDate,
                Value<String?> marketName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
              }) => ShoppingTripsCompanion.insert(
                id: id,
                planId: planId,
                originPlanNameSnapshot: originPlanNameSnapshot,
                purchaseDate: purchaseDate,
                marketName: marketName,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShoppingTripsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoppingTripsTable,
      ShoppingTrip,
      $$ShoppingTripsTableFilterComposer,
      $$ShoppingTripsTableOrderingComposer,
      $$ShoppingTripsTableAnnotationComposer,
      $$ShoppingTripsTableCreateCompanionBuilder,
      $$ShoppingTripsTableUpdateCompanionBuilder,
      (
        ShoppingTrip,
        BaseReferences<_$AppDatabase, $ShoppingTripsTable, ShoppingTrip>,
      ),
      ShoppingTrip,
      PrefetchHooks Function()
    >;
typedef $$PurchaseLinesTableCreateCompanionBuilder =
    PurchaseLinesCompanion Function({
      Value<int> id,
      required int tripId,
      required int productId,
      Value<int?> plannedItemId,
      required String measurementMode,
      required int quantity,
      Value<int?> unitPriceCents,
      Value<int?> totalCents,
      Value<bool> isLabelTotal,
      Value<String> status,
      Value<String?> productNameSnapshot,
      Value<String?> categoryNameSnapshot,
      Value<String?> subcategoryNameSnapshot,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$PurchaseLinesTableUpdateCompanionBuilder =
    PurchaseLinesCompanion Function({
      Value<int> id,
      Value<int> tripId,
      Value<int> productId,
      Value<int?> plannedItemId,
      Value<String> measurementMode,
      Value<int> quantity,
      Value<int?> unitPriceCents,
      Value<int?> totalCents,
      Value<bool> isLabelTotal,
      Value<String> status,
      Value<String?> productNameSnapshot,
      Value<String?> categoryNameSnapshot,
      Value<String?> subcategoryNameSnapshot,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$PurchaseLinesTableFilterComposer
    extends Composer<_$AppDatabase, $PurchaseLinesTable> {
  $$PurchaseLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedItemId => $composableBuilder(
    column: $table.plannedItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get measurementMode => $composableBuilder(
    column: $table.measurementMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPriceCents => $composableBuilder(
    column: $table.unitPriceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCents => $composableBuilder(
    column: $table.totalCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLabelTotal => $composableBuilder(
    column: $table.isLabelTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryNameSnapshot => $composableBuilder(
    column: $table.categoryNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subcategoryNameSnapshot => $composableBuilder(
    column: $table.subcategoryNameSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PurchaseLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchaseLinesTable> {
  $$PurchaseLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedItemId => $composableBuilder(
    column: $table.plannedItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get measurementMode => $composableBuilder(
    column: $table.measurementMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPriceCents => $composableBuilder(
    column: $table.unitPriceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCents => $composableBuilder(
    column: $table.totalCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLabelTotal => $composableBuilder(
    column: $table.isLabelTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryNameSnapshot => $composableBuilder(
    column: $table.categoryNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subcategoryNameSnapshot => $composableBuilder(
    column: $table.subcategoryNameSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PurchaseLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchaseLinesTable> {
  $$PurchaseLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<int> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<int> get plannedItemId => $composableBuilder(
    column: $table.plannedItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get measurementMode => $composableBuilder(
    column: $table.measurementMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get unitPriceCents => $composableBuilder(
    column: $table.unitPriceCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalCents => $composableBuilder(
    column: $table.totalCents,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isLabelTotal => $composableBuilder(
    column: $table.isLabelTotal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get productNameSnapshot => $composableBuilder(
    column: $table.productNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryNameSnapshot => $composableBuilder(
    column: $table.categoryNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subcategoryNameSnapshot => $composableBuilder(
    column: $table.subcategoryNameSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PurchaseLinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PurchaseLinesTable,
          PurchaseLine,
          $$PurchaseLinesTableFilterComposer,
          $$PurchaseLinesTableOrderingComposer,
          $$PurchaseLinesTableAnnotationComposer,
          $$PurchaseLinesTableCreateCompanionBuilder,
          $$PurchaseLinesTableUpdateCompanionBuilder,
          (
            PurchaseLine,
            BaseReferences<_$AppDatabase, $PurchaseLinesTable, PurchaseLine>,
          ),
          PurchaseLine,
          PrefetchHooks Function()
        > {
  $$PurchaseLinesTableTableManager(_$AppDatabase db, $PurchaseLinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchaseLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PurchaseLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PurchaseLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> tripId = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<int?> plannedItemId = const Value.absent(),
                Value<String> measurementMode = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int?> unitPriceCents = const Value.absent(),
                Value<int?> totalCents = const Value.absent(),
                Value<bool> isLabelTotal = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> productNameSnapshot = const Value.absent(),
                Value<String?> categoryNameSnapshot = const Value.absent(),
                Value<String?> subcategoryNameSnapshot = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PurchaseLinesCompanion(
                id: id,
                tripId: tripId,
                productId: productId,
                plannedItemId: plannedItemId,
                measurementMode: measurementMode,
                quantity: quantity,
                unitPriceCents: unitPriceCents,
                totalCents: totalCents,
                isLabelTotal: isLabelTotal,
                status: status,
                productNameSnapshot: productNameSnapshot,
                categoryNameSnapshot: categoryNameSnapshot,
                subcategoryNameSnapshot: subcategoryNameSnapshot,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int tripId,
                required int productId,
                Value<int?> plannedItemId = const Value.absent(),
                required String measurementMode,
                required int quantity,
                Value<int?> unitPriceCents = const Value.absent(),
                Value<int?> totalCents = const Value.absent(),
                Value<bool> isLabelTotal = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> productNameSnapshot = const Value.absent(),
                Value<String?> categoryNameSnapshot = const Value.absent(),
                Value<String?> subcategoryNameSnapshot = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PurchaseLinesCompanion.insert(
                id: id,
                tripId: tripId,
                productId: productId,
                plannedItemId: plannedItemId,
                measurementMode: measurementMode,
                quantity: quantity,
                unitPriceCents: unitPriceCents,
                totalCents: totalCents,
                isLabelTotal: isLabelTotal,
                status: status,
                productNameSnapshot: productNameSnapshot,
                categoryNameSnapshot: categoryNameSnapshot,
                subcategoryNameSnapshot: subcategoryNameSnapshot,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PurchaseLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PurchaseLinesTable,
      PurchaseLine,
      $$PurchaseLinesTableFilterComposer,
      $$PurchaseLinesTableOrderingComposer,
      $$PurchaseLinesTableAnnotationComposer,
      $$PurchaseLinesTableCreateCompanionBuilder,
      $$PurchaseLinesTableUpdateCompanionBuilder,
      (
        PurchaseLine,
        BaseReferences<_$AppDatabase, $PurchaseLinesTable, PurchaseLine>,
      ),
      PurchaseLine,
      PrefetchHooks Function()
    >;
typedef $$AppPreferencesTableCreateCompanionBuilder =
    AppPreferencesCompanion Function({Value<int> id, Value<bool> isDarkMode});
typedef $$AppPreferencesTableUpdateCompanionBuilder =
    AppPreferencesCompanion Function({Value<int> id, Value<bool> isDarkMode});

class $$AppPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDarkMode => $composableBuilder(
    column: $table.isDarkMode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDarkMode => $composableBuilder(
    column: $table.isDarkMode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppPreferencesTable> {
  $$AppPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isDarkMode => $composableBuilder(
    column: $table.isDarkMode,
    builder: (column) => column,
  );
}

class $$AppPreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppPreferencesTable,
          AppPreference,
          $$AppPreferencesTableFilterComposer,
          $$AppPreferencesTableOrderingComposer,
          $$AppPreferencesTableAnnotationComposer,
          $$AppPreferencesTableCreateCompanionBuilder,
          $$AppPreferencesTableUpdateCompanionBuilder,
          (
            AppPreference,
            BaseReferences<_$AppDatabase, $AppPreferencesTable, AppPreference>,
          ),
          AppPreference,
          PrefetchHooks Function()
        > {
  $$AppPreferencesTableTableManager(
    _$AppDatabase db,
    $AppPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppPreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppPreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<bool> isDarkMode = const Value.absent(),
          }) => AppPreferencesCompanion(id: id, isDarkMode: isDarkMode),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<bool> isDarkMode = const Value.absent(),
          }) => AppPreferencesCompanion.insert(id: id, isDarkMode: isDarkMode),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppPreferencesTable,
      AppPreference,
      $$AppPreferencesTableFilterComposer,
      $$AppPreferencesTableOrderingComposer,
      $$AppPreferencesTableAnnotationComposer,
      $$AppPreferencesTableCreateCompanionBuilder,
      $$AppPreferencesTableUpdateCompanionBuilder,
      (
        AppPreference,
        BaseReferences<_$AppDatabase, $AppPreferencesTable, AppPreference>,
      ),
      AppPreference,
      PrefetchHooks Function()
    >;
typedef $$CloudSyncSettingsTableCreateCompanionBuilder =
    CloudSyncSettingsCompanion Function({
      Value<int> id,
      Value<String?> householdId,
      Value<int> remoteRevision,
      Value<String?> lastSyncedHash,
    });
typedef $$CloudSyncSettingsTableUpdateCompanionBuilder =
    CloudSyncSettingsCompanion Function({
      Value<int> id,
      Value<String?> householdId,
      Value<int> remoteRevision,
      Value<String?> lastSyncedHash,
    });

class $$CloudSyncSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $CloudSyncSettingsTable> {
  $$CloudSyncSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncedHash => $composableBuilder(
    column: $table.lastSyncedHash,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CloudSyncSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $CloudSyncSettingsTable> {
  $$CloudSyncSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncedHash => $composableBuilder(
    column: $table.lastSyncedHash,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CloudSyncSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CloudSyncSettingsTable> {
  $$CloudSyncSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncedHash => $composableBuilder(
    column: $table.lastSyncedHash,
    builder: (column) => column,
  );
}

class $$CloudSyncSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CloudSyncSettingsTable,
          CloudSyncSetting,
          $$CloudSyncSettingsTableFilterComposer,
          $$CloudSyncSettingsTableOrderingComposer,
          $$CloudSyncSettingsTableAnnotationComposer,
          $$CloudSyncSettingsTableCreateCompanionBuilder,
          $$CloudSyncSettingsTableUpdateCompanionBuilder,
          (
            CloudSyncSetting,
            BaseReferences<
              _$AppDatabase,
              $CloudSyncSettingsTable,
              CloudSyncSetting
            >,
          ),
          CloudSyncSetting,
          PrefetchHooks Function()
        > {
  $$CloudSyncSettingsTableTableManager(
    _$AppDatabase db,
    $CloudSyncSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CloudSyncSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CloudSyncSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CloudSyncSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> householdId = const Value.absent(),
                Value<int> remoteRevision = const Value.absent(),
                Value<String?> lastSyncedHash = const Value.absent(),
              }) => CloudSyncSettingsCompanion(
                id: id,
                householdId: householdId,
                remoteRevision: remoteRevision,
                lastSyncedHash: lastSyncedHash,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> householdId = const Value.absent(),
                Value<int> remoteRevision = const Value.absent(),
                Value<String?> lastSyncedHash = const Value.absent(),
              }) => CloudSyncSettingsCompanion.insert(
                id: id,
                householdId: householdId,
                remoteRevision: remoteRevision,
                lastSyncedHash: lastSyncedHash,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CloudSyncSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CloudSyncSettingsTable,
      CloudSyncSetting,
      $$CloudSyncSettingsTableFilterComposer,
      $$CloudSyncSettingsTableOrderingComposer,
      $$CloudSyncSettingsTableAnnotationComposer,
      $$CloudSyncSettingsTableCreateCompanionBuilder,
      $$CloudSyncSettingsTableUpdateCompanionBuilder,
      (
        CloudSyncSetting,
        BaseReferences<
          _$AppDatabase,
          $CloudSyncSettingsTable,
          CloudSyncSetting
        >,
      ),
      CloudSyncSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$SubcategoriesTableTableManager get subcategories =>
      $$SubcategoriesTableTableManager(_db, _db.subcategories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$ImportBatchesTableTableManager get importBatches =>
      $$ImportBatchesTableTableManager(_db, _db.importBatches);
  $$ImportEntriesTableTableManager get importEntries =>
      $$ImportEntriesTableTableManager(_db, _db.importEntries);
  $$ShoppingPlansTableTableManager get shoppingPlans =>
      $$ShoppingPlansTableTableManager(_db, _db.shoppingPlans);
  $$PlannedItemsTableTableManager get plannedItems =>
      $$PlannedItemsTableTableManager(_db, _db.plannedItems);
  $$ShoppingTripsTableTableManager get shoppingTrips =>
      $$ShoppingTripsTableTableManager(_db, _db.shoppingTrips);
  $$PurchaseLinesTableTableManager get purchaseLines =>
      $$PurchaseLinesTableTableManager(_db, _db.purchaseLines);
  $$AppPreferencesTableTableManager get appPreferences =>
      $$AppPreferencesTableTableManager(_db, _db.appPreferences);
  $$CloudSyncSettingsTableTableManager get cloudSyncSettings =>
      $$CloudSyncSettingsTableTableManager(_db, _db.cloudSyncSettings);
}
