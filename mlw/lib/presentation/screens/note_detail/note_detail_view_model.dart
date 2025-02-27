import 'package:flutter/foundation.dart';
import 'package:mlw/domain/models/note.dart';
import 'package:mlw/domain/services/note_service.dart';
import 'package:mlw/domain/services/translator_service.dart';

class NoteDetailViewModel extends ChangeNotifier {
  final NoteService _noteService;
  final TranslatorService _translatorService;
  
  Note? _note;
  List<dynamic> _flashCards = [];
  bool _isLoading = false;
  String _error = '';
  
  NoteDetailViewModel({
    required NoteService noteService,
    required TranslatorService translatorService,
  }) : 
    _noteService = noteService,
    _translatorService = translatorService;
  
  // Getters
  Note? get note => _note;
  List<dynamic> get flashCards => _flashCards;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  // 노트 가져오기
  Future<Note?> getNote(String noteId) async {
    try {
      _setLoading(true);
      _note = await _noteService.getNoteById(noteId);
      _setLoading(false);
      return _note;
    } catch (e) {
      _setError('노트를 가져오는 중 오류가 발생했습니다: $e');
      _setLoading(false);
      return null;
    }
  }
  
  // 텍스트 번역
  Future<String> translateText(String text, String fromLanguage, String toLanguage) async {
    try {
      _setLoading(true);
      final translatedText = await _translatorService.translate(text, fromLanguage, toLanguage);
      _setLoading(false);
      return translatedText;
    } catch (e) {
      _setError('텍스트를 번역하는 중 오류가 발생했습니다: $e');
      _setLoading(false);
      return '';
    }
  }
  
  // 노트 업데이트
  Future<Note?> updateNote(Note updatedNote) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      final result = await _noteService.updateNote(updatedNote);
      _note = result;
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = '노트를 업데이트하는 중 오류가 발생했습니다: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  // 플래시카드 추가
  Future<void> addFlashCard(String text) async {
    if (_note == null) return;
    
    try {
      _setLoading(true);
      final updatedNote = await _noteService.addFlashCard(_note!, text);
      _note = updatedNote;
      _setLoading(false);
    } catch (e) {
      _setError('플래시카드를 추가하는 중 오류가 발생했습니다: $e');
      _setLoading(false);
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
} 