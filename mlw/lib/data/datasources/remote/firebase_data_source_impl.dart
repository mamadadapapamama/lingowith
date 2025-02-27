import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/data/datasources/remote/firebase_data_source.dart';

class FirebaseDataSourceImpl implements FirebaseDataSource {
  final FirebaseFirestore firestore;

  FirebaseDataSourceImpl({required this.firestore});

  @override
  CollectionReference getCollection(String collectionPath) {
    return firestore.collection(collectionPath);
  }

  @override
  Future<DocumentSnapshot> getDocument(String collectionPath, String documentId) async {
    return await firestore.collection(collectionPath).doc(documentId).get();
  }

  @override
  Future<DocumentReference> addDocument(String collectionPath, Map<String, dynamic> data) async {
    return await firestore.collection(collectionPath).add(data);
  }

  @override
  Future<void> updateDocument(String collectionPath, String documentId, Map<String, dynamic> data) async {
    await firestore.collection(collectionPath).doc(documentId).update(data);
  }

  @override
  Future<void> setDocument(String collectionPath, String documentId, Map<String, dynamic> data) async {
    await firestore.collection(collectionPath).doc(documentId).set(data);
  }

  @override
  Future<void> deleteDocument(String collectionPath, String documentId) async {
    await firestore.collection(collectionPath).doc(documentId).delete();
  }

  @override
  Future<QuerySnapshot> getDocuments(String collectionPath, List<List<dynamic>> conditions) async {
    Query query = firestore.collection(collectionPath);
    
    for (final condition in conditions) {
      if (condition.length >= 3) {
        final field = condition[0] as String;
        final operator = condition[1] as String;
        final value = condition[2];
        
        if (operator == '==') {
          query = query.where(field, isEqualTo: value);
        } else if (operator == '<') {
          query = query.where(field, isLessThan: value);
        } else if (operator == '<=') {
          query = query.where(field, isLessThanOrEqualTo: value);
        } else if (operator == '>') {
          query = query.where(field, isGreaterThan: value);
        } else if (operator == '>=') {
          query = query.where(field, isGreaterThanOrEqualTo: value);
        } else if (operator == 'array-contains') {
          query = query.where(field, arrayContains: value);
        } else if (operator == 'array-contains-any') {
          query = query.where(field, arrayContainsAny: value as List<dynamic>);
        } else if (operator == 'in') {
          query = query.where(field, whereIn: value as List<dynamic>);
        } else if (operator == 'not-in') {
          query = query.where(field, whereNotIn: value as List<dynamic>);
        }
      }
    }
    
    return await query.get();
  }

  @override
  Future<void> runBatch(Function(WriteBatch) updates) async {
    final batch = firestore.batch();
    updates(batch);
    await batch.commit();
  }

  @override
  Stream<QuerySnapshot> getDocumentsStream(String collectionPath, List<List<dynamic>>? conditions, List<Map<String, dynamic>>? orderBy, int? limit) {
    Query query = firestore.collection(collectionPath);
    
    if (conditions != null) {
      for (final condition in conditions) {
        if (condition.length >= 3) {
          final field = condition[0] as String;
          final operator = condition[1] as String;
          final value = condition[2];
          
          if (operator == '==') {
            query = query.where(field, isEqualTo: value);
          } else if (operator == '<') {
            query = query.where(field, isLessThan: value);
          } else if (operator == '<=') {
            query = query.where(field, isLessThanOrEqualTo: value);
          } else if (operator == '>') {
            query = query.where(field, isGreaterThan: value);
          } else if (operator == '>=') {
            query = query.where(field, isGreaterThanOrEqualTo: value);
          } else if (operator == 'array-contains') {
            query = query.where(field, arrayContains: value);
          } else if (operator == 'array-contains-any') {
            query = query.where(field, arrayContainsAny: value as List<dynamic>);
          } else if (operator == 'in') {
            query = query.where(field, whereIn: value as List<dynamic>);
          } else if (operator == 'not-in') {
            query = query.where(field, whereNotIn: value as List<dynamic>);
          }
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
    return firestore.collection(collectionPath).doc(documentId).snapshots();
  }

  @override
  Stream<QuerySnapshot> queryStream(Query query) {
    return query.snapshots();
  }

  @override
  Future<T> runTransaction<T>(Future<T> Function(Transaction) transaction) {
    return firestore.runTransaction(transaction);
  }
} 