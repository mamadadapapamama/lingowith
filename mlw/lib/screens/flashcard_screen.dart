import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/models/flash_card.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:mlw/repositories/note_repository.dart';

class FlashcardScreen extends StatefulWidget {
  final note_model.Note? note;
  final List<FlashCard>? flashCards;
  final String? title;
  final String? noteId;
  
  const FlashcardScreen({
    Key? key,
    this.note,
  }) : flashCards = null, title = null, noteId = null, super(key: key);
  
  // fromParts 생성자 추가
  const FlashcardScreen.fromParts({
    Key? key,
    required this.flashCards,
    required this.title,
    required this.noteId,
  }) : note = null, super(key: key);
  
  @override
  _FlashcardScreenState createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final NoteRepository _noteRepository = NoteRepository();
  
  List<FlashCard> _flashCards = [];
  int _currentIndex = 0;
  bool _showFront = true;
  bool _isCompleted = false;
  
  @override
  void initState() {
    super.initState();
    _initTts();
    _loadFlashCards();
  }
  
  Future<void> _initTts() async {
    await _flutterTts.setLanguage('zh-CN');
    await _flutterTts.setSpeechRate(0.5);
  }
  
  void _loadFlashCards() {
    if (widget.note != null) {
      setState(() {
        _flashCards = widget.note!.flashCards;
      });
    } else if (widget.flashCards != null) {
      setState(() {
        _flashCards = widget.flashCards!;
      });
    }
  }
  
  void _nextCard() {
    if (_currentIndex < _flashCards.length - 1) {
      setState(() {
        _currentIndex++;
        _showFront = true;
      });
    } else {
      setState(() {
        _isCompleted = true;
      });
    }
  }
  
  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showFront = true;
      });
    }
  }
  
  void _flipCard() {
    setState(() {
      _showFront = !_showFront;
    });
  }
  
  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }
  
  Future<void> _updateFlashCard(FlashCard flashCard) async {
    if (widget.note == null || widget.noteId == null) return;
    
    try {
      // 리뷰 카운트 증가
      final updatedCard = flashCard.incrementReviewCount();
      
      // 노트 ID 가져오기
      final noteId = widget.note?.id ?? widget.noteId!;
      
      // 노트 가져오기
      final note = await _noteRepository.getNote(noteId);
      
      // 플래시카드 업데이트
      final updatedFlashCards = note.flashCards.map((card) {
        if (card.id == flashCard.id) {
          return updatedCard;
        }
        return card;
      }).toList();
      
      // 노트 업데이트
      final updatedNote = note.copyWith(
        flashCards: updatedFlashCards,
        reviewCount: note.reviewCount + 1,
        updatedAt: DateTime.now(),
      );
      
      // Firestore 업데이트
      await _noteRepository.updateNote(updatedNote);
      
      print('플래시카드 업데이트 완료: ${flashCard.id}, 리뷰 카운트: ${updatedCard.reviewCount}');
    } catch (e) {
      print('플래시카드 업데이트 오류: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final title = widget.note?.title ?? widget.title ?? '플래시카드';
    
    if (_flashCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(
          child: Text('플래시카드가 없습니다'),
        ),
      );
    }
    
    if (_isCompleted) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              Text(
                '모든 카드를 완료했습니다!',
                style: TypographyTokens.getStyle('heading.medium'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                    _showFront = true;
                    _isCompleted = false;
                  });
                },
                child: const Text('다시 시작'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
      );
    }
    
    final currentCard = _flashCards[_currentIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isCompleted = true;
              });
            },
            child: const Text(
              '완료',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${_currentIndex + 1} / ${_flashCards.length}',
              style: TypographyTokens.getStyle('body.medium'),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _flipCard,
              child: Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _showFront ? '중국어' : '한국어',
                        style: TypographyTokens.getStyle('body.small').copyWith(
                          color: ColorTokens.getColor('text.secondary'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _showFront ? currentCard.front : currentCard.back,
                        style: TypographyTokens.getStyle('heading.large'),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (_showFront)
                        Text(
                          currentCard.pinyin,
                          style: TypographyTokens.getStyle('body.medium').copyWith(
                            color: ColorTokens.getColor('text.secondary'),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 32),
                      OutlinedButton.icon(
                        onPressed: () => _speak(_showFront ? currentCard.front : currentCard.back),
                        icon: const Icon(Icons.volume_up),
                        label: const Text('듣기'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _currentIndex > 0 ? _previousCard : null,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: '이전 카드',
                ),
                IconButton(
                  onPressed: _nextCard,
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: '다음 카드',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}