import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/models/note_space.dart';

class NoteSpaceRepository {
  final FirebaseFirestore _firestore;
  
  NoteSpaceRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  CollectionReference<Map<String, dynamic>> get _spaces => 
      _firestore.collection('note_spaces');
  
  // Get note spaces for a user
  Stream<List<NoteSpace>> getNoteSpaces(String userId) {
    return _spaces
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NoteSpace.fromFirestore(doc))
            .toList());
  }

  // Create a new note space
  Future<NoteSpace> createNoteSpace(NoteSpace noteSpace) async {
    final docRef = await _spaces.add(noteSpace.toFirestore());
    final doc = await docRef.get();
    return NoteSpace.fromFirestore(doc);
  }

  // Update a note space
  Future<void> updateNoteSpace(NoteSpace noteSpace) async {
    await _spaces
        .doc(noteSpace.id)
        .update(noteSpace.toFirestore());
  }

  // Delete a note space
  Future<void> deleteNoteSpace(String id) async {
    await _spaces.doc(id).delete();
  }

  Future<void> deleteAllSpaceNotes(String spaceId) async {
    try {
      final notes = await _firestore
          .collection('notes')
          .where('spaceId', isEqualTo: spaceId)
          .get();

      for (var doc in notes.docs) {
        await doc.reference.delete();
      }
      print('All notes in space $spaceId have been deleted.');
    } catch (e) {
      print('Error deleting all notes in space $spaceId: $e');
      rethrow;
    }
  }
} 