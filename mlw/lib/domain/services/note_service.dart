import 'dart:io';
import 'package:mlw/data/repositories/note_repository.dart';
import 'package:mlw/domain/models/note.dart';
import 'package:mlw/domain/services/image_processing_service.dart';
import 'package:mlw/domain/services/pinyin_service.dart';
import 'package:mlw/domain/services/translator_service.dart';

class NoteService {
  final NoteRepository _repository;
  final ImageProcessingService _imageProcessingService;
  final TranslatorService _translatorService;
  final PinyinService _pinyinService;
  
  NoteService({
    required NoteRepository repository,
    required ImageProcessingService imageProcessingService,
    required TranslatorService translatorService,
    required PinyinService pinyinService,
  }) : 
    _repository = repository,
    _imageProcessingService = imageProcessingService,
    _translatorService = translatorService,
    _pinyinService = pinyinService;
  
  // 노트 생성
  Future<Note> createNote({
    required String userId,
    required String title,
    String content = '',
  }) async {
    final now = DateTime.now().toIso8601String();
    
    final note = Note(
      id: '',
      userId: userId,
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
    
    return await _repository.createNote(note);
  }
  
  // 노트 가져오기
  Future<Note?> getNoteById(String noteId) async {
    return await _repository.getNoteById(noteId);
  }
  
  // 사용자의 모든 노트 가져오기
  Future<List<Note>> getNotesByUserId(String userId) async {
    return await _repository.getNotesByUserId(userId);
  }
  
  // 노트 업데이트
  Future<Note> updateNote(Note note) async {
    final updatedNote = note.copyWith(
      updatedAt: DateTime.now().toIso8601String(),
    );
    
    await _repository.updateNote(updatedNote);
    return updatedNote;
  }
  
  // 노트 삭제
  Future<void> deleteNote(String noteId) async {
    await _repository.deleteNote(noteId);
  }
  
  // 이미지에서 텍스트 추출하여 노트 생성
  Future<Note> createNoteFromImage(String userId, File imageFile) async {
    // 이미지에서 텍스트 추출
    final extractedText = await _imageProcessingService.extractTextFromImage(imageFile);
    
    // 노트 생성
    final note = Note(
      id: '',
      userId: userId,
      title: '이미지에서 추출된 텍스트',
      content: extractedText,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    
    return await _repository.createNote(note);
  }
  
  // 텍스트로 노트 검색
  Future<List<Note>> searchNotesByText(String userId, String query) async {
    // NoteRepository에 searchNotesByText 메서드가 없으므로 searchNotes 메서드 사용
    return await _repository.searchNotes(userId, query);
  }
  
  // 태그로 노트 검색 (태그 기능이 제거되었으므로 내용 기반 검색으로 대체)
  Future<List<Note>> searchNotesByTag(String userId, String tag) async {
    final notes = await _repository.getNotesByUserId(userId);
    return notes.where((note) => note.content.contains(tag)).toList();
  }
  
  // 노트 검색
  Future<List<Note>> searchNotes(String userId, String query) async {
    return await _repository.searchNotes(userId, query);
  }
  
  // 텍스트 번역
  Future<String> translateText(String text, String fromLanguage, String toLanguage) async {
    return await _translatorService.translate(text, fromLanguage, toLanguage);
  }
  
  // 중국어 텍스트에서 병음 추출
  Future<String> getPinyin(String chineseText) async {
    return await _pinyinService.getPinyin(chineseText);
  }
  
  // 플래시카드 추가 메서드
  Future<Note> addFlashCard(Note note, String text) async {
    final translatedText = await _translatorService.translate(text, 'zh', 'ko');
    final pinyin = await _pinyinService.getPinyin(text);
    
    // 여기서는 플래시카드 추가 로직을 구현해야 하지만,
    // 현재 Note 모델에 flashCards 필드가 없으므로 임시로 content에 추가
    final updatedContent = '${note.content}\n\n플래시카드: $text ($pinyin) - $translatedText';
    
    final updatedNote = note.copyWith(
      content: updatedContent,
      updatedAt: DateTime.now().toIso8601String(),
    );
    
    await _repository.updateNote(updatedNote);
    return updatedNote;
  }
} 