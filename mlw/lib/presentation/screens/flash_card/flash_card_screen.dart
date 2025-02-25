import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mlw/core/di/service_locator.dart';
import 'package:mlw/presentation/screens/flash_card/flash_card_view_model.dart';
import 'package:mlw/data/models/flash_card.dart';
import 'package:mlw/presentation/widgets/flash_card_widget.dart';

class FlashCardScreen extends StatefulWidget {
  final String noteId;
  final String userId;
  
  const FlashCardScreen({
    Key? key,
    required this.noteId,
    required this.userId,
  }) : super(key: key);

  @override
  State<FlashCardScreen> createState() => _FlashCardScreenState();
}

class _FlashCardScreenState extends State<FlashCardScreen> {
  late FlashCardViewModel _viewModel;
  List<FlashCard> _flashCards = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _viewModel = serviceLocator.getFactory<FlashCardViewModel>();
    _loadFlashCards();
  }
  
  Future<void> _loadFlashCards() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final flashCards = await _viewModel.getFlashCardsByNoteId(widget.noteId);
      setState(() {
        _flashCards = flashCards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('플래시카드를 불러오는 중 오류가 발생했습니다: $e')),
      );
    }
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
  
  void _markAsKnown() async {
    if (_flashCards.isEmpty) return;
    
    final currentCard = _flashCards[_currentIndex];
    await _viewModel.updateReviewStatus(currentCard.id, true);
    
    setState(() {
      _flashCards[_currentIndex] = currentCard.copyWith(known: true);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('알고 있는 단어로 표시했습니다')),
    );
  }
  
  void _markAsUnknown() async {
    if (_flashCards.isEmpty) return;
    
    final currentCard = _flashCards[_currentIndex];
    await _viewModel.updateReviewStatus(currentCard.id, false);
    
    setState(() {
      _flashCards[_currentIndex] = currentCard.copyWith(known: false);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('모르는 단어로 표시했습니다')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('플래시카드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFlashCards,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _flashCards.isEmpty
              ? const Center(child: Text('플래시카드가 없습니다'))
              : Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: FlashCardWidget(
                          front: _flashCards[_currentIndex].front,
                          back: _flashCards[_currentIndex].back,
                          pinyin: _flashCards[_currentIndex].pinyin,
                          known: _flashCards[_currentIndex].known,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _previousCard,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('이전'),
                          ),
                          Text('${_currentIndex + 1} / ${_flashCards.length}'),
                          ElevatedButton.icon(
                            onPressed: _nextCard,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('다음'),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _markAsUnknown,
                            icon: const Icon(Icons.close),
                            label: const Text('모름'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _markAsKnown,
                            icon: const Icon(Icons.check),
                            label: const Text('알고 있음'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
} 