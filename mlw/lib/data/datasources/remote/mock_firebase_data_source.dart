import 'package:mlw/data/datasources/remote/firebase_data_source.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockFirebaseDataSource implements FirebaseDataSource {
  final FakeFirebaseFirestore _firestore = FakeFirebaseFirestore();

  @override
  CollectionReference getCollection(String collectionPath) {
    return _firestore.collection(collectionPath);
  }

  @override
  Future<DocumentSnapshot> getDocument(String collectionPath, String documentId) async {
    return await _firestore.collection(collectionPath).doc(documentId).get();
  }

  @override
  Future<DocumentReference> addDocument(String collectionPath, Map<String, dynamic> data) async {
    return await _firestore.collection(collectionPath).add(data);
  }

  @override
  Future<void> updateDocument(String collectionPath, String documentId, Map<String, dynamic> data) async {
    await _firestore.collection(collectionPath).doc(documentId).update(data);
  }

  @override
  Future<void> setDocument(String collectionPath, String documentId, Map<String, dynamic> data) async {
    await _firestore.collection(collectionPath).doc(documentId).set(data);
  }

  @override
  Future<void> deleteDocument(String collectionPath, String documentId) async {
    await _firestore.collection(collectionPath).doc(documentId).delete();
  }

  @override
  Future<QuerySnapshot> getDocuments(String collectionPath, List<List<dynamic>> conditions) async {
    Query<Map<String, dynamic>> query = _firestore.collection(collectionPath);
    
    for (final condition in conditions) {
      if (condition.length >= 3) {
        final field = condition[0] as String;
        final operator = condition[1] as String;
        final value = condition[2];
        
        if (operator == '==') {
          query = query.where(field, isEqualTo: value);
        }
        // 다른 연산자도 필요에 따라 추가
      }
    }
    
    return await query.get();
  }

  @override
  Future<void> runBatch(Function(WriteBatch) updates) async {
    final batch = _firestore.batch();
    updates(batch);
    await batch.commit();
  }

  @override
  Stream<QuerySnapshot> getDocumentsStream(String collectionPath, List<List<dynamic>>? conditions, List<Map<String, dynamic>>? orderBy, int? limit) {
    Query query = _firestore.collection(collectionPath);
    
    if (conditions != null) {
      for (final condition in conditions) {
        if (condition.length >= 3) {
          final field = condition[0] as String;
          final operator = condition[1] as String;
          final value = condition[2];
          
          if (operator == '==') {
            query = query.where(field, isEqualTo: value);
          }
          // 다른 연산자도 필요에 따라 추가
        }
      }
    }
    
    if (orderBy != null) {
      for (final order in orderBy) {
        query = query.orderBy(
          order['field'] as String,
          descending: order['direction'] == 'desc',
        );
      }
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query.snapshots();
  }

  @override
  Stream<DocumentSnapshot> documentStream(String collectionPath, String documentId) {
    return _firestore.collection(collectionPath).doc(documentId).snapshots();
  }

  @override
  Stream<QuerySnapshot> queryStream(Query query) {
    return query.snapshots();
  }

  @override
  Future<T> runTransaction<T>(Future<T> Function(Transaction) transaction) async {
    final fakeTransaction = FakeTransaction();
    return await transaction(fakeTransaction);
  }
}

class FakeTransaction implements Transaction {
  FakeTransaction();
  
  @override
  Transaction delete(DocumentReference<Object?> documentReference) {
    return this;
  }
  
  @override
  Future<DocumentSnapshot<T>> get<T>(DocumentReference<T> documentReference) {
    return documentReference.get();
  }
  
  @override
  Transaction set<T>(DocumentReference<T> documentReference, T data, [SetOptions? options]) {
    documentReference.set(data, options);
    return this;
  }
  
  @override
  Transaction update(DocumentReference<Object?> documentReference, Map<String, dynamic> data) {
    documentReference.update(data);
    return this;
  }
} 