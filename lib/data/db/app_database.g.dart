// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, ReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
      'is_done', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_done" IN (0, 1))'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _remindAtMeta =
      const VerificationMeta('remindAt');
  @override
  late final GeneratedColumn<int> remindAt = GeneratedColumn<int>(
      'remind_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customCategoryLabelMeta =
      const VerificationMeta('customCategoryLabel');
  @override
  late final GeneratedColumn<String> customCategoryLabel =
      GeneratedColumn<String>('custom_category_label', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _locationTriggerEnabledMeta =
      const VerificationMeta('locationTriggerEnabled');
  @override
  late final GeneratedColumn<bool> locationTriggerEnabled =
      GeneratedColumn<bool>('location_trigger_enabled', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("location_trigger_enabled" IN (0, 1))'));
  static const VerificationMeta _locationLatitudeMeta =
      const VerificationMeta('locationLatitude');
  @override
  late final GeneratedColumn<double> locationLatitude = GeneratedColumn<double>(
      'location_latitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _locationLongitudeMeta =
      const VerificationMeta('locationLongitude');
  @override
  late final GeneratedColumn<double> locationLongitude =
      GeneratedColumn<double>('location_longitude', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _locationRadiusMetersMeta =
      const VerificationMeta('locationRadiusMeters');
  @override
  late final GeneratedColumn<double> locationRadiusMeters =
      GeneratedColumn<double>('location_radius_meters', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _locationPlaceLabelMeta =
      const VerificationMeta('locationPlaceLabel');
  @override
  late final GeneratedColumn<String> locationPlaceLabel =
      GeneratedColumn<String>('location_place_label', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        note,
        isDone,
        createdAt,
        remindAt,
        categoryId,
        customCategoryLabel,
        locationTriggerEnabled,
        locationLatitude,
        locationLongitude,
        locationRadiusMeters,
        locationPlaceLabel,
        position,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(Insertable<ReminderRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('is_done')) {
      context.handle(_isDoneMeta,
          isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta));
    } else if (isInserting) {
      context.missing(_isDoneMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('remind_at')) {
      context.handle(_remindAtMeta,
          remindAt.isAcceptableOrUnknown(data['remind_at']!, _remindAtMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('custom_category_label')) {
      context.handle(
          _customCategoryLabelMeta,
          customCategoryLabel.isAcceptableOrUnknown(
              data['custom_category_label']!, _customCategoryLabelMeta));
    }
    if (data.containsKey('location_trigger_enabled')) {
      context.handle(
          _locationTriggerEnabledMeta,
          locationTriggerEnabled.isAcceptableOrUnknown(
              data['location_trigger_enabled']!, _locationTriggerEnabledMeta));
    } else if (isInserting) {
      context.missing(_locationTriggerEnabledMeta);
    }
    if (data.containsKey('location_latitude')) {
      context.handle(
          _locationLatitudeMeta,
          locationLatitude.isAcceptableOrUnknown(
              data['location_latitude']!, _locationLatitudeMeta));
    }
    if (data.containsKey('location_longitude')) {
      context.handle(
          _locationLongitudeMeta,
          locationLongitude.isAcceptableOrUnknown(
              data['location_longitude']!, _locationLongitudeMeta));
    }
    if (data.containsKey('location_radius_meters')) {
      context.handle(
          _locationRadiusMetersMeta,
          locationRadiusMeters.isAcceptableOrUnknown(
              data['location_radius_meters']!, _locationRadiusMetersMeta));
    } else if (isInserting) {
      context.missing(_locationRadiusMetersMeta);
    }
    if (data.containsKey('location_place_label')) {
      context.handle(
          _locationPlaceLabelMeta,
          locationPlaceLabel.isAcceptableOrUnknown(
              data['location_place_label']!, _locationPlaceLabelMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      isDone: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_done'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      remindAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}remind_at']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      customCategoryLabel: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}custom_category_label']),
      locationTriggerEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}location_trigger_enabled'])!,
      locationLatitude: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}location_latitude']),
      locationLongitude: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}location_longitude']),
      locationRadiusMeters: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}location_radius_meters'])!,
      locationPlaceLabel: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}location_place_label']),
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class ReminderRow extends DataClass implements Insertable<ReminderRow> {
  final String id;
  final String title;
  final String? note;
  final bool isDone;
  final int createdAt;
  final int? remindAt;
  final String categoryId;
  final String? customCategoryLabel;
  final bool locationTriggerEnabled;
  final double? locationLatitude;
  final double? locationLongitude;
  final double locationRadiusMeters;
  final String? locationPlaceLabel;
  final int position;
  final int updatedAt;
  final int? deletedAt;
  const ReminderRow(
      {required this.id,
      required this.title,
      this.note,
      required this.isDone,
      required this.createdAt,
      this.remindAt,
      required this.categoryId,
      this.customCategoryLabel,
      required this.locationTriggerEnabled,
      this.locationLatitude,
      this.locationLongitude,
      required this.locationRadiusMeters,
      this.locationPlaceLabel,
      required this.position,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['is_done'] = Variable<bool>(isDone);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || remindAt != null) {
      map['remind_at'] = Variable<int>(remindAt);
    }
    map['category_id'] = Variable<String>(categoryId);
    if (!nullToAbsent || customCategoryLabel != null) {
      map['custom_category_label'] = Variable<String>(customCategoryLabel);
    }
    map['location_trigger_enabled'] = Variable<bool>(locationTriggerEnabled);
    if (!nullToAbsent || locationLatitude != null) {
      map['location_latitude'] = Variable<double>(locationLatitude);
    }
    if (!nullToAbsent || locationLongitude != null) {
      map['location_longitude'] = Variable<double>(locationLongitude);
    }
    map['location_radius_meters'] = Variable<double>(locationRadiusMeters);
    if (!nullToAbsent || locationPlaceLabel != null) {
      map['location_place_label'] = Variable<String>(locationPlaceLabel);
    }
    map['position'] = Variable<int>(position);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      title: Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      isDone: Value(isDone),
      createdAt: Value(createdAt),
      remindAt: remindAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remindAt),
      categoryId: Value(categoryId),
      customCategoryLabel: customCategoryLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(customCategoryLabel),
      locationTriggerEnabled: Value(locationTriggerEnabled),
      locationLatitude: locationLatitude == null && nullToAbsent
          ? const Value.absent()
          : Value(locationLatitude),
      locationLongitude: locationLongitude == null && nullToAbsent
          ? const Value.absent()
          : Value(locationLongitude),
      locationRadiusMeters: Value(locationRadiusMeters),
      locationPlaceLabel: locationPlaceLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(locationPlaceLabel),
      position: Value(position),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ReminderRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      remindAt: serializer.fromJson<int?>(json['remindAt']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      customCategoryLabel:
          serializer.fromJson<String?>(json['customCategoryLabel']),
      locationTriggerEnabled:
          serializer.fromJson<bool>(json['locationTriggerEnabled']),
      locationLatitude: serializer.fromJson<double?>(json['locationLatitude']),
      locationLongitude:
          serializer.fromJson<double?>(json['locationLongitude']),
      locationRadiusMeters:
          serializer.fromJson<double>(json['locationRadiusMeters']),
      locationPlaceLabel:
          serializer.fromJson<String?>(json['locationPlaceLabel']),
      position: serializer.fromJson<int>(json['position']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'note': serializer.toJson<String?>(note),
      'isDone': serializer.toJson<bool>(isDone),
      'createdAt': serializer.toJson<int>(createdAt),
      'remindAt': serializer.toJson<int?>(remindAt),
      'categoryId': serializer.toJson<String>(categoryId),
      'customCategoryLabel': serializer.toJson<String?>(customCategoryLabel),
      'locationTriggerEnabled': serializer.toJson<bool>(locationTriggerEnabled),
      'locationLatitude': serializer.toJson<double?>(locationLatitude),
      'locationLongitude': serializer.toJson<double?>(locationLongitude),
      'locationRadiusMeters': serializer.toJson<double>(locationRadiusMeters),
      'locationPlaceLabel': serializer.toJson<String?>(locationPlaceLabel),
      'position': serializer.toJson<int>(position),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  ReminderRow copyWith(
          {String? id,
          String? title,
          Value<String?> note = const Value.absent(),
          bool? isDone,
          int? createdAt,
          Value<int?> remindAt = const Value.absent(),
          String? categoryId,
          Value<String?> customCategoryLabel = const Value.absent(),
          bool? locationTriggerEnabled,
          Value<double?> locationLatitude = const Value.absent(),
          Value<double?> locationLongitude = const Value.absent(),
          double? locationRadiusMeters,
          Value<String?> locationPlaceLabel = const Value.absent(),
          int? position,
          int? updatedAt,
          Value<int?> deletedAt = const Value.absent()}) =>
      ReminderRow(
        id: id ?? this.id,
        title: title ?? this.title,
        note: note.present ? note.value : this.note,
        isDone: isDone ?? this.isDone,
        createdAt: createdAt ?? this.createdAt,
        remindAt: remindAt.present ? remindAt.value : this.remindAt,
        categoryId: categoryId ?? this.categoryId,
        customCategoryLabel: customCategoryLabel.present
            ? customCategoryLabel.value
            : this.customCategoryLabel,
        locationTriggerEnabled:
            locationTriggerEnabled ?? this.locationTriggerEnabled,
        locationLatitude: locationLatitude.present
            ? locationLatitude.value
            : this.locationLatitude,
        locationLongitude: locationLongitude.present
            ? locationLongitude.value
            : this.locationLongitude,
        locationRadiusMeters: locationRadiusMeters ?? this.locationRadiusMeters,
        locationPlaceLabel: locationPlaceLabel.present
            ? locationPlaceLabel.value
            : this.locationPlaceLabel,
        position: position ?? this.position,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  ReminderRow copyWithCompanion(RemindersCompanion data) {
    return ReminderRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      remindAt: data.remindAt.present ? data.remindAt.value : this.remindAt,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      customCategoryLabel: data.customCategoryLabel.present
          ? data.customCategoryLabel.value
          : this.customCategoryLabel,
      locationTriggerEnabled: data.locationTriggerEnabled.present
          ? data.locationTriggerEnabled.value
          : this.locationTriggerEnabled,
      locationLatitude: data.locationLatitude.present
          ? data.locationLatitude.value
          : this.locationLatitude,
      locationLongitude: data.locationLongitude.present
          ? data.locationLongitude.value
          : this.locationLongitude,
      locationRadiusMeters: data.locationRadiusMeters.present
          ? data.locationRadiusMeters.value
          : this.locationRadiusMeters,
      locationPlaceLabel: data.locationPlaceLabel.present
          ? data.locationPlaceLabel.value
          : this.locationPlaceLabel,
      position: data.position.present ? data.position.value : this.position,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('isDone: $isDone, ')
          ..write('createdAt: $createdAt, ')
          ..write('remindAt: $remindAt, ')
          ..write('categoryId: $categoryId, ')
          ..write('customCategoryLabel: $customCategoryLabel, ')
          ..write('locationTriggerEnabled: $locationTriggerEnabled, ')
          ..write('locationLatitude: $locationLatitude, ')
          ..write('locationLongitude: $locationLongitude, ')
          ..write('locationRadiusMeters: $locationRadiusMeters, ')
          ..write('locationPlaceLabel: $locationPlaceLabel, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      note,
      isDone,
      createdAt,
      remindAt,
      categoryId,
      customCategoryLabel,
      locationTriggerEnabled,
      locationLatitude,
      locationLongitude,
      locationRadiusMeters,
      locationPlaceLabel,
      position,
      updatedAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.note == this.note &&
          other.isDone == this.isDone &&
          other.createdAt == this.createdAt &&
          other.remindAt == this.remindAt &&
          other.categoryId == this.categoryId &&
          other.customCategoryLabel == this.customCategoryLabel &&
          other.locationTriggerEnabled == this.locationTriggerEnabled &&
          other.locationLatitude == this.locationLatitude &&
          other.locationLongitude == this.locationLongitude &&
          other.locationRadiusMeters == this.locationRadiusMeters &&
          other.locationPlaceLabel == this.locationPlaceLabel &&
          other.position == this.position &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class RemindersCompanion extends UpdateCompanion<ReminderRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> note;
  final Value<bool> isDone;
  final Value<int> createdAt;
  final Value<int?> remindAt;
  final Value<String> categoryId;
  final Value<String?> customCategoryLabel;
  final Value<bool> locationTriggerEnabled;
  final Value<double?> locationLatitude;
  final Value<double?> locationLongitude;
  final Value<double> locationRadiusMeters;
  final Value<String?> locationPlaceLabel;
  final Value<int> position;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.isDone = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.remindAt = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.customCategoryLabel = const Value.absent(),
    this.locationTriggerEnabled = const Value.absent(),
    this.locationLatitude = const Value.absent(),
    this.locationLongitude = const Value.absent(),
    this.locationRadiusMeters = const Value.absent(),
    this.locationPlaceLabel = const Value.absent(),
    this.position = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    required String title,
    this.note = const Value.absent(),
    required bool isDone,
    required int createdAt,
    this.remindAt = const Value.absent(),
    required String categoryId,
    this.customCategoryLabel = const Value.absent(),
    required bool locationTriggerEnabled,
    this.locationLatitude = const Value.absent(),
    this.locationLongitude = const Value.absent(),
    required double locationRadiusMeters,
    this.locationPlaceLabel = const Value.absent(),
    required int position,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        isDone = Value(isDone),
        createdAt = Value(createdAt),
        categoryId = Value(categoryId),
        locationTriggerEnabled = Value(locationTriggerEnabled),
        locationRadiusMeters = Value(locationRadiusMeters),
        position = Value(position),
        updatedAt = Value(updatedAt);
  static Insertable<ReminderRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? note,
    Expression<bool>? isDone,
    Expression<int>? createdAt,
    Expression<int>? remindAt,
    Expression<String>? categoryId,
    Expression<String>? customCategoryLabel,
    Expression<bool>? locationTriggerEnabled,
    Expression<double>? locationLatitude,
    Expression<double>? locationLongitude,
    Expression<double>? locationRadiusMeters,
    Expression<String>? locationPlaceLabel,
    Expression<int>? position,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (isDone != null) 'is_done': isDone,
      if (createdAt != null) 'created_at': createdAt,
      if (remindAt != null) 'remind_at': remindAt,
      if (categoryId != null) 'category_id': categoryId,
      if (customCategoryLabel != null)
        'custom_category_label': customCategoryLabel,
      if (locationTriggerEnabled != null)
        'location_trigger_enabled': locationTriggerEnabled,
      if (locationLatitude != null) 'location_latitude': locationLatitude,
      if (locationLongitude != null) 'location_longitude': locationLongitude,
      if (locationRadiusMeters != null)
        'location_radius_meters': locationRadiusMeters,
      if (locationPlaceLabel != null)
        'location_place_label': locationPlaceLabel,
      if (position != null) 'position': position,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? note,
      Value<bool>? isDone,
      Value<int>? createdAt,
      Value<int?>? remindAt,
      Value<String>? categoryId,
      Value<String?>? customCategoryLabel,
      Value<bool>? locationTriggerEnabled,
      Value<double?>? locationLatitude,
      Value<double?>? locationLongitude,
      Value<double>? locationRadiusMeters,
      Value<String?>? locationPlaceLabel,
      Value<int>? position,
      Value<int>? updatedAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return RemindersCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      remindAt: remindAt ?? this.remindAt,
      categoryId: categoryId ?? this.categoryId,
      customCategoryLabel: customCategoryLabel ?? this.customCategoryLabel,
      locationTriggerEnabled:
          locationTriggerEnabled ?? this.locationTriggerEnabled,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      locationRadiusMeters: locationRadiusMeters ?? this.locationRadiusMeters,
      locationPlaceLabel: locationPlaceLabel ?? this.locationPlaceLabel,
      position: position ?? this.position,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (remindAt.present) {
      map['remind_at'] = Variable<int>(remindAt.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (customCategoryLabel.present) {
      map['custom_category_label'] =
          Variable<String>(customCategoryLabel.value);
    }
    if (locationTriggerEnabled.present) {
      map['location_trigger_enabled'] =
          Variable<bool>(locationTriggerEnabled.value);
    }
    if (locationLatitude.present) {
      map['location_latitude'] = Variable<double>(locationLatitude.value);
    }
    if (locationLongitude.present) {
      map['location_longitude'] = Variable<double>(locationLongitude.value);
    }
    if (locationRadiusMeters.present) {
      map['location_radius_meters'] =
          Variable<double>(locationRadiusMeters.value);
    }
    if (locationPlaceLabel.present) {
      map['location_place_label'] = Variable<String>(locationPlaceLabel.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('isDone: $isDone, ')
          ..write('createdAt: $createdAt, ')
          ..write('remindAt: $remindAt, ')
          ..write('categoryId: $categoryId, ')
          ..write('customCategoryLabel: $customCategoryLabel, ')
          ..write('locationTriggerEnabled: $locationTriggerEnabled, ')
          ..write('locationLatitude: $locationLatitude, ')
          ..write('locationLongitude: $locationLongitude, ')
          ..write('locationRadiusMeters: $locationRadiusMeters, ')
          ..write('locationPlaceLabel: $locationPlaceLabel, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BirthdaysTable extends Birthdays
    with TableInfo<$BirthdaysTable, BirthdayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BirthdaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notifyHourMeta =
      const VerificationMeta('notifyHour');
  @override
  late final GeneratedColumn<int> notifyHour = GeneratedColumn<int>(
      'notify_hour', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _notifyMinuteMeta =
      const VerificationMeta('notifyMinute');
  @override
  late final GeneratedColumn<int> notifyMinute = GeneratedColumn<int>(
      'notify_minute', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _advanceOffsetsMinutesMeta =
      const VerificationMeta('advanceOffsetsMinutes');
  @override
  late final GeneratedColumn<String> advanceOffsetsMinutes =
      GeneratedColumn<String>('advance_offsets_minutes', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        note,
        date,
        notifyHour,
        notifyMinute,
        advanceOffsetsMinutes,
        createdAt,
        position,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'birthdays';
  @override
  VerificationContext validateIntegrity(Insertable<BirthdayRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('notify_hour')) {
      context.handle(
          _notifyHourMeta,
          notifyHour.isAcceptableOrUnknown(
              data['notify_hour']!, _notifyHourMeta));
    } else if (isInserting) {
      context.missing(_notifyHourMeta);
    }
    if (data.containsKey('notify_minute')) {
      context.handle(
          _notifyMinuteMeta,
          notifyMinute.isAcceptableOrUnknown(
              data['notify_minute']!, _notifyMinuteMeta));
    } else if (isInserting) {
      context.missing(_notifyMinuteMeta);
    }
    if (data.containsKey('advance_offsets_minutes')) {
      context.handle(
          _advanceOffsetsMinutesMeta,
          advanceOffsetsMinutes.isAcceptableOrUnknown(
              data['advance_offsets_minutes']!, _advanceOffsetsMinutesMeta));
    } else if (isInserting) {
      context.missing(_advanceOffsetsMinutesMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BirthdayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BirthdayRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      notifyHour: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}notify_hour'])!,
      notifyMinute: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}notify_minute'])!,
      advanceOffsetsMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}advance_offsets_minutes'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $BirthdaysTable createAlias(String alias) {
    return $BirthdaysTable(attachedDatabase, alias);
  }
}

class BirthdayRow extends DataClass implements Insertable<BirthdayRow> {
  final String id;
  final String name;
  final String? note;

  /// Takvim tarihi: `DateTime.toIso8601String()` (yerel değer için saat dilimi
  /// eki yok). Anlık zaman değil; saat dilimi değişince gün kaymasın diye
  /// JSON dönemindeki biçimle aynen saklanır.
  final String date;
  final int notifyHour;
  final int notifyMinute;

  /// Önbildirim dakikaları, JSON dizi metni (örn. `[0,1440]`).
  final String advanceOffsetsMinutes;
  final int createdAt;
  final int position;
  final int updatedAt;
  final int? deletedAt;
  const BirthdayRow(
      {required this.id,
      required this.name,
      this.note,
      required this.date,
      required this.notifyHour,
      required this.notifyMinute,
      required this.advanceOffsetsMinutes,
      required this.createdAt,
      required this.position,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['date'] = Variable<String>(date);
    map['notify_hour'] = Variable<int>(notifyHour);
    map['notify_minute'] = Variable<int>(notifyMinute);
    map['advance_offsets_minutes'] = Variable<String>(advanceOffsetsMinutes);
    map['created_at'] = Variable<int>(createdAt);
    map['position'] = Variable<int>(position);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  BirthdaysCompanion toCompanion(bool nullToAbsent) {
    return BirthdaysCompanion(
      id: Value(id),
      name: Value(name),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      date: Value(date),
      notifyHour: Value(notifyHour),
      notifyMinute: Value(notifyMinute),
      advanceOffsetsMinutes: Value(advanceOffsetsMinutes),
      createdAt: Value(createdAt),
      position: Value(position),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory BirthdayRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BirthdayRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      note: serializer.fromJson<String?>(json['note']),
      date: serializer.fromJson<String>(json['date']),
      notifyHour: serializer.fromJson<int>(json['notifyHour']),
      notifyMinute: serializer.fromJson<int>(json['notifyMinute']),
      advanceOffsetsMinutes:
          serializer.fromJson<String>(json['advanceOffsetsMinutes']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      position: serializer.fromJson<int>(json['position']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'note': serializer.toJson<String?>(note),
      'date': serializer.toJson<String>(date),
      'notifyHour': serializer.toJson<int>(notifyHour),
      'notifyMinute': serializer.toJson<int>(notifyMinute),
      'advanceOffsetsMinutes': serializer.toJson<String>(advanceOffsetsMinutes),
      'createdAt': serializer.toJson<int>(createdAt),
      'position': serializer.toJson<int>(position),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  BirthdayRow copyWith(
          {String? id,
          String? name,
          Value<String?> note = const Value.absent(),
          String? date,
          int? notifyHour,
          int? notifyMinute,
          String? advanceOffsetsMinutes,
          int? createdAt,
          int? position,
          int? updatedAt,
          Value<int?> deletedAt = const Value.absent()}) =>
      BirthdayRow(
        id: id ?? this.id,
        name: name ?? this.name,
        note: note.present ? note.value : this.note,
        date: date ?? this.date,
        notifyHour: notifyHour ?? this.notifyHour,
        notifyMinute: notifyMinute ?? this.notifyMinute,
        advanceOffsetsMinutes:
            advanceOffsetsMinutes ?? this.advanceOffsetsMinutes,
        createdAt: createdAt ?? this.createdAt,
        position: position ?? this.position,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  BirthdayRow copyWithCompanion(BirthdaysCompanion data) {
    return BirthdayRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      note: data.note.present ? data.note.value : this.note,
      date: data.date.present ? data.date.value : this.date,
      notifyHour:
          data.notifyHour.present ? data.notifyHour.value : this.notifyHour,
      notifyMinute: data.notifyMinute.present
          ? data.notifyMinute.value
          : this.notifyMinute,
      advanceOffsetsMinutes: data.advanceOffsetsMinutes.present
          ? data.advanceOffsetsMinutes.value
          : this.advanceOffsetsMinutes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      position: data.position.present ? data.position.value : this.position,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BirthdayRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('notifyHour: $notifyHour, ')
          ..write('notifyMinute: $notifyMinute, ')
          ..write('advanceOffsetsMinutes: $advanceOffsetsMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      note,
      date,
      notifyHour,
      notifyMinute,
      advanceOffsetsMinutes,
      createdAt,
      position,
      updatedAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BirthdayRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.note == this.note &&
          other.date == this.date &&
          other.notifyHour == this.notifyHour &&
          other.notifyMinute == this.notifyMinute &&
          other.advanceOffsetsMinutes == this.advanceOffsetsMinutes &&
          other.createdAt == this.createdAt &&
          other.position == this.position &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class BirthdaysCompanion extends UpdateCompanion<BirthdayRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> note;
  final Value<String> date;
  final Value<int> notifyHour;
  final Value<int> notifyMinute;
  final Value<String> advanceOffsetsMinutes;
  final Value<int> createdAt;
  final Value<int> position;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const BirthdaysCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.note = const Value.absent(),
    this.date = const Value.absent(),
    this.notifyHour = const Value.absent(),
    this.notifyMinute = const Value.absent(),
    this.advanceOffsetsMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.position = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BirthdaysCompanion.insert({
    required String id,
    required String name,
    this.note = const Value.absent(),
    required String date,
    required int notifyHour,
    required int notifyMinute,
    required String advanceOffsetsMinutes,
    required int createdAt,
    required int position,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        date = Value(date),
        notifyHour = Value(notifyHour),
        notifyMinute = Value(notifyMinute),
        advanceOffsetsMinutes = Value(advanceOffsetsMinutes),
        createdAt = Value(createdAt),
        position = Value(position),
        updatedAt = Value(updatedAt);
  static Insertable<BirthdayRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? note,
    Expression<String>? date,
    Expression<int>? notifyHour,
    Expression<int>? notifyMinute,
    Expression<String>? advanceOffsetsMinutes,
    Expression<int>? createdAt,
    Expression<int>? position,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (note != null) 'note': note,
      if (date != null) 'date': date,
      if (notifyHour != null) 'notify_hour': notifyHour,
      if (notifyMinute != null) 'notify_minute': notifyMinute,
      if (advanceOffsetsMinutes != null)
        'advance_offsets_minutes': advanceOffsetsMinutes,
      if (createdAt != null) 'created_at': createdAt,
      if (position != null) 'position': position,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BirthdaysCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? note,
      Value<String>? date,
      Value<int>? notifyHour,
      Value<int>? notifyMinute,
      Value<String>? advanceOffsetsMinutes,
      Value<int>? createdAt,
      Value<int>? position,
      Value<int>? updatedAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return BirthdaysCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      note: note ?? this.note,
      date: date ?? this.date,
      notifyHour: notifyHour ?? this.notifyHour,
      notifyMinute: notifyMinute ?? this.notifyMinute,
      advanceOffsetsMinutes:
          advanceOffsetsMinutes ?? this.advanceOffsetsMinutes,
      createdAt: createdAt ?? this.createdAt,
      position: position ?? this.position,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (notifyHour.present) {
      map['notify_hour'] = Variable<int>(notifyHour.value);
    }
    if (notifyMinute.present) {
      map['notify_minute'] = Variable<int>(notifyMinute.value);
    }
    if (advanceOffsetsMinutes.present) {
      map['advance_offsets_minutes'] =
          Variable<String>(advanceOffsetsMinutes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BirthdaysCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('notifyHour: $notifyHour, ')
          ..write('notifyMinute: $notifyMinute, ')
          ..write('advanceOffsetsMinutes: $advanceOffsetsMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _notificationsEnabledMeta =
      const VerificationMeta('notificationsEnabled');
  @override
  late final GeneratedColumn<bool> notificationsEnabled = GeneratedColumn<bool>(
      'notifications_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notifications_enabled" IN (0, 1))'));
  static const VerificationMeta _themeModeMeta =
      const VerificationMeta('themeMode');
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
      'theme_mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, notificationsEnabled, themeMode, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<SettingsRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('notifications_enabled')) {
      context.handle(
          _notificationsEnabledMeta,
          notificationsEnabled.isAcceptableOrUnknown(
              data['notifications_enabled']!, _notificationsEnabledMeta));
    } else if (isInserting) {
      context.missing(_notificationsEnabledMeta);
    }
    if (data.containsKey('theme_mode')) {
      context.handle(_themeModeMeta,
          themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta));
    } else if (isInserting) {
      context.missing(_themeModeMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      notificationsEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}notifications_enabled'])!,
      themeMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}theme_mode'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final int id;
  final bool notificationsEnabled;
  final String themeMode;
  final int updatedAt;
  const SettingsRow(
      {required this.id,
      required this.notificationsEnabled,
      required this.themeMode,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['notifications_enabled'] = Variable<bool>(notificationsEnabled);
    map['theme_mode'] = Variable<String>(themeMode);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      notificationsEnabled: Value(notificationsEnabled),
      themeMode: Value(themeMode),
      updatedAt: Value(updatedAt),
    );
  }

  factory SettingsRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<int>(json['id']),
      notificationsEnabled:
          serializer.fromJson<bool>(json['notificationsEnabled']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'notificationsEnabled': serializer.toJson<bool>(notificationsEnabled),
      'themeMode': serializer.toJson<String>(themeMode),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  SettingsRow copyWith(
          {int? id,
          bool? notificationsEnabled,
          String? themeMode,
          int? updatedAt}) =>
      SettingsRow(
        id: id ?? this.id,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        themeMode: themeMode ?? this.themeMode,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SettingsRow copyWithCompanion(SettingsCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      notificationsEnabled: data.notificationsEnabled.present
          ? data.notificationsEnabled.value
          : this.notificationsEnabled,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('themeMode: $themeMode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, notificationsEnabled, themeMode, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.notificationsEnabled == this.notificationsEnabled &&
          other.themeMode == this.themeMode &&
          other.updatedAt == this.updatedAt);
}

class SettingsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<bool> notificationsEnabled;
  final Value<String> themeMode;
  final Value<int> updatedAt;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    required bool notificationsEnabled,
    required String themeMode,
    required int updatedAt,
  })  : notificationsEnabled = Value(notificationsEnabled),
        themeMode = Value(themeMode),
        updatedAt = Value(updatedAt);
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<bool>? notificationsEnabled,
    Expression<String>? themeMode,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (themeMode != null) 'theme_mode': themeMode,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SettingsCompanion copyWith(
      {Value<int>? id,
      Value<bool>? notificationsEnabled,
      Value<String>? themeMode,
      Value<int>? updatedAt}) {
    return SettingsCompanion(
      id: id ?? this.id,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (notificationsEnabled.present) {
      map['notifications_enabled'] = Variable<bool>(notificationsEnabled.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('themeMode: $themeMode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(Insertable<AppMetaRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaRow extends DataClass implements Insertable<AppMetaRow> {
  final String key;
  final String value;
  const AppMetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory AppMetaRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppMetaRow copyWith({String? key, String? value}) => AppMetaRow(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  AppMetaRow copyWithCompanion(AppMetaCompanion data) {
    return AppMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<AppMetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetaCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return AppMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $BirthdaysTable birthdays = $BirthdaysTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [reminders, birthdays, settings, appMeta];
}

typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  required String id,
  required String title,
  Value<String?> note,
  required bool isDone,
  required int createdAt,
  Value<int?> remindAt,
  required String categoryId,
  Value<String?> customCategoryLabel,
  required bool locationTriggerEnabled,
  Value<double?> locationLatitude,
  Value<double?> locationLongitude,
  required double locationRadiusMeters,
  Value<String?> locationPlaceLabel,
  required int position,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> note,
  Value<bool> isDone,
  Value<int> createdAt,
  Value<int?> remindAt,
  Value<String> categoryId,
  Value<String?> customCategoryLabel,
  Value<bool> locationTriggerEnabled,
  Value<double?> locationLatitude,
  Value<double?> locationLongitude,
  Value<double> locationRadiusMeters,
  Value<String?> locationPlaceLabel,
  Value<int> position,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDone => $composableBuilder(
      column: $table.isDone, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get remindAt => $composableBuilder(
      column: $table.remindAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customCategoryLabel => $composableBuilder(
      column: $table.customCategoryLabel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get locationTriggerEnabled => $composableBuilder(
      column: $table.locationTriggerEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get locationLatitude => $composableBuilder(
      column: $table.locationLatitude,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get locationLongitude => $composableBuilder(
      column: $table.locationLongitude,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get locationRadiusMeters => $composableBuilder(
      column: $table.locationRadiusMeters,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get locationPlaceLabel => $composableBuilder(
      column: $table.locationPlaceLabel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDone => $composableBuilder(
      column: $table.isDone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get remindAt => $composableBuilder(
      column: $table.remindAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customCategoryLabel => $composableBuilder(
      column: $table.customCategoryLabel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get locationTriggerEnabled => $composableBuilder(
      column: $table.locationTriggerEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get locationLatitude => $composableBuilder(
      column: $table.locationLatitude,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get locationLongitude => $composableBuilder(
      column: $table.locationLongitude,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get locationRadiusMeters => $composableBuilder(
      column: $table.locationRadiusMeters,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get locationPlaceLabel => $composableBuilder(
      column: $table.locationPlaceLabel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get remindAt =>
      $composableBuilder(column: $table.remindAt, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get customCategoryLabel => $composableBuilder(
      column: $table.customCategoryLabel, builder: (column) => column);

  GeneratedColumn<bool> get locationTriggerEnabled => $composableBuilder(
      column: $table.locationTriggerEnabled, builder: (column) => column);

  GeneratedColumn<double> get locationLatitude => $composableBuilder(
      column: $table.locationLatitude, builder: (column) => column);

  GeneratedColumn<double> get locationLongitude => $composableBuilder(
      column: $table.locationLongitude, builder: (column) => column);

  GeneratedColumn<double> get locationRadiusMeters => $composableBuilder(
      column: $table.locationRadiusMeters, builder: (column) => column);

  GeneratedColumn<String> get locationPlaceLabel => $composableBuilder(
      column: $table.locationPlaceLabel, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$RemindersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RemindersTable,
    ReminderRow,
    $$RemindersTableFilterComposer,
    $$RemindersTableOrderingComposer,
    $$RemindersTableAnnotationComposer,
    $$RemindersTableCreateCompanionBuilder,
    $$RemindersTableUpdateCompanionBuilder,
    (ReminderRow, BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow>),
    ReminderRow,
    PrefetchHooks Function()> {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<bool> isDone = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int?> remindAt = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
            Value<String?> customCategoryLabel = const Value.absent(),
            Value<bool> locationTriggerEnabled = const Value.absent(),
            Value<double?> locationLatitude = const Value.absent(),
            Value<double?> locationLongitude = const Value.absent(),
            Value<double> locationRadiusMeters = const Value.absent(),
            Value<String?> locationPlaceLabel = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RemindersCompanion(
            id: id,
            title: title,
            note: note,
            isDone: isDone,
            createdAt: createdAt,
            remindAt: remindAt,
            categoryId: categoryId,
            customCategoryLabel: customCategoryLabel,
            locationTriggerEnabled: locationTriggerEnabled,
            locationLatitude: locationLatitude,
            locationLongitude: locationLongitude,
            locationRadiusMeters: locationRadiusMeters,
            locationPlaceLabel: locationPlaceLabel,
            position: position,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> note = const Value.absent(),
            required bool isDone,
            required int createdAt,
            Value<int?> remindAt = const Value.absent(),
            required String categoryId,
            Value<String?> customCategoryLabel = const Value.absent(),
            required bool locationTriggerEnabled,
            Value<double?> locationLatitude = const Value.absent(),
            Value<double?> locationLongitude = const Value.absent(),
            required double locationRadiusMeters,
            Value<String?> locationPlaceLabel = const Value.absent(),
            required int position,
            required int updatedAt,
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RemindersCompanion.insert(
            id: id,
            title: title,
            note: note,
            isDone: isDone,
            createdAt: createdAt,
            remindAt: remindAt,
            categoryId: categoryId,
            customCategoryLabel: customCategoryLabel,
            locationTriggerEnabled: locationTriggerEnabled,
            locationLatitude: locationLatitude,
            locationLongitude: locationLongitude,
            locationRadiusMeters: locationRadiusMeters,
            locationPlaceLabel: locationPlaceLabel,
            position: position,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$RemindersTable, ReminderRow>(table),
                    BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RemindersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RemindersTable,
    ReminderRow,
    $$RemindersTableFilterComposer,
    $$RemindersTableOrderingComposer,
    $$RemindersTableAnnotationComposer,
    $$RemindersTableCreateCompanionBuilder,
    $$RemindersTableUpdateCompanionBuilder,
    (ReminderRow, BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow>),
    ReminderRow,
    PrefetchHooks Function()>;
typedef $$BirthdaysTableCreateCompanionBuilder = BirthdaysCompanion Function({
  required String id,
  required String name,
  Value<String?> note,
  required String date,
  required int notifyHour,
  required int notifyMinute,
  required String advanceOffsetsMinutes,
  required int createdAt,
  required int position,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$BirthdaysTableUpdateCompanionBuilder = BirthdaysCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> note,
  Value<String> date,
  Value<int> notifyHour,
  Value<int> notifyMinute,
  Value<String> advanceOffsetsMinutes,
  Value<int> createdAt,
  Value<int> position,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $$BirthdaysTableFilterComposer
    extends Composer<_$AppDatabase, $BirthdaysTable> {
  $$BirthdaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get notifyHour => $composableBuilder(
      column: $table.notifyHour, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get notifyMinute => $composableBuilder(
      column: $table.notifyMinute, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get advanceOffsetsMinutes => $composableBuilder(
      column: $table.advanceOffsetsMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$BirthdaysTableOrderingComposer
    extends Composer<_$AppDatabase, $BirthdaysTable> {
  $$BirthdaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get notifyHour => $composableBuilder(
      column: $table.notifyHour, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get notifyMinute => $composableBuilder(
      column: $table.notifyMinute,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get advanceOffsetsMinutes => $composableBuilder(
      column: $table.advanceOffsetsMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$BirthdaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $BirthdaysTable> {
  $$BirthdaysTableAnnotationComposer({
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

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get notifyHour => $composableBuilder(
      column: $table.notifyHour, builder: (column) => column);

  GeneratedColumn<int> get notifyMinute => $composableBuilder(
      column: $table.notifyMinute, builder: (column) => column);

  GeneratedColumn<String> get advanceOffsetsMinutes => $composableBuilder(
      column: $table.advanceOffsetsMinutes, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$BirthdaysTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BirthdaysTable,
    BirthdayRow,
    $$BirthdaysTableFilterComposer,
    $$BirthdaysTableOrderingComposer,
    $$BirthdaysTableAnnotationComposer,
    $$BirthdaysTableCreateCompanionBuilder,
    $$BirthdaysTableUpdateCompanionBuilder,
    (BirthdayRow, BaseReferences<_$AppDatabase, $BirthdaysTable, BirthdayRow>),
    BirthdayRow,
    PrefetchHooks Function()> {
  $$BirthdaysTableTableManager(_$AppDatabase db, $BirthdaysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BirthdaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BirthdaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BirthdaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<int> notifyHour = const Value.absent(),
            Value<int> notifyMinute = const Value.absent(),
            Value<String> advanceOffsetsMinutes = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BirthdaysCompanion(
            id: id,
            name: name,
            note: note,
            date: date,
            notifyHour: notifyHour,
            notifyMinute: notifyMinute,
            advanceOffsetsMinutes: advanceOffsetsMinutes,
            createdAt: createdAt,
            position: position,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> note = const Value.absent(),
            required String date,
            required int notifyHour,
            required int notifyMinute,
            required String advanceOffsetsMinutes,
            required int createdAt,
            required int position,
            required int updatedAt,
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BirthdaysCompanion.insert(
            id: id,
            name: name,
            note: note,
            date: date,
            notifyHour: notifyHour,
            notifyMinute: notifyMinute,
            advanceOffsetsMinutes: advanceOffsetsMinutes,
            createdAt: createdAt,
            position: position,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$BirthdaysTable, BirthdayRow>(table),
                    BaseReferences<_$AppDatabase, $BirthdaysTable, BirthdayRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BirthdaysTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BirthdaysTable,
    BirthdayRow,
    $$BirthdaysTableFilterComposer,
    $$BirthdaysTableOrderingComposer,
    $$BirthdaysTableAnnotationComposer,
    $$BirthdaysTableCreateCompanionBuilder,
    $$BirthdaysTableUpdateCompanionBuilder,
    (BirthdayRow, BaseReferences<_$AppDatabase, $BirthdaysTable, BirthdayRow>),
    BirthdayRow,
    PrefetchHooks Function()>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  required bool notificationsEnabled,
  required String themeMode,
  required int updatedAt,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<bool> notificationsEnabled,
  Value<String> themeMode,
  Value<int> updatedAt,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get themeMode => $composableBuilder(
      column: $table.themeMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get themeMode => $composableBuilder(
      column: $table.themeMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get notificationsEnabled => $composableBuilder(
      column: $table.notificationsEnabled, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    SettingsRow,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (SettingsRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingsRow>),
    SettingsRow,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<bool> notificationsEnabled = const Value.absent(),
            Value<String> themeMode = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
          }) =>
              SettingsCompanion(
            id: id,
            notificationsEnabled: notificationsEnabled,
            themeMode: themeMode,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required bool notificationsEnabled,
            required String themeMode,
            required int updatedAt,
          }) =>
              SettingsCompanion.insert(
            id: id,
            notificationsEnabled: notificationsEnabled,
            themeMode: themeMode,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SettingsTable, SettingsRow>(table),
                    BaseReferences<_$AppDatabase, $SettingsTable, SettingsRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    SettingsRow,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (SettingsRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingsRow>),
    SettingsRow,
    PrefetchHooks Function()>;
typedef $$AppMetaTableCreateCompanionBuilder = AppMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppMetaTableUpdateCompanionBuilder = AppMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppMetaTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$AppMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$AppMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppMetaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppMetaTable,
    AppMetaRow,
    $$AppMetaTableFilterComposer,
    $$AppMetaTableOrderingComposer,
    $$AppMetaTableAnnotationComposer,
    $$AppMetaTableCreateCompanionBuilder,
    $$AppMetaTableUpdateCompanionBuilder,
    (AppMetaRow, BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaRow>),
    AppMetaRow,
    PrefetchHooks Function()> {
  $$AppMetaTableTableManager(_$AppDatabase db, $AppMetaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppMetaCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppMetaCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$AppMetaTable, AppMetaRow>(table),
                    BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaRow>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppMetaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppMetaTable,
    AppMetaRow,
    $$AppMetaTableFilterComposer,
    $$AppMetaTableOrderingComposer,
    $$AppMetaTableAnnotationComposer,
    $$AppMetaTableCreateCompanionBuilder,
    $$AppMetaTableUpdateCompanionBuilder,
    (AppMetaRow, BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaRow>),
    AppMetaRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$BirthdaysTableTableManager get birthdays =>
      $$BirthdaysTableTableManager(_db, _db.birthdays);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
}
