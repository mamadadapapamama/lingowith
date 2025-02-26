import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDataSource {
  final FirebaseFirestore _firestore;

  FirebaseDataSource({required FirebaseFirestore firestore}) : _firestore = firestore;

  // 컬렉션 참조 가져오기
  CollectionReference getCollection(String collectionPath) {
    return _firestore.collection(collectionPath);
  }

  // 문서 가져오기
  Future<DocumentSnapshot> getDocument(String collectionPath, String documentId) async {
    return await _firestore.collection(collectionPath).doc(documentId).get();
  }

  // 문서 추가하기
  Future<DocumentReference> addDocument(String collectionPath, Map<String, dynamic> data) async {
    return await _firestore.collection(collectionPath).add(data);
  }

  // 문서 업데이트하기
  Future<void> updateDocument(String collectionPath, String documentId, Map<String, dynamic> data) async {
    await _firestore.collection(collectionPath).doc(documentId).update(data);
  }

  // 문서 설정하기 (덮어쓰기)
  Future<void> setDocument(String collectionPath, String documentId, Map<String, dynamic> data) async {
    await _firestore.collection(collectionPath).doc(documentId).set(data);
  }

  // 문서 삭제하기
  Future<void> deleteDocument(String collectionPath, String documentId) async {
    await _firestore.collection(collectionPath).doc(documentId).delete();
  }

  // 쿼리 실행하기
  Future<QuerySnapshot> getDocuments(
    String collectionPath,
    List<List<dynamic>> conditions,
    {String? orderBy, bool descending = false}
  ) async {
    Query query = _firestore.collection(collectionPath);
    
    // 조건 적용
    for (final condition in conditions) {
      if (condition.length == 3) {
        final field = condition[0] as String;
        final operator = condition[1] as String;
        final value = condition[2];
        
        switch (operator) {
          case '==':
            query = query.where(field, isEqualTo: value);
            break;
          case '!=':
            query = query.where(field, isNotEqualTo: value);
            break;
          case '>':
            query = query.where(field, isGreaterThan: value);
            break;
          case '>=':
            query = query.where(field, isGreaterThanOrEqualTo: value);
            break;
          case '<':
            query = query.where(field, isLessThan: value);
            break;
          case '<=':
            query = query.where(field, isLessThanOrEqualTo: value);
            break;
          case 'array-contains':
            query = query.where(field, arrayContains: value);
            break;
          case 'array-contains-any':
            query = query.where(field, arrayContainsAny: value as List);
            break;
          case 'in':
            query = query.where(field, whereIn: value as List);
            break;
          case 'not-in':
            query = query.where(field, whereNotIn: value as List);
            break;
        }
      }
    }
    
    // 정렬 적용
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    
    return await query.get();
  }

  // 트랜잭션 실행하기
  Future<T> runTransaction<T>(Future<T> Function(Transaction) transactionHandler) async {
    return await _firestore.runTransaction(transactionHandler);
  }

  // 배치 작업 실행하기
  Future<void> runBatch(void Function(WriteBatch) batchHandler) async {
    final batch = _firestore.batch();
    batchHandler(batch);
    await batch.commit();
  }

  // 실시간 문서 스트림
  Stream<DocumentSnapshot> documentStream(String collectionPath, String documentId) {
    return _firestore.collection(collectionPath).doc(documentId).snapshots();
  }

  // 실시간 쿼리 스트림
  Stream<QuerySnapshot> queryStream(
    String collectionPath, {
    List<Map<String, dynamic>>? where,
    List<Map<String, dynamic>>? orderBy,
    int? limit,
  }) {
    Query query = _firestore.collection(collectionPath);
    
    // where 조건 적용
    if (where != null) {
      for (final condition in where) {
        query = query.where(
          condition['field'] as String,
          isEqualTo: condition['operator'] == '==' ? condition['value'] : null,
          isNotEqualTo: condition['operator'] == '!=' ? condition['value'] : null,
          isLessThan: condition['operator'] == '<' ? condition['value'] : null,
          isLessThanOrEqualTo: condition['operator'] == '<=' ? condition['value'] : null,
          isGreaterThan: condition['operator'] == '>' ? condition['value'] : null,
          isGreaterThanOrEqualTo: condition['operator'] == '>=' ? condition['value'] : null,
          arrayContains: condition['operator'] == 'array-contains' ? condition['value'] : null,
          arrayContainsAny: condition['operator'] == 'array-contains-any' ? condition['value'] as List<dynamic>? : null,
          whereIn: condition['operator'] == 'in' ? condition['value'] as List<dynamic>? : null,
          whereNotIn: condition['operator'] == 'not-in' ? condition['value'] as List<dynamic>? : null,
        );
      }
    }
    
    // 정렬 조건 적용
    if (orderBy != null) {
      for (final order in orderBy) {
        query = query.orderBy(
          order['field'] as String,
          descending: order['direction'] == 'desc',
        );
      }
    }
    
    // 결과 개수 제한
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots();
  }
} 