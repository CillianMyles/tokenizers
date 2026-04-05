// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $EventLogTable extends EventLog
    with TableInfo<$EventLogTable, EventLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aggregateTypeMeta = const VerificationMeta(
    'aggregateType',
  );
  @override
  late final GeneratedColumn<String> aggregateType = GeneratedColumn<String>(
    'aggregate_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aggregateIdMeta = const VerificationMeta(
    'aggregateId',
  );
  @override
  late final GeneratedColumn<String> aggregateId = GeneratedColumn<String>(
    'aggregate_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _causationIdMeta = const VerificationMeta(
    'causationId',
  );
  @override
  late final GeneratedColumn<String> causationId = GeneratedColumn<String>(
    'causation_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _correlationIdMeta = const VerificationMeta(
    'correlationId',
  );
  @override
  late final GeneratedColumn<String> correlationId = GeneratedColumn<String>(
    'correlation_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actorTypeMeta = const VerificationMeta(
    'actorType',
  );
  @override
  late final GeneratedColumn<String> actorType = GeneratedColumn<String>(
    'actor_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    eventId,
    aggregateType,
    aggregateId,
    eventType,
    occurredAt,
    causationId,
    correlationId,
    actorType,
    payloadJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('aggregate_type')) {
      context.handle(
        _aggregateTypeMeta,
        aggregateType.isAcceptableOrUnknown(
          data['aggregate_type']!,
          _aggregateTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aggregateTypeMeta);
    }
    if (data.containsKey('aggregate_id')) {
      context.handle(
        _aggregateIdMeta,
        aggregateId.isAcceptableOrUnknown(
          data['aggregate_id']!,
          _aggregateIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aggregateIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('causation_id')) {
      context.handle(
        _causationIdMeta,
        causationId.isAcceptableOrUnknown(
          data['causation_id']!,
          _causationIdMeta,
        ),
      );
    }
    if (data.containsKey('correlation_id')) {
      context.handle(
        _correlationIdMeta,
        correlationId.isAcceptableOrUnknown(
          data['correlation_id']!,
          _correlationIdMeta,
        ),
      );
    }
    if (data.containsKey('actor_type')) {
      context.handle(
        _actorTypeMeta,
        actorType.isAcceptableOrUnknown(data['actor_type']!, _actorTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actorTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  EventLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventLogData(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      aggregateType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aggregate_type'],
      )!,
      aggregateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aggregate_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      causationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}causation_id'],
      ),
      correlationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correlation_id'],
      ),
      actorType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor_type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
    );
  }

  @override
  $EventLogTable createAlias(String alias) {
    return $EventLogTable(attachedDatabase, alias);
  }
}

class EventLogData extends DataClass implements Insertable<EventLogData> {
  /// Event id.
  final String eventId;

  /// Aggregate type.
  final String aggregateType;

  /// Aggregate id.
  final String aggregateId;

  /// Event type.
  final String eventType;

  /// Event occurrence time.
  final DateTime occurredAt;

  /// Optional causation id.
  final String? causationId;

  /// Optional correlation id.
  final String? correlationId;

  /// Actor type.
  final String actorType;

  /// JSON payload.
  final String payloadJson;
  const EventLogData({
    required this.eventId,
    required this.aggregateType,
    required this.aggregateId,
    required this.eventType,
    required this.occurredAt,
    this.causationId,
    this.correlationId,
    required this.actorType,
    required this.payloadJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['aggregate_type'] = Variable<String>(aggregateType);
    map['aggregate_id'] = Variable<String>(aggregateId);
    map['event_type'] = Variable<String>(eventType);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || causationId != null) {
      map['causation_id'] = Variable<String>(causationId);
    }
    if (!nullToAbsent || correlationId != null) {
      map['correlation_id'] = Variable<String>(correlationId);
    }
    map['actor_type'] = Variable<String>(actorType);
    map['payload_json'] = Variable<String>(payloadJson);
    return map;
  }

  EventLogCompanion toCompanion(bool nullToAbsent) {
    return EventLogCompanion(
      eventId: Value(eventId),
      aggregateType: Value(aggregateType),
      aggregateId: Value(aggregateId),
      eventType: Value(eventType),
      occurredAt: Value(occurredAt),
      causationId: causationId == null && nullToAbsent
          ? const Value.absent()
          : Value(causationId),
      correlationId: correlationId == null && nullToAbsent
          ? const Value.absent()
          : Value(correlationId),
      actorType: Value(actorType),
      payloadJson: Value(payloadJson),
    );
  }

