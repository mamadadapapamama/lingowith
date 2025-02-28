import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_space.dart';
import '../models/note.dart';

class NoteRepository {
  final FirebaseFirestore _firestore;
  
  NoteRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  // 컬렉션 참조를 getter로 만들어 재사용
  CollectionReference<Map<String, dynamic>> get _notes => 
      _firestore.collection('notes');
  
  CollectionReference<Map<String, dynamic>> get _spaces => 
      _firestore.collection('note_spaces');
  
  final Map<String, Note> _cache = {};
  
  // 노트 생성
  Future<Note> createNote(Note note) async {
    final docRef = await _notes.add(note.toFirestore());
    final doc = await docRef.get();
    return Note.fromFirestore(doc);
  }
  
  // 노트 스페이스 관련 메서드
  Future<NoteSpace> createNoteSpace(NoteSpace space) async {
    final docRef = await _spaces.add(space.toFirestore());
    final doc = await docRef.get();
    return NoteSpace.fromFirestore(doc);
  }
  
  // 노트 목록 조회
  Stream<List<NoteSpace>> getNoteSpaces(String userId) {
    return _spaces
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NoteSpace.fromFirestore(doc))
            .toList());
  }
  
  // 노트 조회 시 spaceId로 필터링
  Stream<List<Note>> getNotes(String userId, String spaceId) {
    return _notes
        .where('userId', isEqualTo: userId)
        .where('spaceId', isEqualTo: spaceId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Note.fromFirestore(doc))
            .toList());
  }
  
  // 특정 노트 조회
  Future<Note?> getNote(String noteId) async {
    // 캐시에 있으면 반환
    if (_cache.containsKey(noteId)) {
      return _cache[noteId]!;
    }
    
    // 없으면 Firestore에서 가져오기
    final docSnapshot = await _firestore.collection('notes').doc(noteId).get();
    final note = Note.fromFirestore(docSnapshot);
    
    // 캐시에 저장
    _cache[noteId] = note;
    
    return note;
  }
  
  // 노트 수정
  Future<void> updateNote(Note note) async {
    await _notes
        .doc(note.id)
        .update(note.toFirestore());
  }
  
  // 노트 삭제
  Future<void> deleteNote(String noteId) async {
    await _notes.doc(noteId).delete();
  }

  // 특정 사용자의 모든 노트 삭제
  Future<void> deleteAllUserNotes(String userId) async {
    final batch = _firestore.batch();
    final snapshots = await _notes.where('userId', isEqualTo: userId).get();
    
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  // 특정 스페이스의 모든 노트 삭제
  Future<void> deleteAllSpaceNotes(String spaceId) async {
    final batch = _firestore.batch();
    final snapshots = await _notes.where('spaceId', isEqualTo: spaceId).get();
    
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  Future<void> updateNoteTitle(String noteId, String newTitle) async {
    try {
      // 문서 존재 여부 먼저 확인
      final docSnapshot = await _notes.doc(noteId).get();
      
      if (!docSnapshot.exists) {
        throw Exception('노트를 찾을 수 없습니다: $noteId');
      }
      
      // 문서가 존재하면 업데이트
      await _notes.doc(noteId).update({
        'title': newTitle,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('노트 제목 업데이트 성공: $noteId');
    } catch (e) {
      print('노트 제목 업데이트 오류: $e');
      rethrow;
    }
  }

  Future<void> ensureDataConsistency(String noteId) async {
    final docSnapshot = await _firestore.collection('notes').doc(noteId).get();
    if (docSnapshot.exists) {
      final note = Note.fromFirestore(docSnapshot);
      
      // 플래시카드와 knownFlashCards 간의 일관성 확인
      final updatedFlashCards = note.flashCards
          .where((card) => !note.knownFlashCards.contains(card.front))
          .toList();
      
      // 데이터가 일관되지 않으면 업데이트
      if (updatedFlashCards.length != note.flashCards.length) {
        await _firestore.collection('notes').doc(noteId).update({
          'flashCards': updatedFlashCards.map((card) => card.toJson()).toList(),
        });
      }
    }
  }

  // 캐시 무효화
  void invalidateCache(String noteId) {
    _cache.remove(noteId);
  }

  Future<List<Note>> getNotesSafely(String spaceId) async {
    try {
      final snapshot = await _firestore
          .collection('notes')
          .where('spaceId', isEqualTo: spaceId)
          .get();
      
      return snapshot.docs
          .map((doc) => Note.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('노트 목록 가져오기 오류: $e');
      // 오류 발생 시 캐시된 데이터 반환 또는 빈 목록 반환
      return [];
    }
  }
} 