import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/data/models/note_space.dart';

class NoteSpaceRepository {
  final FirebaseFirestore _firestore;
  final CollectionReference _noteSpacesCollection;

  NoteSpaceRepository({
    required FirebaseFirestore firestore,
  }) : 
    _firestore = firestore,
    _noteSpacesCollection = firestore.collection('note_spaces');

  // 노트 스페이스 가져오기
  Future<NoteSpace> getNoteSpaceById(String spaceId) async {
    try {
      final doc = await _noteSpacesCollection.doc(spaceId).get();
      
      if (!doc.exists) {
        throw Exception('노트 스페이스를 찾을 수 없습니다.');
      }
      
      return NoteSpace.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Error getting note space: $e');
      rethrow;
    }
  }

  // 사용자 ID로 노트 스페이스 목록 가져오기
  Future<List<NoteSpace>> getNoteSpacesByUserId(String userId) async {
    try {
      final snapshot = await _noteSpacesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => NoteSpace.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting note spaces: $e');
      rethrow;
    }
  }

  // 노트 스페이스 생성
  Future<NoteSpace> createNoteSpace(NoteSpace noteSpace) async {
    try {
      final docRef = _noteSpacesCollection.doc();
      final noteSpaceWithId = noteSpace.copyWith(id: docRef.id);
      
      await docRef.set(noteSpaceWithId.toMap());
      
      return noteSpaceWithId;
    } catch (e) {
      print('Error creating note space: $e');
      rethrow;
    }
  }

  // 노트 스페이스 업데이트
  Future<void> updateNoteSpace(NoteSpace noteSpace) async {
    try {
      await _noteSpacesCollection.doc(noteSpace.id).update(noteSpace.toMap());
    } catch (e) {
      print('Error updating note space: $e');
      rethrow;
    }
  }

  // 노트 스페이스 삭제
  Future<void> deleteNoteSpace(String spaceId) async {
    try {
      await _noteSpacesCollection.doc(spaceId).delete();
    } catch (e) {
      print('Error deleting note space: $e');
      rethrow;
    }
  }
} 