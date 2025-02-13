import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note.dart';

class NoteRepository {
  final FirebaseFirestore _firestore;
  
  NoteRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  // 컬렉션 참조를 getter로 만들어 재사용
  CollectionReference<Map<String, dynamic>> get _notes => 
      _firestore.collection('notes');
  
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
} 