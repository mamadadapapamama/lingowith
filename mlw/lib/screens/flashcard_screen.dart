import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart';
import 'package:mlw/repositories/note_repository.dart';

class FlashCardScreen extends StatefulWidget {
  final List<FlashCard> flashCards;

  const FlashCardScreen({
    Key? key,
    required this.flashCards,
  }) : super(key: key);

  @override
  State<FlashCardScreen> createState() => _FlashCardScreenState();
}

class _FlashCardScreenState extends State<FlashCardScreen> {
  int _currentIndex = 0;
  bool _showFront = true;
  final NoteRepository _repository = NoteRepository();

  Future<void> _nextCard() async {
    if (_currentIndex < widget.flashCards.length - 1) {
      // 현재 카드의 리뷰 카운트 증가
      final currentCard = widget.flashCards[_currentIndex];
      final updatedCard = currentCard.incrementReviewCount();
      
      // Firestore 업데이트
      try {
        final note = await _repository.getNote(currentCard.noteId);
        if (note != null) {
          final updatedFlashCards = List<FlashCard>.from(note.flashCards);
          updatedFlashCards[_currentIndex] = updatedCard;
          
          final updatedNote = note.copyWith(
            id: note.id,
            flashCards: updatedFlashCards,
            updatedAt: DateTime.now(),
          );
          
          await _repository.updateNote(updatedNote);
        }
      } catch (e) {
        print('Error updating review count: $e');
      }

      setState(() {
        _currentIndex++;
        _showFront = true;
      });
    }
  }

  void _previousCard() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
        _showFront = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('플래시카드 ${_currentIndex + 1}/${widget.flashCards.length}'),
      ),
      body: GestureDetector(
        onTap: () => setState(() => _showFront = !_showFront),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _showFront
                      ? widget.flashCards[_currentIndex].text
                      : widget.flashCards[_currentIndex].translation ?? '',
                  style: const TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _previousCard,
            ),
            Text('${_currentIndex + 1}/${widget.flashCards.length}'),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _nextCard,
            ),
          ],
        ),
      ),
    );
  }
}
