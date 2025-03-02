import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/models/note.dart';
import 'package:mlw/models/flash_card.dart';
import 'package:mlw/models/note_space.dart';

class NoteRepository {
  final FirebaseFirestore _firestore;
  
  // 캐시 관련 필드 추가
  final Map<String, Note> _noteCache = {};
  final Map<String, NoteSpace> _spaceCache = {};
  
  NoteRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  // 기본 CRUD 작업
  Future<Note> createNote(Note note) async {
    final docRef = _firestore.collection('notes').doc();
    final noteWithId = note.copyWith(id: docRef.id);
    await docRef.set(noteWithId.toFirestore());
    
    // 캐시에 추가
    _noteCache[noteWithId.id] = noteWithId;
    
    return noteWithId;
  }
  
  Future<Note> getNote(String noteId) async {
    // 캐시 확인
    if (_noteCache.containsKey(noteId)) {
      print('노트 캐시 히트: $noteId');
      return _noteCache[noteId]!;
    }
    
    final doc = await _firestore.collection('notes').doc(noteId).get();
    if (!doc.exists) {
      throw Exception('노트를 찾을 수 없습니다: $noteId');
    }
    
    final note = Note.fromFirestore(doc);
    
    // 캐시에 추가
    _noteCache[noteId] = note;
    
    return note;
  }
  
  Future<List<Note>> getNotes(String userId, {String? spaceId}) async {
    Query query = _firestore.collection('notes')
        .where('isDeleted', isEqualTo: false);
    
    if (userId.isNotEmpty) {
      query = query.where('userId', isEqualTo: userId);
    }
    
    if (spaceId != null) {
      query = query.where('spaceId', isEqualTo: spaceId);
    }
    
    final snapshot = await query.get();
    final notes = snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();
    
    // 캐시 업데이트
    for (final note in notes) {
      _noteCache[note.id] = note;
    }
    
    return notes;
  }
  
  Future<Note> updateNote(Note note) async {
    await _firestore.collection('notes').doc(note.id).update(note.toFirestore());
    
    // 캐시 업데이트
    _noteCache[note.id] = note;
    
    return note;
  }
  
  Future<void> deleteNote(String noteId) async {
    // 소프트 삭제 - isDeleted 플래그 설정
    await _firestore.collection('notes').doc(noteId).update({'isDeleted': true});
    
    // 캐시에서 제거
    _noteCache.remove(noteId);
  }
  
  // 플래시카드 관련 기능
  Future<Note> addFlashCard(Note note, FlashCard flashCard) async {
    // noteId 필드 추가
    final flashCardWithNoteId = flashCard.copyWith(
      noteId: note.id,
    );
    
    // 플래시카드 목록에 추가
    final updatedFlashCards = List<FlashCard>.from(note.flashCards)
      ..add(flashCardWithNoteId);
    
    // 노트 업데이트
    final updatedNote = note.copyWith(
      flashCards: updatedFlashCards,
      flashcardCount: updatedFlashCards.length,
      updatedAt: DateTime.now(),
    );
    
    // Firestore 업데이트
    await updateNote(updatedNote);
    
    return updatedNote;
  }
  
  Future<Note> removeFlashCard(Note note, String flashCardId) async {
    final updatedFlashCards = note.flashCards.where((card) => card.id != flashCardId).toList();
    final updatedNote = note.copyWith(
      flashCards: updatedFlashCards,
      updatedAt: DateTime.now(),
    );
    return await updateNote(updatedNote);
  }
  
  // 페이지 관련 기능
  Future<Note> addPage(Note note, Page page) async {
    final updatedPages = [...note.pages, page];
    final updatedNote = note.copyWith(
      pages: updatedPages,
      updatedAt: DateTime.now(),
    );
    return await updateNote(updatedNote);
  }
  
