import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mlw/core/di/service_locator.dart';
import 'package:mlw/presentation/screens/note_detail/note_detail_view_model.dart';
import 'package:mlw/presentation/screens/flash_card/flash_card_screen.dart';
import 'package:mlw/data/models/note.dart';

class NoteDetailScreen extends StatefulWidget {
  final String noteId;
  final String userId;
  
  const NoteDetailScreen({
    Key? key,
    required this.noteId,
    required this.userId,
  }) : super(key: key);

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late NoteDetailViewModel _viewModel;
  late TextEditingController _contentController;
  bool _isLoading = true;
  Note? _note;

  @override
  void initState() {
    super.initState();
    _viewModel = serviceLocator.getFactory<NoteDetailViewModel>();
    _contentController = TextEditingController();
    _loadNote();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final note = await _viewModel.getNote(widget.noteId);
      setState(() {
        _note = note;
        _contentController.text = note?.content ?? '';
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

  Future<void> _saveNote() async {
    if (_note == null) return;
    
    try {
      await _viewModel.updateNote(
        _note!.copyWith(content: _contentController.text),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('노트가 저장되었습니다')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('노트를 저장하는 중 오류가 발생했습니다: $e')),
      );
    }
  }

  Future<void> _createFlashCards() async {
    if (_note == null) return;
    
    final selectedText = _getSelectedText();
    if (selectedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('텍스트를 선택해주세요')),
      );
      return;
    }
    
    try {
      await _viewModel.createFlashCardsFromText(
        userId: widget.userId,
        noteId: widget.noteId,
        text: selectedText,
        sourceLanguage: '중국어',
        targetLanguage: '한국어',
      );
      
      if (!mounted) return;
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FlashCardScreen(
            noteId: widget.noteId,
            userId: widget.userId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('플래시카드를 생성하는 중 오류가 발생했습니다: $e')),
      );
    }
  }

  String _getSelectedText() {
    final TextSelection selection = _contentController.selection;
    if (selection.isValid && !selection.isCollapsed) {
      return _contentController.text.substring(selection.start, selection.end);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_note?.title ?? '노트 상세'),
        actions: [
          if (_note != null) ...[
            IconButton(
              icon: const Icon(Icons.flash_on),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FlashCardScreen(
                      noteId: widget.noteId,
                      userId: widget.userId,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveNote,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _note == null
              ? const Center(child: Text('노트를 찾을 수 없습니다'))
              : Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: _contentController,
                          maxLines: null,
                          expands: true,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '내용을 입력하세요...',
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _note != null
          ? FloatingActionButton(
              onPressed: _createFlashCards,
              child: const Icon(Icons.add_card),
            )
          : null,
    );
  }
} 