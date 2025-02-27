import 'package:flutter/foundation.dart';
import 'package:mlw/domain/models/note.dart';
import 'package:mlw/domain/models/user.dart';
import 'package:mlw/domain/services/note_service.dart';
import 'package:mlw/domain/services/user_service.dart';

class HomeViewModel extends ChangeNotifier {
  final UserService userService;
  final NoteService noteService;
  
  User? _user;
  List<Note> _notes = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  HomeViewModel({
    required this.userService,
    required this.noteService,
  });
  
  User? get user => _user;
  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  Future<void> loadUserData(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      _user = await userService.getUser(userId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = '사용자 정보를 불러오는 중 오류가 발생했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> loadNotes(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      
      _notes = await noteService.getNotesByUserId(userId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = '노트를 불러오는 중 오류가 발생했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> deleteNote(String noteId) async {
    try {
      await noteService.deleteNote(noteId);
      _notes.removeWhere((note) => note.id == noteId);
      notifyListeners();
    } catch (e) {
      _errorMessage = '노트를 삭제하는 중 오류가 발생했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  Future<Note?> createNote({required String title, String content = ''}) async {
    try {
      if (_user == null) throw Exception('사용자 정보가 없습니다');
      
      final newNote = await noteService.createNote(
        userId: _user!.id,
        title: title,
        content: content,
      );
      
      await loadNotes(_user!.id);
      return newNote;
    } catch (e) {
      _errorMessage = '노트를 생성하는 중 오류가 발생했습니다: $e';
      notifyListeners();
      rethrow;
    }
  }
  
  void loadMockData() {
    // Mock 사용자 데이터
    _user = User(
      id: 'mock_user_id',
      name: '테스트 사용자',
      email: 'test@example.com',
      createdAt: DateTime.now().toIso8601String(),
    );
    
    // Mock 노트 데이터
    _notes = [
      Note(
        id: 'mock_note_1',
        title: '중국어 기초 회화',
        content: '안녕하세요 = 你好 (nǐ hǎo)',
        userId: 'mock_user_id',
        createdAt: DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
      Note(
        id: 'mock_note_2',
        title: '중국어 숫자',
        content: '1 = 一 (yī)\n2 = 二 (èr)\n3 = 三 (sān)',
        userId: 'mock_user_id',
        createdAt: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
      Note(
        id: 'mock_note_3',
        title: '중국어 음식',
        content: '밥 = 饭 (fàn)\n물 = 水 (shuǐ)',
        userId: 'mock_user_id',
        createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
    ];
    
    notifyListeners();
  }
} 