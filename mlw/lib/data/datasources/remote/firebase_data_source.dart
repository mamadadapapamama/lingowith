import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDataSource {
  final FirebaseFirestore _firestore;

  FirebaseDataSource({required FirebaseFirestore firestore}) : _firestore = firestore;

  // 컬렉션 참조 가져오기
  CollectionReference getCollection(String path) {
    return _firestore.collection(path);
  }

  // 문서 가져오기
  Future<DocumentSnapshot> getDocument(String path, String id) async {
    return await _firestore.collection(path).doc(id).get();
  }

  // 문서 목록 가져오기 (쿼리 조건 포함)
  Future<QuerySnapshot> getDocuments(
    String collectionPath, {
    List<Map<String, dynamic>>? where,
    List<Map<String, dynamic>>? orderBy,
    int? limit,
  }) async {
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
    
    return await query.get();
  }

  // 문서 추가
  Future<DocumentReference> addDocument(String collectionPath, Map<String, dynamic> data) async {
    return await _firestore.collection(collectionPath).add(data);
  }

  // 문서 생성/업데이트
  Future<void> setDocument(String path, String id, Map<String, dynamic> data) async {
    await _firestore.collection(path).doc(id).set(data);
  }

  // 문서 업데이트
  Future<void> updateDocument(String path, String id, Map<String, dynamic> data) async {
    await _firestore.collection(path).doc(id).update(data);
  }

  // 문서 삭제
  Future<void> deleteDocument(String path, String id) async {
    await _firestore.collection(path).doc(id).delete();
  }

  // 쿼리 실행
  Future<QuerySnapshot> query(String path, {
    List<List<dynamic>> filters = const [],
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    Query query = _firestore.collection(path);
    
    for (final filter in filters) {
      if (filter.length == 3) {
        query = query.where(filter[0], isEqualTo: filter[1] == '==' ? filter[2] : null);
      }
    }
    
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return await query.get();
  }

  // 트랜잭션 실행
  Future<T> runTransaction<T>(Future<T> Function(Transaction) transactionHandler) async {
    return await _firestore.runTransaction(transactionHandler);
  }

  // 배치 작업 실행
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