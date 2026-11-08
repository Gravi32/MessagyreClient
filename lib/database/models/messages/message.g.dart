// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetMessageCollection on Isar {
  IsarCollection<Message> get messages => this.collection();
}

const MessageSchema = CollectionSchema(
  name: r'Message',
  id: 2463283977299753079,
  properties: {
    r'attachmentData': PropertySchema(
      id: 0,
      name: r'attachmentData',
      type: IsarType.string,
    ),
    r'chatUsername': PropertySchema(
      id: 1,
      name: r'chatUsername',
      type: IsarType.string,
    ),
    r'content': PropertySchema(
      id: 2,
      name: r'content',
      type: IsarType.string,
    ),
    r'formattedTime': PropertySchema(
      id: 3,
      name: r'formattedTime',
      type: IsarType.string,
    ),
    r'isDeleted': PropertySchema(
      id: 4,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'isFailed': PropertySchema(
      id: 5,
      name: r'isFailed',
      type: IsarType.bool,
    ),
    r'isOwned': PropertySchema(
      id: 6,
      name: r'isOwned',
      type: IsarType.bool,
    ),
    r'localPath': PropertySchema(
      id: 7,
      name: r'localPath',
      type: IsarType.string,
    ),
    r'sentAt': PropertySchema(
      id: 8,
      name: r'sentAt',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 9,
      name: r'status',
      type: IsarType.byte,
      enumMap: _MessagestatusEnumValueMap,
    ),
    r'transfer': PropertySchema(
      id: 10,
      name: r'transfer',
      type: IsarType.byte,
      enumMap: _MessagetransferEnumValueMap,
    ),
    r'uuid': PropertySchema(
      id: 11,
      name: r'uuid',
      type: IsarType.string,
    )
  },
  estimateSize: _messageEstimateSize,
  serialize: _messageSerialize,
  deserialize: _messageDeserialize,
  deserializeProp: _messageDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'chatUsername_sentAt': IndexSchema(
      id: 7412881566252582649,
      name: r'chatUsername_sentAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'chatUsername',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'sentAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _messageGetId,
  getLinks: _messageGetLinks,
  attach: _messageAttach,
  version: '3.1.0+1',
);

int _messageEstimateSize(
  Message object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.attachmentData;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.chatUsername;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.content.length * 3;
  bytesCount += 3 + object.formattedTime.length * 3;
  {
    final value = object.localPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _messageSerialize(
  Message object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.attachmentData);
  writer.writeString(offsets[1], object.chatUsername);
  writer.writeString(offsets[2], object.content);
  writer.writeString(offsets[3], object.formattedTime);
  writer.writeBool(offsets[4], object.isDeleted);
  writer.writeBool(offsets[5], object.isFailed);
  writer.writeBool(offsets[6], object.isOwned);
  writer.writeString(offsets[7], object.localPath);
  writer.writeDateTime(offsets[8], object.sentAt);
  writer.writeByte(offsets[9], object.status.index);
  writer.writeByte(offsets[10], object.transfer.index);
  writer.writeString(offsets[11], object.uuid);
}

Message _messageDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Message();
  object.attachmentData = reader.readStringOrNull(offsets[0]);
  object.chatUsername = reader.readStringOrNull(offsets[1]);
  object.content = reader.readString(offsets[2]);
  object.id = id;
  object.isDeleted = reader.readBool(offsets[4]);
  object.isOwned = reader.readBool(offsets[6]);
  object.localPath = reader.readStringOrNull(offsets[7]);
  object.sentAt = reader.readDateTime(offsets[8]);
  object.status =
      _MessagestatusValueEnumMap[reader.readByteOrNull(offsets[9])] ??
          MessageStatus.Sending;
  object.transfer =
      _MessagetransferValueEnumMap[reader.readByteOrNull(offsets[10])] ??
          TransferState.none;
  object.uuid = reader.readString(offsets[11]);
  return object;
}

P _messageDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    case 9:
      return (_MessagestatusValueEnumMap[reader.readByteOrNull(offset)] ??
          MessageStatus.Sending) as P;
    case 10:
      return (_MessagetransferValueEnumMap[reader.readByteOrNull(offset)] ??
          TransferState.none) as P;
    case 11:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _MessagestatusEnumValueMap = {
  'Sending': 0,
  'Sent': 1,
  'Delivered': 2,
  'Read': 3,
  'Failed': 4,
};
const _MessagestatusValueEnumMap = {
  0: MessageStatus.Sending,
  1: MessageStatus.Sent,
  2: MessageStatus.Delivered,
  3: MessageStatus.Read,
  4: MessageStatus.Failed,
};
const _MessagetransferEnumValueMap = {
  'none': 0,
  'pending': 1,
  'uploading': 2,
  'downloading': 3,
  'ready': 4,
  'failed': 5,
  'expired': 6,
};
const _MessagetransferValueEnumMap = {
  0: TransferState.none,
  1: TransferState.pending,
  2: TransferState.uploading,
  3: TransferState.downloading,
  4: TransferState.ready,
  5: TransferState.failed,
  6: TransferState.expired,
};

Id _messageGetId(Message object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _messageGetLinks(Message object) {
  return [];
}

void _messageAttach(IsarCollection<dynamic> col, Id id, Message object) {
  object.id = id;
}

extension MessageByIndex on IsarCollection<Message> {
  Future<Message?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  Message? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<Message?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<Message?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(Message object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(Message object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<Message> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<Message> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension MessageQueryWhereSort on QueryBuilder<Message, Message, QWhere> {
  QueryBuilder<Message, Message, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension MessageQueryWhere on QueryBuilder<Message, Message, QWhereClause> {
  QueryBuilder<Message, Message, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Message, Message, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Message, Message, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Message, Message, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterWhereClause> uuidEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterWhereClause> uuidNotEqualTo(
      String uuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Message, Message, QAfterWhereClause>
      chatUsernameIsNullAnySentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'chatUsername_sentAt',
        value: [null],
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterWhereClause>
      chatUsernameIsNotNullAnySentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'chatUsername_sentAt',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterWhereClause>
      chatUsernameEqualToAnySentAt(String? chatUsername) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'chatUsername_sentAt',
        value: [chatUsername],
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterWhereClause>
      chatUsernameNotEqualToAnySentAt(String? chatUsername) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chatUsername_sentAt',
              lower: [],
              upper: [chatUsername],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chatUsername_sentAt',
              lower: [chatUsername],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chatUsername_sentAt',
              lower: [chatUsername],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chatUsername_sentAt',
              lower: [],
              upper: [chatUsername],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Message, Message, QAfterWhereClause> chatUsernameSentAtEqualTo(
      String? chatUsername, DateTime sentAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'chatUsername_sentAt',
        value: [chatUsername, sentAt],
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterWhereClause>
      chatUsernameEqualToSentAtNotEqualTo(
          String? chatUsername, DateTime sentAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chatUsername_sentAt',
              lower: [chatUsername],
              upper: [chatUsername, sentAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chatUsername_sentAt',
              lower: [chatUsername, sentAt],
              includeLower: false,
              upper: [chatUsername],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chatUsername_sentAt',
              lower: [chatUsername, sentAt],
              includeLower: false,
              upper: [chatUsername],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'chatUsername_sentAt',
              lower: [chatUsername],
              upper: [chatUsername, sentAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Message, Message, QAfterWhereClause>
      chatUsernameEqualToSentAtGreaterThan(
    String? chatUsername,
    DateTime sentAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'chatUsername_sentAt',
        lower: [chatUsername, sentAt],
        includeLower: include,
        upper: [chatUsername],
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterWhereClause>
      chatUsernameEqualToSentAtLessThan(
    String? chatUsername,
    DateTime sentAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'chatUsername_sentAt',
        lower: [chatUsername],
        upper: [chatUsername, sentAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterWhereClause>
      chatUsernameEqualToSentAtBetween(
    String? chatUsername,
    DateTime lowerSentAt,
    DateTime upperSentAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'chatUsername_sentAt',
        lower: [chatUsername, lowerSentAt],
        includeLower: includeLower,
        upper: [chatUsername, upperSentAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension MessageQueryFilter
    on QueryBuilder<Message, Message, QFilterCondition> {
  QueryBuilder<Message, Message, QAfterFilterCondition> attachmentDataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'attachmentData',
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition>
      attachmentDataIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'attachmentData',
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> attachmentDataEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attachmentData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition>
      attachmentDataGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'attachmentData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> attachmentDataLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'attachmentData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> attachmentDataBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'attachmentData',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition>
      attachmentDataStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'attachmentData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> attachmentDataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'attachmentData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> attachmentDataContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'attachmentData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> attachmentDataMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'attachmentData',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition>
      attachmentDataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'attachmentData',
        value: '',
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition>
      attachmentDataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'attachmentData',
        value: '',
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> chatUsernameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'chatUsername',
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition>
      chatUsernameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'chatUsername',
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> chatUsernameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chatUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> chatUsernameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chatUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> chatUsernameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chatUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> chatUsernameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chatUsername',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> chatUsernameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'chatUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> chatUsernameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'chatUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> chatUsernameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'chatUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> chatUsernameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'chatUsername',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> chatUsernameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chatUsername',
        value: '',
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition>
      chatUsernameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'chatUsername',
        value: '',
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> contentEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> contentGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> contentLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> contentBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'content',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> contentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> contentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> contentContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'content',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> contentMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'content',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'content',
        value: '',
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> formattedTimeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'formattedTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition>
      formattedTimeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'formattedTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> formattedTimeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'formattedTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> formattedTimeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'formattedTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> formattedTimeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'formattedTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> formattedTimeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'formattedTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> formattedTimeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'formattedTime',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> formattedTimeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'formattedTime',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> formattedTimeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'formattedTime',
        value: '',
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition>
      formattedTimeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'formattedTime',
        value: '',
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> isDeletedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> isFailedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isFailed',
        value: value,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> isOwnedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isOwned',
        value: value,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> localPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'localPath',
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> localPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'localPath',
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> localPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> localPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> localPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> localPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> localPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> localPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> localPathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'localPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> localPathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'localPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> localPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> localPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'localPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> sentAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sentAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> sentAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sentAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> sentAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sentAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> sentAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sentAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> statusEqualTo(
      MessageStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> statusGreaterThan(
    MessageStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> statusLessThan(
    MessageStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> statusBetween(
    MessageStatus lower,
    MessageStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> transferEqualTo(
      TransferState value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'transfer',
        value: value,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> transferGreaterThan(
    TransferState value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'transfer',
        value: value,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> transferLessThan(
    TransferState value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'transfer',
        value: value,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> transferBetween(
    TransferState lower,
    TransferState upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'transfer',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> uuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> uuidContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> uuidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Message, Message, QAfterFilterCondition> uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }
}

extension MessageQueryObject
    on QueryBuilder<Message, Message, QFilterCondition> {}

extension MessageQueryLinks
    on QueryBuilder<Message, Message, QFilterCondition> {}

extension MessageQuerySortBy on QueryBuilder<Message, Message, QSortBy> {
  QueryBuilder<Message, Message, QAfterSortBy> sortByAttachmentData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attachmentData', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByAttachmentDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attachmentData', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByChatUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chatUsername', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByChatUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chatUsername', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByFormattedTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedTime', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByFormattedTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedTime', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByIsFailed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFailed', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByIsFailedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFailed', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByIsOwned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOwned', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByIsOwnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOwned', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByLocalPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByLocalPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortBySentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentAt', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortBySentAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentAt', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByTransfer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transfer', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByTransferDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transfer', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension MessageQuerySortThenBy
    on QueryBuilder<Message, Message, QSortThenBy> {
  QueryBuilder<Message, Message, QAfterSortBy> thenByAttachmentData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attachmentData', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByAttachmentDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attachmentData', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByChatUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chatUsername', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByChatUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chatUsername', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByFormattedTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedTime', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByFormattedTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formattedTime', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByIsDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDeleted', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByIsFailed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFailed', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByIsFailedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFailed', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByIsOwned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOwned', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByIsOwnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isOwned', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByLocalPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByLocalPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenBySentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentAt', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenBySentAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentAt', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByTransfer() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transfer', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByTransferDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transfer', Sort.desc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Message, Message, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension MessageQueryWhereDistinct
    on QueryBuilder<Message, Message, QDistinct> {
  QueryBuilder<Message, Message, QDistinct> distinctByAttachmentData(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attachmentData',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Message, Message, QDistinct> distinctByChatUsername(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chatUsername', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Message, Message, QDistinct> distinctByContent(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Message, Message, QDistinct> distinctByFormattedTime(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'formattedTime',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Message, Message, QDistinct> distinctByIsDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDeleted');
    });
  }

  QueryBuilder<Message, Message, QDistinct> distinctByIsFailed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFailed');
    });
  }

  QueryBuilder<Message, Message, QDistinct> distinctByIsOwned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isOwned');
    });
  }

  QueryBuilder<Message, Message, QDistinct> distinctByLocalPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Message, Message, QDistinct> distinctBySentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sentAt');
    });
  }

  QueryBuilder<Message, Message, QDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<Message, Message, QDistinct> distinctByTransfer() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transfer');
    });
  }

  QueryBuilder<Message, Message, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension MessageQueryProperty
    on QueryBuilder<Message, Message, QQueryProperty> {
  QueryBuilder<Message, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Message, String?, QQueryOperations> attachmentDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attachmentData');
    });
  }

  QueryBuilder<Message, String?, QQueryOperations> chatUsernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chatUsername');
    });
  }

  QueryBuilder<Message, String, QQueryOperations> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<Message, String, QQueryOperations> formattedTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'formattedTime');
    });
  }

  QueryBuilder<Message, bool, QQueryOperations> isDeletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDeleted');
    });
  }

  QueryBuilder<Message, bool, QQueryOperations> isFailedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFailed');
    });
  }

  QueryBuilder<Message, bool, QQueryOperations> isOwnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isOwned');
    });
  }

  QueryBuilder<Message, String?, QQueryOperations> localPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localPath');
    });
  }

  QueryBuilder<Message, DateTime, QQueryOperations> sentAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sentAt');
    });
  }

  QueryBuilder<Message, MessageStatus, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<Message, TransferState, QQueryOperations> transferProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transfer');
    });
  }

  QueryBuilder<Message, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
