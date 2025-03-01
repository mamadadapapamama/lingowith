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
        content: widget.extractedText ?? '',
        imageUrl: widget.imageUrl ?? '',
        extractedText: widget.extractedText ?? '',
        translatedText: widget.translatedText ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDeleted: false,
        flashcardCount: 0,
        reviewCount: 0,
        flashCards: [], // 빈 플래시카드 목록 추가
        knownFlashCards: {}, // 빈 알고 있는 플래시카드 집합 추가
      );
      
      print('노트 생성 중...');
      final createdNote = await _noteRepository.createNote(newNote);
      print('노트 생성 완료: ${createdNote.id}');
      
      // 생성된 노트 저장
      setState(() {
        _note = createdNote;
      });
      
      // 생성된 노트가 Firestore에 확실히 저장되었는지 확인
      await Future.delayed(const Duration(milliseconds: 500));
      final verifyNote = await _noteRepository.getNote(createdNote.id);
      print('노트 확인: ${verifyNote.id}, 제목: ${verifyNote.title}');
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NoteDetailScreen(
              note: _note!, // null 체크 후 사용
              initialTranslatedContent: widget.translatedText,
            ),
          ),
        );
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