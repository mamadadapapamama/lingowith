import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart';
import 'package:mlw/models/note_space.dart';
import 'package:mlw/repositories/note_repository.dart';
import 'package:mlw/screens/note_detail_screen.dart';
import 'package:mlw/screens/create_note_screen.dart';
import 'dart:async';

class NoteSpaceScreen extends StatefulWidget {
  final String spaceId;
  final String userId;

  const NoteSpaceScreen({
    Key? key, 
    required this.spaceId,
    required this.userId,
  }) : super(key: key);

  @override
  _NoteSpaceScreenState createState() => _NoteSpaceScreenState();
}

class _NoteSpaceScreenState extends State<NoteSpaceScreen> {
  final NoteRepository _noteRepository = NoteRepository();
  List<Note> _notes = [];
  NoteSpace? _space;
  bool _isLoading = true;
  String? _error;
  
  // StreamSubscription 선언을 nullable로 변경
  StreamSubscription<List<Note>>? _notesSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    // null 체크 후 취소
    _notesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // 노트 스페이스 정보 로드
      _space = await _noteRepository.getNoteSpace(widget.spaceId);
      
      // 노트 목록 로드 (스트림 대신 Future 사용)
      _notes = await _noteRepository.getNotesSafely(widget.spaceId);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('노트 스페이스 데이터 로드 오류: $e');
      setState(() {
        _isLoading = false;
        _error = '데이터를 불러오는 중 오류가 발생했습니다: $e';
      });
    }
  }

  void _createNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateNoteScreen(
          spaceId: widget.spaceId,
          userId: widget.userId,
        ),
      ),
    ).then((_) {
      // 노트 생성 후 목록 새로고침
      _loadData();
    });
  }

  void _openNoteDetail(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(note: note),
      ),
    ).then((_) {
      // 노트 상세 화면에서 돌아온 후 목록 새로고침
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_space?.name ?? '노트 스페이스'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNote,
        child: const Icon(Icons.add),
        tooltip: '새 노트 만들기',
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48.0,
              color: Colors.red,
            ),
            const SizedBox(height: 16.0),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    
    if (_notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.note_alt_outlined,
              size: 64.0,
              color: Colors.grey,
            ),
            const SizedBox(height: 16.0),
            const Text(
              '노트가 없습니다',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _createNote,
              child: const Text('첫 노트 만들기'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ListTile(
            title: Text(
              note.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '플래시카드: ${note.flashcardCount}개 · 복습: ${note.reviewCount}회',
              maxLines: 1,
            ),
            leading: note.imageUrl != null && note.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Image.network(
                      note.imageUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.note);
                      },
                    ),
                  )
                : const Icon(Icons.note),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openNoteDetail(note),
          ),
        );
      },
    );
  }
} 