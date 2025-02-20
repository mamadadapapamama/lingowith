import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/models/note.dart';

class NoteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Note>> getNotes(String spaceId, String userId) {
    return _firestore
        .collection('notes')
        .where('spaceId', isEqualTo: spaceId)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Note.fromJson({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  Future<Note> createNote(Note note) async {
    final docRef = await _firestore.collection('notes').add({
      'spaceId': note.spaceId,
      'userId': note.userId,
      'title': note.title,
      'content': note.content,
      'pages': note.pages.map((e) => e.toJson()).toList(),
      'flashCards': note.flashCards.map((e) => e.toJson()).toList(),
      'createdAt': note.createdAt,
      'updatedAt': note.updatedAt,
    });

    return note.copyWith(id: docRef.id);
  }

  Future<void> updateNote(Note note) async {
    await _firestore.collection('notes').doc(note.id).update({
      'title': note.title,
      'content': note.content,
      'pages': note.pages.map((e) => e.toJson()).toList(),
      'flashCards': note.flashCards.map((e) => e.toJson()).toList(),
      'updatedAt': note.updatedAt,
    });
  }

  Future<void> deleteNote(String id) async {
    await _firestore.collection('notes').doc(id).delete();
  }

  Future<void> updateFlashCard(String noteId, int index, FlashCard updatedCard) async {
    try {
      final note = await getNote(noteId);
      if (note != null) {
        final updatedFlashCards = List<FlashCard>.from(note.flashCards);
        updatedFlashCards[index] = updatedCard;
        
        final updatedNote = note.copyWith(
          flashCards: updatedFlashCards,
          updatedAt: DateTime.now(),
        );
        
        await updateNote(updatedNote);
      }
    } catch (e) {
      print('Error updating flash card: $e');
      rethrow;
    }
  }

  Future<Note?> getNote(String id) async {
    try {
      final doc = await _firestore.collection('notes').doc(id).get();
      if (doc.exists) {
        return Note.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting note: $e');
      rethrow;
    }
  }
} 