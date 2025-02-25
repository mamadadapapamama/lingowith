import 'package:flutter/foundation.dart';
import 'package:mlw/domain/services/note_service.dart';
import 'package:mlw/domain/services/flash_card_service.dart';
import 'package:mlw/data/models/note.dart';
import 'package:mlw/data/models/flash_card.dart';
import 'package:mlw/services/translator.dart';

class NoteDetailViewModel with ChangeNotifier {
  final NoteService _noteService;
  final FlashCardService _flashCardService;
  final TranslatorService _translatorService;
  
  Note? _note;
  List<FlashCard> _flashCards = [];
  bool _isLoading = false;
  String _error = '';
  int _flashCardCount = 0;
  
  NoteDetailViewModel({
    required NoteService noteService,
    required FlashCardService flashCardService,
    required TranslatorService translatorService,
  }) : 
    _noteService = noteService,
    _flashCardService = flashCardService,
    _translatorService = translatorService;
  
  // Getters
  Note? get note => _note;
  List<FlashCard> get flashCards => _flashCards;
  bool get isLoading => _isLoading;
  String get error => _error;
  int get flashCardCount => _flashCardCount;
  
  // 노트 가져오기
  Future<Note?> getNote(String noteId) async {
    try {
      _setLoading(true);
      _note = await _noteService.getNoteById(noteId);
      _flashCardCount = await _flashCardService.getFlashCardCountByNoteId(noteId);
      _error = '';
      _setLoading(false);
      return _note;
    } catch (e) {
      _setError('노트를 불러오는 중 오류가 발생했습니다: $e');
      _setLoading(false);
      return null;
    }
  }
  
  // 노트 로드
  Future<void> loadNote(String noteId) async {
    _setLoading(true);
    try {
      _note = await _noteService.getNoteById(noteId);
      _flashCardCount = await _flashCardService.getFlashCardCountByNoteId(noteId);
      _error = '';
    } catch (e) {
      _error = '노트를 불러오는 중 오류가 발생했습니다: $e';
    } finally {
      _setLoading(false);
    }
  }
  
  // 플래시카드 로드
  Future<void> loadFlashCards(String noteId) async {
    try {
      _flashCards = await _flashCardService.getFlashCardsByNoteId(noteId);
    } catch (e) {
      _error = e.toString();
    }
  }
  
  // 노트 업데이트
  Future<Note?> updateNote(Note updatedNote) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      await _noteService.updateNote(updatedNote);
      _note = updatedNote;
      _setLoading(false);
      return _note;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }
  
  // 노트 내용 업데이트
  Future<void> updateNoteContent(String content) async {
    if (_note == null) return;
    
    _setLoading(true);
    try {
      final updatedNote = _note!.copyWith(
        content: content,
        updatedAt: DateTime.now(),
      );
      
      await _noteService.updateNote(updatedNote);
      _note = updatedNote;
      _error = '';
    } catch (e) {
      _error = '노트를 업데이트하는 중 오류가 발생했습니다: $e';
    } finally {
      _setLoading(false);
    }
  }
  
  // 텍스트에서 플래시카드 생성
  Future<void> createFlashCardsFromText({
    required String userId,
    required String noteId,
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    _setLoading(true);
    try {
      await _flashCardService.createFlashCardsFromText(
        userId: userId,
        noteId: noteId,
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      _setLoading(false);
    } catch (e) {
      _setError('플래시카드를 생성하는 중 오류가 발생했습니다: $e');
      _setLoading(false);
      rethrow;
    }
  }
  
  // 선택된 텍스트에서 플래시카드 생성
  Future<void> createFlashCardFromSelectedText(String selectedText) async {
    if (_note == null) return;
    
    _setLoading(true);
    try {
      // 번역
      final translation = await _translatorService.translate(
        selectedText,
        from: 'zh-CN',
        to: 'ko',
      );
      
      // 핀인 생성
      final pinyin = await _noteService.getPinyin(selectedText);
      
      // 플래시카드 생성
      await _flashCardService.createFlashCard(
        userId: _note!.userId,
        noteId: _note!.id,
        front: selectedText,
        back: translation,
        pinyin: pinyin,
      );
      
      _flashCardCount = await _flashCardService.getFlashCardCountByNoteId(_note!.id);
      _error = '';
    } catch (e) {
      _error = '플래시카드를 생성하는 중 오류가 발생했습니다: $e';
    } finally {
      _setLoading(false);
    }
  }
  
  // 플래시카드 삭제
  Future<void> deleteFlashCard(String flashCardId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      await _flashCardService.deleteFlashCard(flashCardId);
      _flashCards = _flashCards.where((card) => card.id != flashCardId).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 텍스트 번역
  Future<String> translateText(String text, String from, String to) async {
    try {
      return await _translatorService.translate(text, from: from, to: to);
    } catch (e) {
      _setError('텍스트를 번역하는 중 오류가 발생했습니다: $e');
      return '';
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }
} 