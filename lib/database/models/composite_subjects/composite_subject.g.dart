// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'composite_subject.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCompositeSubjectCollection on Isar {
  IsarCollection<CompositeSubject> get compositeSubjects => this.collection();
}

const CompositeSubjectSchema = CollectionSchema(
  name: r'CompositeSubject',
  id: -6647909848621739095,
  properties: {
    r'code': PropertySchema(
      id: 0,
      name: r'code',
      type: IsarType.string,
    ),
    r'firstSubjectWeight': PropertySchema(
      id: 1,
      name: r'firstSubjectWeight',
      type: IsarType.double,
    ),
    r'name': PropertySchema(
      id: 2,
      name: r'name',
      type: IsarType.string,
    ),
    r'secondSubjectWeight': PropertySchema(
      id: 3,
      name: r'secondSubjectWeight',
      type: IsarType.double,
    )
  },
  estimateSize: _compositeSubjectEstimateSize,
  serialize: _compositeSubjectSerialize,
  deserialize: _compositeSubjectDeserialize,
  deserializeProp: _compositeSubjectDeserializeProp,
  idName: r'id',
  indexes: {
    r'code': IndexSchema(
      id: 329780482934683790,
      name: r'code',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'code',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {
    r'firstSubject': LinkSchema(
      id: 4725008061256842417,
      name: r'firstSubject',
      target: r'Subject',
      single: true,
    ),
    r'secondSubject': LinkSchema(
      id: -8602205191203514954,
      name: r'secondSubject',
      target: r'Subject',
      single: true,
    )
  },
  embeddedSchemas: {},
  getId: _compositeSubjectGetId,
  getLinks: _compositeSubjectGetLinks,
  attach: _compositeSubjectAttach,
  version: '3.1.0+1',
);

int _compositeSubjectEstimateSize(
  CompositeSubject object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.code.length * 3;
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _compositeSubjectSerialize(
  CompositeSubject object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.code);
  writer.writeDouble(offsets[1], object.firstSubjectWeight);
  writer.writeString(offsets[2], object.name);
  writer.writeDouble(offsets[3], object.secondSubjectWeight);
}

CompositeSubject _compositeSubjectDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CompositeSubject();
  object.code = reader.readString(offsets[0]);
  object.firstSubjectWeight = reader.readDouble(offsets[1]);
  object.id = id;
  object.name = reader.readString(offsets[2]);
  object.secondSubjectWeight = reader.readDouble(offsets[3]);
  return object;
}

P _compositeSubjectDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDouble(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _compositeSubjectGetId(CompositeSubject object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _compositeSubjectGetLinks(CompositeSubject object) {
  return [object.firstSubject, object.secondSubject];
}

void _compositeSubjectAttach(
    IsarCollection<dynamic> col, Id id, CompositeSubject object) {
  object.id = id;
  object.firstSubject
      .attach(col, col.isar.collection<Subject>(), r'firstSubject', id);
  object.secondSubject
      .attach(col, col.isar.collection<Subject>(), r'secondSubject', id);
}

extension CompositeSubjectByIndex on IsarCollection<CompositeSubject> {
  Future<CompositeSubject?> getByCode(String code) {
    return getByIndex(r'code', [code]);
  }

  CompositeSubject? getByCodeSync(String code) {
    return getByIndexSync(r'code', [code]);
  }

  Future<bool> deleteByCode(String code) {
    return deleteByIndex(r'code', [code]);
  }

  bool deleteByCodeSync(String code) {
    return deleteByIndexSync(r'code', [code]);
  }

  Future<List<CompositeSubject?>> getAllByCode(List<String> codeValues) {
    final values = codeValues.map((e) => [e]).toList();
    return getAllByIndex(r'code', values);
  }

  List<CompositeSubject?> getAllByCodeSync(List<String> codeValues) {
    final values = codeValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'code', values);
  }

  Future<int> deleteAllByCode(List<String> codeValues) {
    final values = codeValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'code', values);
  }

  int deleteAllByCodeSync(List<String> codeValues) {
    final values = codeValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'code', values);
  }

  Future<Id> putByCode(CompositeSubject object) {
    return putByIndex(r'code', object);
  }

  Id putByCodeSync(CompositeSubject object, {bool saveLinks = true}) {
    return putByIndexSync(r'code', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCode(List<CompositeSubject> objects) {
    return putAllByIndex(r'code', objects);
  }

  List<Id> putAllByCodeSync(List<CompositeSubject> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'code', objects, saveLinks: saveLinks);
  }
}

extension CompositeSubjectQueryWhereSort
    on QueryBuilder<CompositeSubject, CompositeSubject, QWhere> {
  QueryBuilder<CompositeSubject, CompositeSubject, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CompositeSubjectQueryWhere
    on QueryBuilder<CompositeSubject, CompositeSubject, QWhereClause> {
  QueryBuilder<CompositeSubject, CompositeSubject, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterWhereClause> idBetween(
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

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterWhereClause>
      codeEqualTo(String code) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'code',
        value: [code],
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterWhereClause>
      codeNotEqualTo(String code) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'code',
              lower: [],
              upper: [code],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'code',
              lower: [code],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'code',
              lower: [code],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'code',
              lower: [],
              upper: [code],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CompositeSubjectQueryFilter
    on QueryBuilder<CompositeSubject, CompositeSubject, QFilterCondition> {
  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      codeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      codeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      codeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      codeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'code',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      codeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      codeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      codeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      codeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'code',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      codeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'code',
        value: '',
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      codeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'code',
        value: '',
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      firstSubjectWeightEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'firstSubjectWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      firstSubjectWeightGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'firstSubjectWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      firstSubjectWeightLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'firstSubjectWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      firstSubjectWeightBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'firstSubjectWeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      secondSubjectWeightEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'secondSubjectWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      secondSubjectWeightGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'secondSubjectWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      secondSubjectWeightLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'secondSubjectWeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      secondSubjectWeightBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'secondSubjectWeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension CompositeSubjectQueryObject
    on QueryBuilder<CompositeSubject, CompositeSubject, QFilterCondition> {}

extension CompositeSubjectQueryLinks
    on QueryBuilder<CompositeSubject, CompositeSubject, QFilterCondition> {
  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      firstSubject(FilterQuery<Subject> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'firstSubject');
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      firstSubjectIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'firstSubject', 0, true, 0, true);
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      secondSubject(FilterQuery<Subject> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'secondSubject');
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterFilterCondition>
      secondSubjectIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'secondSubject', 0, true, 0, true);
    });
  }
}

