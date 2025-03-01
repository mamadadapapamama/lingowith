import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/models/note_space.dart';
import 'package:mlw/repositories/note_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mlw/screens/home/home_screen_logic.dart';
import 'package:mlw/screens/home/image_handler.dart';
import 'package:mlw/screens/home/home_screen_widgets.dart';
import 'package:mlw/screens/note_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? userId;
  
  const HomeScreen({Key? key, this.userId}) : super(key: key);
  
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NoteRepository _noteRepository = NoteRepository();
  final NoteRepository _spaceRepository = NoteRepository();
  
  late HomeScreenLogic _logic;
  ImageHandler? _imageHandler;
  
  List<note_model.Note> _notes = [];
  NoteSpace? _currentNoteSpace;
  bool _isLoading = true;
  String? _error;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    print('HomeScreen initState called');
    
    _logic = HomeScreenLogic(
      auth: _auth,
      noteRepository: _noteRepository,
      spaceRepository: _spaceRepository,
      onNotesChanged: _updateNotes,
      onNoteSpaceChanged: _updateNoteSpace,
      onLoadingChanged: _updateLoading,
      onErrorChanged: _updateError,
    );
    
    // 로딩 타임아웃 설정
    Future.delayed(const Duration(seconds: 5), () {
      if (_isLoading && mounted) {
        print('로딩 타임아웃 발생, 강제로 로딩 상태 해제');
        setState(() {
          _isLoading = false;
        });
        
        // 강제 새로고침 시도
        _logic.forceRefreshNotes();
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_isInitialized) {
      _isInitialized = true;
      
      // 개선된 초기화 플로우
      _initializeApp();
    }
  }
  
  // 앱 초기화 플로우 개선
  Future<void> _initializeApp() async {
    try {
      // 1. 먼저 캐시에서 데이터 로드 (빠른 UI 표시를 위해)
      await _logic.loadCachedData();
      
      // 2. 현재 노트 스페이스 로드
      await _logic.loadCurrentNoteSpace();
      
      // 3. 노트 스페이스가 로드되면 ImageHandler 초기화
      if (_currentNoteSpace != null) {
        setState(() {
          _imageHandler = ImageHandler(
            context: context,
            spaceId: _currentNoteSpace!.id,
            userId: 'anonymous', // 익명 사용자로 설정
            onNoteCreated: _handleNoteCreated,
          );
        });
        
        // 4. 노트 로드 (캐시에서 로드된 노트가 없는 경우에만)
        if (_notes.isEmpty) {
          print('캐시에서 로드된 노트가 없어 Firestore에서 노트 로드 시작');
          await _logic.refreshNotes();
        } else {
          print('캐시에서 ${_notes.length}개 노트가 이미 로드됨');
        }
      }
    } catch (e) {
      print('앱 초기화 오류: $e');
      setState(() {
        _error = '앱 초기화 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }
  
  void _updateNotes(List<note_model.Note> notes) {
    print('노트 업데이트: ${notes.length}개');
    setState(() {
      _notes = notes;
    });
    print('상태 업데이트 후 노트 수: ${_notes.length}개');
  }
  
  void _updateNoteSpace(NoteSpace? noteSpace) {
    print('노트 스페이스 업데이트: ${noteSpace?.id}, 이름: ${noteSpace?.name}');
    setState(() {
      _currentNoteSpace = noteSpace;
    });
  }
  
  void _updateLoading(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }
  
  void _updateError(String? error) {
    setState(() {
      _error = error;
    });
  }
  
  void _handleNoteCreated(note_model.Note note) {
    _logic.refreshNotes();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeScreenAppBar(
        title: _currentNoteSpace?.name ?? '노트',
        onSettings: () => Navigator.pushNamed(context, '/settings'),
      ),
      body: _buildBody(),
      floatingActionButton: _imageHandler != null ? FloatingActionButton(
        onPressed: () => _imageHandler!.showImageSourceActionSheet(),
        child: const Icon(Icons.add),
      ) : null,
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(child: Text('오류: $_error'));
    }
    
    // 디버깅을 위한 로그 추가
    print('현재 노트 수: ${_notes.length}');
    
    if (_notes.isEmpty) {
      return const Center(child: Text('노트가 없습니다. + 버튼을 눌러 노트를 추가하세요.'));
    }
    
    return NoteGridView(
      notes: _notes,
      onNoteTap: (note) => _logic.navigateToNoteDetail(context, note),
      onRefresh: _logic.refreshNotes,
    );
  }
} 