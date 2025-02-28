import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/models/note_space.dart';

class NoteSpaceRepository {
  final _firestore = FirebaseFirestore.instance;

  Future<List<NoteSpace>> getNoteSpaces(String userId) async {
    try {
      print('노트 스페이스 가져오기 시작: $userId');
      final snapshot = await _firestore
          .collection('note_spaces')
          .where('userId', isEqualTo: userId)
          .get();
      
      print('노트 스페이스 쿼리 결과: ${snapshot.docs.length}개');
      
      final spaces = snapshot.docs
          .map((doc) => NoteSpace.fromFirestore(doc))
          .toList();
      
      return spaces;
    } catch (e) {
      print('노트 스페이스 가져오기 오류: $e');
      return [];
    }
  }

  Future<NoteSpace> createNoteSpace(NoteSpace noteSpace) async {
    final docRef = await _firestore.collection('note_spaces').add({
      'userId': noteSpace.userId,
      'name': noteSpace.name,
      'language': noteSpace.language,
      'createdAt': noteSpace.createdAt,
      'updatedAt': noteSpace.updatedAt,
    });

    return noteSpace.copyWith(id: docRef.id);
  }

  Future<void> updateNoteSpace(NoteSpace noteSpace) async {
    await _firestore.collection('note_spaces').doc(noteSpace.id).update({
      'name': noteSpace.name,
      'language': noteSpace.language,
      'updatedAt': noteSpace.updatedAt,
    });
  }

  Future<void> deleteNoteSpace(String id) async {
    await _firestore.collection('note_spaces').doc(id).delete();
  }

  Future<void> deleteAllSpaceNotes(String spaceId) async {
    final batch = _firestore.batch();
    final notesSnapshot = await _firestore
        .collection('notes')
        .where('spaceId', isEqualTo: spaceId)
        .get();

    for (var doc in notesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
} 