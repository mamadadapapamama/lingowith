import 'dart:io';
import 'package:mlw/data/repositories/note_repository.dart';
import 'package:mlw/data/models/note.dart';
import 'package:mlw/domain/services/image_processing_service.dart';
import 'package:mlw/services/translator.dart';
import 'package:mlw/services/pinyin_service.dart';

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
    final now = DateTime.now();
    
    final note = Note(
      id: '',
      spaceId: 'default_space',
      userId: userId,
      title: title,
      content: content,
      pages: [],
      flashCards: [],
      highlightedTexts: [],
      knownFlashCards: [],
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
      updatedAt: DateTime.now(),
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
    final extractedText = await _imageProcessingService.extractTextFromImage(imageFile.path);
    
    // 노트 생성
    final note = Note(
      id: '', // 저장 시 자동 생성
      spaceId: 'default_space',
      userId: userId,
      title: '이미지에서 추출된 텍스트',
      content: extractedText,
      pages: [],
      flashCards: [],
      highlightedTexts: [],
      knownFlashCards: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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
  
  // 이미지에서 텍스트 추출
  Future<String> extractTextFromImage(String imagePath) async {
    return await _imageProcessingService.extractTextFromImage(imagePath);
  }
  
  // 텍스트 번역
  Future<String> translateText(String text, String from, String to) async {
    return await _translatorService.translate(text, from: from, to: to);
  }
  
  // 핀인 생성
  Future<String> getPinyin(String text) async {
    return await _pinyinService.getPinyin(text);
  }
} 