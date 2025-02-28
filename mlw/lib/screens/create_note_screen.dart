import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/repositories/note_repository.dart';
import 'package:mlw/screens/note_detail_screen.dart';

class CreateNoteScreen extends StatefulWidget {
  final String spaceId;
  final String userId;
  final String imageUrl;
  final String extractedText;
  final String translatedText;

  const CreateNoteScreen({
    Key? key,
    required this.spaceId,
    required this.userId,
    required this.imageUrl,
    required this.extractedText,
    required this.translatedText,
  }) : super(key: key);

  @override
  _CreateNoteScreenState createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final _titleController = TextEditingController();
  final _noteRepository = NoteRepository();
  bool _isCreating = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _createNote() async {
    if (_isCreating) return;
    
    setState(() {
      _isCreating = true;
      _error = null;
    });
    
    try {
      // 노트 생성
      final newNote = note_model.Note(
        id: '',
        spaceId: widget.spaceId,
        userId: widget.userId,
        title: _titleController.text.isNotEmpty ? _titleController.text : 'New Note',
        content: '',
        imageUrl: widget.imageUrl,
        extractedText: widget.extractedText,
        translatedText: widget.translatedText,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDeleted: false,
        flashcardCount: 0,
        reviewCount: 0,
        lastReviewedAt: null,
      );
      
      print('노트 생성 중...');
      final createdNote = await _noteRepository.createNote(newNote);
      print('노트 생성 완료: ${createdNote?.id}');
      
      // 생성된 노트가 Firestore에 확실히 저장되었는지 확인
      await Future.delayed(const Duration(milliseconds: 500));
      final verifyNote = await _noteRepository.getNote(createdNote?.id ?? '');
      print('노트 확인: ${verifyNote.id}, 제목: ${verifyNote.title}');
      
      if (createdNote != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteDetailScreen(note: createdNote),
          ),
        );
      } else {
        print('노트 생성 실패: createdNote는 null입니다.');
      }
    } catch (e) {
      print('노트 생성 오류: $e');
      setState(() {
        _error = '노트 생성 중 오류가 발생했습니다: $e';
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Note'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            ElevatedButton(
              onPressed: _createNote,
              child: Text('Create Note'),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
} 