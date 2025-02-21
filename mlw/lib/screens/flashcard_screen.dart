import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart';
import 'package:mlw/repositories/note_repository.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';

class FlashCardScreen extends StatefulWidget {
  final List<FlashCard> flashCards;
  final String noteId;

  const FlashCardScreen({
    super.key,
    required this.flashCards,
    required this.noteId,
  });

  @override
  State<FlashCardScreen> createState() => _FlashCardScreenState();
}

class _FlashCardScreenState extends State<FlashCardScreen> {
  late int _currentIndex;
  late bool _showFront;
  late NoteRepository _noteRepository;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    _showFront = true;
    _noteRepository = NoteRepository();
  }

  void _nextCard() async {
    if (_currentIndex < widget.flashCards.length - 1) {
      // Increment review count for current card
      final updatedCard = widget.flashCards[_currentIndex].incrementReviewCount();
      await _noteRepository.updateFlashCard(widget.noteId, _currentIndex, updatedCard);

      setState(() {
        _currentIndex++;
        _showFront = true;
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

  void _toggleCard() {
    setState(() {
      _showFront = !_showFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flashCard = widget.flashCards[_currentIndex];
    
    return Scaffold(
      backgroundColor: ColorTokens.getColor('surface.background'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.flashCards.length}',
          style: TypographyTokens.getStyle('titleMedium'),
        ),
      ),
      body: GestureDetector(
        onTap: _toggleCard,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _showFront ? flashCard.front : flashCard.back,
                  style: TypographyTokens.getStyle('bodyLarge'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: _currentIndex > 0 ? _previousCard : null,
                    ),
                    const SizedBox(width: 32),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: _currentIndex < widget.flashCards.length - 1 ? _nextCard : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
