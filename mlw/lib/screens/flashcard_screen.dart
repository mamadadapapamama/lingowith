import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart';
import 'package:mlw/models/flash_card.dart';
// FlashCard 클래스 충돌 해결을 위해 별칭 사용
import 'package:mlw/models/flash_card.dart' as flash_card_model;
import 'package:mlw/repositories/note_repository.dart';
import 'dart:math';
import 'package:mlw/theme/app_theme.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';

class FlashcardScreen extends StatefulWidget {
  final Note note;
  final Function(int)? onFlashcardCompleted;

  const FlashcardScreen({
    Key? key,
    required this.note,
    this.onFlashcardCompleted,
  }) : super(key: key);

  factory FlashcardScreen.fromParts({
    Key? key,
    required List<dynamic> flashCards,
    required String title,
    required String noteId,
    Function(int)? onFlashcardCompleted,
  }) {
    // FlashCard 객체로 변환
    final List<FlashCard> cards = flashCards.map((card) {
      if (card is FlashCard) {
        return card;
      }
      
      // 동적 데이터에서 FlashCard 생성
      return FlashCard(
        front: card.front,
        back: card.back,
        pinyin: card.pinyin ?? '',
        noteId: noteId,
        createdAt: DateTime.now(),
        reviewCount: 0,
        // imageUrl 필드 제거 (필요 없음)
      );
    }).toList();

    // Note 객체 생성
    final note = Note(
      id: noteId,
      spaceId: '',
      userId: '',
      title: title,
      content: '',
      imageUrl: '',
      extractedText: '',
      translatedText: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDeleted: false,
      flashcardCount: cards.length,
      reviewCount: 0,
      lastReviewedAt: null,
      pages: [],
      flashCards: cards,
      highlightedTexts: {},
      knownFlashCards: {},
    );

    return FlashcardScreen(
      key: key,
      note: note,
      onFlashcardCompleted: onFlashcardCompleted,
    );
  }

  @override
  _FlashcardScreenState createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final NoteRepository _noteRepository = NoteRepository();
  
  // FlashCard 타입을 flash_card_model.FlashCard로 변경
  late List<flash_card_model.FlashCard> _flashCards;
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isCompleted = false;
  int _knownCount = 0;
  
  // 학습 완료 여부를 추적하는 변수
  bool _isLearningCompleted = false;
  
  @override
  void initState() {
    super.initState();
    _initializeFlashcards();
  }
  
  void _initializeFlashcards() {
    // 플래시카드 목록 초기화
    _flashCards = List.from(widget.note.flashCards);
    
    // 플래시카드가 없으면 빈 목록으로 초기화
    if (_flashCards.isEmpty) {
      _isCompleted = true;
      return;
    }
    
    // 플래시카드 섞기
    _flashCards.shuffle(Random());
    
    // 이미 알고 있는 플래시카드 필터링 (선택적)
    // _flashCards = _flashCards.where((card) => 
    //   !widget.note.knownFlashCards.contains(card.front)).toList();
    
    _currentIndex = 0;
    _showAnswer = false;
    _isCompleted = _flashCards.isEmpty;
    _knownCount = 0;
  }
  
  void _nextCard({required bool isKnown}) async {
    if (_currentIndex >= _flashCards.length - 1) {
      // 마지막 카드인 경우
      if (isKnown) {
        _markCardAsKnown(_flashCards[_currentIndex]);
        _knownCount++;
      }
      
      setState(() {
        _isCompleted = true;
        _isLearningCompleted = true;
      });
      
      // 학습 완료 콜백 호출
      if (widget.onFlashcardCompleted != null) {
        widget.onFlashcardCompleted!(_knownCount);
      }
    } else {
      // 다음 카드로 이동
      if (isKnown) {
        _markCardAsKnown(_flashCards[_currentIndex]);
        _knownCount++;
      }
      
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
    }
  }
  
  // FlashCard 타입을 flash_card_model.FlashCard로 변경
  Future<void> _markCardAsKnown(flash_card_model.FlashCard card) async {
    try {
      // 현재 노트의 knownFlashCards 집합에 추가
      final updatedKnownCards = Set<String>.from(widget.note.knownFlashCards);
      updatedKnownCards.add(card.front);
      
      // 노트 업데이트
      final updatedNote = widget.note.copyWith(
        knownFlashCards: updatedKnownCards,
        flashcardCount: widget.note.flashcardCount,
        reviewCount: widget.note.reviewCount,
      );
      
      await _noteRepository.updateNote(updatedNote);
    } catch (e) {
      print('플래시카드 상태 업데이트 오류: $e');
    }
  }
  
  void _resetLearning() {
    setState(() {
      _initializeFlashcards();
      _isLearningCompleted = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('플래시카드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetLearning,
            tooltip: '다시 시작',
          ),
        ],
      ),
      body: _isCompleted ? _buildCompletionScreen() : _buildFlashcardScreen(),
    );
  }
  
  Widget _buildFlashcardScreen() {
    if (_flashCards.isEmpty) {
      return const Center(
        child: Text('플래시카드가 없습니다. 노트에 플래시카드를 추가해주세요.'),
      );
    }
    
    final currentCard = _flashCards[_currentIndex];
    
    return Column(
      children: [
        LinearProgressIndicator(
          value: (_currentIndex + 1) / _flashCards.length,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '${_currentIndex + 1} / ${_flashCards.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _showAnswer = !_showAnswer;
              });
            },
            child: Card(
              margin: const EdgeInsets.all(16.0),
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showAnswer ? '답변' : '질문',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      _showAnswer ? currentCard.back : currentCard.front,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24.0),
                    if (!_showAnswer)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showAnswer = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 12.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text('답변 보기'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        if (_showAnswer)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _nextCard(isKnown: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text('모름'),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _nextCard(isKnown: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text('알고 있음'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildCompletionScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80.0,
            color: Colors.green.shade400,
          ),
          const SizedBox(height: 24.0),
          Text(
            '학습 완료!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16.0),
          Text(
            '알고 있는 카드: $_knownCount / ${_flashCards.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 32.0),
          ElevatedButton(
            onPressed: _resetLearning,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('다시 학습하기'),
          ),
          const SizedBox(height: 16.0),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true); // 학습 완료 후 true 반환
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
            ),
            child: const Text('돌아가기'),
          ),
        ],
      ),
    );
  }
} 