extension CompositeSubjectQuerySortBy
    on QueryBuilder<CompositeSubject, CompositeSubject, QSortBy> {
  QueryBuilder<CompositeSubject, CompositeSubject, QAfterSortBy> sortByCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.asc);
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterSortBy>
      sortByCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.desc);
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterSortBy>
      sortByFirstSubjectWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstSubjectWeight', Sort.asc);
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterSortBy>
      sortByFirstSubjectWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstSubjectWeight', Sort.desc);
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterSortBy>
      sortBySecondSubjectWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondSubjectWeight', Sort.asc);
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterSortBy>
      sortBySecondSubjectWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondSubjectWeight', Sort.desc);
    });
  }
}

extension CompositeSubjectQuerySortThenBy
    on QueryBuilder<CompositeSubject, CompositeSubject, QSortThenBy> {
  QueryBuilder<CompositeSubject, CompositeSubject, QAfterSortBy> thenByCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.asc);
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterSortBy>
      thenByCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.desc);
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterSortBy>
      thenByFirstSubjectWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstSubjectWeight', Sort.asc);
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterSortBy>
      thenByFirstSubjectWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'firstSubjectWeight', Sort.desc);
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterSortBy>
      thenBySecondSubjectWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondSubjectWeight', Sort.asc);
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QAfterSortBy>
      thenBySecondSubjectWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondSubjectWeight', Sort.desc);
    });
  }
}

extension CompositeSubjectQueryWhereDistinct
    on QueryBuilder<CompositeSubject, CompositeSubject, QDistinct> {
  QueryBuilder<CompositeSubject, CompositeSubject, QDistinct> distinctByCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'code', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QDistinct>
      distinctByFirstSubjectWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'firstSubjectWeight');
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CompositeSubject, CompositeSubject, QDistinct>
      distinctBySecondSubjectWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'secondSubjectWeight');
    });
  }
}

extension CompositeSubjectQueryProperty
    on QueryBuilder<CompositeSubject, CompositeSubject, QQueryProperty> {
  QueryBuilder<CompositeSubject, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CompositeSubject, String, QQueryOperations> codeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'code');
    });
  }

  QueryBuilder<CompositeSubject, double, QQueryOperations>
      firstSubjectWeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'firstSubjectWeight');
    });
  }

  QueryBuilder<CompositeSubject, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<CompositeSubject, double, QQueryOperations>
      secondSubjectWeightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'secondSubjectWeight');
    });
  }
}
