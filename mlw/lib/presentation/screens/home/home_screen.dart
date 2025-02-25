import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mlw/presentation/screens/home/home_view_model.dart';
import 'package:mlw/presentation/widgets/note_card.dart';
import 'package:mlw/presentation/screens/note_detail/note_detail_screen.dart';
import 'package:mlw/core/di/service_locator.dart';
import 'package:mlw/data/models/note.dart';

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
  late HomeViewModel _viewModel;
  bool _isLoading = true;
  List<Note> _notes = [];
  
  @override
  void initState() {
    super.initState();
    _viewModel = serviceLocator.getFactory<HomeViewModel>();
    _loadNotes();
  }
  
  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final notes = await _viewModel.getNotes(widget.userId);
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('노트를 불러오는 중 오류가 발생했습니다: $e')),
      );
    }
  }
  
  Future<void> _createNewNote() async {
    final titleController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 노트 만들기'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: '노트 제목을 입력하세요',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('만들기'),
          ),
        ],
      ),
    );
    
    if (result == true && titleController.text.isNotEmpty) {
      try {
        final note = await _viewModel.createNote(
          userId: widget.userId,
          title: titleController.text,
        );
        
        if (note != null) {
          setState(() {
            _notes = [note, ..._notes];
          });
          
          if (!mounted) return;
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(
                noteId: note.id,
                userId: widget.userId,
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('노트를 생성하는 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 노트'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/settings',
                arguments: widget.userId,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? _buildEmptyState()
              : _buildNotesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewNote,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.note_alt_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '노트가 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '새 노트를 만들어 학습을 시작하세요',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewNote,
            icon: const Icon(Icons.add),
            label: const Text('새 노트 만들기'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(
              note.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              note.content.isEmpty
                  ? '내용 없음'
                  : note.content.length > 50
                      ? '${note.content.substring(0, 50)}...'
                      : note.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteDetailScreen(
                    noteId: note.id,
                    userId: widget.userId,
                  ),
                ),
              ).then((_) => _loadNotes());
            },
          ),
        );
      },
    );
  }
} 