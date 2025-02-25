import 'package:mlw/data/datasources/remote/firebase_data_source.dart';
import 'package:mlw/data/models/note.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NoteRepository {
  final FirebaseDataSource _remoteDataSource;
  static const String _notesCollection = 'notes';

  NoteRepository({
    required FirebaseDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  // 사용자 노트 목록 가져오기
  Future<List<Note>> getNotesByUserId(String userId) async {
    final querySnapshot = await _remoteDataSource.getDocuments(
      _notesCollection,
      where: [
        {'field': 'userId', 'operator': '==', 'value': userId}
      ],
      orderBy: [
        {'field': 'updatedAt', 'direction': 'desc'}
      ],
    );
    
    return querySnapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();
  }

  // 노트 상세 가져오기
  Future<Note?> getNoteById(String noteId) async {
    final doc = await _remoteDataSource.getDocument(_notesCollection, noteId);
    if (doc.exists) {
      return Note.fromFirestore(doc);
    }
    return null;
  }

  // 노트 생성
  Future<Note> createNote(Note note) async {
    final docRef = await _remoteDataSource.addDocument(_notesCollection, note.toFirestore());
    return note.copyWith(id: docRef.id);
  }

  // 노트 업데이트
  Future<void> updateNote(Note note) async {
    await _remoteDataSource.updateDocument(
      _notesCollection,
      note.id,
      note.toFirestore(),
    );
  }

  // 노트 삭제
  Future<void> deleteNote(String noteId) async {
    await _remoteDataSource.deleteDocument(_notesCollection, noteId);
  }

  // 노트 검색
  Future<List<Note>> searchNotes(String userId, String query) async {
    // 실제 구현에서는 Firestore의 전문 검색 기능 또는 Algolia 같은 서비스 사용
    // 여기서는 간단한 클라이언트 측 필터링으로 구현
    
    final notes = await getNotesByUserId(userId);
    final lowerQuery = query.toLowerCase();
    
    return notes.where((note) => 
      note.title.toLowerCase().contains(lowerQuery) || 
      note.content.toLowerCase().contains(lowerQuery)
    ).toList();
  }
} 