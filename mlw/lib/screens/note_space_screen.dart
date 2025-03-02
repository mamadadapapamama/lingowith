import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mlw/models/note.dart';
import 'package:mlw/models/note_space.dart';
import 'package:mlw/repositories/note_repository.dart';
import 'package:mlw/screens/create_note_screen.dart';
import 'package:mlw/screens/note_detail_screen.dart';
import 'package:mlw/screens/note_space_settings_screen.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:mlw/widgets/note_card.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NoteSpaceScreen extends StatefulWidget {
  final String spaceId;
  
  const NoteSpaceScreen({
    Key? key,
    required this.spaceId,
  }) : super(key: key);
  
  @override
  _NoteSpaceScreenState createState() => _NoteSpaceScreenState();
}

class _NoteSpaceScreenState extends State<NoteSpaceScreen> {
  final NoteRepository _noteRepository = NoteRepository();
  
  NoteSpace? _space;
  List<Note> _notes = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // 노트 스페이스 정보 로드
      _space = await _noteRepository.getNoteSpace(widget.spaceId);
      
      // 노트 목록 로드
      _notes = await _noteRepository.getNotesSafely(widget.spaceId);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      
      print('노트 스페이스 데이터 로드 오류: $e');
    }
  }
  
  void _navigateToCreateNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateNoteScreen(
          spaceId: widget.spaceId,
          userId: _space?.userId ?? '',
          language: _space?.language ?? 'zh',
        ),
      ),
    );
    
    if (result == true) {
      _loadData();
    }
  }
  
  void _navigateToNoteDetail(Note note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(
          noteId: note.id,
          spaceId: note.spaceId,
          note: note,
        ),
      ),
    );
    
    if (result == true) {
      _loadData();
    }
  }
  
  void _navigateToSettings() async {
    if (_space == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteSpaceSettingsScreen(
          noteSpace: _space!,
        ),
      ),
    );
    
    if (result == true) {
      _loadData();
    }
  }
  
  void _deleteNote(String noteId) {
    // Implementation of deleteNote method
  }
  
  void _updateNoteTitle(String noteId, String newTitle) {
    // Implementation of updateNoteTitle method
  }
  
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: ColorTokens.getColor('background'),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: ColorTokens.getColor('background'),
        appBar: AppBar(
          backgroundColor: ColorTokens.getColor('background'),
          elevation: 0,
          leading: IconButton(
            icon: SvgPicture.asset(
              'assets/icon/back.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                ColorTokens.getColor('text'),
                BlendMode.srcIn,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _space?.name ?? 'Note Space',
            style: TypographyTokens.getStyle('heading.h2'),
          ),
          actions: [
            IconButton(
              icon: SvgPicture.asset(
                'assets/icon/settings.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  ColorTokens.getColor('text'),
                  BlendMode.srcIn,
                ),
              ),
              onPressed: _navigateToSettings,
            ),
          ],
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToCreateNote,
          backgroundColor: ColorTokens.getColor('primary'),
          child: const Icon(Icons.add),
        ),
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
            Text(
              '오류가 발생했습니다',
              style: TypographyTokens.getStyle('body.large'),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TypographyTokens.getStyle('body.medium'),
            ),
            const SizedBox(height: 16),
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
            SvgPicture.asset(
              'assets/icon/empty_notes.svg',
              width: 120,
              height: 120,
              colorFilter: ColorFilter.mode(
                ColorTokens.getColor('disabled'),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '노트가 없습니다',
              style: TypographyTokens.getStyle('body.large'),
            ),
            const SizedBox(height: 8),
            Text(
              '새 노트를 추가해보세요',
              style: TypographyTokens.getStyle('body.medium').copyWith(
                color: ColorTokens.getColor('text.secondary'),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: NoteCard(
            note: note,
            onTap: () => _navigateToNoteDetail(note),
            onPressed: () => _navigateToNoteDetail(note),
            onDelete: (noteId) => _deleteNote(noteId),
            onTitleEdit: (noteId, newTitle) => _updateNoteTitle(noteId, newTitle),
          ),
        );
      },
    );
  }
} 