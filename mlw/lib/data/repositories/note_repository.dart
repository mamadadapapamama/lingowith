import 'package:mlw/data/datasources/remote/remote_data_source.dart';
import 'package:mlw/domain/models/note.dart';

class NoteRepository {
  final RemoteDataSource remoteDataSource;
  final String _collection = 'notes';
  
  NoteRepository({required this.remoteDataSource});

  // 사용자 노트 목록 가져오기
  Future<List<Note>> getNotesByUserId(String userId) async {
    try {
      final snapshot = await remoteDataSource.getDocuments(
        _collection,
        where: 'userId',
        isEqualTo: userId,
        orderBy: 'updatedAt',
        descending: true,
      );
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Note.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      throw Exception('노트 목록을 가져오는 중 오류가 발생했습니다: $e');
    }
  }

  // 노트 상세 가져오기
  Future<Note?> getNoteById(String id) async {
    try {
      final doc = await remoteDataSource.getDocument(_collection, id);
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      return Note.fromJson({...data, 'id': doc.id});
    } catch (e) {
      throw Exception('노트를 가져오는 중 오류가 발생했습니다: $e');
    }
  }

  // 노트 생성
  Future<Note> createNote(Note note) async {
    try {
      final docRef = await remoteDataSource.addDocument(_collection, note.toJson());
      return note.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('노트를 생성하는 중 오류가 발생했습니다: $e');
    }
  }

  // 노트 업데이트
  Future<void> updateNote(Note note) async {
    try {
      await remoteDataSource.updateDocument(
        _collection,
        note.id,
        note.toJson(),
      );
    } catch (e) {
      throw Exception('노트를 업데이트하는 중 오류가 발생했습니다: $e');
    }
  }

  // 노트 삭제
  Future<void> deleteNote(String id) async {
    try {
      await remoteDataSource.deleteDocument(_collection, id);
    } catch (e) {
      throw Exception('노트를 삭제하는 중 오류가 발생했습니다: $e');
    }
  }

  // 노트 검색
  Future<List<Note>> searchNotes(String userId, String query) async {
    try {
      final notes = await getNotesByUserId(userId);
      final lowerQuery = query.toLowerCase();
      
      return notes.where((note) {
        final lowerTitle = note.title.toLowerCase();
        final lowerContent = note.content.toLowerCase();
        return lowerTitle.contains(lowerQuery) || lowerContent.contains(lowerQuery);
      }).toList();
    } catch (e) {
      throw Exception('노트를 검색하는 중 오류가 발생했습니다: $e');
    }
  }

  // 노트에 페이지 추가
  Future<void> addPageToNote(String noteId, String pageId) async {
    try {
      final note = await getNoteById(noteId);
      if (note == null) {
        throw Exception('노트를 찾을 수 없습니다');
      }
      
      final updatedPageIds = List<String>.from(note.pageIds)..add(pageId);
      await updateNote(note.copyWith(
        pageIds: updatedPageIds,
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      throw Exception('노트에 페이지를 추가하는 중 오류가 발생했습니다: $e');
    }
  }

  // 노트에서 페이지 제거
  Future<void> removePageFromNote(String noteId, String pageId) async {
    try {
      final note = await getNoteById(noteId);
      if (note == null) {
        throw Exception('노트를 찾을 수 없습니다');
      }
      
      final updatedPageIds = List<String>.from(note.pageIds)..remove(pageId);
      await updateNote(note.copyWith(
        pageIds: updatedPageIds,
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      throw Exception('노트에서 페이지를 제거하는 중 오류가 발생했습니다: $e');
    }
  }

  // 플래시카드 수 업데이트
  Future<void> updateFlashCardCount(String noteId, int count) async {
    try {
      final note = await getNoteById(noteId);
      if (note == null) {
        throw Exception('노트를 찾을 수 없습니다');
      }
      
      await updateNote(note.copyWith(
        flashCardCount: count,
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      throw Exception('플래시카드 수를 업데이트하는 중 오류가 발생했습니다: $e');
    }
  }
} 