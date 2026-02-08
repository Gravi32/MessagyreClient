// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetChatCollection on Isar {
  IsarCollection<Chat> get chats => this.collection();
}

const ChatSchema = CollectionSchema(
  name: r'Chat',
  id: -4292359458225261721,
  properties: {
    r'isPinned': PropertySchema(
      id: 0,
      name: r'isPinned',
      type: IsarType.bool,
    ),
    r'recipientDisplayUsername': PropertySchema(
      id: 1,
      name: r'recipientDisplayUsername',
      type: IsarType.string,
    ),
    r'recipientUsername': PropertySchema(
      id: 2,
      name: r'recipientUsername',
      type: IsarType.string,
    ),
    r'unreadMessages': PropertySchema(
      id: 3,
      name: r'unreadMessages',
      type: IsarType.long,
    )
  },
  estimateSize: _chatEstimateSize,
  serialize: _chatSerialize,
  deserialize: _chatDeserialize,
  deserializeProp: _chatDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'messages': LinkSchema(
      id: 5088296045962649861,
      name: r'messages',
      target: r'Message',
      single: false,
    )
  },
  embeddedSchemas: {},
  getId: _chatGetId,
  getLinks: _chatGetLinks,
  attach: _chatAttach,
  version: '3.1.0+1',
);

int _chatEstimateSize(
  Chat object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.recipientDisplayUsername;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.recipientUsername.length * 3;
  return bytesCount;
}

void _chatSerialize(
  Chat object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.isPinned);
  writer.writeString(offsets[1], object.recipientDisplayUsername);
  writer.writeString(offsets[2], object.recipientUsername);
  writer.writeLong(offsets[3], object.unreadMessages);
}

Chat _chatDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Chat();
  object.id = id;
  object.isPinned = reader.readBool(offsets[0]);
  object.recipientDisplayUsername = reader.readStringOrNull(offsets[1]);
  object.recipientUsername = reader.readString(offsets[2]);
  object.unreadMessages = reader.readLong(offsets[3]);
  return object;
}

P _chatDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _chatGetId(Chat object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _chatGetLinks(Chat object) {
  return [object.messages];
}

void _chatAttach(IsarCollection<dynamic> col, Id id, Chat object) {
  object.id = id;
  object.messages.attach(col, col.isar.collection<Message>(), r'messages', id);
}

extension ChatQueryWhereSort on QueryBuilder<Chat, Chat, QWhere> {
  QueryBuilder<Chat, Chat, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ChatQueryWhere on QueryBuilder<Chat, Chat, QWhereClause> {
  QueryBuilder<Chat, Chat, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Chat, Chat, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Chat, Chat, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Chat, Chat, QAfterWhereClause> idBetween(
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
}

extension ChatQueryFilter on QueryBuilder<Chat, Chat, QFilterCondition> {
  QueryBuilder<Chat, Chat, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Chat, Chat, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Chat, Chat, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Chat, Chat, QAfterFilterCondition> isPinnedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPinned',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      recipientDisplayUsernameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'recipientDisplayUsername',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      recipientDisplayUsernameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'recipientDisplayUsername',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      recipientDisplayUsernameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recipientDisplayUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      recipientDisplayUsernameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recipientDisplayUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      recipientDisplayUsernameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recipientDisplayUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      recipientDisplayUsernameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recipientDisplayUsername',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      recipientDisplayUsernameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'recipientDisplayUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      recipientDisplayUsernameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'recipientDisplayUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      recipientDisplayUsernameContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'recipientDisplayUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      recipientDisplayUsernameMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'recipientDisplayUsername',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      recipientDisplayUsernameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recipientDisplayUsername',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      recipientDisplayUsernameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'recipientDisplayUsername',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> recipientUsernameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recipientUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> recipientUsernameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recipientUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> recipientUsernameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recipientUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> recipientUsernameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recipientUsername',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> recipientUsernameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'recipientUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> recipientUsernameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'recipientUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> recipientUsernameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'recipientUsername',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> recipientUsernameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'recipientUsername',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> recipientUsernameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recipientUsername',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition>
      recipientUsernameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'recipientUsername',
        value: '',
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> unreadMessagesEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unreadMessages',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> unreadMessagesGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'unreadMessages',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> unreadMessagesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'unreadMessages',
        value: value,
      ));
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> unreadMessagesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'unreadMessages',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ChatQueryObject on QueryBuilder<Chat, Chat, QFilterCondition> {}

extension ChatQueryLinks on QueryBuilder<Chat, Chat, QFilterCondition> {
  QueryBuilder<Chat, Chat, QAfterFilterCondition> messages(
      FilterQuery<Message> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'messages');
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> messagesLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'messages', length, true, length, true);
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> messagesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'messages', 0, true, 0, true);
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> messagesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'messages', 0, false, 999999, true);
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> messagesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'messages', 0, true, length, include);
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> messagesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'messages', length, include, 999999, true);
    });
  }

  QueryBuilder<Chat, Chat, QAfterFilterCondition> messagesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'messages', lower, includeLower, upper, includeUpper);
    });
  }
}

extension ChatQuerySortBy on QueryBuilder<Chat, Chat, QSortBy> {
  QueryBuilder<Chat, Chat, QAfterSortBy> sortByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByRecipientDisplayUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recipientDisplayUsername', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByRecipientDisplayUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recipientDisplayUsername', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByRecipientUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recipientUsername', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByRecipientUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recipientUsername', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByUnreadMessages() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadMessages', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> sortByUnreadMessagesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadMessages', Sort.desc);
    });
  }
}

extension ChatQuerySortThenBy on QueryBuilder<Chat, Chat, QSortThenBy> {
  QueryBuilder<Chat, Chat, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByIsPinnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPinned', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByRecipientDisplayUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recipientDisplayUsername', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByRecipientDisplayUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recipientDisplayUsername', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByRecipientUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recipientUsername', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByRecipientUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recipientUsername', Sort.desc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByUnreadMessages() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadMessages', Sort.asc);
    });
  }

  QueryBuilder<Chat, Chat, QAfterSortBy> thenByUnreadMessagesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unreadMessages', Sort.desc);
    });
  }
}

extension ChatQueryWhereDistinct on QueryBuilder<Chat, Chat, QDistinct> {
  QueryBuilder<Chat, Chat, QDistinct> distinctByIsPinned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPinned');
    });
  }

  QueryBuilder<Chat, Chat, QDistinct> distinctByRecipientDisplayUsername(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recipientDisplayUsername',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Chat, Chat, QDistinct> distinctByRecipientUsername(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recipientUsername',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Chat, Chat, QDistinct> distinctByUnreadMessages() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unreadMessages');
    });
  }
}

extension ChatQueryProperty on QueryBuilder<Chat, Chat, QQueryProperty> {
  QueryBuilder<Chat, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Chat, bool, QQueryOperations> isPinnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPinned');
    });
  }

  QueryBuilder<Chat, String?, QQueryOperations>
      recipientDisplayUsernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recipientDisplayUsername');
    });
  }

  QueryBuilder<Chat, String, QQueryOperations> recipientUsernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recipientUsername');
    });
  }

  QueryBuilder<Chat, int, QQueryOperations> unreadMessagesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unreadMessages');
    });
  }
}