  Future<Note> updatePage(Note note, int pageIndex, Page page) async {
    if (pageIndex < 0 || pageIndex >= note.pages.length) {
      throw Exception('유효하지 않은 페이지 인덱스: $pageIndex');
    }
    
    final updatedPages = List<Page>.from(note.pages);
    updatedPages[pageIndex] = page;
    
    final updatedNote = note.copyWith(
      pages: updatedPages,
      updatedAt: DateTime.now(),
    );
    return await updateNote(updatedNote);
  }
  
  Future<Note> removePage(Note note, int pageIndex) async {
    if (pageIndex < 0 || pageIndex >= note.pages.length) {
      throw Exception('유효하지 않은 페이지 인덱스: $pageIndex');
    }
    
    final updatedPages = List<Page>.from(note.pages);
    updatedPages.removeAt(pageIndex);
    
    final updatedNote = note.copyWith(
      pages: updatedPages,
      updatedAt: DateTime.now(),
    );
    return await updateNote(updatedNote);
  }
  
  // 노트 스페이스 관련 기능
  Future<NoteSpace> createNoteSpace(NoteSpace noteSpace) async {
    final docRef = _firestore.collection('note_spaces').doc();
    final spaceWithId = noteSpace.copyWith(id: docRef.id);
    await docRef.set(spaceWithId.toFirestore());
    
    // 캐시에 추가
    _spaceCache[spaceWithId.id] = spaceWithId;
    
    return spaceWithId;
  }
  
  Future<NoteSpace> getNoteSpace(String spaceId) async {
    // 캐시 확인
    if (_spaceCache.containsKey(spaceId)) {
      print('스페이스 캐시 히트: $spaceId');
      return _spaceCache[spaceId]!;
    }
    
    final doc = await _firestore.collection('note_spaces').doc(spaceId).get();
    if (!doc.exists) {
      throw Exception('노트 스페이스를 찾을 수 없습니다: $spaceId');
    }
    
    final space = NoteSpace.fromFirestore(doc);
    
    // 캐시에 추가
    _spaceCache[spaceId] = space;
    
    return space;
  }
  
  Future<List<NoteSpace>> getNoteSpaces(String userId) async {
    final snapshot = await _firestore.collection('note_spaces')
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .get();
    
    final spaces = snapshot.docs.map((doc) => NoteSpace.fromFirestore(doc)).toList();
    
    // 캐시 업데이트
    for (final space in spaces) {
      _spaceCache[space.id] = space;
    }
    
    return spaces;
  }
  
  Future<NoteSpace> updateNoteSpace(NoteSpace noteSpace) async {
    await _firestore.collection('note_spaces').doc(noteSpace.id).update(noteSpace.toFirestore());
    
    // 캐시 업데이트
    _spaceCache[noteSpace.id] = noteSpace;
    
    return noteSpace;
  }
  
  Future<void> deleteNoteSpace(String spaceId) async {
    // 소프트 삭제 - isDeleted 플래그 설정
    await _firestore.collection('note_spaces').doc(spaceId).update({'isDeleted': true});
    
    // 캐시에서 제거
    _spaceCache.remove(spaceId);
  }
  
  // 안전하게 노트 가져오기 (오류 발생 시 빈 목록 반환)
  Future<List<Note>> getNotesSafely(String spaceId) async {
    try {
      return await getNotes('', spaceId: spaceId);
    } catch (e) {
      print('노트 로드 오류: $e');
      return [];
    }
  }
  
  // 캐시 관련 메서드 추가
  void clearCache() {
    print('캐시 초기화');
    _noteCache.clear();
    _spaceCache.clear();
  }
  
  int getCacheSize() {
    return _noteCache.length + _spaceCache.length;
  }
  
  // 스트림 기반 노트 조회 메서드 추가
  Stream<List<Note>> getNotesStream(String spaceId) {
    return _firestore.collection('notes')
        .where('spaceId', isEqualTo: spaceId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final notes = snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();
          
          // 캐시 업데이트
          for (final note in notes) {
            _noteCache[note.id] = note;
          }
          
          return notes;
        });
  }
}