import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:mlw/widgets/flashcard_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FlashcardScreen extends StatefulWidget {
  final Note note;
  
  const FlashcardScreen({Key? key, required this.note}) : super(key: key);

  FlashcardScreen.fromParts({
    Key? key,
    required List<FlashCard> flashCards,
    required String title,
    required String noteId,
  }) : this(
    key: key,
    note: Note(
      id: noteId,
      spaceId: '',
      userId: '',
      title: title,
      flashCards: flashCards,
    ),
  );

  @override
  _FlashcardScreenState createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late List<FlashCard> _flashCards;
  int _currentIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _flashCards = List.from(widget.note.flashCards);
  }

  void _nextCard() {
    if (_currentIndex < _flashCards.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  Future<void> _markAsDone(FlashCard card) async {
    // 노트에서 플래시카드 제거
    final updatedFlashCards = List<FlashCard>.from(_flashCards);
    updatedFlashCards.removeAt(_currentIndex);
    
    // 노트 업데이트
    final updatedNote = widget.note.copyWith(
      flashCards: updatedFlashCards,
      knownFlashCards: {...widget.note.knownFlashCards, card.front},
      updatedAt: DateTime.now(),
    );
    
    // Firestore 업데이트
    await _firestore.collection('notes').doc(widget.note.id).update(updatedNote.toFirestore());
    
    // UI 업데이트
    setState(() {
      _flashCards = updatedFlashCards;
      if (_currentIndex >= _flashCards.length) {
        _currentIndex = _flashCards.length - 1;
      }
      if (_currentIndex < 0) {
        _currentIndex = 0;
      }
    });
    
    // 모든 카드를 완료했을 때
    if (_flashCards.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 플래시카드를 완료했습니다!')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_flashCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('플래시카드'),
          backgroundColor: ColorTokens.getColor('primary.400'),
        ),
        body: Center(
          child: Text(
            '플래시카드가 없습니다',
            style: TypographyTokens.getStyle('body.large'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '플래시카드 (${_currentIndex + 1}/${_flashCards.length})',
          style: TypographyTokens.getStyle('heading.h3').copyWith(
            color: ColorTokens.getColor('base.0'),
          ),
        ),
        backgroundColor: ColorTokens.getColor('primary.400'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  // 오른쪽으로 스와이프 - 이전 카드
                  _previousCard();
                } else if (details.primaryVelocity! < 0) {
                  // 왼쪽으로 스와이프 - 다음 카드
                  _nextCard();
                }
              },
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! < 0) {
                  // 위로 스와이프 - 완료 표시
                  _markAsDone(_flashCards[_currentIndex]);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FlashcardWidget(
                  flashCard: _flashCards[_currentIndex],
                  onDone: () => _markAsDone(_flashCards[_currentIndex]),
                ),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: ColorTokens.getColor('base.0'),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: _currentIndex > 0 
                ? ColorTokens.getColor('primary.400') 
                : ColorTokens.getColor('text.disabled'),
            ),
            onPressed: _currentIndex > 0 ? _previousCard : null,
          ),
          ElevatedButton(
            onPressed: () => _markAsDone(_flashCards[_currentIndex]),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorTokens.getColor('success.400'),
              foregroundColor: ColorTokens.getColor('base.0'),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Done',
              style: TypographyTokens.getStyle('button.medium'),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios,
              color: _currentIndex < _flashCards.length - 1 
                ? ColorTokens.getColor('primary.400') 
                : ColorTokens.getColor('text.disabled'),
            ),
            onPressed: _currentIndex < _flashCards.length - 1 ? _nextCard : null,
          ),
        ],
      ),
    );
  }
} 