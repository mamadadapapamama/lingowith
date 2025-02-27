import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mlw/widgets/flash_card.dart' as flash_card_widget;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FlashCardScreen extends StatefulWidget {
  final List<note_model.FlashCard> flashCards;
  final String title;
  final String noteId;

  const FlashCardScreen({
    Key? key,
    required this.flashCards,
    required this.title,
    required this.noteId,
  }) : super(key: key);

  @override
  State<FlashCardScreen> createState() => _FlashCardScreenState();
}

class _FlashCardScreenState extends State<FlashCardScreen> {
  bool _showFront = true;
  int _currentIndex = 0;
  final FlutterTts _flutterTts = FlutterTts();
  int _remainingCards = 0;
  List<note_model.FlashCard> _currentFlashCards = [];
  int _keepCount = 0;
  int _archiveCount = 0;

  @override
  void initState() {
    super.initState();
    _remainingCards = widget.flashCards.length;
    _currentFlashCards = List.from(widget.flashCards);
    _initTTS();
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage('zh-CN');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void _flipCard() {
    setState(() {
      _showFront = !_showFront;
    });
  }

  void _keepCard() {
    setState(() {
      _showFront = true;
      if (_currentIndex < _remainingCards - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
    });
  }

  void _markAsDone() {
    setState(() {
      _remainingCards--;
      _showFront = true;
    });
  }

  void _previousCard() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + _remainingCards) % _remainingCards;
      _showFront = true;
    });
  }

  void _nextCard() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _remainingCards;
      _showFront = true;
    });
  }

  void _markAsKnown(note_model.FlashCard card) async {
    try {
      final noteDoc = await FirebaseFirestore.instance.collection('notes').doc(widget.noteId).get();
      final note = note_model.Note.fromFirestore(noteDoc);
      
      final updatedKnownCards = Map<String, bool>.from(note.knownFlashCards);
      updatedKnownCards[card.front] = true;
      
      final updatedNote = note.copyWith(
        knownFlashCards: updatedKnownCards,
        updatedAt: DateTime.now(),
      );
      
      await FirebaseFirestore.instance.collection('notes').doc(widget.noteId).update(updatedNote.toFirestore());
      
      setState(() {
        _remainingCards = note.flashCards.length - updatedKnownCards.values.where((known) => known).length;
        _currentFlashCards = note.flashCards
            .where((card) => !updatedKnownCards.containsKey(card.front) || !updatedKnownCards[card.front]!)
            .toList();
      });
      
      _nextCard();
    } catch (e) {
      print('Error marking card as known: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카드 상태 업데이트 중 오류가 발생했습니다: $e')),
      );
    }
  }

  note_model.FlashCard _getCardAtIndex(int index) {
    return _currentFlashCards[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            SvgPicture.asset('assets/icon/flashcard.svg'),
            const SizedBox(width: 8),
            const Text('Flashcards'),
          ],
        ),
        actions: [
          Text('${_currentIndex + 1}/$_remainingCards'),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Keep/Archive Counts
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                _CountButton(
                  count: _keepCount,
                  label: 'Keep',
                  color: ColorTokens.getColor('tertiary.400'),
                  onTap: () {
                    // TODO: Show kept flashcards
                  },
                ),
                const SizedBox(width: 16),
                _CountButton(
                  count: _archiveCount,
                  label: 'Archive',
                  color: ColorTokens.getColor('secondary.400'),
                  onTap: () {
                    // TODO: Show archived flashcards
                  },
                ),
              ],
            ),
          ),
          
          // Flashcard
          Expanded(
            child: PageView.builder(
              itemCount: _remainingCards,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _showFront = true;
                });
              },
              itemBuilder: (context, index) {
                final card = _getCardAtIndex(index);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: flash_card_widget.FlashCard(
                    front: card.front,
                    back: card.back,
                    pinyin: card.pinyin,
                    showFront: _showFront,
                    onFlip: _flipCard,
                    onKeep: () {
                      setState(() {
                        _keepCount++;
                        _remainingCards--;
                        _currentFlashCards.removeAt(index);
                      });
                    },
                    onArchive: () {
                      setState(() {
                        _archiveCount++;
                        _remainingCards--;
                        _currentFlashCards.removeAt(index);
                      });
                    },
                    flutterTts: _flutterTts,
                  ),
                );
              },
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

class _CountButton extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CountButton({
    required this.count,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                count.toString(),
                style: TypographyTokens.getStyle('heading.h3'),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TypographyTokens.getStyle('body.medium'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 