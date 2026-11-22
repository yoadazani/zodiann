// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'simulated_v2_database.dart';

// ignore_for_file: type=lint
class $SavedSquaresV2Table extends SavedSquaresV2
    with TableInfo<$SavedSquaresV2Table, SavedSquaresV2Data> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedSquaresV2Table(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _configJsonMeta = const VerificationMeta(
    'configJson',
  );
  @override
  late final GeneratedColumn<String> configJson = GeneratedColumn<String>(
    'config_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    configJson,
    createdAt,
    updatedAt,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_squares';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedSquaresV2Data> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('config_json')) {
      context.handle(
        _configJsonMeta,
        configJson.isAcceptableOrUnknown(data['config_json']!, _configJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_configJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedSquaresV2Data map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedSquaresV2Data(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      configJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $SavedSquaresV2Table createAlias(String alias) {
    return $SavedSquaresV2Table(attachedDatabase, alias);
  }
}

class SavedSquaresV2Data extends DataClass
    implements Insertable<SavedSquaresV2Data> {
  final String id;
  final String name;
  final String configJson;
  final int createdAt;
  final int updatedAt;
  final String? note;
  const SavedSquaresV2Data({
    required this.id,
    required this.name,
    required this.configJson,
    required this.createdAt,
    required this.updatedAt,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['config_json'] = Variable<String>(configJson);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  SavedSquaresV2Companion toCompanion(bool nullToAbsent) {
    return SavedSquaresV2Companion(
      id: Value(id),
      name: Value(name),
      configJson: Value(configJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory SavedSquaresV2Data.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedSquaresV2Data(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      configJson: serializer.fromJson<String>(json['configJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'configJson': serializer.toJson<String>(configJson),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'note': serializer.toJson<String?>(note),
    };
  }

  SavedSquaresV2Data copyWith({
    String? id,
    String? name,
    String? configJson,
    int? createdAt,
    int? updatedAt,
    Value<String?> note = const Value.absent(),
  }) => SavedSquaresV2Data(
    id: id ?? this.id,
    name: name ?? this.name,
    configJson: configJson ?? this.configJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    note: note.present ? note.value : this.note,
  );
  SavedSquaresV2Data copyWithCompanion(SavedSquaresV2Companion data) {
    return SavedSquaresV2Data(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      configJson: data.configJson.present
          ? data.configJson.value
          : this.configJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedSquaresV2Data(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('configJson: $configJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, configJson, createdAt, updatedAt, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedSquaresV2Data &&
          other.id == this.id &&
          other.name == this.name &&
          other.configJson == this.configJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.note == this.note);
}

class SavedSquaresV2Companion extends UpdateCompanion<SavedSquaresV2Data> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> configJson;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String?> note;
  final Value<int> rowid;
  const SavedSquaresV2Companion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.configJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedSquaresV2Companion.insert({
    required String id,
    required String name,
    required String configJson,
    required int createdAt,
    required int updatedAt,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       configJson = Value(configJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SavedSquaresV2Data> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? configJson,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (configJson != null) 'config_json': configJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedSquaresV2Companion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? configJson,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return SavedSquaresV2Companion(
      id: id ?? this.id,
      name: name ?? this.name,
      configJson: configJson ?? this.configJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (configJson.present) {
      map['config_json'] = Variable<String>(configJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedSquaresV2Companion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('configJson: $configJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SimulatedV2Database extends GeneratedDatabase {
  _$SimulatedV2Database(QueryExecutor e) : super(e);
  $SimulatedV2DatabaseManager get managers => $SimulatedV2DatabaseManager(this);
  late final $SavedSquaresV2Table savedSquaresV2 = $SavedSquaresV2Table(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [savedSquaresV2];
}

typedef $$SavedSquaresV2TableCreateCompanionBuilder =
    SavedSquaresV2Companion Function({
      required String id,
      required String name,
      required String configJson,
      required int createdAt,
      required int updatedAt,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$SavedSquaresV2TableUpdateCompanionBuilder =
    SavedSquaresV2Companion Function({
      Value<String> id,
      Value<String> name,
      Value<String> configJson,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String?> note,
      Value<int> rowid,
    });

class $$SavedSquaresV2TableFilterComposer
    extends Composer<_$SimulatedV2Database, $SavedSquaresV2Table> {
  $$SavedSquaresV2TableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedSquaresV2TableOrderingComposer
    extends Composer<_$SimulatedV2Database, $SavedSquaresV2Table> {
  $$SavedSquaresV2TableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedSquaresV2TableAnnotationComposer
    extends Composer<_$SimulatedV2Database, $SavedSquaresV2Table> {
  $$SavedSquaresV2TableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$SavedSquaresV2TableTableManager
    extends
        RootTableManager<
          _$SimulatedV2Database,
          $SavedSquaresV2Table,
          SavedSquaresV2Data,
          $$SavedSquaresV2TableFilterComposer,
          $$SavedSquaresV2TableOrderingComposer,
          $$SavedSquaresV2TableAnnotationComposer,
          $$SavedSquaresV2TableCreateCompanionBuilder,
          $$SavedSquaresV2TableUpdateCompanionBuilder,
          (
            SavedSquaresV2Data,
            BaseReferences<
              _$SimulatedV2Database,
              $SavedSquaresV2Table,
              SavedSquaresV2Data
            >,
          ),
          SavedSquaresV2Data,
          PrefetchHooks Function()
        > {
  $$SavedSquaresV2TableTableManager(
    _$SimulatedV2Database db,
    $SavedSquaresV2Table table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedSquaresV2TableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedSquaresV2TableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedSquaresV2TableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> configJson = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedSquaresV2Companion(
                id: id,
                name: name,
                configJson: configJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String configJson,
                required int createdAt,
                required int updatedAt,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedSquaresV2Companion.insert(
                id: id,
                name: name,
                configJson: configJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavedSquaresV2Table, SavedSquaresV2Data>(table),
                  BaseReferences<
                    _$SimulatedV2Database,
                    $SavedSquaresV2Table,
                    SavedSquaresV2Data
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedSquaresV2TableProcessedTableManager =
    ProcessedTableManager<
      _$SimulatedV2Database,
      $SavedSquaresV2Table,
      SavedSquaresV2Data,
      $$SavedSquaresV2TableFilterComposer,
      $$SavedSquaresV2TableOrderingComposer,
      $$SavedSquaresV2TableAnnotationComposer,
      $$SavedSquaresV2TableCreateCompanionBuilder,
      $$SavedSquaresV2TableUpdateCompanionBuilder,
      (
        SavedSquaresV2Data,
        BaseReferences<
          _$SimulatedV2Database,
          $SavedSquaresV2Table,
          SavedSquaresV2Data
        >,
      ),
      SavedSquaresV2Data,
      PrefetchHooks Function()
    >;

class $SimulatedV2DatabaseManager {
  final _$SimulatedV2Database _db;
  $SimulatedV2DatabaseManager(this._db);
  $$SavedSquaresV2TableTableManager get savedSquaresV2 =>
      $$SavedSquaresV2TableTableManager(_db, _db.savedSquaresV2);
}