  factory EventLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventLogData(
      eventId: serializer.fromJson<String>(json['eventId']),
      aggregateType: serializer.fromJson<String>(json['aggregateType']),
      aggregateId: serializer.fromJson<String>(json['aggregateId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      causationId: serializer.fromJson<String?>(json['causationId']),
      correlationId: serializer.fromJson<String?>(json['correlationId']),
      actorType: serializer.fromJson<String>(json['actorType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'aggregateType': serializer.toJson<String>(aggregateType),
      'aggregateId': serializer.toJson<String>(aggregateId),
      'eventType': serializer.toJson<String>(eventType),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'causationId': serializer.toJson<String?>(causationId),
      'correlationId': serializer.toJson<String?>(correlationId),
      'actorType': serializer.toJson<String>(actorType),
      'payloadJson': serializer.toJson<String>(payloadJson),
    };
  }

  EventLogData copyWith({
    String? eventId,
    String? aggregateType,
    String? aggregateId,
    String? eventType,
    DateTime? occurredAt,
    Value<String?> causationId = const Value.absent(),
    Value<String?> correlationId = const Value.absent(),
    String? actorType,
    String? payloadJson,
  }) => EventLogData(
    eventId: eventId ?? this.eventId,
    aggregateType: aggregateType ?? this.aggregateType,
    aggregateId: aggregateId ?? this.aggregateId,
    eventType: eventType ?? this.eventType,
    occurredAt: occurredAt ?? this.occurredAt,
    causationId: causationId.present ? causationId.value : this.causationId,
    correlationId: correlationId.present
        ? correlationId.value
        : this.correlationId,
    actorType: actorType ?? this.actorType,
    payloadJson: payloadJson ?? this.payloadJson,
  );
  EventLogData copyWithCompanion(EventLogCompanion data) {
    return EventLogData(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      aggregateType: data.aggregateType.present
          ? data.aggregateType.value
          : this.aggregateType,
      aggregateId: data.aggregateId.present
          ? data.aggregateId.value
          : this.aggregateId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      causationId: data.causationId.present
          ? data.causationId.value
          : this.causationId,
      correlationId: data.correlationId.present
          ? data.correlationId.value
          : this.correlationId,
      actorType: data.actorType.present ? data.actorType.value : this.actorType,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventLogData(')
          ..write('eventId: $eventId, ')
          ..write('aggregateType: $aggregateType, ')
          ..write('aggregateId: $aggregateId, ')
          ..write('eventType: $eventType, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('causationId: $causationId, ')
          ..write('correlationId: $correlationId, ')
          ..write('actorType: $actorType, ')
          ..write('payloadJson: $payloadJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    eventId,
    aggregateType,
    aggregateId,
    eventType,
    occurredAt,
    causationId,
    correlationId,
    actorType,
    payloadJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventLogData &&
          other.eventId == this.eventId &&
          other.aggregateType == this.aggregateType &&
          other.aggregateId == this.aggregateId &&
          other.eventType == this.eventType &&
          other.occurredAt == this.occurredAt &&
          other.causationId == this.causationId &&
          other.correlationId == this.correlationId &&
          other.actorType == this.actorType &&
          other.payloadJson == this.payloadJson);
}

class EventLogCompanion extends UpdateCompanion<EventLogData> {
  final Value<String> eventId;
  final Value<String> aggregateType;
  final Value<String> aggregateId;
  final Value<String> eventType;
  final Value<DateTime> occurredAt;
  final Value<String?> causationId;
  final Value<String?> correlationId;
  final Value<String> actorType;
  final Value<String> payloadJson;
  final Value<int> rowid;
  const EventLogCompanion({
    this.eventId = const Value.absent(),
    this.aggregateType = const Value.absent(),
    this.aggregateId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.causationId = const Value.absent(),
    this.correlationId = const Value.absent(),
    this.actorType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventLogCompanion.insert({
    required String eventId,
    required String aggregateType,
    required String aggregateId,
    required String eventType,
    required DateTime occurredAt,
    this.causationId = const Value.absent(),
    this.correlationId = const Value.absent(),
    required String actorType,
    required String payloadJson,
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       aggregateType = Value(aggregateType),
       aggregateId = Value(aggregateId),
       eventType = Value(eventType),
       occurredAt = Value(occurredAt),
       actorType = Value(actorType),
       payloadJson = Value(payloadJson);
  static Insertable<EventLogData> custom({
    Expression<String>? eventId,
    Expression<String>? aggregateType,
    Expression<String>? aggregateId,
    Expression<String>? eventType,
    Expression<DateTime>? occurredAt,
    Expression<String>? causationId,
    Expression<String>? correlationId,
    Expression<String>? actorType,
    Expression<String>? payloadJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (aggregateType != null) 'aggregate_type': aggregateType,
      if (aggregateId != null) 'aggregate_id': aggregateId,
      if (eventType != null) 'event_type': eventType,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (causationId != null) 'causation_id': causationId,
      if (correlationId != null) 'correlation_id': correlationId,
      if (actorType != null) 'actor_type': actorType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventLogCompanion copyWith({
    Value<String>? eventId,
    Value<String>? aggregateType,
    Value<String>? aggregateId,
    Value<String>? eventType,
    Value<DateTime>? occurredAt,
    Value<String?>? causationId,
    Value<String?>? correlationId,
    Value<String>? actorType,
    Value<String>? payloadJson,
    Value<int>? rowid,
  }) {
    return EventLogCompanion(
      eventId: eventId ?? this.eventId,
      aggregateType: aggregateType ?? this.aggregateType,
      aggregateId: aggregateId ?? this.aggregateId,
      eventType: eventType ?? this.eventType,
      occurredAt: occurredAt ?? this.occurredAt,
      causationId: causationId ?? this.causationId,
      correlationId: correlationId ?? this.correlationId,
      actorType: actorType ?? this.actorType,
      payloadJson: payloadJson ?? this.payloadJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (aggregateType.present) {
      map['aggregate_type'] = Variable<String>(aggregateType.value);
    }
    if (aggregateId.present) {
      map['aggregate_id'] = Variable<String>(aggregateId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (causationId.present) {
      map['causation_id'] = Variable<String>(causationId.value);
    }
    if (correlationId.present) {
      map['correlation_id'] = Variable<String>(correlationId.value);
    }
    if (actorType.present) {
      map['actor_type'] = Variable<String>(actorType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventLogCompanion(')
          ..write('eventId: $eventId, ')
          ..write('aggregateType: $aggregateType, ')
          ..write('aggregateId: $aggregateId, ')
          ..write('eventType: $eventType, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('causationId: $causationId, ')
          ..write('correlationId: $correlationId, ')
          ..write('actorType: $actorType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationThreadsTableTable extends ConversationThreadsTable
    with
        TableInfo<
          $ConversationThreadsTableTable,
          ConversationThreadsTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationThreadsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _threadIdMeta = const VerificationMeta(
    'threadId',
  );
  @override
  late final GeneratedColumn<String> threadId = GeneratedColumn<String>(
    'thread_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastMessagePreviewMeta =
      const VerificationMeta('lastMessagePreview');
  @override
  late final GeneratedColumn<String> lastMessagePreview =
      GeneratedColumn<String>(
        'last_message_preview',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastUpdatedAtMeta = const VerificationMeta(
    'lastUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUpdatedAt =
      GeneratedColumn<DateTime>(
        'last_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _pendingProposalCountMeta =
      const VerificationMeta('pendingProposalCount');
  @override
  late final GeneratedColumn<int> pendingProposalCount = GeneratedColumn<int>(
    'pending_proposal_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    threadId,
    title,
    lastMessagePreview,
    lastUpdatedAt,
    pendingProposalCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversation_threads_view';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConversationThreadsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('thread_id')) {
      context.handle(
        _threadIdMeta,
        threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_threadIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('last_message_preview')) {
      context.handle(
        _lastMessagePreviewMeta,
        lastMessagePreview.isAcceptableOrUnknown(
          data['last_message_preview']!,
          _lastMessagePreviewMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastMessagePreviewMeta);
    }
    if (data.containsKey('last_updated_at')) {
      context.handle(
        _lastUpdatedAtMeta,
        lastUpdatedAt.isAcceptableOrUnknown(
          data['last_updated_at']!,
          _lastUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedAtMeta);
    }
    if (data.containsKey('pending_proposal_count')) {
      context.handle(
        _pendingProposalCountMeta,
        pendingProposalCount.isAcceptableOrUnknown(
          data['pending_proposal_count']!,
          _pendingProposalCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pendingProposalCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {threadId};
  @override
  ConversationThreadsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationThreadsTableData(
      threadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thread_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      lastMessagePreview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_preview'],
      )!,
      lastUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_updated_at'],
      )!,
      pendingProposalCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pending_proposal_count'],
      )!,
    );
  }

  @override
  $ConversationThreadsTableTable createAlias(String alias) {
    return $ConversationThreadsTableTable(attachedDatabase, alias);
  }
}

class ConversationThreadsTableData extends DataClass
    implements Insertable<ConversationThreadsTableData> {
  /// Thread id.
  final String threadId;

  /// Thread title.
  final String title;

  /// Latest preview text.
  final String lastMessagePreview;

  /// Last updated time.
  final DateTime lastUpdatedAt;

  /// Number of pending proposals.
  final int pendingProposalCount;
  const ConversationThreadsTableData({
    required this.threadId,
    required this.title,
    required this.lastMessagePreview,
    required this.lastUpdatedAt,
    required this.pendingProposalCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['thread_id'] = Variable<String>(threadId);
    map['title'] = Variable<String>(title);
    map['last_message_preview'] = Variable<String>(lastMessagePreview);
    map['last_updated_at'] = Variable<DateTime>(lastUpdatedAt);
    map['pending_proposal_count'] = Variable<int>(pendingProposalCount);
    return map;
  }

  ConversationThreadsTableCompanion toCompanion(bool nullToAbsent) {
    return ConversationThreadsTableCompanion(
      threadId: Value(threadId),
      title: Value(title),
      lastMessagePreview: Value(lastMessagePreview),
      lastUpdatedAt: Value(lastUpdatedAt),
      pendingProposalCount: Value(pendingProposalCount),
    );
  }

  factory ConversationThreadsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationThreadsTableData(
      threadId: serializer.fromJson<String>(json['threadId']),
      title: serializer.fromJson<String>(json['title']),
      lastMessagePreview: serializer.fromJson<String>(
        json['lastMessagePreview'],
      ),
      lastUpdatedAt: serializer.fromJson<DateTime>(json['lastUpdatedAt']),
      pendingProposalCount: serializer.fromJson<int>(
        json['pendingProposalCount'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'threadId': serializer.toJson<String>(threadId),
      'title': serializer.toJson<String>(title),
      'lastMessagePreview': serializer.toJson<String>(lastMessagePreview),
      'lastUpdatedAt': serializer.toJson<DateTime>(lastUpdatedAt),
      'pendingProposalCount': serializer.toJson<int>(pendingProposalCount),
    };
  }

  ConversationThreadsTableData copyWith({
    String? threadId,
    String? title,
    String? lastMessagePreview,
    DateTime? lastUpdatedAt,
    int? pendingProposalCount,
  }) => ConversationThreadsTableData(
    threadId: threadId ?? this.threadId,
    title: title ?? this.title,
    lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    pendingProposalCount: pendingProposalCount ?? this.pendingProposalCount,
  );
  ConversationThreadsTableData copyWithCompanion(
    ConversationThreadsTableCompanion data,
  ) {
    return ConversationThreadsTableData(
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      title: data.title.present ? data.title.value : this.title,
      lastMessagePreview: data.lastMessagePreview.present
          ? data.lastMessagePreview.value
          : this.lastMessagePreview,
      lastUpdatedAt: data.lastUpdatedAt.present
          ? data.lastUpdatedAt.value
          : this.lastUpdatedAt,
      pendingProposalCount: data.pendingProposalCount.present
          ? data.pendingProposalCount.value
          : this.pendingProposalCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationThreadsTableData(')
          ..write('threadId: $threadId, ')
          ..write('title: $title, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('lastUpdatedAt: $lastUpdatedAt, ')
          ..write('pendingProposalCount: $pendingProposalCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    threadId,
    title,
    lastMessagePreview,
    lastUpdatedAt,
    pendingProposalCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationThreadsTableData &&
          other.threadId == this.threadId &&
          other.title == this.title &&
          other.lastMessagePreview == this.lastMessagePreview &&
          other.lastUpdatedAt == this.lastUpdatedAt &&
          other.pendingProposalCount == this.pendingProposalCount);
}

class ConversationThreadsTableCompanion
    extends UpdateCompanion<ConversationThreadsTableData> {
  final Value<String> threadId;
  final Value<String> title;
  final Value<String> lastMessagePreview;
  final Value<DateTime> lastUpdatedAt;
  final Value<int> pendingProposalCount;
  final Value<int> rowid;
  const ConversationThreadsTableCompanion({
    this.threadId = const Value.absent(),
    this.title = const Value.absent(),
    this.lastMessagePreview = const Value.absent(),
    this.lastUpdatedAt = const Value.absent(),
    this.pendingProposalCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationThreadsTableCompanion.insert({
    required String threadId,
    required String title,
    required String lastMessagePreview,
    required DateTime lastUpdatedAt,
    required int pendingProposalCount,
    this.rowid = const Value.absent(),
  }) : threadId = Value(threadId),
       title = Value(title),
       lastMessagePreview = Value(lastMessagePreview),
       lastUpdatedAt = Value(lastUpdatedAt),
       pendingProposalCount = Value(pendingProposalCount);
  static Insertable<ConversationThreadsTableData> custom({
    Expression<String>? threadId,
    Expression<String>? title,
    Expression<String>? lastMessagePreview,
    Expression<DateTime>? lastUpdatedAt,
    Expression<int>? pendingProposalCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (threadId != null) 'thread_id': threadId,
      if (title != null) 'title': title,
      if (lastMessagePreview != null)
        'last_message_preview': lastMessagePreview,
      if (lastUpdatedAt != null) 'last_updated_at': lastUpdatedAt,
      if (pendingProposalCount != null)
        'pending_proposal_count': pendingProposalCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationThreadsTableCompanion copyWith({
    Value<String>? threadId,
    Value<String>? title,
    Value<String>? lastMessagePreview,
    Value<DateTime>? lastUpdatedAt,
    Value<int>? pendingProposalCount,
    Value<int>? rowid,
  }) {
    return ConversationThreadsTableCompanion(
      threadId: threadId ?? this.threadId,
      title: title ?? this.title,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      pendingProposalCount: pendingProposalCount ?? this.pendingProposalCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (threadId.present) {
      map['thread_id'] = Variable<String>(threadId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (lastMessagePreview.present) {
      map['last_message_preview'] = Variable<String>(lastMessagePreview.value);
    }
    if (lastUpdatedAt.present) {
      map['last_updated_at'] = Variable<DateTime>(lastUpdatedAt.value);
    }
    if (pendingProposalCount.present) {
      map['pending_proposal_count'] = Variable<int>(pendingProposalCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationThreadsTableCompanion(')
          ..write('threadId: $threadId, ')
          ..write('title: $title, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('lastUpdatedAt: $lastUpdatedAt, ')
          ..write('pendingProposalCount: $pendingProposalCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTableTable extends MessagesTable
    with TableInfo<$MessagesTableTable, MessagesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _threadIdMeta = const VerificationMeta(
    'threadId',
  );
  @override
  late final GeneratedColumn<String> threadId = GeneratedColumn<String>(
    'thread_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actorMeta = const VerificationMeta('actor');
  @override
  late final GeneratedColumn<String> actor = GeneratedColumn<String>(
    'actor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    messageId,
    threadId,
    actor,
    body,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages_view';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessagesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('thread_id')) {
      context.handle(
        _threadIdMeta,
        threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_threadIdMeta);
    }
    if (data.containsKey('actor')) {
      context.handle(
        _actorMeta,
        actor.isAcceptableOrUnknown(data['actor']!, _actorMeta),
      );
    } else if (isInserting) {
      context.missing(_actorMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  MessagesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessagesTableData(
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      threadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thread_id'],
      )!,
      actor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actor'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MessagesTableTable createAlias(String alias) {
    return $MessagesTableTable(attachedDatabase, alias);
  }
}

class MessagesTableData extends DataClass
    implements Insertable<MessagesTableData> {
  /// Message id.
  final String messageId;

  /// Parent thread.
  final String threadId;

  /// Actor value.
  final String actor;

  /// Message body.
  final String body;

  /// Created at.
  final DateTime createdAt;
  const MessagesTableData({
    required this.messageId,
    required this.threadId,
    required this.actor,
    required this.body,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['thread_id'] = Variable<String>(threadId);
    map['actor'] = Variable<String>(actor);
    map['body'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MessagesTableCompanion toCompanion(bool nullToAbsent) {
    return MessagesTableCompanion(
      messageId: Value(messageId),
      threadId: Value(threadId),
      actor: Value(actor),
      body: Value(body),
      createdAt: Value(createdAt),
    );
  }

  factory MessagesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessagesTableData(
      messageId: serializer.fromJson<String>(json['messageId']),
      threadId: serializer.fromJson<String>(json['threadId']),
      actor: serializer.fromJson<String>(json['actor']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'threadId': serializer.toJson<String>(threadId),
      'actor': serializer.toJson<String>(actor),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MessagesTableData copyWith({
    String? messageId,
    String? threadId,
    String? actor,
    String? body,
    DateTime? createdAt,
  }) => MessagesTableData(
    messageId: messageId ?? this.messageId,
    threadId: threadId ?? this.threadId,
    actor: actor ?? this.actor,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
  );
  MessagesTableData copyWithCompanion(MessagesTableCompanion data) {
    return MessagesTableData(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      actor: data.actor.present ? data.actor.value : this.actor,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessagesTableData(')
          ..write('messageId: $messageId, ')
          ..write('threadId: $threadId, ')
          ..write('actor: $actor, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(messageId, threadId, actor, body, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessagesTableData &&
          other.messageId == this.messageId &&
          other.threadId == this.threadId &&
          other.actor == this.actor &&
          other.body == this.body &&
          other.createdAt == this.createdAt);
}

class MessagesTableCompanion extends UpdateCompanion<MessagesTableData> {
  final Value<String> messageId;
  final Value<String> threadId;
  final Value<String> actor;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MessagesTableCompanion({
    this.messageId = const Value.absent(),
    this.threadId = const Value.absent(),
    this.actor = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesTableCompanion.insert({
    required String messageId,
    required String threadId,
    required String actor,
    required String body,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       threadId = Value(threadId),
       actor = Value(actor),
       body = Value(body),
       createdAt = Value(createdAt);
  static Insertable<MessagesTableData> custom({
    Expression<String>? messageId,
    Expression<String>? threadId,
    Expression<String>? actor,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (threadId != null) 'thread_id': threadId,
      if (actor != null) 'actor': actor,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesTableCompanion copyWith({
    Value<String>? messageId,
    Value<String>? threadId,
    Value<String>? actor,
    Value<String>? body,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MessagesTableCompanion(
      messageId: messageId ?? this.messageId,
      threadId: threadId ?? this.threadId,
      actor: actor ?? this.actor,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (threadId.present) {
      map['thread_id'] = Variable<String>(threadId.value);
    }
    if (actor.present) {
      map['actor'] = Variable<String>(actor.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesTableCompanion(')
          ..write('messageId: $messageId, ')
          ..write('threadId: $threadId, ')
          ..write('actor: $actor, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProposalsTableTable extends ProposalsTable
    with TableInfo<$ProposalsTableTable, ProposalsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProposalsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _proposalIdMeta = const VerificationMeta(
    'proposalId',
  );
  @override
  late final GeneratedColumn<String> proposalId = GeneratedColumn<String>(
    'proposal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _threadIdMeta = const VerificationMeta(
    'threadId',
  );
  @override
  late final GeneratedColumn<String> threadId = GeneratedColumn<String>(
    'thread_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assistantTextMeta = const VerificationMeta(
    'assistantText',
  );
  @override
  late final GeneratedColumn<String> assistantText = GeneratedColumn<String>(
    'assistant_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    proposalId,
    threadId,
    summary,
    assistantText,
    createdAt,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'proposals_view';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProposalsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('proposal_id')) {
      context.handle(
        _proposalIdMeta,
        proposalId.isAcceptableOrUnknown(data['proposal_id']!, _proposalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_proposalIdMeta);
    }
    if (data.containsKey('thread_id')) {
      context.handle(
        _threadIdMeta,
        threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_threadIdMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('assistant_text')) {
      context.handle(
        _assistantTextMeta,
        assistantText.isAcceptableOrUnknown(
          data['assistant_text']!,
          _assistantTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_assistantTextMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {proposalId};
  @override
  ProposalsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProposalsTableData(
      proposalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proposal_id'],
      )!,
      threadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thread_id'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      assistantText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assistant_text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $ProposalsTableTable createAlias(String alias) {
    return $ProposalsTableTable(attachedDatabase, alias);
  }
}

class ProposalsTableData extends DataClass
    implements Insertable<ProposalsTableData> {
  /// Proposal id.
  final String proposalId;

  /// Thread id.
  final String threadId;

  /// Proposal summary.
  final String summary;

  /// Assistant text.
  final String assistantText;

  /// Created at.
  final DateTime createdAt;

  /// Proposal status.
  final String status;
  const ProposalsTableData({
    required this.proposalId,
    required this.threadId,
    required this.summary,
    required this.assistantText,
    required this.createdAt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['proposal_id'] = Variable<String>(proposalId);
    map['thread_id'] = Variable<String>(threadId);
    map['summary'] = Variable<String>(summary);
    map['assistant_text'] = Variable<String>(assistantText);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['status'] = Variable<String>(status);
    return map;
  }

  ProposalsTableCompanion toCompanion(bool nullToAbsent) {
    return ProposalsTableCompanion(
      proposalId: Value(proposalId),
      threadId: Value(threadId),
      summary: Value(summary),
      assistantText: Value(assistantText),
      createdAt: Value(createdAt),
      status: Value(status),
    );
  }

  factory ProposalsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProposalsTableData(
      proposalId: serializer.fromJson<String>(json['proposalId']),
      threadId: serializer.fromJson<String>(json['threadId']),
      summary: serializer.fromJson<String>(json['summary']),
      assistantText: serializer.fromJson<String>(json['assistantText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'proposalId': serializer.toJson<String>(proposalId),
      'threadId': serializer.toJson<String>(threadId),
      'summary': serializer.toJson<String>(summary),
      'assistantText': serializer.toJson<String>(assistantText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'status': serializer.toJson<String>(status),
    };
  }

  ProposalsTableData copyWith({
    String? proposalId,
    String? threadId,
    String? summary,
    String? assistantText,
    DateTime? createdAt,
    String? status,
  }) => ProposalsTableData(
    proposalId: proposalId ?? this.proposalId,
    threadId: threadId ?? this.threadId,
    summary: summary ?? this.summary,
    assistantText: assistantText ?? this.assistantText,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
  );
  ProposalsTableData copyWithCompanion(ProposalsTableCompanion data) {
    return ProposalsTableData(
      proposalId: data.proposalId.present
          ? data.proposalId.value
          : this.proposalId,
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      summary: data.summary.present ? data.summary.value : this.summary,
      assistantText: data.assistantText.present
          ? data.assistantText.value
          : this.assistantText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProposalsTableData(')
          ..write('proposalId: $proposalId, ')
          ..write('threadId: $threadId, ')
          ..write('summary: $summary, ')
          ..write('assistantText: $assistantText, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    proposalId,
    threadId,
    summary,
    assistantText,
    createdAt,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProposalsTableData &&
          other.proposalId == this.proposalId &&
          other.threadId == this.threadId &&
          other.summary == this.summary &&
          other.assistantText == this.assistantText &&
          other.createdAt == this.createdAt &&
          other.status == this.status);
}

class ProposalsTableCompanion extends UpdateCompanion<ProposalsTableData> {
  final Value<String> proposalId;
  final Value<String> threadId;
  final Value<String> summary;
  final Value<String> assistantText;
  final Value<DateTime> createdAt;
  final Value<String> status;
  final Value<int> rowid;
  const ProposalsTableCompanion({
    this.proposalId = const Value.absent(),
    this.threadId = const Value.absent(),
    this.summary = const Value.absent(),
    this.assistantText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProposalsTableCompanion.insert({
    required String proposalId,
    required String threadId,
    required String summary,
    required String assistantText,
    required DateTime createdAt,
    required String status,
    this.rowid = const Value.absent(),
  }) : proposalId = Value(proposalId),
       threadId = Value(threadId),
       summary = Value(summary),
       assistantText = Value(assistantText),
       createdAt = Value(createdAt),
       status = Value(status);
  static Insertable<ProposalsTableData> custom({
    Expression<String>? proposalId,
    Expression<String>? threadId,
    Expression<String>? summary,
    Expression<String>? assistantText,
    Expression<DateTime>? createdAt,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (proposalId != null) 'proposal_id': proposalId,
      if (threadId != null) 'thread_id': threadId,
      if (summary != null) 'summary': summary,
      if (assistantText != null) 'assistant_text': assistantText,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProposalsTableCompanion copyWith({
    Value<String>? proposalId,
    Value<String>? threadId,
    Value<String>? summary,
    Value<String>? assistantText,
    Value<DateTime>? createdAt,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return ProposalsTableCompanion(
      proposalId: proposalId ?? this.proposalId,
      threadId: threadId ?? this.threadId,
      summary: summary ?? this.summary,
      assistantText: assistantText ?? this.assistantText,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (proposalId.present) {
      map['proposal_id'] = Variable<String>(proposalId.value);
    }
    if (threadId.present) {
      map['thread_id'] = Variable<String>(threadId.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (assistantText.present) {
      map['assistant_text'] = Variable<String>(assistantText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProposalsTableCompanion(')
          ..write('proposalId: $proposalId, ')
          ..write('threadId: $threadId, ')
          ..write('summary: $summary, ')
          ..write('assistantText: $assistantText, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProposalActionsTableTable extends ProposalActionsTable
    with TableInfo<$ProposalActionsTableTable, ProposalActionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProposalActionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _actionIdMeta = const VerificationMeta(
    'actionId',
  );
  @override
  late final GeneratedColumn<String> actionId = GeneratedColumn<String>(
    'action_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proposalIdMeta = const VerificationMeta(
    'proposalId',
  );
  @override
  late final GeneratedColumn<String> proposalId = GeneratedColumn<String>(
    'proposal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medicationNameMeta = const VerificationMeta(
    'medicationName',
  );
  @override
  late final GeneratedColumn<String> medicationName = GeneratedColumn<String>(
    'medication_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doseAmountMeta = const VerificationMeta(
    'doseAmount',
  );
  @override
  late final GeneratedColumn<String> doseAmount = GeneratedColumn<String>(
    'dose_amount',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doseUnitMeta = const VerificationMeta(
    'doseUnit',
  );
  @override
  late final GeneratedColumn<String> doseUnit = GeneratedColumn<String>(
    'dose_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routeMeta = const VerificationMeta('route');
  @override
  late final GeneratedColumn<String> route = GeneratedColumn<String>(
    'route',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timesJsonMeta = const VerificationMeta(
    'timesJson',
  );
  @override
  late final GeneratedColumn<String> timesJson = GeneratedColumn<String>(
    'times_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetScheduleIdMeta = const VerificationMeta(
    'targetScheduleId',
  );
  @override
  late final GeneratedColumn<String> targetScheduleId = GeneratedColumn<String>(
    'target_schedule_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _missingFieldsJsonMeta = const VerificationMeta(
    'missingFieldsJson',
  );
  @override
  late final GeneratedColumn<String> missingFieldsJson =
      GeneratedColumn<String>(
        'missing_fields_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    actionId,
    proposalId,
    type,
    medicationName,
    doseAmount,
    doseUnit,
    route,
    startDate,
    endDate,
    timesJson,
    notes,
    targetScheduleId,
    missingFieldsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'proposal_actions_view';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProposalActionsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('action_id')) {
      context.handle(
        _actionIdMeta,
        actionId.isAcceptableOrUnknown(data['action_id']!, _actionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_actionIdMeta);
    }
    if (data.containsKey('proposal_id')) {
      context.handle(
        _proposalIdMeta,
        proposalId.isAcceptableOrUnknown(data['proposal_id']!, _proposalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_proposalIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('medication_name')) {
      context.handle(
        _medicationNameMeta,
        medicationName.isAcceptableOrUnknown(
          data['medication_name']!,
          _medicationNameMeta,
        ),
      );
    }
    if (data.containsKey('dose_amount')) {
      context.handle(
        _doseAmountMeta,
        doseAmount.isAcceptableOrUnknown(data['dose_amount']!, _doseAmountMeta),
      );
    }
    if (data.containsKey('dose_unit')) {
      context.handle(
        _doseUnitMeta,
        doseUnit.isAcceptableOrUnknown(data['dose_unit']!, _doseUnitMeta),
      );
    }
    if (data.containsKey('route')) {
      context.handle(
        _routeMeta,
        route.isAcceptableOrUnknown(data['route']!, _routeMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('times_json')) {
      context.handle(
        _timesJsonMeta,
        timesJson.isAcceptableOrUnknown(data['times_json']!, _timesJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_timesJsonMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('target_schedule_id')) {
      context.handle(
        _targetScheduleIdMeta,
        targetScheduleId.isAcceptableOrUnknown(
          data['target_schedule_id']!,
          _targetScheduleIdMeta,
        ),
      );
    }
    if (data.containsKey('missing_fields_json')) {
      context.handle(
        _missingFieldsJsonMeta,
        missingFieldsJson.isAcceptableOrUnknown(
          data['missing_fields_json']!,
          _missingFieldsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_missingFieldsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {actionId};
  @override
  ProposalActionsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProposalActionsTableData(
      actionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_id'],
      )!,
      proposalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proposal_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      medicationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_name'],
      ),
      doseAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dose_amount'],
      ),
      doseUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dose_unit'],
      ),
      route: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
      timesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}times_json'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      targetScheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_schedule_id'],
      ),
      missingFieldsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}missing_fields_json'],
      )!,
    );
  }

  @override
  $ProposalActionsTableTable createAlias(String alias) {
    return $ProposalActionsTableTable(attachedDatabase, alias);
  }
}

class ProposalActionsTableData extends DataClass
    implements Insertable<ProposalActionsTableData> {
  /// Action id.
  final String actionId;

  /// Parent proposal id.
  final String proposalId;

  /// Action type.
  final String type;

  /// Optional medication name.
  final String? medicationName;

  /// Optional dose amount.
  final String? doseAmount;

  /// Optional dose unit.
  final String? doseUnit;

  /// Optional route.
  final String? route;

  /// Optional start date.
  final String? startDate;

  /// Optional end date.
  final String? endDate;

  /// Encoded times list.
  final String timesJson;

  /// Optional notes.
  final String? notes;

  /// Optional target schedule id.
  final String? targetScheduleId;

  /// Encoded missing fields list.
  final String missingFieldsJson;
  const ProposalActionsTableData({
    required this.actionId,
    required this.proposalId,
    required this.type,
    this.medicationName,
    this.doseAmount,
    this.doseUnit,
    this.route,
    this.startDate,
    this.endDate,
    required this.timesJson,
    this.notes,
    this.targetScheduleId,
    required this.missingFieldsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['action_id'] = Variable<String>(actionId);
    map['proposal_id'] = Variable<String>(proposalId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || medicationName != null) {
      map['medication_name'] = Variable<String>(medicationName);
    }
    if (!nullToAbsent || doseAmount != null) {
      map['dose_amount'] = Variable<String>(doseAmount);
    }
    if (!nullToAbsent || doseUnit != null) {
      map['dose_unit'] = Variable<String>(doseUnit);
    }
    if (!nullToAbsent || route != null) {
      map['route'] = Variable<String>(route);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<String>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    map['times_json'] = Variable<String>(timesJson);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || targetScheduleId != null) {
      map['target_schedule_id'] = Variable<String>(targetScheduleId);
    }
    map['missing_fields_json'] = Variable<String>(missingFieldsJson);
    return map;
  }

  ProposalActionsTableCompanion toCompanion(bool nullToAbsent) {
    return ProposalActionsTableCompanion(
      actionId: Value(actionId),
      proposalId: Value(proposalId),
      type: Value(type),
      medicationName: medicationName == null && nullToAbsent
          ? const Value.absent()
          : Value(medicationName),
      doseAmount: doseAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(doseAmount),
      doseUnit: doseUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(doseUnit),
      route: route == null && nullToAbsent
          ? const Value.absent()
          : Value(route),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      timesJson: Value(timesJson),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      targetScheduleId: targetScheduleId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetScheduleId),
      missingFieldsJson: Value(missingFieldsJson),
    );
  }

  factory ProposalActionsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProposalActionsTableData(
      actionId: serializer.fromJson<String>(json['actionId']),
      proposalId: serializer.fromJson<String>(json['proposalId']),
      type: serializer.fromJson<String>(json['type']),
      medicationName: serializer.fromJson<String?>(json['medicationName']),
      doseAmount: serializer.fromJson<String?>(json['doseAmount']),
      doseUnit: serializer.fromJson<String?>(json['doseUnit']),
      route: serializer.fromJson<String?>(json['route']),
      startDate: serializer.fromJson<String?>(json['startDate']),
      endDate: serializer.fromJson<String?>(json['endDate']),
      timesJson: serializer.fromJson<String>(json['timesJson']),
      notes: serializer.fromJson<String?>(json['notes']),
      targetScheduleId: serializer.fromJson<String?>(json['targetScheduleId']),
      missingFieldsJson: serializer.fromJson<String>(json['missingFieldsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'actionId': serializer.toJson<String>(actionId),
      'proposalId': serializer.toJson<String>(proposalId),
      'type': serializer.toJson<String>(type),
      'medicationName': serializer.toJson<String?>(medicationName),
      'doseAmount': serializer.toJson<String?>(doseAmount),
      'doseUnit': serializer.toJson<String?>(doseUnit),
      'route': serializer.toJson<String?>(route),
      'startDate': serializer.toJson<String?>(startDate),
      'endDate': serializer.toJson<String?>(endDate),
      'timesJson': serializer.toJson<String>(timesJson),
      'notes': serializer.toJson<String?>(notes),
      'targetScheduleId': serializer.toJson<String?>(targetScheduleId),
      'missingFieldsJson': serializer.toJson<String>(missingFieldsJson),
    };
  }

  ProposalActionsTableData copyWith({
    String? actionId,
    String? proposalId,
    String? type,
    Value<String?> medicationName = const Value.absent(),
    Value<String?> doseAmount = const Value.absent(),
    Value<String?> doseUnit = const Value.absent(),
    Value<String?> route = const Value.absent(),
    Value<String?> startDate = const Value.absent(),
    Value<String?> endDate = const Value.absent(),
    String? timesJson,
    Value<String?> notes = const Value.absent(),
    Value<String?> targetScheduleId = const Value.absent(),
    String? missingFieldsJson,
  }) => ProposalActionsTableData(
    actionId: actionId ?? this.actionId,
    proposalId: proposalId ?? this.proposalId,
    type: type ?? this.type,
    medicationName: medicationName.present
        ? medicationName.value
        : this.medicationName,
    doseAmount: doseAmount.present ? doseAmount.value : this.doseAmount,
    doseUnit: doseUnit.present ? doseUnit.value : this.doseUnit,
    route: route.present ? route.value : this.route,
    startDate: startDate.present ? startDate.value : this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    timesJson: timesJson ?? this.timesJson,
    notes: notes.present ? notes.value : this.notes,
    targetScheduleId: targetScheduleId.present
        ? targetScheduleId.value
        : this.targetScheduleId,
    missingFieldsJson: missingFieldsJson ?? this.missingFieldsJson,
  );
  ProposalActionsTableData copyWithCompanion(
    ProposalActionsTableCompanion data,
  ) {
    return ProposalActionsTableData(
      actionId: data.actionId.present ? data.actionId.value : this.actionId,
      proposalId: data.proposalId.present
          ? data.proposalId.value
          : this.proposalId,
      type: data.type.present ? data.type.value : this.type,
      medicationName: data.medicationName.present
          ? data.medicationName.value
          : this.medicationName,
      doseAmount: data.doseAmount.present
          ? data.doseAmount.value
          : this.doseAmount,
      doseUnit: data.doseUnit.present ? data.doseUnit.value : this.doseUnit,
      route: data.route.present ? data.route.value : this.route,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      timesJson: data.timesJson.present ? data.timesJson.value : this.timesJson,
      notes: data.notes.present ? data.notes.value : this.notes,
      targetScheduleId: data.targetScheduleId.present
          ? data.targetScheduleId.value
          : this.targetScheduleId,
      missingFieldsJson: data.missingFieldsJson.present
          ? data.missingFieldsJson.value
          : this.missingFieldsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProposalActionsTableData(')
          ..write('actionId: $actionId, ')
          ..write('proposalId: $proposalId, ')
          ..write('type: $type, ')
          ..write('medicationName: $medicationName, ')
          ..write('doseAmount: $doseAmount, ')
          ..write('doseUnit: $doseUnit, ')
          ..write('route: $route, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('timesJson: $timesJson, ')
          ..write('notes: $notes, ')
          ..write('targetScheduleId: $targetScheduleId, ')
          ..write('missingFieldsJson: $missingFieldsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    actionId,
    proposalId,
    type,
    medicationName,
    doseAmount,
    doseUnit,
    route,
    startDate,
    endDate,
    timesJson,
    notes,
    targetScheduleId,
    missingFieldsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProposalActionsTableData &&
          other.actionId == this.actionId &&
          other.proposalId == this.proposalId &&
          other.type == this.type &&
          other.medicationName == this.medicationName &&
          other.doseAmount == this.doseAmount &&
          other.doseUnit == this.doseUnit &&
          other.route == this.route &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.timesJson == this.timesJson &&
          other.notes == this.notes &&
          other.targetScheduleId == this.targetScheduleId &&
          other.missingFieldsJson == this.missingFieldsJson);
}

class ProposalActionsTableCompanion
    extends UpdateCompanion<ProposalActionsTableData> {
  final Value<String> actionId;
  final Value<String> proposalId;
  final Value<String> type;
  final Value<String?> medicationName;
  final Value<String?> doseAmount;
  final Value<String?> doseUnit;
  final Value<String?> route;
  final Value<String?> startDate;
  final Value<String?> endDate;
  final Value<String> timesJson;
  final Value<String?> notes;
  final Value<String?> targetScheduleId;
  final Value<String> missingFieldsJson;
  final Value<int> rowid;
  const ProposalActionsTableCompanion({
    this.actionId = const Value.absent(),
    this.proposalId = const Value.absent(),
    this.type = const Value.absent(),
    this.medicationName = const Value.absent(),
    this.doseAmount = const Value.absent(),
    this.doseUnit = const Value.absent(),
    this.route = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.timesJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.targetScheduleId = const Value.absent(),
    this.missingFieldsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProposalActionsTableCompanion.insert({
    required String actionId,
    required String proposalId,
    required String type,
    this.medicationName = const Value.absent(),
    this.doseAmount = const Value.absent(),
    this.doseUnit = const Value.absent(),
    this.route = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    required String timesJson,
    this.notes = const Value.absent(),
    this.targetScheduleId = const Value.absent(),
    required String missingFieldsJson,
    this.rowid = const Value.absent(),
  }) : actionId = Value(actionId),
       proposalId = Value(proposalId),
       type = Value(type),
       timesJson = Value(timesJson),
       missingFieldsJson = Value(missingFieldsJson);
  static Insertable<ProposalActionsTableData> custom({
    Expression<String>? actionId,
    Expression<String>? proposalId,
    Expression<String>? type,
    Expression<String>? medicationName,
    Expression<String>? doseAmount,
    Expression<String>? doseUnit,
    Expression<String>? route,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? timesJson,
    Expression<String>? notes,
    Expression<String>? targetScheduleId,
    Expression<String>? missingFieldsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (actionId != null) 'action_id': actionId,
      if (proposalId != null) 'proposal_id': proposalId,
      if (type != null) 'type': type,
      if (medicationName != null) 'medication_name': medicationName,
      if (doseAmount != null) 'dose_amount': doseAmount,
      if (doseUnit != null) 'dose_unit': doseUnit,
      if (route != null) 'route': route,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (timesJson != null) 'times_json': timesJson,
      if (notes != null) 'notes': notes,
      if (targetScheduleId != null) 'target_schedule_id': targetScheduleId,
      if (missingFieldsJson != null) 'missing_fields_json': missingFieldsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProposalActionsTableCompanion copyWith({
    Value<String>? actionId,
    Value<String>? proposalId,
    Value<String>? type,
    Value<String?>? medicationName,
    Value<String?>? doseAmount,
    Value<String?>? doseUnit,
    Value<String?>? route,
    Value<String?>? startDate,
    Value<String?>? endDate,
    Value<String>? timesJson,
    Value<String?>? notes,
    Value<String?>? targetScheduleId,
    Value<String>? missingFieldsJson,
    Value<int>? rowid,
  }) {
    return ProposalActionsTableCompanion(
      actionId: actionId ?? this.actionId,
      proposalId: proposalId ?? this.proposalId,
      type: type ?? this.type,
      medicationName: medicationName ?? this.medicationName,
      doseAmount: doseAmount ?? this.doseAmount,
      doseUnit: doseUnit ?? this.doseUnit,
      route: route ?? this.route,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      timesJson: timesJson ?? this.timesJson,
      notes: notes ?? this.notes,
      targetScheduleId: targetScheduleId ?? this.targetScheduleId,
      missingFieldsJson: missingFieldsJson ?? this.missingFieldsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (actionId.present) {
      map['action_id'] = Variable<String>(actionId.value);
    }
    if (proposalId.present) {
      map['proposal_id'] = Variable<String>(proposalId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (medicationName.present) {
      map['medication_name'] = Variable<String>(medicationName.value);
    }
    if (doseAmount.present) {
      map['dose_amount'] = Variable<String>(doseAmount.value);
    }
    if (doseUnit.present) {
      map['dose_unit'] = Variable<String>(doseUnit.value);
    }
    if (route.present) {
      map['route'] = Variable<String>(route.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (timesJson.present) {
      map['times_json'] = Variable<String>(timesJson.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (targetScheduleId.present) {
      map['target_schedule_id'] = Variable<String>(targetScheduleId.value);
    }
    if (missingFieldsJson.present) {
      map['missing_fields_json'] = Variable<String>(missingFieldsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProposalActionsTableCompanion(')
          ..write('actionId: $actionId, ')
          ..write('proposalId: $proposalId, ')
          ..write('type: $type, ')
          ..write('medicationName: $medicationName, ')
          ..write('doseAmount: $doseAmount, ')
          ..write('doseUnit: $doseUnit, ')
          ..write('route: $route, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('timesJson: $timesJson, ')
          ..write('notes: $notes, ')
          ..write('targetScheduleId: $targetScheduleId, ')
          ..write('missingFieldsJson: $missingFieldsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicationsTableTable extends MedicationsTable
    with TableInfo<$MedicationsTableTable, MedicationsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medicationNameMeta = const VerificationMeta(
    'medicationName',
  );
  @override
  late final GeneratedColumn<String> medicationName = GeneratedColumn<String>(
    'medication_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [medicationId, medicationName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medications_view';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('medication_name')) {
      context.handle(
        _medicationNameMeta,
        medicationName.isAcceptableOrUnknown(
          data['medication_name']!,
          _medicationNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {medicationId};
  @override
  MedicationsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationsTableData(
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_id'],
      )!,
      medicationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_name'],
      )!,
    );
  }

  @override
  $MedicationsTableTable createAlias(String alias) {
    return $MedicationsTableTable(attachedDatabase, alias);
  }
}

class MedicationsTableData extends DataClass
    implements Insertable<MedicationsTableData> {
  /// Medication id.
  final String medicationId;

  /// Medication name.
  final String medicationName;
  const MedicationsTableData({
    required this.medicationId,
    required this.medicationName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['medication_id'] = Variable<String>(medicationId);
    map['medication_name'] = Variable<String>(medicationName);
    return map;
  }

  MedicationsTableCompanion toCompanion(bool nullToAbsent) {
    return MedicationsTableCompanion(
      medicationId: Value(medicationId),
      medicationName: Value(medicationName),
    );
  }

  factory MedicationsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationsTableData(
      medicationId: serializer.fromJson<String>(json['medicationId']),
      medicationName: serializer.fromJson<String>(json['medicationName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'medicationId': serializer.toJson<String>(medicationId),
      'medicationName': serializer.toJson<String>(medicationName),
    };
  }

  MedicationsTableData copyWith({
    String? medicationId,
    String? medicationName,
  }) => MedicationsTableData(
    medicationId: medicationId ?? this.medicationId,
    medicationName: medicationName ?? this.medicationName,
  );
  MedicationsTableData copyWithCompanion(MedicationsTableCompanion data) {
    return MedicationsTableData(
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      medicationName: data.medicationName.present
          ? data.medicationName.value
          : this.medicationName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationsTableData(')
          ..write('medicationId: $medicationId, ')
          ..write('medicationName: $medicationName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(medicationId, medicationName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationsTableData &&
          other.medicationId == this.medicationId &&
          other.medicationName == this.medicationName);
}

class MedicationsTableCompanion extends UpdateCompanion<MedicationsTableData> {
  final Value<String> medicationId;
  final Value<String> medicationName;
  final Value<int> rowid;
  const MedicationsTableCompanion({
    this.medicationId = const Value.absent(),
    this.medicationName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationsTableCompanion.insert({
    required String medicationId,
    required String medicationName,
    this.rowid = const Value.absent(),
  }) : medicationId = Value(medicationId),
       medicationName = Value(medicationName);
  static Insertable<MedicationsTableData> custom({
    Expression<String>? medicationId,
    Expression<String>? medicationName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (medicationId != null) 'medication_id': medicationId,
      if (medicationName != null) 'medication_name': medicationName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationsTableCompanion copyWith({
    Value<String>? medicationId,
    Value<String>? medicationName,
    Value<int>? rowid,
  }) {
    return MedicationsTableCompanion(
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (medicationId.present) {
      map['medication_id'] = Variable<String>(medicationId.value);
    }
    if (medicationName.present) {
      map['medication_name'] = Variable<String>(medicationName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationsTableCompanion(')
          ..write('medicationId: $medicationId, ')
          ..write('medicationName: $medicationName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicationSchedulesTableTable extends MedicationSchedulesTable
    with
        TableInfo<
          $MedicationSchedulesTableTable,
          MedicationSchedulesTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationSchedulesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  @override
  late final GeneratedColumn<String> scheduleId = GeneratedColumn<String>(
    'schedule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medicationNameMeta = const VerificationMeta(
    'medicationName',
  );
  @override
  late final GeneratedColumn<String> medicationName = GeneratedColumn<String>(
    'medication_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doseAmountMeta = const VerificationMeta(
    'doseAmount',
  );
  @override
  late final GeneratedColumn<String> doseAmount = GeneratedColumn<String>(
    'dose_amount',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _doseUnitMeta = const VerificationMeta(
    'doseUnit',
  );
  @override
  late final GeneratedColumn<String> doseUnit = GeneratedColumn<String>(
    'dose_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routeMeta = const VerificationMeta('route');
  @override
  late final GeneratedColumn<String> route = GeneratedColumn<String>(
    'route',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timesJsonMeta = const VerificationMeta(
    'timesJson',
  );
  @override
  late final GeneratedColumn<String> timesJson = GeneratedColumn<String>(
    'times_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceProposalIdMeta = const VerificationMeta(
    'sourceProposalId',
  );
  @override
  late final GeneratedColumn<String> sourceProposalId = GeneratedColumn<String>(
    'source_proposal_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _threadIdMeta = const VerificationMeta(
    'threadId',
  );
  @override
  late final GeneratedColumn<String> threadId = GeneratedColumn<String>(
    'thread_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    scheduleId,
    medicationName,
    doseAmount,
    doseUnit,
    route,
    startDate,
    endDate,
    timesJson,
    notes,
    sourceProposalId,
    threadId,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_schedules_view';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationSchedulesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('schedule_id')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(data['schedule_id']!, _scheduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scheduleIdMeta);
    }
    if (data.containsKey('medication_name')) {
      context.handle(
        _medicationNameMeta,
        medicationName.isAcceptableOrUnknown(
          data['medication_name']!,
          _medicationNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationNameMeta);
    }
    if (data.containsKey('dose_amount')) {
      context.handle(
        _doseAmountMeta,
        doseAmount.isAcceptableOrUnknown(data['dose_amount']!, _doseAmountMeta),
      );
    }
    if (data.containsKey('dose_unit')) {
      context.handle(
        _doseUnitMeta,
        doseUnit.isAcceptableOrUnknown(data['dose_unit']!, _doseUnitMeta),
      );
    }
    if (data.containsKey('route')) {
      context.handle(
        _routeMeta,
        route.isAcceptableOrUnknown(data['route']!, _routeMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('times_json')) {
      context.handle(
        _timesJsonMeta,
        timesJson.isAcceptableOrUnknown(data['times_json']!, _timesJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_timesJsonMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('source_proposal_id')) {
      context.handle(
        _sourceProposalIdMeta,
        sourceProposalId.isAcceptableOrUnknown(
          data['source_proposal_id']!,
          _sourceProposalIdMeta,
        ),
      );
    }
    if (data.containsKey('thread_id')) {
      context.handle(
        _threadIdMeta,
        threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scheduleId};
  @override
  MedicationSchedulesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationSchedulesTableData(
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_id'],
      )!,
      medicationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_name'],
      )!,
      doseAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dose_amount'],
      ),
      doseUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dose_unit'],
      ),
      route: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
      timesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}times_json'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      sourceProposalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_proposal_id'],
      ),
      threadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thread_id'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $MedicationSchedulesTableTable createAlias(String alias) {
    return $MedicationSchedulesTableTable(attachedDatabase, alias);
  }
}

class MedicationSchedulesTableData extends DataClass
    implements Insertable<MedicationSchedulesTableData> {
  /// Schedule id.
  final String scheduleId;

  /// Medication name.
  final String medicationName;

  /// Optional dose amount.
  final String? doseAmount;

  /// Optional dose unit.
  final String? doseUnit;

  /// Optional route.
  final String? route;

  /// Start date.
  final String startDate;

  /// Optional end date.
  final String? endDate;

  /// Encoded times list.
  final String timesJson;

  /// Optional notes.
  final String? notes;

  /// Source proposal id.
  final String? sourceProposalId;

  /// Source thread id.
  final String? threadId;

  /// Active flag.
  final bool isActive;
  const MedicationSchedulesTableData({
    required this.scheduleId,
    required this.medicationName,
    this.doseAmount,
    this.doseUnit,
    this.route,
    required this.startDate,
    this.endDate,
    required this.timesJson,
    this.notes,
    this.sourceProposalId,
    this.threadId,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['schedule_id'] = Variable<String>(scheduleId);
    map['medication_name'] = Variable<String>(medicationName);
    if (!nullToAbsent || doseAmount != null) {
      map['dose_amount'] = Variable<String>(doseAmount);
    }
    if (!nullToAbsent || doseUnit != null) {
      map['dose_unit'] = Variable<String>(doseUnit);
    }
    if (!nullToAbsent || route != null) {
      map['route'] = Variable<String>(route);
    }
    map['start_date'] = Variable<String>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    map['times_json'] = Variable<String>(timesJson);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || sourceProposalId != null) {
      map['source_proposal_id'] = Variable<String>(sourceProposalId);
    }
    if (!nullToAbsent || threadId != null) {
      map['thread_id'] = Variable<String>(threadId);
    }
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  MedicationSchedulesTableCompanion toCompanion(bool nullToAbsent) {
    return MedicationSchedulesTableCompanion(
      scheduleId: Value(scheduleId),
      medicationName: Value(medicationName),
      doseAmount: doseAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(doseAmount),
      doseUnit: doseUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(doseUnit),
      route: route == null && nullToAbsent
          ? const Value.absent()
          : Value(route),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      timesJson: Value(timesJson),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      sourceProposalId: sourceProposalId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceProposalId),
      threadId: threadId == null && nullToAbsent
          ? const Value.absent()
          : Value(threadId),
      isActive: Value(isActive),
    );
  }

  factory MedicationSchedulesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationSchedulesTableData(
      scheduleId: serializer.fromJson<String>(json['scheduleId']),
      medicationName: serializer.fromJson<String>(json['medicationName']),
      doseAmount: serializer.fromJson<String?>(json['doseAmount']),
      doseUnit: serializer.fromJson<String?>(json['doseUnit']),
      route: serializer.fromJson<String?>(json['route']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String?>(json['endDate']),
      timesJson: serializer.fromJson<String>(json['timesJson']),
      notes: serializer.fromJson<String?>(json['notes']),
      sourceProposalId: serializer.fromJson<String?>(json['sourceProposalId']),
      threadId: serializer.fromJson<String?>(json['threadId']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scheduleId': serializer.toJson<String>(scheduleId),
      'medicationName': serializer.toJson<String>(medicationName),
      'doseAmount': serializer.toJson<String?>(doseAmount),
      'doseUnit': serializer.toJson<String?>(doseUnit),
      'route': serializer.toJson<String?>(route),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String?>(endDate),
      'timesJson': serializer.toJson<String>(timesJson),
      'notes': serializer.toJson<String?>(notes),
      'sourceProposalId': serializer.toJson<String?>(sourceProposalId),
      'threadId': serializer.toJson<String?>(threadId),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  MedicationSchedulesTableData copyWith({
    String? scheduleId,
    String? medicationName,
    Value<String?> doseAmount = const Value.absent(),
    Value<String?> doseUnit = const Value.absent(),
    Value<String?> route = const Value.absent(),
    String? startDate,
    Value<String?> endDate = const Value.absent(),
    String? timesJson,
    Value<String?> notes = const Value.absent(),
    Value<String?> sourceProposalId = const Value.absent(),
    Value<String?> threadId = const Value.absent(),
    bool? isActive,
  }) => MedicationSchedulesTableData(
    scheduleId: scheduleId ?? this.scheduleId,
    medicationName: medicationName ?? this.medicationName,
    doseAmount: doseAmount.present ? doseAmount.value : this.doseAmount,
    doseUnit: doseUnit.present ? doseUnit.value : this.doseUnit,
    route: route.present ? route.value : this.route,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    timesJson: timesJson ?? this.timesJson,
    notes: notes.present ? notes.value : this.notes,
    sourceProposalId: sourceProposalId.present
        ? sourceProposalId.value
        : this.sourceProposalId,
    threadId: threadId.present ? threadId.value : this.threadId,
    isActive: isActive ?? this.isActive,
  );
  MedicationSchedulesTableData copyWithCompanion(
    MedicationSchedulesTableCompanion data,
  ) {
    return MedicationSchedulesTableData(
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      medicationName: data.medicationName.present
          ? data.medicationName.value
          : this.medicationName,
      doseAmount: data.doseAmount.present
          ? data.doseAmount.value
          : this.doseAmount,
      doseUnit: data.doseUnit.present ? data.doseUnit.value : this.doseUnit,
      route: data.route.present ? data.route.value : this.route,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      timesJson: data.timesJson.present ? data.timesJson.value : this.timesJson,
      notes: data.notes.present ? data.notes.value : this.notes,
      sourceProposalId: data.sourceProposalId.present
          ? data.sourceProposalId.value
          : this.sourceProposalId,
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationSchedulesTableData(')
          ..write('scheduleId: $scheduleId, ')
          ..write('medicationName: $medicationName, ')
          ..write('doseAmount: $doseAmount, ')
          ..write('doseUnit: $doseUnit, ')
          ..write('route: $route, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('timesJson: $timesJson, ')
          ..write('notes: $notes, ')
          ..write('sourceProposalId: $sourceProposalId, ')
          ..write('threadId: $threadId, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    scheduleId,
    medicationName,
    doseAmount,
    doseUnit,
    route,
    startDate,
    endDate,
    timesJson,
    notes,
    sourceProposalId,
    threadId,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationSchedulesTableData &&
          other.scheduleId == this.scheduleId &&
          other.medicationName == this.medicationName &&
          other.doseAmount == this.doseAmount &&
          other.doseUnit == this.doseUnit &&
          other.route == this.route &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.timesJson == this.timesJson &&
          other.notes == this.notes &&
          other.sourceProposalId == this.sourceProposalId &&
          other.threadId == this.threadId &&
          other.isActive == this.isActive);
}

class MedicationSchedulesTableCompanion
    extends UpdateCompanion<MedicationSchedulesTableData> {
  final Value<String> scheduleId;
  final Value<String> medicationName;
  final Value<String?> doseAmount;
  final Value<String?> doseUnit;
  final Value<String?> route;
  final Value<String> startDate;
  final Value<String?> endDate;
  final Value<String> timesJson;
  final Value<String?> notes;
  final Value<String?> sourceProposalId;
  final Value<String?> threadId;
  final Value<bool> isActive;
  final Value<int> rowid;
  const MedicationSchedulesTableCompanion({
    this.scheduleId = const Value.absent(),
    this.medicationName = const Value.absent(),
    this.doseAmount = const Value.absent(),
    this.doseUnit = const Value.absent(),
    this.route = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.timesJson = const Value.absent(),
    this.notes = const Value.absent(),
    this.sourceProposalId = const Value.absent(),
    this.threadId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationSchedulesTableCompanion.insert({
    required String scheduleId,
    required String medicationName,
    this.doseAmount = const Value.absent(),
    this.doseUnit = const Value.absent(),
    this.route = const Value.absent(),
    required String startDate,
    this.endDate = const Value.absent(),
    required String timesJson,
    this.notes = const Value.absent(),
    this.sourceProposalId = const Value.absent(),
    this.threadId = const Value.absent(),
    required bool isActive,
    this.rowid = const Value.absent(),
  }) : scheduleId = Value(scheduleId),
       medicationName = Value(medicationName),
       startDate = Value(startDate),
       timesJson = Value(timesJson),
       isActive = Value(isActive);
  static Insertable<MedicationSchedulesTableData> custom({
    Expression<String>? scheduleId,
    Expression<String>? medicationName,
    Expression<String>? doseAmount,
    Expression<String>? doseUnit,
    Expression<String>? route,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? timesJson,
    Expression<String>? notes,
    Expression<String>? sourceProposalId,
    Expression<String>? threadId,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scheduleId != null) 'schedule_id': scheduleId,
      if (medicationName != null) 'medication_name': medicationName,
      if (doseAmount != null) 'dose_amount': doseAmount,
      if (doseUnit != null) 'dose_unit': doseUnit,
      if (route != null) 'route': route,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (timesJson != null) 'times_json': timesJson,
      if (notes != null) 'notes': notes,
      if (sourceProposalId != null) 'source_proposal_id': sourceProposalId,
      if (threadId != null) 'thread_id': threadId,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationSchedulesTableCompanion copyWith({
    Value<String>? scheduleId,
    Value<String>? medicationName,
    Value<String?>? doseAmount,
    Value<String?>? doseUnit,
    Value<String?>? route,
    Value<String>? startDate,
    Value<String?>? endDate,
    Value<String>? timesJson,
    Value<String?>? notes,
    Value<String?>? sourceProposalId,
    Value<String?>? threadId,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return MedicationSchedulesTableCompanion(
      scheduleId: scheduleId ?? this.scheduleId,
      medicationName: medicationName ?? this.medicationName,
      doseAmount: doseAmount ?? this.doseAmount,
      doseUnit: doseUnit ?? this.doseUnit,
      route: route ?? this.route,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      timesJson: timesJson ?? this.timesJson,
      notes: notes ?? this.notes,
      sourceProposalId: sourceProposalId ?? this.sourceProposalId,
      threadId: threadId ?? this.threadId,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scheduleId.present) {
      map['schedule_id'] = Variable<String>(scheduleId.value);
    }
    if (medicationName.present) {
      map['medication_name'] = Variable<String>(medicationName.value);
    }
    if (doseAmount.present) {
      map['dose_amount'] = Variable<String>(doseAmount.value);
    }
    if (doseUnit.present) {
      map['dose_unit'] = Variable<String>(doseUnit.value);
    }
    if (route.present) {
      map['route'] = Variable<String>(route.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (timesJson.present) {
      map['times_json'] = Variable<String>(timesJson.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (sourceProposalId.present) {
      map['source_proposal_id'] = Variable<String>(sourceProposalId.value);
    }
    if (threadId.present) {
      map['thread_id'] = Variable<String>(threadId.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationSchedulesTableCompanion(')
          ..write('scheduleId: $scheduleId, ')
          ..write('medicationName: $medicationName, ')
          ..write('doseAmount: $doseAmount, ')
          ..write('doseUnit: $doseUnit, ')
          ..write('route: $route, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('timesJson: $timesJson, ')
          ..write('notes: $notes, ')
          ..write('sourceProposalId: $sourceProposalId, ')
          ..write('threadId: $threadId, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicationScheduleTimesTableTable extends MedicationScheduleTimesTable
    with
        TableInfo<
          $MedicationScheduleTimesTableTable,
          MedicationScheduleTimesTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationScheduleTimesTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  @override
  late final GeneratedColumn<String> scheduleId = GeneratedColumn<String>(
    'schedule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeOfDayMeta = const VerificationMeta(
    'timeOfDay',
  );
  @override
  late final GeneratedColumn<String> timeOfDay = GeneratedColumn<String>(
    'time_of_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, scheduleId, timeOfDay];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_schedule_times_view';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationScheduleTimesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('schedule_id')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(data['schedule_id']!, _scheduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scheduleIdMeta);
    }
    if (data.containsKey('time_of_day')) {
      context.handle(
        _timeOfDayMeta,
        timeOfDay.isAcceptableOrUnknown(data['time_of_day']!, _timeOfDayMeta),
      );
    } else if (isInserting) {
      context.missing(_timeOfDayMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationScheduleTimesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationScheduleTimesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_id'],
      )!,
      timeOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_of_day'],
      )!,
    );
  }

  @override
  $MedicationScheduleTimesTableTable createAlias(String alias) {
    return $MedicationScheduleTimesTableTable(attachedDatabase, alias);
  }
}

class MedicationScheduleTimesTableData extends DataClass
    implements Insertable<MedicationScheduleTimesTableData> {
  /// Synthetic id.
  final int id;

  /// Parent schedule id.
  final String scheduleId;

  /// Time in `HH:mm`.
  final String timeOfDay;
  const MedicationScheduleTimesTableData({
    required this.id,
    required this.scheduleId,
    required this.timeOfDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['schedule_id'] = Variable<String>(scheduleId);
    map['time_of_day'] = Variable<String>(timeOfDay);
    return map;
  }

  MedicationScheduleTimesTableCompanion toCompanion(bool nullToAbsent) {
    return MedicationScheduleTimesTableCompanion(
      id: Value(id),
      scheduleId: Value(scheduleId),
      timeOfDay: Value(timeOfDay),
    );
  }

  factory MedicationScheduleTimesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationScheduleTimesTableData(
      id: serializer.fromJson<int>(json['id']),
      scheduleId: serializer.fromJson<String>(json['scheduleId']),
      timeOfDay: serializer.fromJson<String>(json['timeOfDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scheduleId': serializer.toJson<String>(scheduleId),
      'timeOfDay': serializer.toJson<String>(timeOfDay),
    };
  }

  MedicationScheduleTimesTableData copyWith({
    int? id,
    String? scheduleId,
    String? timeOfDay,
  }) => MedicationScheduleTimesTableData(
    id: id ?? this.id,
    scheduleId: scheduleId ?? this.scheduleId,
    timeOfDay: timeOfDay ?? this.timeOfDay,
  );
  MedicationScheduleTimesTableData copyWithCompanion(
    MedicationScheduleTimesTableCompanion data,
  ) {
    return MedicationScheduleTimesTableData(
      id: data.id.present ? data.id.value : this.id,
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      timeOfDay: data.timeOfDay.present ? data.timeOfDay.value : this.timeOfDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationScheduleTimesTableData(')
          ..write('id: $id, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('timeOfDay: $timeOfDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, scheduleId, timeOfDay);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationScheduleTimesTableData &&
          other.id == this.id &&
          other.scheduleId == this.scheduleId &&
          other.timeOfDay == this.timeOfDay);
}

class MedicationScheduleTimesTableCompanion
    extends UpdateCompanion<MedicationScheduleTimesTableData> {
  final Value<int> id;
  final Value<String> scheduleId;
  final Value<String> timeOfDay;
  const MedicationScheduleTimesTableCompanion({
    this.id = const Value.absent(),
    this.scheduleId = const Value.absent(),
    this.timeOfDay = const Value.absent(),
  });
  MedicationScheduleTimesTableCompanion.insert({
    this.id = const Value.absent(),
    required String scheduleId,
    required String timeOfDay,
  }) : scheduleId = Value(scheduleId),
       timeOfDay = Value(timeOfDay);
  static Insertable<MedicationScheduleTimesTableData> custom({
    Expression<int>? id,
    Expression<String>? scheduleId,
    Expression<String>? timeOfDay,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scheduleId != null) 'schedule_id': scheduleId,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
    });
  }

  MedicationScheduleTimesTableCompanion copyWith({
    Value<int>? id,
    Value<String>? scheduleId,
    Value<String>? timeOfDay,
  }) {
    return MedicationScheduleTimesTableCompanion(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      timeOfDay: timeOfDay ?? this.timeOfDay,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scheduleId.present) {
      map['schedule_id'] = Variable<String>(scheduleId.value);
    }
    if (timeOfDay.present) {
      map['time_of_day'] = Variable<String>(timeOfDay.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationScheduleTimesTableCompanion(')
          ..write('id: $id, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('timeOfDay: $timeOfDay')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EventLogTable eventLog = $EventLogTable(this);
  late final $ConversationThreadsTableTable conversationThreadsTable =
      $ConversationThreadsTableTable(this);
  late final $MessagesTableTable messagesTable = $MessagesTableTable(this);
  late final $ProposalsTableTable proposalsTable = $ProposalsTableTable(this);
  late final $ProposalActionsTableTable proposalActionsTable =
      $ProposalActionsTableTable(this);
  late final $MedicationsTableTable medicationsTable = $MedicationsTableTable(
    this,
  );
  late final $MedicationSchedulesTableTable medicationSchedulesTable =
      $MedicationSchedulesTableTable(this);
  late final $MedicationScheduleTimesTableTable medicationScheduleTimesTable =
      $MedicationScheduleTimesTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    eventLog,
    conversationThreadsTable,
    messagesTable,
    proposalsTable,
    proposalActionsTable,
    medicationsTable,
    medicationSchedulesTable,
    medicationScheduleTimesTable,
  ];
}

typedef $$EventLogTableCreateCompanionBuilder =
    EventLogCompanion Function({
      required String eventId,
      required String aggregateType,
      required String aggregateId,
      required String eventType,
      required DateTime occurredAt,
      Value<String?> causationId,
      Value<String?> correlationId,
      required String actorType,
      required String payloadJson,
      Value<int> rowid,
    });
typedef $$EventLogTableUpdateCompanionBuilder =
    EventLogCompanion Function({
      Value<String> eventId,
      Value<String> aggregateType,
      Value<String> aggregateId,
      Value<String> eventType,
      Value<DateTime> occurredAt,
      Value<String?> causationId,
      Value<String?> correlationId,
      Value<String> actorType,
      Value<String> payloadJson,
      Value<int> rowid,
    });

class $$EventLogTableFilterComposer
    extends Composer<_$AppDatabase, $EventLogTable> {
  $$EventLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aggregateType => $composableBuilder(
    column: $table.aggregateType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aggregateId => $composableBuilder(
    column: $table.aggregateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get causationId => $composableBuilder(
    column: $table.causationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correlationId => $composableBuilder(
    column: $table.correlationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actorType => $composableBuilder(
    column: $table.actorType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventLogTableOrderingComposer
    extends Composer<_$AppDatabase, $EventLogTable> {
  $$EventLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aggregateType => $composableBuilder(
    column: $table.aggregateType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aggregateId => $composableBuilder(
    column: $table.aggregateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get causationId => $composableBuilder(
    column: $table.causationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correlationId => $composableBuilder(
    column: $table.correlationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actorType => $composableBuilder(
    column: $table.actorType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventLogTable> {
  $$EventLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get aggregateType => $composableBuilder(
    column: $table.aggregateType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aggregateId => $composableBuilder(
    column: $table.aggregateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get causationId => $composableBuilder(
    column: $table.causationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get correlationId => $composableBuilder(
    column: $table.correlationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actorType =>
      $composableBuilder(column: $table.actorType, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );
}

class $$EventLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventLogTable,
          EventLogData,
          $$EventLogTableFilterComposer,
          $$EventLogTableOrderingComposer,
          $$EventLogTableAnnotationComposer,
          $$EventLogTableCreateCompanionBuilder,
          $$EventLogTableUpdateCompanionBuilder,
          (
            EventLogData,
            BaseReferences<_$AppDatabase, $EventLogTable, EventLogData>,
          ),
          EventLogData,
          PrefetchHooks Function()
        > {
  $$EventLogTableTableManager(_$AppDatabase db, $EventLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<String> aggregateType = const Value.absent(),
                Value<String> aggregateId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String?> causationId = const Value.absent(),
                Value<String?> correlationId = const Value.absent(),
                Value<String> actorType = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventLogCompanion(
                eventId: eventId,
                aggregateType: aggregateType,
                aggregateId: aggregateId,
                eventType: eventType,
                occurredAt: occurredAt,
                causationId: causationId,
                correlationId: correlationId,
                actorType: actorType,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required String aggregateType,
                required String aggregateId,
                required String eventType,
                required DateTime occurredAt,
                Value<String?> causationId = const Value.absent(),
                Value<String?> correlationId = const Value.absent(),
                required String actorType,
                required String payloadJson,
                Value<int> rowid = const Value.absent(),
              }) => EventLogCompanion.insert(
                eventId: eventId,
                aggregateType: aggregateType,
                aggregateId: aggregateId,
                eventType: eventType,
                occurredAt: occurredAt,
                causationId: causationId,
                correlationId: correlationId,
                actorType: actorType,
                payloadJson: payloadJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventLogTable,
      EventLogData,
      $$EventLogTableFilterComposer,
      $$EventLogTableOrderingComposer,
      $$EventLogTableAnnotationComposer,
      $$EventLogTableCreateCompanionBuilder,
      $$EventLogTableUpdateCompanionBuilder,
      (
        EventLogData,
        BaseReferences<_$AppDatabase, $EventLogTable, EventLogData>,
      ),
      EventLogData,
      PrefetchHooks Function()
    >;
typedef $$ConversationThreadsTableTableCreateCompanionBuilder =
    ConversationThreadsTableCompanion Function({
      required String threadId,
      required String title,
      required String lastMessagePreview,
      required DateTime lastUpdatedAt,
      required int pendingProposalCount,
      Value<int> rowid,
    });
typedef $$ConversationThreadsTableTableUpdateCompanionBuilder =
    ConversationThreadsTableCompanion Function({
      Value<String> threadId,
      Value<String> title,
      Value<String> lastMessagePreview,
      Value<DateTime> lastUpdatedAt,
      Value<int> pendingProposalCount,
      Value<int> rowid,
    });

class $$ConversationThreadsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationThreadsTableTable> {
  $$ConversationThreadsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pendingProposalCount => $composableBuilder(
    column: $table.pendingProposalCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConversationThreadsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationThreadsTableTable> {
  $$ConversationThreadsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pendingProposalCount => $composableBuilder(
    column: $table.pendingProposalCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConversationThreadsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationThreadsTableTable> {
  $$ConversationThreadsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get threadId =>
      $composableBuilder(column: $table.threadId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pendingProposalCount => $composableBuilder(
    column: $table.pendingProposalCount,
    builder: (column) => column,
  );
}

class $$ConversationThreadsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationThreadsTableTable,
          ConversationThreadsTableData,
          $$ConversationThreadsTableTableFilterComposer,
          $$ConversationThreadsTableTableOrderingComposer,
          $$ConversationThreadsTableTableAnnotationComposer,
          $$ConversationThreadsTableTableCreateCompanionBuilder,
          $$ConversationThreadsTableTableUpdateCompanionBuilder,
          (
            ConversationThreadsTableData,
            BaseReferences<
              _$AppDatabase,
              $ConversationThreadsTableTable,
              ConversationThreadsTableData
            >,
          ),
          ConversationThreadsTableData,
          PrefetchHooks Function()
        > {
  $$ConversationThreadsTableTableTableManager(
    _$AppDatabase db,
    $ConversationThreadsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationThreadsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ConversationThreadsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ConversationThreadsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> threadId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> lastMessagePreview = const Value.absent(),
                Value<DateTime> lastUpdatedAt = const Value.absent(),
                Value<int> pendingProposalCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationThreadsTableCompanion(
                threadId: threadId,
                title: title,
                lastMessagePreview: lastMessagePreview,
                lastUpdatedAt: lastUpdatedAt,
                pendingProposalCount: pendingProposalCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String threadId,
                required String title,
                required String lastMessagePreview,
                required DateTime lastUpdatedAt,
                required int pendingProposalCount,
                Value<int> rowid = const Value.absent(),
              }) => ConversationThreadsTableCompanion.insert(
                threadId: threadId,
                title: title,
                lastMessagePreview: lastMessagePreview,
                lastUpdatedAt: lastUpdatedAt,
                pendingProposalCount: pendingProposalCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConversationThreadsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationThreadsTableTable,
      ConversationThreadsTableData,
      $$ConversationThreadsTableTableFilterComposer,
      $$ConversationThreadsTableTableOrderingComposer,
      $$ConversationThreadsTableTableAnnotationComposer,
      $$ConversationThreadsTableTableCreateCompanionBuilder,
      $$ConversationThreadsTableTableUpdateCompanionBuilder,
      (
        ConversationThreadsTableData,
        BaseReferences<
          _$AppDatabase,
          $ConversationThreadsTableTable,
          ConversationThreadsTableData
        >,
      ),
      ConversationThreadsTableData,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableTableCreateCompanionBuilder =
    MessagesTableCompanion Function({
      required String messageId,
      required String threadId,
      required String actor,
      required String body,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$MessagesTableTableUpdateCompanionBuilder =
    MessagesTableCompanion Function({
      Value<String> messageId,
      Value<String> threadId,
      Value<String> actor,
      Value<String> body,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$MessagesTableTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTableTable> {
  $$MessagesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTableTable> {
  $$MessagesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actor => $composableBuilder(
    column: $table.actor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTableTable> {
  $$MessagesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get threadId =>
      $composableBuilder(column: $table.threadId, builder: (column) => column);

  GeneratedColumn<String> get actor =>
      $composableBuilder(column: $table.actor, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MessagesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTableTable,
          MessagesTableData,
          $$MessagesTableTableFilterComposer,
          $$MessagesTableTableOrderingComposer,
          $$MessagesTableTableAnnotationComposer,
          $$MessagesTableTableCreateCompanionBuilder,
          $$MessagesTableTableUpdateCompanionBuilder,
          (
            MessagesTableData,
            BaseReferences<
              _$AppDatabase,
              $MessagesTableTable,
              MessagesTableData
            >,
          ),
          MessagesTableData,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableTableManager(_$AppDatabase db, $MessagesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<String> threadId = const Value.absent(),
                Value<String> actor = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesTableCompanion(
                messageId: messageId,
                threadId: threadId,
                actor: actor,
                body: body,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                required String threadId,
                required String actor,
                required String body,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MessagesTableCompanion.insert(
                messageId: messageId,
                threadId: threadId,
                actor: actor,
                body: body,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTableTable,
      MessagesTableData,
      $$MessagesTableTableFilterComposer,
      $$MessagesTableTableOrderingComposer,
      $$MessagesTableTableAnnotationComposer,
      $$MessagesTableTableCreateCompanionBuilder,
      $$MessagesTableTableUpdateCompanionBuilder,
      (
        MessagesTableData,
        BaseReferences<_$AppDatabase, $MessagesTableTable, MessagesTableData>,
      ),
      MessagesTableData,
      PrefetchHooks Function()
    >;
typedef $$ProposalsTableTableCreateCompanionBuilder =
    ProposalsTableCompanion Function({
      required String proposalId,
      required String threadId,
      required String summary,
      required String assistantText,
      required DateTime createdAt,
      required String status,
      Value<int> rowid,
    });
typedef $$ProposalsTableTableUpdateCompanionBuilder =
    ProposalsTableCompanion Function({
      Value<String> proposalId,
      Value<String> threadId,
      Value<String> summary,
      Value<String> assistantText,
      Value<DateTime> createdAt,
      Value<String> status,
      Value<int> rowid,
    });

class $$ProposalsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProposalsTableTable> {
  $$ProposalsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get proposalId => $composableBuilder(
    column: $table.proposalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assistantText => $composableBuilder(
    column: $table.assistantText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProposalsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProposalsTableTable> {
  $$ProposalsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get proposalId => $composableBuilder(
    column: $table.proposalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assistantText => $composableBuilder(
    column: $table.assistantText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProposalsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProposalsTableTable> {
  $$ProposalsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get proposalId => $composableBuilder(
    column: $table.proposalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get threadId =>
      $composableBuilder(column: $table.threadId, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get assistantText => $composableBuilder(
    column: $table.assistantText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$ProposalsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProposalsTableTable,
          ProposalsTableData,
          $$ProposalsTableTableFilterComposer,
          $$ProposalsTableTableOrderingComposer,
          $$ProposalsTableTableAnnotationComposer,
          $$ProposalsTableTableCreateCompanionBuilder,
          $$ProposalsTableTableUpdateCompanionBuilder,
          (
            ProposalsTableData,
            BaseReferences<
              _$AppDatabase,
              $ProposalsTableTable,
              ProposalsTableData
            >,
          ),
          ProposalsTableData,
          PrefetchHooks Function()
        > {
  $$ProposalsTableTableTableManager(
    _$AppDatabase db,
    $ProposalsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProposalsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProposalsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProposalsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> proposalId = const Value.absent(),
                Value<String> threadId = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> assistantText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProposalsTableCompanion(
                proposalId: proposalId,
                threadId: threadId,
                summary: summary,
                assistantText: assistantText,
                createdAt: createdAt,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String proposalId,
                required String threadId,
                required String summary,
                required String assistantText,
                required DateTime createdAt,
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => ProposalsTableCompanion.insert(
                proposalId: proposalId,
                threadId: threadId,
                summary: summary,
                assistantText: assistantText,
                createdAt: createdAt,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProposalsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProposalsTableTable,
      ProposalsTableData,
      $$ProposalsTableTableFilterComposer,
      $$ProposalsTableTableOrderingComposer,
      $$ProposalsTableTableAnnotationComposer,
      $$ProposalsTableTableCreateCompanionBuilder,
      $$ProposalsTableTableUpdateCompanionBuilder,
      (
        ProposalsTableData,
        BaseReferences<_$AppDatabase, $ProposalsTableTable, ProposalsTableData>,
      ),
      ProposalsTableData,
      PrefetchHooks Function()
    >;
typedef $$ProposalActionsTableTableCreateCompanionBuilder =
    ProposalActionsTableCompanion Function({
      required String actionId,
      required String proposalId,
      required String type,
      Value<String?> medicationName,
      Value<String?> doseAmount,
      Value<String?> doseUnit,
      Value<String?> route,
      Value<String?> startDate,
      Value<String?> endDate,
      required String timesJson,
      Value<String?> notes,
      Value<String?> targetScheduleId,
      required String missingFieldsJson,
      Value<int> rowid,
    });
typedef $$ProposalActionsTableTableUpdateCompanionBuilder =
    ProposalActionsTableCompanion Function({
      Value<String> actionId,
      Value<String> proposalId,
      Value<String> type,
      Value<String?> medicationName,
      Value<String?> doseAmount,
      Value<String?> doseUnit,
      Value<String?> route,
      Value<String?> startDate,
      Value<String?> endDate,
      Value<String> timesJson,
      Value<String?> notes,
      Value<String?> targetScheduleId,
      Value<String> missingFieldsJson,
      Value<int> rowid,
    });

class $$ProposalActionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ProposalActionsTableTable> {
  $$ProposalActionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get actionId => $composableBuilder(
    column: $table.actionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get proposalId => $composableBuilder(
    column: $table.proposalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doseAmount => $composableBuilder(
    column: $table.doseAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doseUnit => $composableBuilder(
    column: $table.doseUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get route => $composableBuilder(
    column: $table.route,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timesJson => $composableBuilder(
    column: $table.timesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetScheduleId => $composableBuilder(
    column: $table.targetScheduleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get missingFieldsJson => $composableBuilder(
    column: $table.missingFieldsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProposalActionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ProposalActionsTableTable> {
  $$ProposalActionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get actionId => $composableBuilder(
    column: $table.actionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get proposalId => $composableBuilder(
    column: $table.proposalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doseAmount => $composableBuilder(
    column: $table.doseAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doseUnit => $composableBuilder(
    column: $table.doseUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get route => $composableBuilder(
    column: $table.route,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timesJson => $composableBuilder(
    column: $table.timesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetScheduleId => $composableBuilder(
    column: $table.targetScheduleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get missingFieldsJson => $composableBuilder(
    column: $table.missingFieldsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProposalActionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProposalActionsTableTable> {
  $$ProposalActionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get actionId =>
      $composableBuilder(column: $table.actionId, builder: (column) => column);

  GeneratedColumn<String> get proposalId => $composableBuilder(
    column: $table.proposalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get doseAmount => $composableBuilder(
    column: $table.doseAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get doseUnit =>
      $composableBuilder(column: $table.doseUnit, builder: (column) => column);

  GeneratedColumn<String> get route =>
      $composableBuilder(column: $table.route, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get timesJson =>
      $composableBuilder(column: $table.timesJson, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get targetScheduleId => $composableBuilder(
    column: $table.targetScheduleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get missingFieldsJson => $composableBuilder(
    column: $table.missingFieldsJson,
    builder: (column) => column,
  );
}

class $$ProposalActionsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProposalActionsTableTable,
          ProposalActionsTableData,
          $$ProposalActionsTableTableFilterComposer,
          $$ProposalActionsTableTableOrderingComposer,
          $$ProposalActionsTableTableAnnotationComposer,
          $$ProposalActionsTableTableCreateCompanionBuilder,
          $$ProposalActionsTableTableUpdateCompanionBuilder,
          (
            ProposalActionsTableData,
            BaseReferences<
              _$AppDatabase,
              $ProposalActionsTableTable,
              ProposalActionsTableData
            >,
          ),
          ProposalActionsTableData,
          PrefetchHooks Function()
        > {
  $$ProposalActionsTableTableTableManager(
    _$AppDatabase db,
    $ProposalActionsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProposalActionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProposalActionsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProposalActionsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> actionId = const Value.absent(),
                Value<String> proposalId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> medicationName = const Value.absent(),
                Value<String?> doseAmount = const Value.absent(),
                Value<String?> doseUnit = const Value.absent(),
                Value<String?> route = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String> timesJson = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> targetScheduleId = const Value.absent(),
                Value<String> missingFieldsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProposalActionsTableCompanion(
                actionId: actionId,
                proposalId: proposalId,
                type: type,
                medicationName: medicationName,
                doseAmount: doseAmount,
                doseUnit: doseUnit,
                route: route,
                startDate: startDate,
                endDate: endDate,
                timesJson: timesJson,
                notes: notes,
                targetScheduleId: targetScheduleId,
                missingFieldsJson: missingFieldsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String actionId,
                required String proposalId,
                required String type,
                Value<String?> medicationName = const Value.absent(),
                Value<String?> doseAmount = const Value.absent(),
                Value<String?> doseUnit = const Value.absent(),
                Value<String?> route = const Value.absent(),
                Value<String?> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                required String timesJson,
                Value<String?> notes = const Value.absent(),
                Value<String?> targetScheduleId = const Value.absent(),
                required String missingFieldsJson,
                Value<int> rowid = const Value.absent(),
              }) => ProposalActionsTableCompanion.insert(
                actionId: actionId,
                proposalId: proposalId,
                type: type,
                medicationName: medicationName,
                doseAmount: doseAmount,
                doseUnit: doseUnit,
                route: route,
                startDate: startDate,
                endDate: endDate,
                timesJson: timesJson,
                notes: notes,
                targetScheduleId: targetScheduleId,
                missingFieldsJson: missingFieldsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProposalActionsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProposalActionsTableTable,
      ProposalActionsTableData,
      $$ProposalActionsTableTableFilterComposer,
      $$ProposalActionsTableTableOrderingComposer,
      $$ProposalActionsTableTableAnnotationComposer,
      $$ProposalActionsTableTableCreateCompanionBuilder,
      $$ProposalActionsTableTableUpdateCompanionBuilder,
      (
        ProposalActionsTableData,
        BaseReferences<
          _$AppDatabase,
          $ProposalActionsTableTable,
          ProposalActionsTableData
        >,
      ),
      ProposalActionsTableData,
      PrefetchHooks Function()
    >;
typedef $$MedicationsTableTableCreateCompanionBuilder =
    MedicationsTableCompanion Function({
      required String medicationId,
      required String medicationName,
      Value<int> rowid,
    });
typedef $$MedicationsTableTableUpdateCompanionBuilder =
    MedicationsTableCompanion Function({
      Value<String> medicationId,
      Value<String> medicationName,
      Value<int> rowid,
    });

class $$MedicationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationsTableTable> {
  $$MedicationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MedicationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationsTableTable> {
  $$MedicationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationsTableTable> {
  $$MedicationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => column,
  );
}

class $$MedicationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationsTableTable,
          MedicationsTableData,
          $$MedicationsTableTableFilterComposer,
          $$MedicationsTableTableOrderingComposer,
          $$MedicationsTableTableAnnotationComposer,
          $$MedicationsTableTableCreateCompanionBuilder,
          $$MedicationsTableTableUpdateCompanionBuilder,
          (
            MedicationsTableData,
            BaseReferences<
              _$AppDatabase,
              $MedicationsTableTable,
              MedicationsTableData
            >,
          ),
          MedicationsTableData,
          PrefetchHooks Function()
        > {
  $$MedicationsTableTableTableManager(
    _$AppDatabase db,
    $MedicationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicationsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> medicationId = const Value.absent(),
                Value<String> medicationName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationsTableCompanion(
                medicationId: medicationId,
                medicationName: medicationName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String medicationId,
                required String medicationName,
                Value<int> rowid = const Value.absent(),
              }) => MedicationsTableCompanion.insert(
                medicationId: medicationId,
                medicationName: medicationName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MedicationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationsTableTable,
      MedicationsTableData,
      $$MedicationsTableTableFilterComposer,
      $$MedicationsTableTableOrderingComposer,
      $$MedicationsTableTableAnnotationComposer,
      $$MedicationsTableTableCreateCompanionBuilder,
      $$MedicationsTableTableUpdateCompanionBuilder,
      (
        MedicationsTableData,
        BaseReferences<
          _$AppDatabase,
          $MedicationsTableTable,
          MedicationsTableData
        >,
      ),
      MedicationsTableData,
      PrefetchHooks Function()
    >;
typedef $$MedicationSchedulesTableTableCreateCompanionBuilder =
    MedicationSchedulesTableCompanion Function({
      required String scheduleId,
      required String medicationName,
      Value<String?> doseAmount,
      Value<String?> doseUnit,
      Value<String?> route,
      required String startDate,
      Value<String?> endDate,
      required String timesJson,
      Value<String?> notes,
      Value<String?> sourceProposalId,
      Value<String?> threadId,
      required bool isActive,
      Value<int> rowid,
    });
typedef $$MedicationSchedulesTableTableUpdateCompanionBuilder =
    MedicationSchedulesTableCompanion Function({
      Value<String> scheduleId,
      Value<String> medicationName,
      Value<String?> doseAmount,
      Value<String?> doseUnit,
      Value<String?> route,
      Value<String> startDate,
      Value<String?> endDate,
      Value<String> timesJson,
      Value<String?> notes,
      Value<String?> sourceProposalId,
      Value<String?> threadId,
      Value<bool> isActive,
      Value<int> rowid,
    });

class $$MedicationSchedulesTableTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationSchedulesTableTable> {
  $$MedicationSchedulesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doseAmount => $composableBuilder(
    column: $table.doseAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get doseUnit => $composableBuilder(
    column: $table.doseUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get route => $composableBuilder(
    column: $table.route,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timesJson => $composableBuilder(
    column: $table.timesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceProposalId => $composableBuilder(
    column: $table.sourceProposalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MedicationSchedulesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationSchedulesTableTable> {
  $$MedicationSchedulesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doseAmount => $composableBuilder(
    column: $table.doseAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get doseUnit => $composableBuilder(
    column: $table.doseUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get route => $composableBuilder(
    column: $table.route,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timesJson => $composableBuilder(
    column: $table.timesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceProposalId => $composableBuilder(
    column: $table.sourceProposalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationSchedulesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationSchedulesTableTable> {
  $$MedicationSchedulesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get doseAmount => $composableBuilder(
    column: $table.doseAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get doseUnit =>
      $composableBuilder(column: $table.doseUnit, builder: (column) => column);

  GeneratedColumn<String> get route =>
      $composableBuilder(column: $table.route, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get timesJson =>
      $composableBuilder(column: $table.timesJson, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get sourceProposalId => $composableBuilder(
    column: $table.sourceProposalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get threadId =>
      $composableBuilder(column: $table.threadId, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$MedicationSchedulesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationSchedulesTableTable,
          MedicationSchedulesTableData,
          $$MedicationSchedulesTableTableFilterComposer,
          $$MedicationSchedulesTableTableOrderingComposer,
          $$MedicationSchedulesTableTableAnnotationComposer,
          $$MedicationSchedulesTableTableCreateCompanionBuilder,
          $$MedicationSchedulesTableTableUpdateCompanionBuilder,
          (
            MedicationSchedulesTableData,
            BaseReferences<
              _$AppDatabase,
              $MedicationSchedulesTableTable,
              MedicationSchedulesTableData
            >,
          ),
          MedicationSchedulesTableData,
          PrefetchHooks Function()
        > {
  $$MedicationSchedulesTableTableTableManager(
    _$AppDatabase db,
    $MedicationSchedulesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationSchedulesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MedicationSchedulesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MedicationSchedulesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> scheduleId = const Value.absent(),
                Value<String> medicationName = const Value.absent(),
                Value<String?> doseAmount = const Value.absent(),
                Value<String?> doseUnit = const Value.absent(),
                Value<String?> route = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String> timesJson = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> sourceProposalId = const Value.absent(),
                Value<String?> threadId = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationSchedulesTableCompanion(
                scheduleId: scheduleId,
                medicationName: medicationName,
                doseAmount: doseAmount,
                doseUnit: doseUnit,
                route: route,
                startDate: startDate,
                endDate: endDate,
                timesJson: timesJson,
                notes: notes,
                sourceProposalId: sourceProposalId,
                threadId: threadId,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scheduleId,
                required String medicationName,
                Value<String?> doseAmount = const Value.absent(),
                Value<String?> doseUnit = const Value.absent(),
                Value<String?> route = const Value.absent(),
                required String startDate,
                Value<String?> endDate = const Value.absent(),
                required String timesJson,
                Value<String?> notes = const Value.absent(),
                Value<String?> sourceProposalId = const Value.absent(),
                Value<String?> threadId = const Value.absent(),
                required bool isActive,
                Value<int> rowid = const Value.absent(),
              }) => MedicationSchedulesTableCompanion.insert(
                scheduleId: scheduleId,
                medicationName: medicationName,
                doseAmount: doseAmount,
                doseUnit: doseUnit,
                route: route,
                startDate: startDate,
                endDate: endDate,
                timesJson: timesJson,
                notes: notes,
                sourceProposalId: sourceProposalId,
                threadId: threadId,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MedicationSchedulesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationSchedulesTableTable,
      MedicationSchedulesTableData,
      $$MedicationSchedulesTableTableFilterComposer,
      $$MedicationSchedulesTableTableOrderingComposer,
      $$MedicationSchedulesTableTableAnnotationComposer,
      $$MedicationSchedulesTableTableCreateCompanionBuilder,
      $$MedicationSchedulesTableTableUpdateCompanionBuilder,
      (
        MedicationSchedulesTableData,
        BaseReferences<
          _$AppDatabase,
          $MedicationSchedulesTableTable,
          MedicationSchedulesTableData
        >,
      ),
      MedicationSchedulesTableData,
      PrefetchHooks Function()
    >;
typedef $$MedicationScheduleTimesTableTableCreateCompanionBuilder =
    MedicationScheduleTimesTableCompanion Function({
      Value<int> id,
      required String scheduleId,
      required String timeOfDay,
    });
typedef $$MedicationScheduleTimesTableTableUpdateCompanionBuilder =
    MedicationScheduleTimesTableCompanion Function({
      Value<int> id,
      Value<String> scheduleId,
      Value<String> timeOfDay,
    });

class $$MedicationScheduleTimesTableTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationScheduleTimesTableTable> {
  $$MedicationScheduleTimesTableTableFilterComposer({
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

  ColumnFilters<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeOfDay => $composableBuilder(
    column: $table.timeOfDay,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MedicationScheduleTimesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationScheduleTimesTableTable> {
  $$MedicationScheduleTimesTableTableOrderingComposer({
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

  ColumnOrderings<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeOfDay => $composableBuilder(
    column: $table.timeOfDay,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationScheduleTimesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationScheduleTimesTableTable> {
  $$MedicationScheduleTimesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeOfDay =>
      $composableBuilder(column: $table.timeOfDay, builder: (column) => column);
}

class $$MedicationScheduleTimesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationScheduleTimesTableTable,
          MedicationScheduleTimesTableData,
          $$MedicationScheduleTimesTableTableFilterComposer,
          $$MedicationScheduleTimesTableTableOrderingComposer,
          $$MedicationScheduleTimesTableTableAnnotationComposer,
          $$MedicationScheduleTimesTableTableCreateCompanionBuilder,
          $$MedicationScheduleTimesTableTableUpdateCompanionBuilder,
          (
            MedicationScheduleTimesTableData,
            BaseReferences<
              _$AppDatabase,
              $MedicationScheduleTimesTableTable,
              MedicationScheduleTimesTableData
            >,
          ),
          MedicationScheduleTimesTableData,
          PrefetchHooks Function()
        > {
  $$MedicationScheduleTimesTableTableTableManager(
    _$AppDatabase db,
    $MedicationScheduleTimesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationScheduleTimesTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$MedicationScheduleTimesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$MedicationScheduleTimesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> scheduleId = const Value.absent(),
                Value<String> timeOfDay = const Value.absent(),
              }) => MedicationScheduleTimesTableCompanion(
                id: id,
                scheduleId: scheduleId,
                timeOfDay: timeOfDay,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String scheduleId,
                required String timeOfDay,
              }) => MedicationScheduleTimesTableCompanion.insert(
                id: id,
                scheduleId: scheduleId,
                timeOfDay: timeOfDay,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MedicationScheduleTimesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationScheduleTimesTableTable,
      MedicationScheduleTimesTableData,
      $$MedicationScheduleTimesTableTableFilterComposer,
      $$MedicationScheduleTimesTableTableOrderingComposer,
      $$MedicationScheduleTimesTableTableAnnotationComposer,
      $$MedicationScheduleTimesTableTableCreateCompanionBuilder,
      $$MedicationScheduleTimesTableTableUpdateCompanionBuilder,
      (
        MedicationScheduleTimesTableData,
        BaseReferences<
          _$AppDatabase,
          $MedicationScheduleTimesTableTable,
          MedicationScheduleTimesTableData
        >,
      ),
      MedicationScheduleTimesTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EventLogTableTableManager get eventLog =>
      $$EventLogTableTableManager(_db, _db.eventLog);
  $$ConversationThreadsTableTableTableManager get conversationThreadsTable =>
      $$ConversationThreadsTableTableTableManager(
        _db,
        _db.conversationThreadsTable,
      );
  $$MessagesTableTableTableManager get messagesTable =>
      $$MessagesTableTableTableManager(_db, _db.messagesTable);
  $$ProposalsTableTableTableManager get proposalsTable =>
      $$ProposalsTableTableTableManager(_db, _db.proposalsTable);
  $$ProposalActionsTableTableTableManager get proposalActionsTable =>
      $$ProposalActionsTableTableTableManager(_db, _db.proposalActionsTable);
  $$MedicationsTableTableTableManager get medicationsTable =>
      $$MedicationsTableTableTableManager(_db, _db.medicationsTable);
  $$MedicationSchedulesTableTableTableManager get medicationSchedulesTable =>
      $$MedicationSchedulesTableTableTableManager(
        _db,
        _db.medicationSchedulesTable,
      );
  $$MedicationScheduleTimesTableTableTableManager
  get medicationScheduleTimesTable =>
      $$MedicationScheduleTimesTableTableTableManager(
        _db,
        _db.medicationScheduleTimesTable,
      );
}
