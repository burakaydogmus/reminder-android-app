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
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remindAtMeta =
      const VerificationMeta('remindAt');
  @override
  late final GeneratedColumn<String> remindAt = GeneratedColumn<String>(
      'remind_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  static const VerificationMeta _recurrenceMeta =
      const VerificationMeta('recurrence');
  @override
  late final GeneratedColumn<String> recurrence = GeneratedColumn<String>(
      'recurrence', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
      'pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _routineIdMeta =
      const VerificationMeta('routineId');
  @override
  late final GeneratedColumn<String> routineId = GeneratedColumn<String>(
      'routine_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _routineItemIdMeta =
      const VerificationMeta('routineItemId');
  @override
  late final GeneratedColumn<String> routineItemId = GeneratedColumn<String>(
      'routine_item_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
        deletedAt,
        recurrence,
        priority,
        pinned,
        routineId,
        routineItemId
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
    if (data.containsKey('recurrence')) {
      context.handle(
          _recurrenceMeta,
          recurrence.isAcceptableOrUnknown(
              data['recurrence']!, _recurrenceMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('pinned')) {
      context.handle(_pinnedMeta,
          pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta));
    }
    if (data.containsKey('routine_id')) {
      context.handle(_routineIdMeta,
          routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta));
    }
    if (data.containsKey('routine_item_id')) {
      context.handle(
          _routineItemIdMeta,
          routineItemId.isAcceptableOrUnknown(
              data['routine_item_id']!, _routineItemIdMeta));
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
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      remindAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remind_at']),
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
      recurrence: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recurrence']),
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      pinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pinned'])!,
      routineId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}routine_id']),
      routineItemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}routine_item_id']),
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
  final String createdAt;
  final String? remindAt;
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

  /// Tekrar kuralı (v2, F3.1): `RecurrenceRule.toJson()` JSON metni;
  /// `NULL` = tekrar yok (v1 satırları).
  final String? recurrence;

  /// Öncelik (v4, F3.4): 0 yok … 3 yüksek (`ReminderPriority`). Eski
  /// satırlar 0 alır.
  final int priority;

  /// Sabitlenmiş (v4, F3.4). Eski satırlar `false` alır.
  final bool pinned;

  /// Bu hatırlatıcıyı oluşturan rutin (v7, F3.7); elle oluşturulanlarda NULL.
  ///
  /// **Yabancı anahtar değildir** (kategori kimliği gibi gevşek bağ): yedekten
  /// geri yükleme hatırlatıcıları rutinlerden ayrı transaction'da yazar ve
  /// eski bir yedekte rutin hiç olmayabilir; kısıtlama koyulsa böyle bir içe
  /// aktarma tamamen başarısız olurdu. Bilinmeyen kimlik yalnızca bağın kaybı
  /// demektir.
  final String? routineId;

  /// Hatırlatıcıyı oluşturan rutin adımı (v7, F3.7); [routineId] ile birlikte
  /// "bu adım zaten uygulanmış" denetimini kesinleştirir.
  final String? routineItemId;
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
      this.deletedAt,
      this.recurrence,
      required this.priority,
      required this.pinned,
      this.routineId,
      this.routineItemId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['is_done'] = Variable<bool>(isDone);
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || remindAt != null) {
      map['remind_at'] = Variable<String>(remindAt);
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
    if (!nullToAbsent || recurrence != null) {
      map['recurrence'] = Variable<String>(recurrence);
    }
    map['priority'] = Variable<int>(priority);
    map['pinned'] = Variable<bool>(pinned);
    if (!nullToAbsent || routineId != null) {
      map['routine_id'] = Variable<String>(routineId);
    }
    if (!nullToAbsent || routineItemId != null) {
      map['routine_item_id'] = Variable<String>(routineItemId);
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
      recurrence: recurrence == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrence),
      priority: Value(priority),
      pinned: Value(pinned),
      routineId: routineId == null && nullToAbsent
          ? const Value.absent()
          : Value(routineId),
      routineItemId: routineItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(routineItemId),
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
      createdAt: serializer.fromJson<String>(json['createdAt']),
      remindAt: serializer.fromJson<String?>(json['remindAt']),
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
      recurrence: serializer.fromJson<String?>(json['recurrence']),
      priority: serializer.fromJson<int>(json['priority']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      routineId: serializer.fromJson<String?>(json['routineId']),
      routineItemId: serializer.fromJson<String?>(json['routineItemId']),
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
      'createdAt': serializer.toJson<String>(createdAt),
      'remindAt': serializer.toJson<String?>(remindAt),
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
      'recurrence': serializer.toJson<String?>(recurrence),
      'priority': serializer.toJson<int>(priority),
      'pinned': serializer.toJson<bool>(pinned),
      'routineId': serializer.toJson<String?>(routineId),
      'routineItemId': serializer.toJson<String?>(routineItemId),
    };
  }

  ReminderRow copyWith(
          {String? id,
          String? title,
          Value<String?> note = const Value.absent(),
          bool? isDone,
          String? createdAt,
          Value<String?> remindAt = const Value.absent(),
          String? categoryId,
          Value<String?> customCategoryLabel = const Value.absent(),
          bool? locationTriggerEnabled,
          Value<double?> locationLatitude = const Value.absent(),
          Value<double?> locationLongitude = const Value.absent(),
          double? locationRadiusMeters,
          Value<String?> locationPlaceLabel = const Value.absent(),
          int? position,
          int? updatedAt,
          Value<int?> deletedAt = const Value.absent(),
          Value<String?> recurrence = const Value.absent(),
          int? priority,
          bool? pinned,
          Value<String?> routineId = const Value.absent(),
          Value<String?> routineItemId = const Value.absent()}) =>
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
        recurrence: recurrence.present ? recurrence.value : this.recurrence,
        priority: priority ?? this.priority,
        pinned: pinned ?? this.pinned,
        routineId: routineId.present ? routineId.value : this.routineId,
        routineItemId:
            routineItemId.present ? routineItemId.value : this.routineItemId,
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
      recurrence:
          data.recurrence.present ? data.recurrence.value : this.recurrence,
      priority: data.priority.present ? data.priority.value : this.priority,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      routineItemId: data.routineItemId.present
          ? data.routineItemId.value
          : this.routineItemId,
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
          ..write('deletedAt: $deletedAt, ')
          ..write('recurrence: $recurrence, ')
          ..write('priority: $priority, ')
          ..write('pinned: $pinned, ')
          ..write('routineId: $routineId, ')
          ..write('routineItemId: $routineItemId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
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
        deletedAt,
        recurrence,
        priority,
        pinned,
        routineId,
        routineItemId
      ]);
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
          other.deletedAt == this.deletedAt &&
          other.recurrence == this.recurrence &&
          other.priority == this.priority &&
          other.pinned == this.pinned &&
          other.routineId == this.routineId &&
          other.routineItemId == this.routineItemId);
}

