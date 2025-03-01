import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/repositories/note_repository.dart';
import 'package:mlw/screens/note_detail_screen.dart';

class CreateNoteScreen extends StatefulWidget {
  final String spaceId;
  final String userId;
  final String? imageUrl;
  final String? extractedText;
  final String? translatedText;

  const CreateNoteScreen({
    Key? key,
    required this.spaceId,
    required this.userId,
    this.imageUrl,
    this.extractedText,
    this.translatedText,
  }) : super(key: key);

  @override
  _CreateNoteScreenState createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final NoteRepository _noteRepository = NoteRepository();
  final TextEditingController _titleController = TextEditingController();
  
  bool _isCreating = false;
  String? _error;
  
  // _note 변수를 nullable로 변경
  note_model.Note? _note;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _createNote() async {
    try {
      setState(() {
        _isCreating = true;
      });
      
      // 페이지 생성
      final page = note_model.Page(
        imageUrl: widget.imageUrl ?? '',
        extractedText: widget.extractedText ?? '',
        translatedText: widget.translatedText ?? '',
      );
      
      // 노트 생성
      final note = note_model.Note(
        id: '',
        spaceId: widget.spaceId,
        userId: widget.userId,
        title: _titleController.text.isNotEmpty ? _titleController.text : 'New Note',
        content: '',
        imageUrl: '',
        extractedText: '',
        translatedText: '',
        pages: [page],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDeleted: false,
        flashcardCount: 0,
        reviewCount: 0,
        knownFlashCards: <String>{},
        highlightedTexts: <String>{},
      );
      
      // 노트 저장
      final createdNote = await _noteRepository.createNote(note);
      
      setState(() {
        _isCreating = false;
      });
      
      // 노트 상세 화면으로 이동
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NoteDetailScreen(
              noteId: createdNote.id,
              spaceId: createdNote.spaceId,
              note: createdNote,
            ),
          ),
        );
      }
    } catch (e) {
      print('노트 생성 오류: $e');
      setState(() {
        _isCreating = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('노트 생성 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 노트 만들기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '노트 제목을 입력하세요',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            
            const SizedBox(height: 16.0),
            
            if (widget.extractedText != null && widget.extractedText!.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '추출된 텍스트:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(widget.extractedText!),
                      ),
                      
                      const SizedBox(height: 16.0),
                      
                      if (widget.translatedText != null && widget.translatedText!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '번역된 텍스트:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(widget.translatedText!),
                            ),
                          ],
                        ),
                      
                      const SizedBox(height: 16.0),
                      
                      if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '이미지:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                widget.imageUrl!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: 200,
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: Text('이미지를 불러올 수 없습니다'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 24.0),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createNote,
                child: _isCreating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('생성 중...'),
                        ],
                      )
                    : const Text('노트 생성'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 