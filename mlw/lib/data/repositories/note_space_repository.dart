import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/data/datasources/remote/firebase_data_source.dart';
import 'package:mlw/data/models/note_space.dart';

class NoteSpaceRepository {
  final FirebaseDataSource remoteDataSource;
  static const String _collection = 'note_spaces';
  
  NoteSpaceRepository({required this.remoteDataSource});
  
  // 노트 스페이스 생성
  Future<NoteSpace> createNoteSpace(NoteSpace noteSpace) async {
    try {
      final docRef = await remoteDataSource.addDocument(_collection, noteSpace.toMap());
      return noteSpace.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('노트 스페이스를 생성하는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 사용자별 노트 스페이스 목록 조회
  Future<List<NoteSpace>> getNoteSpacesByUserId(String userId) async {
    try {
      final snapshot = await remoteDataSource.getDocuments(
        _collection,
        [
          ['userId', '==', userId],
        ],
      );
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return NoteSpace.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      throw Exception('노트 스페이스 목록을 가져오는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 노트 스페이스 상세 조회
  Future<NoteSpace?> getNoteSpaceById(String id) async {
    try {
      final doc = await remoteDataSource.getDocument(_collection, id);
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      return NoteSpace.fromMap({...data, 'id': doc.id});
    } catch (e) {
      throw Exception('노트 스페이스를 가져오는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 노트 스페이스 업데이트
  Future<void> updateNoteSpace(NoteSpace noteSpace) async {
    try {
      await remoteDataSource.updateDocument(
        _collection,
        noteSpace.id,
        noteSpace.toMap(),
      );
    } catch (e) {
      throw Exception('노트 스페이스를 업데이트하는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 노트 스페이스 삭제
  Future<void> deleteNoteSpace(String id) async {
    try {
      await remoteDataSource.deleteDocument(_collection, id);
    } catch (e) {
      throw Exception('노트 스페이스를 삭제하는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 노트 스페이스에 노트 추가
  Future<void> addNoteToSpace(String spaceId, String noteId) async {
    try {
      final noteSpace = await getNoteSpaceById(spaceId);
      if (noteSpace == null) {
        throw Exception('노트 스페이스를 찾을 수 없습니다');
      }
      
      final updatedNoteIds = List<String>.from(noteSpace.noteIds)..add(noteId);
      await updateNoteSpace(noteSpace.copyWith(
        noteIds: updatedNoteIds,
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      throw Exception('노트 스페이스에 노트를 추가하는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 노트 스페이스에서 노트 제거
  Future<void> removeNoteFromSpace(String spaceId, String noteId) async {
    try {
      final noteSpace = await getNoteSpaceById(spaceId);
      if (noteSpace == null) {
        throw Exception('노트 스페이스를 찾을 수 없습니다');
      }
      
      final updatedNoteIds = List<String>.from(noteSpace.noteIds)..remove(noteId);
      await updateNoteSpace(noteSpace.copyWith(
        noteIds: updatedNoteIds,
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      throw Exception('노트 스페이스에서 노트를 제거하는 중 오류가 발생했습니다: $e');
    }
  }
  }