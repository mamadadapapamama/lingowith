import 'package:flutter/foundation.dart';
import 'package:mlw/data/models/note.dart';
import 'package:mlw/domain/services/note_service.dart';
import 'package:mlw/domain/services/user_service.dart';
import 'package:mlw/data/models/user_settings.dart';

class HomeViewModel extends ChangeNotifier {
  final NoteService _noteService;
  final UserService _userService;
  
  List<Note> _notes = [];
  UserSettings? _userSettings;
  bool _isLoading = false;
  String _error = '';
  String _userId = '';
  
  HomeViewModel({
    required UserService userService,
    required NoteService noteService,
  }) : 
    _userService = userService,
    _noteService = noteService;
  
  List<Note> get notes => _notes;
  UserSettings? get userSettings => _userSettings;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  set userId(String value) {
    _userId = value;
  }
  
  Future<void> loadNotes() async {
    if (_userId.isEmpty) {
      _error = '사용자 ID가 없습니다';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      _notes = await _noteService.getNotesByUserId(_userId);
      _userSettings = await _userService.getUserSettings(_userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  Future<Note?> createNote({required String title, String content = ''}) async {
    if (_userId.isEmpty) {
      _error = '사용자 ID가 없습니다';
      notifyListeners();
      return null;
    }
    
    try {
      final note = await _noteService.createNote(
        userId: _userId,
        title: title,
        content: content,
      );
      
      await loadNotes(); // 노트 목록 새로고침
      return note;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  Future<void> deleteNote(String noteId) async {
    try {
      await _noteService.deleteNote(noteId);
      _notes.removeWhere((note) => note.id == noteId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // 노트 검색
  Future<void> searchNotes(String userId, String query) async {
    if (query.isEmpty) {
      loadNotes();
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
} 