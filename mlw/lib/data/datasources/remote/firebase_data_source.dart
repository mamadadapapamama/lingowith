import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FirebaseDataSource {
  CollectionReference getCollection(String collectionPath);
  Future<DocumentSnapshot> getDocument(String collectionPath, String documentId);
  Future<DocumentReference> addDocument(String collectionPath, Map<String, dynamic> data);
  Future<void> updateDocument(String collectionPath, String documentId, Map<String, dynamic> data);
  Future<void> setDocument(String collectionPath, String documentId, Map<String, dynamic> data);
  Future<void> deleteDocument(String collectionPath, String documentId);
  Future<QuerySnapshot> getDocuments(String collectionPath, List<List<dynamic>> conditions);
  Future<void> runBatch(Function(WriteBatch) updates);
  Stream<QuerySnapshot> getDocumentsStream(String collectionPath, List<List<dynamic>>? conditions, List<Map<String, dynamic>>? orderBy, int? limit);
  
  // 누락된 메서드들
  Stream<DocumentSnapshot> documentStream(String collectionPath, String documentId);
  Stream<QuerySnapshot> queryStream(Query query);
  Future<T> runTransaction<T>(Future<T> Function(Transaction) transaction);
} 