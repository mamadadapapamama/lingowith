import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mlw/presentation/screens/home/home_view_model.dart';
import 'package:mlw/presentation/widgets/note_card.dart';
import 'package:mlw/presentation/screens/note_detail/note_detail_screen.dart';
import 'package:mlw/core/di/service_locator.dart';
import 'package:mlw/data/models/note.dart';
import 'package:mlw/presentation/widgets/custom_app_bar.dart';
import 'package:mlw/presentation/widgets/loading_indicator.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  
  const HomeScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _viewModel;
  
  @override
  void initState() {
    super.initState();
    _viewModel = serviceLocator<HomeViewModel>();
    _viewModel.userId = widget.userId;
    _loadNotes();
  }
  
  Future<void> _loadNotes() async {
    await _viewModel.loadNotes();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '내 노트',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildBody() {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        if (_viewModel.isLoading) {
          return const LoadingIndicator();
        }
        
        if (_viewModel.error.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '오류가 발생했습니다: ${_viewModel.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadNotes,
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }
        
        if (_viewModel.notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '노트가 없습니다.\n새 노트를 추가해보세요!',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showAddNoteDialog,
                  child: const Text('노트 추가'),
                ),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: _loadNotes,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _viewModel.notes.length,
            itemBuilder: (context, index) {
              final note = _viewModel.notes[index];
              return NoteCard(
                note: note,
                onTap: () => _navigateToNoteDetail(note),
                onDelete: () => _deleteNote(note),
              );
            },
          ),
        );
      },
    );
  }
  
  void _navigateToNoteDetail(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(
          noteId: note.id,
          userId: widget.userId,
        ),
      ),
    ).then((_) => _loadNotes());
  }
  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('노트 삭제'),
        content: Text('정말로 "${note.title}" 노트를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _viewModel.deleteNote(note.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('노트가 삭제되었습니다')),
        );
      }
    }
  }
  
  Future<void> _showAddNoteDialog() async {
    final titleController = TextEditingController();
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 노트 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, {
                      'type': 'text',
                      'title': titleController.text,
                    });
                  },
                  icon: const Icon(Icons.text_fields),
                  label: const Text('텍스트'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, {
                      'type': 'image',
                      'title': titleController.text,
                    });
                  },
                  icon: const Icon(Icons.image),
                  label: const Text('이미지'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      final type = result['type'] as String;
      final title = result['title'] as String;
      
      if (title.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('제목을 입력해주세요')),
          );
        }
        return;
      }
      
      if (type == 'text') {
        await _createTextNote(title);
      } else if (type == 'image') {
        await _createImageNote(title);
      }
    }
  }
  
  Future<void> _createTextNote(String title) async {
    final note = await _viewModel.createNote(title: title);
    if (note != null && mounted) {
      _navigateToNoteDetail(note);
    }
  }
  
  Future<void> _createImageNote(String title) async {
    // 이미지 선택 및 처리 로직은 추후 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이미지 노트 기능은 아직 구현 중입니다')),
    );
  }
} 