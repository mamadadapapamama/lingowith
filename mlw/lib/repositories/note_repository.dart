import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/models/note.dart';

class NoteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _notesCollection;

  NoteRepository() : _notesCollection = FirebaseFirestore.instance.collection('notes');

  Future<List<Note>> getNotesList(String userId, String spaceId) async {
    print("Repository: Getting notes for userId: $userId, spaceId: $spaceId");
    
    try {
      final snapshot = await _notesCollection
          .where('userId', isEqualTo: userId)
          .where('spaceId', isEqualTo: spaceId)
          .get();
      
      print("Repository: Found ${snapshot.docs.length} documents");
      
      final notes = snapshot.docs.map((doc) {
        try {
          final note = Note.fromFirestore(doc);
          print("Successfully parsed note: ${note.id}, title: ${note.title}");
          return note;
        } catch (e) {
          print("Error parsing note ${doc.id}: $e");
          return null;
        }
      }).where((note) => note != null).cast<Note>().toList();
      
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print("Repository: Returning ${notes.length} valid notes");
      return notes;
    } catch (e) {
      print("Repository error: $e");
      rethrow;
    }
  }

  Future<Note> getNote(String id) async {
    final doc = await _notesCollection.doc(id).get();
    return Note.fromFirestore(doc);
  }

  Future<Note> createNote(Note note) async {
    final docRef = await _notesCollection.add(note.toFirestore());
    final newDoc = await docRef.get();
    return Note.fromFirestore(newDoc);
  }

  Future<void> updateNote(Note note) async {
    await _notesCollection.doc(note.id).update(note.toFirestore());
  }

  Future<void> deleteNote(String id) async {
    await _notesCollection.doc(id).delete();
  }

  Future<void> updateNoteTitle(String id, String title) async {
    await _notesCollection.doc(id).update({
      'title': title,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateHighlightedTexts(String id, Set<String> highlightedTexts) async {
    await _notesCollection.doc(id).update({
      'highlightedTexts': highlightedTexts.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFlashCards(String id, List<FlashCard> flashCards) async {
    await _notesCollection.doc(id).update({
      'flashCards': flashCards.map((card) => card.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateKnownFlashCards(String id, Map<String, bool> knownFlashCards) async {
    await _notesCollection.doc(id).update({
      'knownFlashCards': knownFlashCards,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFlashCard(String noteId, int index, FlashCard updatedCard) async {
    try {
      final note = await getNote(noteId);
      final updatedFlashCards = List<FlashCard>.from(note.flashCards);
      if (index < updatedFlashCards.length) {
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

  // 노트 스페이스의 모든 노트 가져오기
  Stream<List<Note>> getNotes(String spaceId) {
    print('getNotes 호출됨: spaceId=$spaceId');
    return _firestore
        .collection('notes')
        .where('spaceId', isEqualTo: spaceId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Firestore 쿼리 결과: ${snapshot.docs.length}개');
          return snapshot.docs
              .map((doc) => Note.fromFirestore(doc))
              .where((note) => !(note.isDeleted ?? false))
              .toList();
        });
  }

  // 노트 스페이스의 모든 노트 관찰하기 (getNotes와 동일한 기능)
  Stream<List<Note>> watchNotes(String spaceId) {
    return getNotes(spaceId);
  }

  // 모든 노트 가져오기 (필터링 없이)
  Future<void> _loadAllNotes() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('notes').get();
      print('Firebase에 총 ${snapshot.docs.length}개의 노트가 있습니다.');
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('노트 ID: ${doc.id}, 제목: ${data['title']}, 사용자: ${data['userId']}, 스페이스: ${data['spaceId']}');
      }
    } catch (e) {
      print('모든 노트 로드 오류: $e');
    }
  }
} 