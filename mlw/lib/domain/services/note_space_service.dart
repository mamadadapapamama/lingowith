import 'package:mlw/data/models/note_space.dart';
import 'package:mlw/data/repositories/note_space_repository.dart';
import 'package:mlw/data/models/text_display_mode.dart';

class NoteSpaceService {
  final NoteSpaceRepository _repository;
  
  NoteSpaceService({required NoteSpaceRepository repository})
      : _repository = repository;
  
  // 노트 스페이스 생성
  Future<NoteSpace> createNoteSpace({
    required String userId,
    required String name,
    required String language,
    required String translationLanguage,
    TextDisplayMode displayMode = TextDisplayMode.both,
    bool ttsEnabled = true,
    bool sentenceTtsEnabled = true,
  }) async {
    final now = DateTime.now();
    
    final noteSpace = NoteSpace(
      id: '',
      name: name,
      userId: userId,
      language: language,
      translationLanguage: translationLanguage,
      displayMode: displayMode,
      ttsEnabled: ttsEnabled,
      sentenceTtsEnabled: sentenceTtsEnabled,
      createdAt: now,
      updatedAt: now,
    );
    
    return await _repository.createNoteSpace(noteSpace);
  }
  
  // 사용자별 노트 스페이스 목록 조회
  Future<List<NoteSpace>> getNoteSpacesByUserId(String userId) async {
    return await _repository.getNoteSpacesByUserId(userId);
  }
  
  // 노트 스페이스 상세 조회
  Future<NoteSpace?> getNoteSpaceById(String id) async {
    return await _repository.getNoteSpaceById(id);
  }
  
  // 노트 스페이스 업데이트
  Future<void> updateNoteSpace(NoteSpace noteSpace) async {
    final updatedNoteSpace = noteSpace.copyWith(
      updatedAt: DateTime.now(),
    );
    
    await _repository.updateNoteSpace(updatedNoteSpace);
  }
  
  // 노트 스페이스 삭제
  Future<void> deleteNoteSpace(String id) async {
    await _repository.deleteNoteSpace(id);
  }
  
  // 노트 스페이스에 노트 추가
  Future<void> addNoteToSpace(String spaceId, String noteId) async {
    await _repository.addNoteToSpace(spaceId, noteId);
  }
  
  // 노트 스페이스에서 노트 제거
  Future<void> removeNoteFromSpace(String spaceId, String noteId) async {
    await _repository.removeNoteFromSpace(spaceId, noteId);
  }
  
  // 노트 스페이스 설정 업데이트
  Future<void> updateNoteSpaceSettings({
    required String id,
    String? name,
    TextDisplayMode? displayMode,
    bool? ttsEnabled,
    bool? sentenceTtsEnabled,
  }) async {
    final noteSpace = await _repository.getNoteSpaceById(id);
    if (noteSpace == null) {
      throw Exception('노트 스페이스를 찾을 수 없습니다');
    }
    
    final updatedNoteSpace = noteSpace.copyWith(
      name: name,
      displayMode: displayMode,
      ttsEnabled: ttsEnabled,
      sentenceTtsEnabled: sentenceTtsEnabled,
      updatedAt: DateTime.now(),
    );
    
    await _repository.updateNoteSpace(updatedNoteSpace);
  }
} 