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
    final doc = await _notes.doc(noteId).get();
    if (!doc.exists) return null;
    return Note.fromFirestore(doc);
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
} 