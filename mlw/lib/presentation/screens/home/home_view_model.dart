import 'package:flutter/foundation.dart';
import 'package:mlw/data/models/note.dart';
import 'package:mlw/domain/services/note_service.dart';
import 'package:mlw/domain/services/user_service.dart';
import 'package:mlw/data/models/user_settings.dart';

class HomeViewModel with ChangeNotifier {
  final NoteService _noteService;
  final UserService _userService;
  
  List<Note> _notes = [];
  UserSettings? _userSettings;
  bool _isLoading = false;
  String _error = '';
  
  HomeViewModel({
    required NoteService noteService,
    required UserService userService,
  }) : 
    _noteService = noteService,
    _userService = userService;
  
  List<Note> get notes => _notes;
  UserSettings? get userSettings => _userSettings;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  // 노트 목록 가져오기
  Future<List<Note>> getNotes(String userId) async {
    try {
      _setLoading(true);
      _notes = await _noteService.getNotesByUserId(userId);
      _setLoading(false);
      return _notes;
    } catch (e) {
      _setError('노트를 가져오는 중 오류가 발생했습니다: $e');
      _setLoading(false);
      return [];
    }
  }
  
  // 노트 생성
  Future<Note> createNote({
    required String userId,
    required String title,
    String content = '',
  }) async {
    try {
      final note = await _noteService.createNote(
        userId: userId,
        title: title,
        content: content,
      );
      _notes = [note, ..._notes];
      return note;
    } catch (e) {
      _setError('노트를 생성하는 중 오류가 발생했습니다: $e');
      rethrow;
    }
  }
  
  // 데이터 로드
  Future<void> loadData(String userId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      _notes = await _noteService.getNotesByUserId(userId);
      _userSettings = await _userService.getUserSettings(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 노트 삭제
  Future<void> deleteNote(String noteId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _noteService.deleteNote(noteId);
      _notes = _notes.where((note) => note.id != noteId).toList();
    } catch (e) {
      _error = '노트 삭제 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 노트 검색
  Future<void> searchNotes(String userId, String query) async {
    if (query.isEmpty) {
      loadData(userId);
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _notes = await _noteService.searchNotesByText(userId, query);
    } catch (e) {
      _error = '노트 검색 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
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