class RemindersCompanion extends UpdateCompanion<ReminderRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> note;
  final Value<bool> isDone;
  final Value<String> createdAt;
  final Value<String?> remindAt;
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
  final Value<String?> recurrence;
  final Value<int> priority;
  final Value<bool> pinned;
  final Value<String?> routineId;
  final Value<String?> routineItemId;
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
    this.recurrence = const Value.absent(),
    this.priority = const Value.absent(),
    this.pinned = const Value.absent(),
    this.routineId = const Value.absent(),
    this.routineItemId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    required String title,
    this.note = const Value.absent(),
    required bool isDone,
    required String createdAt,
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
    this.recurrence = const Value.absent(),
    this.priority = const Value.absent(),
    this.pinned = const Value.absent(),
    this.routineId = const Value.absent(),
    this.routineItemId = const Value.absent(),
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
    Expression<String>? createdAt,
    Expression<String>? remindAt,
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
    Expression<String>? recurrence,
    Expression<int>? priority,
    Expression<bool>? pinned,
    Expression<String>? routineId,
    Expression<String>? routineItemId,
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
      if (recurrence != null) 'recurrence': recurrence,
      if (priority != null) 'priority': priority,
      if (pinned != null) 'pinned': pinned,
      if (routineId != null) 'routine_id': routineId,
      if (routineItemId != null) 'routine_item_id': routineItemId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? note,
      Value<bool>? isDone,
      Value<String>? createdAt,
      Value<String?>? remindAt,
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
      Value<String?>? recurrence,
      Value<int>? priority,
      Value<bool>? pinned,
      Value<String?>? routineId,
      Value<String?>? routineItemId,
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
      recurrence: recurrence ?? this.recurrence,
      priority: priority ?? this.priority,
      pinned: pinned ?? this.pinned,
      routineId: routineId ?? this.routineId,
      routineItemId: routineItemId ?? this.routineItemId,
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
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (remindAt.present) {
      map['remind_at'] = Variable<String>(remindAt.value);
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
    if (recurrence.present) {
      map['recurrence'] = Variable<String>(recurrence.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (routineId.present) {
      map['routine_id'] = Variable<String>(routineId.value);
    }
    if (routineItemId.present) {
      map['routine_item_id'] = Variable<String>(routineItemId.value);
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
          ..write('recurrence: $recurrence, ')
          ..write('priority: $priority, ')
          ..write('pinned: $pinned, ')
          ..write('routineId: $routineId, ')
          ..write('routineItemId: $routineItemId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubtasksTable extends Subtasks
    with TableInfo<$SubtasksTable, SubtaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubtasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _reminderIdMeta =
      const VerificationMeta('reminderId');
  @override
  late final GeneratedColumn<String> reminderId = GeneratedColumn<String>(
      'reminder_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES reminders (id)'));
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
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
      'is_done', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_done" IN (0, 1))'));
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
  List<GeneratedColumn> get $columns =>
      [reminderId, id, title, isDone, position, updatedAt, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subtasks';
  @override
  VerificationContext validateIntegrity(Insertable<SubtaskRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('reminder_id')) {
      context.handle(
          _reminderIdMeta,
          reminderId.isAcceptableOrUnknown(
              data['reminder_id']!, _reminderIdMeta));
    } else if (isInserting) {
      context.missing(_reminderIdMeta);
    }
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
    if (data.containsKey('is_done')) {
      context.handle(_isDoneMeta,
          isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta));
    } else if (isInserting) {
      context.missing(_isDoneMeta);
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
  Set<GeneratedColumn> get $primaryKey => {reminderId, id};
  @override
  SubtaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubtaskRow(
      reminderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reminder_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      isDone: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_done'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $SubtasksTable createAlias(String alias) {
    return $SubtasksTable(attachedDatabase, alias);
  }
}

class SubtaskRow extends DataClass implements Insertable<SubtaskRow> {
  final String reminderId;
  final String id;
  final String title;
  final bool isDone;
  final int position;
  final int updatedAt;
  final int? deletedAt;
  const SubtaskRow(
      {required this.reminderId,
      required this.id,
      required this.title,
      required this.isDone,
      required this.position,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['reminder_id'] = Variable<String>(reminderId);
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['is_done'] = Variable<bool>(isDone);
    map['position'] = Variable<int>(position);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  SubtasksCompanion toCompanion(bool nullToAbsent) {
    return SubtasksCompanion(
      reminderId: Value(reminderId),
      id: Value(id),
      title: Value(title),
      isDone: Value(isDone),
      position: Value(position),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory SubtaskRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubtaskRow(
      reminderId: serializer.fromJson<String>(json['reminderId']),
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      position: serializer.fromJson<int>(json['position']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'reminderId': serializer.toJson<String>(reminderId),
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'isDone': serializer.toJson<bool>(isDone),
      'position': serializer.toJson<int>(position),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  SubtaskRow copyWith(
          {String? reminderId,
          String? id,
          String? title,
          bool? isDone,
          int? position,
          int? updatedAt,
          Value<int?> deletedAt = const Value.absent()}) =>
      SubtaskRow(
        reminderId: reminderId ?? this.reminderId,
        id: id ?? this.id,
        title: title ?? this.title,
        isDone: isDone ?? this.isDone,
        position: position ?? this.position,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  SubtaskRow copyWithCompanion(SubtasksCompanion data) {
    return SubtaskRow(
      reminderId:
          data.reminderId.present ? data.reminderId.value : this.reminderId,
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      position: data.position.present ? data.position.value : this.position,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubtaskRow(')
          ..write('reminderId: $reminderId, ')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('isDone: $isDone, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      reminderId, id, title, isDone, position, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubtaskRow &&
          other.reminderId == this.reminderId &&
          other.id == this.id &&
          other.title == this.title &&
          other.isDone == this.isDone &&
          other.position == this.position &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SubtasksCompanion extends UpdateCompanion<SubtaskRow> {
  final Value<String> reminderId;
  final Value<String> id;
  final Value<String> title;
  final Value<bool> isDone;
  final Value<int> position;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const SubtasksCompanion({
    this.reminderId = const Value.absent(),
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.isDone = const Value.absent(),
    this.position = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubtasksCompanion.insert({
    required String reminderId,
    required String id,
    required String title,
    required bool isDone,
    required int position,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : reminderId = Value(reminderId),
        id = Value(id),
        title = Value(title),
        isDone = Value(isDone),
        position = Value(position),
        updatedAt = Value(updatedAt);
  static Insertable<SubtaskRow> custom({
    Expression<String>? reminderId,
    Expression<String>? id,
    Expression<String>? title,
    Expression<bool>? isDone,
    Expression<int>? position,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (reminderId != null) 'reminder_id': reminderId,
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (isDone != null) 'is_done': isDone,
      if (position != null) 'position': position,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubtasksCompanion copyWith(
      {Value<String>? reminderId,
      Value<String>? id,
      Value<String>? title,
      Value<bool>? isDone,
      Value<int>? position,
      Value<int>? updatedAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return SubtasksCompanion(
      reminderId: reminderId ?? this.reminderId,
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      position: position ?? this.position,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (reminderId.present) {
      map['reminder_id'] = Variable<String>(reminderId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
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
    return (StringBuffer('SubtasksCompanion(')
          ..write('reminderId: $reminderId, ')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('isDone: $isDone, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _colorKeyMeta =
      const VerificationMeta('colorKey');
  @override
  late final GeneratedColumn<String> colorKey = GeneratedColumn<String>(
      'color_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconKeyMeta =
      const VerificationMeta('iconKey');
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
      'icon_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
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
  List<GeneratedColumn> get $columns =>
      [id, name, colorKey, iconKey, position, updatedAt, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<CategoryRow> instance,
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
    if (data.containsKey('color_key')) {
      context.handle(_colorKeyMeta,
          colorKey.isAcceptableOrUnknown(data['color_key']!, _colorKeyMeta));
    } else if (isInserting) {
      context.missing(_colorKeyMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(_iconKeyMeta,
          iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta));
    } else if (isInserting) {
      context.missing(_iconKeyMeta);
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
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      colorKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_key'])!,
      iconKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_key'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String name;
  final String colorKey;
  final String iconKey;
  final int position;
  final int updatedAt;
  final int? deletedAt;
  const CategoryRow(
      {required this.id,
      required this.name,
      required this.colorKey,
      required this.iconKey,
      required this.position,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color_key'] = Variable<String>(colorKey);
    map['icon_key'] = Variable<String>(iconKey);
    map['position'] = Variable<int>(position);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      colorKey: Value(colorKey),
      iconKey: Value(iconKey),
      position: Value(position),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory CategoryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorKey: serializer.fromJson<String>(json['colorKey']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
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
      'colorKey': serializer.toJson<String>(colorKey),
      'iconKey': serializer.toJson<String>(iconKey),
      'position': serializer.toJson<int>(position),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  CategoryRow copyWith(
          {String? id,
          String? name,
          String? colorKey,
          String? iconKey,
          int? position,
          int? updatedAt,
          Value<int?> deletedAt = const Value.absent()}) =>
      CategoryRow(
        id: id ?? this.id,
        name: name ?? this.name,
        colorKey: colorKey ?? this.colorKey,
        iconKey: iconKey ?? this.iconKey,
        position: position ?? this.position,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorKey: data.colorKey.present ? data.colorKey.value : this.colorKey,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      position: data.position.present ? data.position.value : this.position,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorKey: $colorKey, ')
          ..write('iconKey: $iconKey, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, colorKey, iconKey, position, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorKey == this.colorKey &&
          other.iconKey == this.iconKey &&
          other.position == this.position &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> colorKey;
  final Value<String> iconKey;
  final Value<int> position;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorKey = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.position = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    required String colorKey,
    required String iconKey,
    required int position,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        colorKey = Value(colorKey),
        iconKey = Value(iconKey),
        position = Value(position),
        updatedAt = Value(updatedAt);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? colorKey,
    Expression<String>? iconKey,
    Expression<int>? position,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorKey != null) 'color_key': colorKey,
      if (iconKey != null) 'icon_key': iconKey,
      if (position != null) 'position': position,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? colorKey,
      Value<String>? iconKey,
      Value<int>? position,
      Value<int>? updatedAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorKey: colorKey ?? this.colorKey,
      iconKey: iconKey ?? this.iconKey,
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
    if (colorKey.present) {
      map['color_key'] = Variable<String>(colorKey.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
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
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorKey: $colorKey, ')
          ..write('iconKey: $iconKey, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoutinesTable extends Routines
    with TableInfo<$RoutinesTable, RoutineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutinesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _colorKeyMeta =
      const VerificationMeta('colorKey');
  @override
  late final GeneratedColumn<String> colorKey = GeneratedColumn<String>(
      'color_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _iconKeyMeta =
      const VerificationMeta('iconKey');
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
      'icon_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _repeatRuleMeta =
      const VerificationMeta('repeatRule');
  @override
  late final GeneratedColumn<String> repeatRule = GeneratedColumn<String>(
      'repeat_rule', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
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
        colorKey,
        iconKey,
        repeatRule,
        createdAt,
        position,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routines';
  @override
  VerificationContext validateIntegrity(Insertable<RoutineRow> instance,
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
    if (data.containsKey('color_key')) {
      context.handle(_colorKeyMeta,
          colorKey.isAcceptableOrUnknown(data['color_key']!, _colorKeyMeta));
    }
    if (data.containsKey('icon_key')) {
      context.handle(_iconKeyMeta,
          iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta));
    }
    if (data.containsKey('repeat_rule')) {
      context.handle(
          _repeatRuleMeta,
          repeatRule.isAcceptableOrUnknown(
              data['repeat_rule']!, _repeatRuleMeta));
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
  RoutineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutineRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      colorKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_key']),
      iconKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_key']),
      repeatRule: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}repeat_rule']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $RoutinesTable createAlias(String alias) {
    return $RoutinesTable(attachedDatabase, alias);
  }
}

class RoutineRow extends DataClass implements Insertable<RoutineRow> {
  final String id;
  final String name;
  final String? colorKey;
  final String? iconKey;

  /// Otomatik uygulama kuralı (`RecurrenceRule.toJson()`); `NULL` = tekrar yok.
  final String? repeatRule;
  final String createdAt;
  final int position;
  final int updatedAt;
  final int? deletedAt;
  const RoutineRow(
      {required this.id,
      required this.name,
      this.colorKey,
      this.iconKey,
      this.repeatRule,
      required this.createdAt,
      required this.position,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || colorKey != null) {
      map['color_key'] = Variable<String>(colorKey);
    }
    if (!nullToAbsent || iconKey != null) {
      map['icon_key'] = Variable<String>(iconKey);
    }
    if (!nullToAbsent || repeatRule != null) {
      map['repeat_rule'] = Variable<String>(repeatRule);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['position'] = Variable<int>(position);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  RoutinesCompanion toCompanion(bool nullToAbsent) {
    return RoutinesCompanion(
      id: Value(id),
      name: Value(name),
      colorKey: colorKey == null && nullToAbsent
          ? const Value.absent()
          : Value(colorKey),
      iconKey: iconKey == null && nullToAbsent
          ? const Value.absent()
          : Value(iconKey),
      repeatRule: repeatRule == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatRule),
      createdAt: Value(createdAt),
      position: Value(position),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory RoutineRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorKey: serializer.fromJson<String?>(json['colorKey']),
      iconKey: serializer.fromJson<String?>(json['iconKey']),
      repeatRule: serializer.fromJson<String?>(json['repeatRule']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
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
      'colorKey': serializer.toJson<String?>(colorKey),
      'iconKey': serializer.toJson<String?>(iconKey),
      'repeatRule': serializer.toJson<String?>(repeatRule),
      'createdAt': serializer.toJson<String>(createdAt),
      'position': serializer.toJson<int>(position),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  RoutineRow copyWith(
          {String? id,
          String? name,
          Value<String?> colorKey = const Value.absent(),
          Value<String?> iconKey = const Value.absent(),
          Value<String?> repeatRule = const Value.absent(),
          String? createdAt,
          int? position,
          int? updatedAt,
          Value<int?> deletedAt = const Value.absent()}) =>
      RoutineRow(
        id: id ?? this.id,
        name: name ?? this.name,
        colorKey: colorKey.present ? colorKey.value : this.colorKey,
        iconKey: iconKey.present ? iconKey.value : this.iconKey,
        repeatRule: repeatRule.present ? repeatRule.value : this.repeatRule,
        createdAt: createdAt ?? this.createdAt,
        position: position ?? this.position,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  RoutineRow copyWithCompanion(RoutinesCompanion data) {
    return RoutineRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorKey: data.colorKey.present ? data.colorKey.value : this.colorKey,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      repeatRule:
          data.repeatRule.present ? data.repeatRule.value : this.repeatRule,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      position: data.position.present ? data.position.value : this.position,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorKey: $colorKey, ')
          ..write('iconKey: $iconKey, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('createdAt: $createdAt, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorKey, iconKey, repeatRule,
      createdAt, position, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutineRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorKey == this.colorKey &&
          other.iconKey == this.iconKey &&
          other.repeatRule == this.repeatRule &&
          other.createdAt == this.createdAt &&
          other.position == this.position &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class RoutinesCompanion extends UpdateCompanion<RoutineRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> colorKey;
  final Value<String?> iconKey;
  final Value<String?> repeatRule;
  final Value<String> createdAt;
  final Value<int> position;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const RoutinesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorKey = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.position = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoutinesCompanion.insert({
    required String id,
    required String name,
    this.colorKey = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.repeatRule = const Value.absent(),
    required String createdAt,
    required int position,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        position = Value(position),
        updatedAt = Value(updatedAt);
  static Insertable<RoutineRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? colorKey,
    Expression<String>? iconKey,
    Expression<String>? repeatRule,
    Expression<String>? createdAt,
    Expression<int>? position,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorKey != null) 'color_key': colorKey,
      if (iconKey != null) 'icon_key': iconKey,
      if (repeatRule != null) 'repeat_rule': repeatRule,
      if (createdAt != null) 'created_at': createdAt,
      if (position != null) 'position': position,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoutinesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? colorKey,
      Value<String?>? iconKey,
      Value<String?>? repeatRule,
      Value<String>? createdAt,
      Value<int>? position,
      Value<int>? updatedAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return RoutinesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorKey: colorKey ?? this.colorKey,
      iconKey: iconKey ?? this.iconKey,
      repeatRule: repeatRule ?? this.repeatRule,
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
    if (colorKey.present) {
      map['color_key'] = Variable<String>(colorKey.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (repeatRule.present) {
      map['repeat_rule'] = Variable<String>(repeatRule.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
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
    return (StringBuffer('RoutinesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorKey: $colorKey, ')
          ..write('iconKey: $iconKey, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('createdAt: $createdAt, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoutineItemsTable extends RoutineItems
    with TableInfo<$RoutineItemsTable, RoutineItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutineItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _routineIdMeta =
      const VerificationMeta('routineId');
  @override
  late final GeneratedColumn<String> routineId = GeneratedColumn<String>(
      'routine_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES routines (id)'));
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
  static const VerificationMeta _timeOfDayMeta =
      const VerificationMeta('timeOfDay');
  @override
  late final GeneratedColumn<String> timeOfDay = GeneratedColumn<String>(
      'time_of_day', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _subtasksMeta =
      const VerificationMeta('subtasks');
  @override
  late final GeneratedColumn<String> subtasks = GeneratedColumn<String>(
      'subtasks', aliasedName, true,
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
        routineId,
        id,
        title,
        timeOfDay,
        categoryId,
        priority,
        subtasks,
        position,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routine_items';
  @override
  VerificationContext validateIntegrity(Insertable<RoutineItemRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('routine_id')) {
      context.handle(_routineIdMeta,
          routineId.isAcceptableOrUnknown(data['routine_id']!, _routineIdMeta));
    } else if (isInserting) {
      context.missing(_routineIdMeta);
    }
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
    if (data.containsKey('time_of_day')) {
      context.handle(
          _timeOfDayMeta,
          timeOfDay.isAcceptableOrUnknown(
              data['time_of_day']!, _timeOfDayMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('subtasks')) {
      context.handle(_subtasksMeta,
          subtasks.isAcceptableOrUnknown(data['subtasks']!, _subtasksMeta));
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
  Set<GeneratedColumn> get $primaryKey => {routineId, id};
  @override
  RoutineItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutineItemRow(
      routineId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}routine_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      timeOfDay: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}time_of_day']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      subtasks: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subtasks']),
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $RoutineItemsTable createAlias(String alias) {
    return $RoutineItemsTable(attachedDatabase, alias);
  }
}

class RoutineItemRow extends DataClass implements Insertable<RoutineItemRow> {
  final String routineId;
  final String id;
  final String title;

  /// Günün saati, `HH:MM`; NULL = saatsiz adım.
  final String? timeOfDay;
  final String categoryId;
  final int priority;

  /// Şablon maddeleri, JSON dizi metni; NULL = madde yok.
  final String? subtasks;
  final int position;
  final int updatedAt;
  final int? deletedAt;
  const RoutineItemRow(
      {required this.routineId,
      required this.id,
      required this.title,
      this.timeOfDay,
      required this.categoryId,
      required this.priority,
      this.subtasks,
      required this.position,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['routine_id'] = Variable<String>(routineId);
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || timeOfDay != null) {
      map['time_of_day'] = Variable<String>(timeOfDay);
    }
    map['category_id'] = Variable<String>(categoryId);
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || subtasks != null) {
      map['subtasks'] = Variable<String>(subtasks);
    }
    map['position'] = Variable<int>(position);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  RoutineItemsCompanion toCompanion(bool nullToAbsent) {
    return RoutineItemsCompanion(
      routineId: Value(routineId),
      id: Value(id),
      title: Value(title),
      timeOfDay: timeOfDay == null && nullToAbsent
          ? const Value.absent()
          : Value(timeOfDay),
      categoryId: Value(categoryId),
      priority: Value(priority),
      subtasks: subtasks == null && nullToAbsent
          ? const Value.absent()
          : Value(subtasks),
      position: Value(position),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory RoutineItemRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineItemRow(
      routineId: serializer.fromJson<String>(json['routineId']),
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      timeOfDay: serializer.fromJson<String?>(json['timeOfDay']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      priority: serializer.fromJson<int>(json['priority']),
      subtasks: serializer.fromJson<String?>(json['subtasks']),
      position: serializer.fromJson<int>(json['position']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'routineId': serializer.toJson<String>(routineId),
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'timeOfDay': serializer.toJson<String?>(timeOfDay),
      'categoryId': serializer.toJson<String>(categoryId),
      'priority': serializer.toJson<int>(priority),
      'subtasks': serializer.toJson<String?>(subtasks),
      'position': serializer.toJson<int>(position),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  RoutineItemRow copyWith(
          {String? routineId,
          String? id,
          String? title,
          Value<String?> timeOfDay = const Value.absent(),
          String? categoryId,
          int? priority,
          Value<String?> subtasks = const Value.absent(),
          int? position,
          int? updatedAt,
          Value<int?> deletedAt = const Value.absent()}) =>
      RoutineItemRow(
        routineId: routineId ?? this.routineId,
        id: id ?? this.id,
        title: title ?? this.title,
        timeOfDay: timeOfDay.present ? timeOfDay.value : this.timeOfDay,
        categoryId: categoryId ?? this.categoryId,
        priority: priority ?? this.priority,
        subtasks: subtasks.present ? subtasks.value : this.subtasks,
        position: position ?? this.position,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  RoutineItemRow copyWithCompanion(RoutineItemsCompanion data) {
    return RoutineItemRow(
      routineId: data.routineId.present ? data.routineId.value : this.routineId,
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      timeOfDay: data.timeOfDay.present ? data.timeOfDay.value : this.timeOfDay,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      priority: data.priority.present ? data.priority.value : this.priority,
      subtasks: data.subtasks.present ? data.subtasks.value : this.subtasks,
      position: data.position.present ? data.position.value : this.position,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineItemRow(')
          ..write('routineId: $routineId, ')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('categoryId: $categoryId, ')
          ..write('priority: $priority, ')
          ..write('subtasks: $subtasks, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(routineId, id, title, timeOfDay, categoryId,
      priority, subtasks, position, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutineItemRow &&
          other.routineId == this.routineId &&
          other.id == this.id &&
          other.title == this.title &&
          other.timeOfDay == this.timeOfDay &&
          other.categoryId == this.categoryId &&
          other.priority == this.priority &&
          other.subtasks == this.subtasks &&
          other.position == this.position &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class RoutineItemsCompanion extends UpdateCompanion<RoutineItemRow> {
  final Value<String> routineId;
  final Value<String> id;
  final Value<String> title;
  final Value<String?> timeOfDay;
  final Value<String> categoryId;
  final Value<int> priority;
  final Value<String?> subtasks;
  final Value<int> position;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const RoutineItemsCompanion({
    this.routineId = const Value.absent(),
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.priority = const Value.absent(),
    this.subtasks = const Value.absent(),
    this.position = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoutineItemsCompanion.insert({
    required String routineId,
    required String id,
    required String title,
    this.timeOfDay = const Value.absent(),
    required String categoryId,
    this.priority = const Value.absent(),
    this.subtasks = const Value.absent(),
    required int position,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : routineId = Value(routineId),
        id = Value(id),
        title = Value(title),
        categoryId = Value(categoryId),
        position = Value(position),
        updatedAt = Value(updatedAt);
  static Insertable<RoutineItemRow> custom({
    Expression<String>? routineId,
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? timeOfDay,
    Expression<String>? categoryId,
    Expression<int>? priority,
    Expression<String>? subtasks,
    Expression<int>? position,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (routineId != null) 'routine_id': routineId,
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (categoryId != null) 'category_id': categoryId,
      if (priority != null) 'priority': priority,
      if (subtasks != null) 'subtasks': subtasks,
      if (position != null) 'position': position,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoutineItemsCompanion copyWith(
      {Value<String>? routineId,
      Value<String>? id,
      Value<String>? title,
      Value<String?>? timeOfDay,
      Value<String>? categoryId,
      Value<int>? priority,
      Value<String?>? subtasks,
      Value<int>? position,
      Value<int>? updatedAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return RoutineItemsCompanion(
      routineId: routineId ?? this.routineId,
      id: id ?? this.id,
      title: title ?? this.title,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      subtasks: subtasks ?? this.subtasks,
      position: position ?? this.position,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (routineId.present) {
      map['routine_id'] = Variable<String>(routineId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (timeOfDay.present) {
      map['time_of_day'] = Variable<String>(timeOfDay.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (subtasks.present) {
      map['subtasks'] = Variable<String>(subtasks.value);
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
    return (StringBuffer('RoutineItemsCompanion(')
          ..write('routineId: $routineId, ')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('categoryId: $categoryId, ')
          ..write('priority: $priority, ')
          ..write('subtasks: $subtasks, ')
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
  static const VerificationMeta _birthMonthMeta =
      const VerificationMeta('birthMonth');
  @override
  late final GeneratedColumn<int> birthMonth = GeneratedColumn<int>(
      'birth_month', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _birthDayMeta =
      const VerificationMeta('birthDay');
  @override
  late final GeneratedColumn<int> birthDay = GeneratedColumn<int>(
      'birth_day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _birthYearMeta =
      const VerificationMeta('birthYear');
  @override
  late final GeneratedColumn<int> birthYear = GeneratedColumn<int>(
      'birth_year', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
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
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
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
        birthMonth,
        birthDay,
        birthYear,
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
    if (data.containsKey('birth_month')) {
      context.handle(
          _birthMonthMeta,
          birthMonth.isAcceptableOrUnknown(
              data['birth_month']!, _birthMonthMeta));
    } else if (isInserting) {
      context.missing(_birthMonthMeta);
    }
    if (data.containsKey('birth_day')) {
      context.handle(_birthDayMeta,
          birthDay.isAcceptableOrUnknown(data['birth_day']!, _birthDayMeta));
    } else if (isInserting) {
      context.missing(_birthDayMeta);
    }
    if (data.containsKey('birth_year')) {
      context.handle(_birthYearMeta,
          birthYear.isAcceptableOrUnknown(data['birth_year']!, _birthYearMeta));
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
      birthMonth: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}birth_month'])!,
      birthDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}birth_day'])!,
      birthYear: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}birth_year']),
      notifyHour: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}notify_hour'])!,
      notifyMinute: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}notify_minute'])!,
      advanceOffsetsMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}advance_offsets_minutes'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
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

  /// Doğum ayı (1–12).
  final int birthMonth;

  /// Ayın günü (1–31).
  final int birthDay;

  /// Doğum yılı; **bilinmiyorsa NULL**.
  final int? birthYear;
  final int notifyHour;
  final int notifyMinute;

  /// Önbildirim dakikaları, JSON dizi metni (örn. `[0,1440]`).
  final String advanceOffsetsMinutes;
  final String createdAt;
  final int position;
  final int updatedAt;
  final int? deletedAt;
  const BirthdayRow(
      {required this.id,
      required this.name,
      this.note,
      required this.birthMonth,
      required this.birthDay,
      this.birthYear,
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
    map['birth_month'] = Variable<int>(birthMonth);
    map['birth_day'] = Variable<int>(birthDay);
    if (!nullToAbsent || birthYear != null) {
      map['birth_year'] = Variable<int>(birthYear);
    }
    map['notify_hour'] = Variable<int>(notifyHour);
    map['notify_minute'] = Variable<int>(notifyMinute);
    map['advance_offsets_minutes'] = Variable<String>(advanceOffsetsMinutes);
    map['created_at'] = Variable<String>(createdAt);
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
      birthMonth: Value(birthMonth),
      birthDay: Value(birthDay),
      birthYear: birthYear == null && nullToAbsent
          ? const Value.absent()
          : Value(birthYear),
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
      birthMonth: serializer.fromJson<int>(json['birthMonth']),
      birthDay: serializer.fromJson<int>(json['birthDay']),
      birthYear: serializer.fromJson<int?>(json['birthYear']),
      notifyHour: serializer.fromJson<int>(json['notifyHour']),
      notifyMinute: serializer.fromJson<int>(json['notifyMinute']),
      advanceOffsetsMinutes:
          serializer.fromJson<String>(json['advanceOffsetsMinutes']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
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
      'birthMonth': serializer.toJson<int>(birthMonth),
      'birthDay': serializer.toJson<int>(birthDay),
      'birthYear': serializer.toJson<int?>(birthYear),
      'notifyHour': serializer.toJson<int>(notifyHour),
      'notifyMinute': serializer.toJson<int>(notifyMinute),
      'advanceOffsetsMinutes': serializer.toJson<String>(advanceOffsetsMinutes),
      'createdAt': serializer.toJson<String>(createdAt),
      'position': serializer.toJson<int>(position),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  BirthdayRow copyWith(
          {String? id,
          String? name,
          Value<String?> note = const Value.absent(),
          int? birthMonth,
          int? birthDay,
          Value<int?> birthYear = const Value.absent(),
          int? notifyHour,
          int? notifyMinute,
          String? advanceOffsetsMinutes,
          String? createdAt,
          int? position,
          int? updatedAt,
          Value<int?> deletedAt = const Value.absent()}) =>
      BirthdayRow(
        id: id ?? this.id,
        name: name ?? this.name,
        note: note.present ? note.value : this.note,
        birthMonth: birthMonth ?? this.birthMonth,
        birthDay: birthDay ?? this.birthDay,
        birthYear: birthYear.present ? birthYear.value : this.birthYear,
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
      birthMonth:
          data.birthMonth.present ? data.birthMonth.value : this.birthMonth,
      birthDay: data.birthDay.present ? data.birthDay.value : this.birthDay,
      birthYear: data.birthYear.present ? data.birthYear.value : this.birthYear,
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
          ..write('birthMonth: $birthMonth, ')
          ..write('birthDay: $birthDay, ')
          ..write('birthYear: $birthYear, ')
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
      birthMonth,
      birthDay,
      birthYear,
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
          other.birthMonth == this.birthMonth &&
          other.birthDay == this.birthDay &&
          other.birthYear == this.birthYear &&
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
  final Value<int> birthMonth;
  final Value<int> birthDay;
  final Value<int?> birthYear;
  final Value<int> notifyHour;
  final Value<int> notifyMinute;
  final Value<String> advanceOffsetsMinutes;
  final Value<String> createdAt;
  final Value<int> position;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const BirthdaysCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.note = const Value.absent(),
    this.birthMonth = const Value.absent(),
    this.birthDay = const Value.absent(),
    this.birthYear = const Value.absent(),
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
    required int birthMonth,
    required int birthDay,
    this.birthYear = const Value.absent(),
    required int notifyHour,
    required int notifyMinute,
    required String advanceOffsetsMinutes,
    required String createdAt,
    required int position,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        birthMonth = Value(birthMonth),
        birthDay = Value(birthDay),
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
    Expression<int>? birthMonth,
    Expression<int>? birthDay,
    Expression<int>? birthYear,
    Expression<int>? notifyHour,
    Expression<int>? notifyMinute,
    Expression<String>? advanceOffsetsMinutes,
    Expression<String>? createdAt,
    Expression<int>? position,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (note != null) 'note': note,
      if (birthMonth != null) 'birth_month': birthMonth,
      if (birthDay != null) 'birth_day': birthDay,
      if (birthYear != null) 'birth_year': birthYear,
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
      Value<int>? birthMonth,
      Value<int>? birthDay,
      Value<int?>? birthYear,
      Value<int>? notifyHour,
      Value<int>? notifyMinute,
      Value<String>? advanceOffsetsMinutes,
      Value<String>? createdAt,
      Value<int>? position,
      Value<int>? updatedAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return BirthdaysCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      note: note ?? this.note,
      birthMonth: birthMonth ?? this.birthMonth,
      birthDay: birthDay ?? this.birthDay,
      birthYear: birthYear ?? this.birthYear,
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
    if (birthMonth.present) {
      map['birth_month'] = Variable<int>(birthMonth.value);
    }
    if (birthDay.present) {
      map['birth_day'] = Variable<int>(birthDay.value);
    }
    if (birthYear.present) {
      map['birth_year'] = Variable<int>(birthYear.value);
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
      map['created_at'] = Variable<String>(createdAt.value);
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
          ..write('birthMonth: $birthMonth, ')
          ..write('birthDay: $birthDay, ')
          ..write('birthYear: $birthYear, ')
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
  late final $SubtasksTable subtasks = $SubtasksTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $RoutinesTable routines = $RoutinesTable(this);
  late final $RoutineItemsTable routineItems = $RoutineItemsTable(this);
  late final $BirthdaysTable birthdays = $BirthdaysTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        reminders,
        subtasks,
        categories,
        routines,
        routineItems,
        birthdays,
        settings,
        appMeta
      ];
}

typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  required String id,
  required String title,
  Value<String?> note,
  required bool isDone,
  required String createdAt,
  Value<String?> remindAt,
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
  Value<String?> recurrence,
  Value<int> priority,
  Value<bool> pinned,
  Value<String?> routineId,
  Value<String?> routineItemId,
  Value<int> rowid,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> note,
  Value<bool> isDone,
  Value<String> createdAt,
  Value<String?> remindAt,
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
  Value<String?> recurrence,
  Value<int> priority,
  Value<bool> pinned,
  Value<String?> routineId,
  Value<String?> routineItemId,
  Value<int> rowid,
});

final class $$RemindersTableReferences
    extends BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SubtasksTable, List<SubtaskRow>>
      _subtasksRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.subtasks,
              aliasName: 'reminders__id__subtasks__reminder_id');

  $$SubtasksTableProcessedTableManager get subtasksRefs {
    final manager = $$SubtasksTableTableManager($_db, $_db.subtasks)
        .filter((f) => f.reminderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_subtasksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

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

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remindAt => $composableBuilder(
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

  ColumnFilters<String> get recurrence => $composableBuilder(
      column: $table.recurrence, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pinned => $composableBuilder(
      column: $table.pinned, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get routineId => $composableBuilder(
      column: $table.routineId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get routineItemId => $composableBuilder(
      column: $table.routineItemId, builder: (column) => ColumnFilters(column));

  Expression<bool> subtasksRefs(
      Expression<bool> Function($$SubtasksTableFilterComposer f) f) {
    final $$SubtasksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.subtasks,
        getReferencedColumn: (t) => t.reminderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubtasksTableFilterComposer(
              $db: $db,
              $table: $db.subtasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
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

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remindAt => $composableBuilder(
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

  ColumnOrderings<String> get recurrence => $composableBuilder(
      column: $table.recurrence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pinned => $composableBuilder(
      column: $table.pinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get routineId => $composableBuilder(
      column: $table.routineId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get routineItemId => $composableBuilder(
      column: $table.routineItemId,
      builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get remindAt =>
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

  GeneratedColumn<String> get recurrence => $composableBuilder(
      column: $table.recurrence, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<String> get routineId =>
      $composableBuilder(column: $table.routineId, builder: (column) => column);

  GeneratedColumn<String> get routineItemId => $composableBuilder(
      column: $table.routineItemId, builder: (column) => column);

  Expression<T> subtasksRefs<T extends Object>(
      Expression<T> Function($$SubtasksTableAnnotationComposer a) f) {
    final $$SubtasksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.subtasks,
        getReferencedColumn: (t) => t.reminderId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubtasksTableAnnotationComposer(
              $db: $db,
              $table: $db.subtasks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
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
    (ReminderRow, $$RemindersTableReferences),
    ReminderRow,
    PrefetchHooks Function({bool subtasksRefs})> {
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
            Value<String> createdAt = const Value.absent(),
            Value<String?> remindAt = const Value.absent(),
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
            Value<String?> recurrence = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<bool> pinned = const Value.absent(),
            Value<String?> routineId = const Value.absent(),
            Value<String?> routineItemId = const Value.absent(),
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
            recurrence: recurrence,
            priority: priority,
            pinned: pinned,
            routineId: routineId,
            routineItemId: routineItemId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> note = const Value.absent(),
            required bool isDone,
            required String createdAt,
            Value<String?> remindAt = const Value.absent(),
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
            Value<String?> recurrence = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<bool> pinned = const Value.absent(),
            Value<String?> routineId = const Value.absent(),
            Value<String?> routineItemId = const Value.absent(),
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
            recurrence: recurrence,
            priority: priority,
            pinned: pinned,
            routineId: routineId,
            routineItemId: routineItemId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$RemindersTable, ReminderRow>(table),
                    $$RemindersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({subtasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (subtasksRefs) db.subtasks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (subtasksRefs)
                    await $_getPrefetchedData<ReminderRow, $RemindersTable,
                            SubtaskRow>(
                        currentTable: table,
                        referencedTable:
                            $$RemindersTableReferences._subtasksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RemindersTableReferences(db, table, p0)
                                .subtasksRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.reminderId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
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
    (ReminderRow, $$RemindersTableReferences),
    ReminderRow,
    PrefetchHooks Function({bool subtasksRefs})>;
typedef $$SubtasksTableCreateCompanionBuilder = SubtasksCompanion Function({
  required String reminderId,
  required String id,
  required String title,
  required bool isDone,
  required int position,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$SubtasksTableUpdateCompanionBuilder = SubtasksCompanion Function({
  Value<String> reminderId,
  Value<String> id,
  Value<String> title,
  Value<bool> isDone,
  Value<int> position,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $$SubtasksTableReferences
    extends BaseReferences<_$AppDatabase, $SubtasksTable, SubtaskRow> {
  $$SubtasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RemindersTable _reminderIdTable(_$AppDatabase db) =>
      db.reminders.createAlias('subtasks__reminder_id__reminders__id');

  $$RemindersTableProcessedTableManager get reminderId {
    final $_column = $_itemColumn<String>('reminder_id')!;

    final manager = $$RemindersTableTableManager($_db, $_db.reminders)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_reminderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SubtasksTableFilterComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableFilterComposer({
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

  ColumnFilters<bool> get isDone => $composableBuilder(
      column: $table.isDone, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$RemindersTableFilterComposer get reminderId {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.reminderId,
        referencedTable: $db.reminders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RemindersTableFilterComposer(
              $db: $db,
              $table: $db.reminders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SubtasksTableOrderingComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableOrderingComposer({
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

  ColumnOrderings<bool> get isDone => $composableBuilder(
      column: $table.isDone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$RemindersTableOrderingComposer get reminderId {
    final $$RemindersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.reminderId,
        referencedTable: $db.reminders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RemindersTableOrderingComposer(
              $db: $db,
              $table: $db.reminders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SubtasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubtasksTable> {
  $$SubtasksTableAnnotationComposer({
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

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$RemindersTableAnnotationComposer get reminderId {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.reminderId,
        referencedTable: $db.reminders,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RemindersTableAnnotationComposer(
              $db: $db,
              $table: $db.reminders,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SubtasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SubtasksTable,
    SubtaskRow,
    $$SubtasksTableFilterComposer,
    $$SubtasksTableOrderingComposer,
    $$SubtasksTableAnnotationComposer,
    $$SubtasksTableCreateCompanionBuilder,
    $$SubtasksTableUpdateCompanionBuilder,
    (SubtaskRow, $$SubtasksTableReferences),
    SubtaskRow,
    PrefetchHooks Function({bool reminderId})> {
  $$SubtasksTableTableManager(_$AppDatabase db, $SubtasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubtasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubtasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubtasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> reminderId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<bool> isDone = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SubtasksCompanion(
            reminderId: reminderId,
            id: id,
            title: title,
            isDone: isDone,
            position: position,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String reminderId,
            required String id,
            required String title,
            required bool isDone,
            required int position,
            required int updatedAt,
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SubtasksCompanion.insert(
            reminderId: reminderId,
            id: id,
            title: title,
            isDone: isDone,
            position: position,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SubtasksTable, SubtaskRow>(table),
                    $$SubtasksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({reminderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (reminderId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.reminderId,
                    referencedTable:
                        $$SubtasksTableReferences._reminderIdTable(db),
                    referencedColumn:
                        $$SubtasksTableReferences._reminderIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SubtasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SubtasksTable,
    SubtaskRow,
    $$SubtasksTableFilterComposer,
    $$SubtasksTableOrderingComposer,
    $$SubtasksTableAnnotationComposer,
    $$SubtasksTableCreateCompanionBuilder,
    $$SubtasksTableUpdateCompanionBuilder,
    (SubtaskRow, $$SubtasksTableReferences),
    SubtaskRow,
    PrefetchHooks Function({bool reminderId})>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String name,
  required String colorKey,
  required String iconKey,
  required int position,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> colorKey,
  Value<String> iconKey,
  Value<int> position,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
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
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorKey => $composableBuilder(
      column: $table.colorKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconKey => $composableBuilder(
      column: $table.iconKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
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
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorKey => $composableBuilder(
      column: $table.colorKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconKey => $composableBuilder(
      column: $table.iconKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
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
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get colorKey =>
      $composableBuilder(column: $table.colorKey, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    CategoryRow,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (CategoryRow, BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>),
    CategoryRow,
    PrefetchHooks Function()> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> colorKey = const Value.absent(),
            Value<String> iconKey = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            name: name,
            colorKey: colorKey,
            iconKey: iconKey,
            position: position,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String colorKey,
            required String iconKey,
            required int position,
            required int updatedAt,
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            name: name,
            colorKey: colorKey,
            iconKey: iconKey,
            position: position,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$CategoriesTable, CategoryRow>(table),
                    BaseReferences<_$AppDatabase, $CategoriesTable,
                        CategoryRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    CategoryRow,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (CategoryRow, BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>),
    CategoryRow,
    PrefetchHooks Function()>;
typedef $$RoutinesTableCreateCompanionBuilder = RoutinesCompanion Function({
  required String id,
  required String name,
  Value<String?> colorKey,
  Value<String?> iconKey,
  Value<String?> repeatRule,
  required String createdAt,
  required int position,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$RoutinesTableUpdateCompanionBuilder = RoutinesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> colorKey,
  Value<String?> iconKey,
  Value<String?> repeatRule,
  Value<String> createdAt,
  Value<int> position,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $$RoutinesTableReferences
    extends BaseReferences<_$AppDatabase, $RoutinesTable, RoutineRow> {
  $$RoutinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RoutineItemsTable, List<RoutineItemRow>>
      _routineItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.routineItems,
              aliasName: 'routines__id__routine_items__routine_id');

  $$RoutineItemsTableProcessedTableManager get routineItemsRefs {
    final manager = $$RoutineItemsTableTableManager($_db, $_db.routineItems)
        .filter((f) => f.routineId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_routineItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RoutinesTableFilterComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableFilterComposer({
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

  ColumnFilters<String> get colorKey => $composableBuilder(
      column: $table.colorKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconKey => $composableBuilder(
      column: $table.iconKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get repeatRule => $composableBuilder(
      column: $table.repeatRule, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> routineItemsRefs(
      Expression<bool> Function($$RoutineItemsTableFilterComposer f) f) {
    final $$RoutineItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.routineItems,
        getReferencedColumn: (t) => t.routineId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutineItemsTableFilterComposer(
              $db: $db,
              $table: $db.routineItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RoutinesTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableOrderingComposer({
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

  ColumnOrderings<String> get colorKey => $composableBuilder(
      column: $table.colorKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconKey => $composableBuilder(
      column: $table.iconKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repeatRule => $composableBuilder(
      column: $table.repeatRule, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$RoutinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutinesTable> {
  $$RoutinesTableAnnotationComposer({
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

  GeneratedColumn<String> get colorKey =>
      $composableBuilder(column: $table.colorKey, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<String> get repeatRule => $composableBuilder(
      column: $table.repeatRule, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> routineItemsRefs<T extends Object>(
      Expression<T> Function($$RoutineItemsTableAnnotationComposer a) f) {
    final $$RoutineItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.routineItems,
        getReferencedColumn: (t) => t.routineId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutineItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.routineItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$RoutinesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RoutinesTable,
    RoutineRow,
    $$RoutinesTableFilterComposer,
    $$RoutinesTableOrderingComposer,
    $$RoutinesTableAnnotationComposer,
    $$RoutinesTableCreateCompanionBuilder,
    $$RoutinesTableUpdateCompanionBuilder,
    (RoutineRow, $$RoutinesTableReferences),
    RoutineRow,
    PrefetchHooks Function({bool routineItemsRefs})> {
  $$RoutinesTableTableManager(_$AppDatabase db, $RoutinesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> colorKey = const Value.absent(),
            Value<String?> iconKey = const Value.absent(),
            Value<String?> repeatRule = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RoutinesCompanion(
            id: id,
            name: name,
            colorKey: colorKey,
            iconKey: iconKey,
            repeatRule: repeatRule,
            createdAt: createdAt,
            position: position,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> colorKey = const Value.absent(),
            Value<String?> iconKey = const Value.absent(),
            Value<String?> repeatRule = const Value.absent(),
            required String createdAt,
            required int position,
            required int updatedAt,
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RoutinesCompanion.insert(
            id: id,
            name: name,
            colorKey: colorKey,
            iconKey: iconKey,
            repeatRule: repeatRule,
            createdAt: createdAt,
            position: position,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$RoutinesTable, RoutineRow>(table),
                    $$RoutinesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({routineItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (routineItemsRefs) db.routineItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (routineItemsRefs)
                    await $_getPrefetchedData<RoutineRow, $RoutinesTable,
                            RoutineItemRow>(
                        currentTable: table,
                        referencedTable: $$RoutinesTableReferences
                            ._routineItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$RoutinesTableReferences(db, table, p0)
                                .routineItemsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.routineId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$RoutinesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RoutinesTable,
    RoutineRow,
    $$RoutinesTableFilterComposer,
    $$RoutinesTableOrderingComposer,
    $$RoutinesTableAnnotationComposer,
    $$RoutinesTableCreateCompanionBuilder,
    $$RoutinesTableUpdateCompanionBuilder,
    (RoutineRow, $$RoutinesTableReferences),
    RoutineRow,
    PrefetchHooks Function({bool routineItemsRefs})>;
typedef $$RoutineItemsTableCreateCompanionBuilder = RoutineItemsCompanion
    Function({
  required String routineId,
  required String id,
  required String title,
  Value<String?> timeOfDay,
  required String categoryId,
  Value<int> priority,
  Value<String?> subtasks,
  required int position,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$RoutineItemsTableUpdateCompanionBuilder = RoutineItemsCompanion
    Function({
  Value<String> routineId,
  Value<String> id,
  Value<String> title,
  Value<String?> timeOfDay,
  Value<String> categoryId,
  Value<int> priority,
  Value<String?> subtasks,
  Value<int> position,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $$RoutineItemsTableReferences
    extends BaseReferences<_$AppDatabase, $RoutineItemsTable, RoutineItemRow> {
  $$RoutineItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RoutinesTable _routineIdTable(_$AppDatabase db) =>
      db.routines.createAlias('routine_items__routine_id__routines__id');

  $$RoutinesTableProcessedTableManager get routineId {
    final $_column = $_itemColumn<String>('routine_id')!;

    final manager = $$RoutinesTableTableManager($_db, $_db.routines)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_routineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RoutineItemsTableFilterComposer
    extends Composer<_$AppDatabase, $RoutineItemsTable> {
  $$RoutineItemsTableFilterComposer({
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

  ColumnFilters<String> get timeOfDay => $composableBuilder(
      column: $table.timeOfDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subtasks => $composableBuilder(
      column: $table.subtasks, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$RoutinesTableFilterComposer get routineId {
    final $$RoutinesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routineId,
        referencedTable: $db.routines,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutinesTableFilterComposer(
              $db: $db,
              $table: $db.routines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RoutineItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $RoutineItemsTable> {
  $$RoutineItemsTableOrderingComposer({
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

  ColumnOrderings<String> get timeOfDay => $composableBuilder(
      column: $table.timeOfDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subtasks => $composableBuilder(
      column: $table.subtasks, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$RoutinesTableOrderingComposer get routineId {
    final $$RoutinesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routineId,
        referencedTable: $db.routines,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutinesTableOrderingComposer(
              $db: $db,
              $table: $db.routines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RoutineItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoutineItemsTable> {
  $$RoutineItemsTableAnnotationComposer({
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

  GeneratedColumn<String> get timeOfDay =>
      $composableBuilder(column: $table.timeOfDay, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get subtasks =>
      $composableBuilder(column: $table.subtasks, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$RoutinesTableAnnotationComposer get routineId {
    final $$RoutinesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.routineId,
        referencedTable: $db.routines,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$RoutinesTableAnnotationComposer(
              $db: $db,
              $table: $db.routines,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$RoutineItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RoutineItemsTable,
    RoutineItemRow,
    $$RoutineItemsTableFilterComposer,
    $$RoutineItemsTableOrderingComposer,
    $$RoutineItemsTableAnnotationComposer,
    $$RoutineItemsTableCreateCompanionBuilder,
    $$RoutineItemsTableUpdateCompanionBuilder,
    (RoutineItemRow, $$RoutineItemsTableReferences),
    RoutineItemRow,
    PrefetchHooks Function({bool routineId})> {
  $$RoutineItemsTableTableManager(_$AppDatabase db, $RoutineItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutineItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutineItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutineItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> routineId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> timeOfDay = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<String?> subtasks = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RoutineItemsCompanion(
            routineId: routineId,
            id: id,
            title: title,
            timeOfDay: timeOfDay,
            categoryId: categoryId,
            priority: priority,
            subtasks: subtasks,
            position: position,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String routineId,
            required String id,
            required String title,
            Value<String?> timeOfDay = const Value.absent(),
            required String categoryId,
            Value<int> priority = const Value.absent(),
            Value<String?> subtasks = const Value.absent(),
            required int position,
            required int updatedAt,
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RoutineItemsCompanion.insert(
            routineId: routineId,
            id: id,
            title: title,
            timeOfDay: timeOfDay,
            categoryId: categoryId,
            priority: priority,
            subtasks: subtasks,
            position: position,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$RoutineItemsTable, RoutineItemRow>(table),
                    $$RoutineItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({routineId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (routineId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.routineId,
                    referencedTable:
                        $$RoutineItemsTableReferences._routineIdTable(db),
                    referencedColumn:
                        $$RoutineItemsTableReferences._routineIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$RoutineItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RoutineItemsTable,
    RoutineItemRow,
    $$RoutineItemsTableFilterComposer,
    $$RoutineItemsTableOrderingComposer,
    $$RoutineItemsTableAnnotationComposer,
    $$RoutineItemsTableCreateCompanionBuilder,
    $$RoutineItemsTableUpdateCompanionBuilder,
    (RoutineItemRow, $$RoutineItemsTableReferences),
    RoutineItemRow,
    PrefetchHooks Function({bool routineId})>;
typedef $$BirthdaysTableCreateCompanionBuilder = BirthdaysCompanion Function({
  required String id,
  required String name,
  Value<String?> note,
  required int birthMonth,
  required int birthDay,
  Value<int?> birthYear,
  required int notifyHour,
  required int notifyMinute,
  required String advanceOffsetsMinutes,
  required String createdAt,
  required int position,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$BirthdaysTableUpdateCompanionBuilder = BirthdaysCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> note,
  Value<int> birthMonth,
  Value<int> birthDay,
  Value<int?> birthYear,
  Value<int> notifyHour,
  Value<int> notifyMinute,
  Value<String> advanceOffsetsMinutes,
  Value<String> createdAt,
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

  ColumnFilters<int> get birthMonth => $composableBuilder(
      column: $table.birthMonth, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get birthDay => $composableBuilder(
      column: $table.birthDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get birthYear => $composableBuilder(
      column: $table.birthYear, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get notifyHour => $composableBuilder(
      column: $table.notifyHour, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get notifyMinute => $composableBuilder(
      column: $table.notifyMinute, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get advanceOffsetsMinutes => $composableBuilder(
      column: $table.advanceOffsetsMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
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

  ColumnOrderings<int> get birthMonth => $composableBuilder(
      column: $table.birthMonth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get birthDay => $composableBuilder(
      column: $table.birthDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get birthYear => $composableBuilder(
      column: $table.birthYear, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get notifyHour => $composableBuilder(
      column: $table.notifyHour, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get notifyMinute => $composableBuilder(
      column: $table.notifyMinute,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get advanceOffsetsMinutes => $composableBuilder(
      column: $table.advanceOffsetsMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
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

  GeneratedColumn<int> get birthMonth => $composableBuilder(
      column: $table.birthMonth, builder: (column) => column);

  GeneratedColumn<int> get birthDay =>
      $composableBuilder(column: $table.birthDay, builder: (column) => column);

  GeneratedColumn<int> get birthYear =>
      $composableBuilder(column: $table.birthYear, builder: (column) => column);

  GeneratedColumn<int> get notifyHour => $composableBuilder(
      column: $table.notifyHour, builder: (column) => column);

  GeneratedColumn<int> get notifyMinute => $composableBuilder(
      column: $table.notifyMinute, builder: (column) => column);

  GeneratedColumn<String> get advanceOffsetsMinutes => $composableBuilder(
      column: $table.advanceOffsetsMinutes, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
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
            Value<int> birthMonth = const Value.absent(),
            Value<int> birthDay = const Value.absent(),
            Value<int?> birthYear = const Value.absent(),
            Value<int> notifyHour = const Value.absent(),
            Value<int> notifyMinute = const Value.absent(),
            Value<String> advanceOffsetsMinutes = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BirthdaysCompanion(
            id: id,
            name: name,
            note: note,
            birthMonth: birthMonth,
            birthDay: birthDay,
            birthYear: birthYear,
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
            required int birthMonth,
            required int birthDay,
            Value<int?> birthYear = const Value.absent(),
            required int notifyHour,
            required int notifyMinute,
            required String advanceOffsetsMinutes,
            required String createdAt,
            required int position,
            required int updatedAt,
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BirthdaysCompanion.insert(
            id: id,
            name: name,
            note: note,
            birthMonth: birthMonth,
            birthDay: birthDay,
            birthYear: birthYear,
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
  $$SubtasksTableTableManager get subtasks =>
      $$SubtasksTableTableManager(_db, _db.subtasks);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$RoutinesTableTableManager get routines =>
      $$RoutinesTableTableManager(_db, _db.routines);
  $$RoutineItemsTableTableManager get routineItems =>
      $$RoutineItemsTableTableManager(_db, _db.routineItems);
  $$BirthdaysTableTableManager get birthdays =>
      $$BirthdaysTableTableManager(_db, _db.birthdays);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
}
