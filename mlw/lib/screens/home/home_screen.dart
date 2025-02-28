import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/models/note_space.dart';
import 'package:mlw/repositories/note_repository.dart';
import 'package:mlw/repositories/note_space_repository.dart';
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
  final NoteSpaceRepository _spaceRepository = NoteSpaceRepository();
  
  late HomeScreenLogic _logic;
  late ImageHandler _imageHandler;
  
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
      _logic.loadCachedData().then((_) {
        _logic.loadCurrentNoteSpace().then((_) {
          // NoteSpace가 로드된 후 ImageHandler 초기화
          if (_currentNoteSpace != null) {
            _imageHandler = ImageHandler(
              context: context,
              spaceId: _currentNoteSpace!.id,
              userId: widget.userId ?? 'test_user_id',
              onNoteCreated: _handleNoteCreated,
            );
          }
        });
      });
    }
  }
  
  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }
  
  void _updateNotes(List<note_model.Note> notes) {
    setState(() {
      _notes = notes;
    });
  }
  
  void _updateNoteSpace(NoteSpace? noteSpace) {
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
        onRefresh: _logic.forceRefreshNotes,
        onCheckDataState: _logic.checkDataState,
        onSettings: () => Navigator.pushNamed(context, '/settings'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _imageHandler.showImageSourceActionSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(child: Text('오류: $_error'));
    }
    
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