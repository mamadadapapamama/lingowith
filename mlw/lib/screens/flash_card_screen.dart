import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mlw/widgets/flash_card.dart' as flash_card_widget;
import 'package:flutter_tts/flutter_tts.dart';

class FlashCardScreen extends StatefulWidget {
  final List<note_model.FlashCard> flashCards;
  final String title;

  const FlashCardScreen({
    Key? key,
    required this.flashCards,
    required this.title,
  }) : super(key: key);

  @override
  State<FlashCardScreen> createState() => _FlashCardScreenState();
}

class _FlashCardScreenState extends State<FlashCardScreen> {
  bool _showFront = true;
  int _currentIndex = 0;
  final FlutterTts _flutterTts = FlutterTts();
  late List<note_model.FlashCard> _remainingCards;
  int _keepCount = 0;
  int _archiveCount = 0;

  @override
  void initState() {
    super.initState();
    _remainingCards = List.from(widget.flashCards);
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
      if (_currentIndex < _remainingCards.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
    });
  }

  void _markAsDone() {
    setState(() {
      _remainingCards.removeAt(_currentIndex);
      if (_currentIndex >= _remainingCards.length) {
        _currentIndex = 0;
      }
      _showFront = true;
    });
  }

  void _previousCard() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + _remainingCards.length) % _remainingCards.length;
      _showFront = true;
    });
  }

  void _nextCard() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _remainingCards.length;
      _showFront = true;
    });
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
            Text('Flashcards'),
          ],
        ),
        actions: [
          Text('${_currentIndex + 1}/${_remainingCards.length}'),
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
              itemCount: _remainingCards.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _showFront = true;
                });
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: flash_card_widget.FlashCard(
                    front: _remainingCards[index].front,
                    back: _remainingCards[index].back,
                    pinyin: null,
                    showFront: _showFront,
                    onFlip: _flipCard,
                    onKeep: () {
                      setState(() {
                        _keepCount++;
                        _remainingCards.removeAt(index);
                      });
                    },
                    onArchive: () {
                      setState(() {
                        _archiveCount++;
                        _remainingCards.removeAt(index);
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