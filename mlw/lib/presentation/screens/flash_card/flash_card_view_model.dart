import 'package:flutter/foundation.dart';
import 'package:mlw/data/models/flash_card.dart';
import 'package:mlw/domain/services/flash_card_service.dart';
import 'package:mlw/domain/services/tts_service.dart';

class FlashCardViewModel with ChangeNotifier {
  final FlashCardService _flashCardService;
  final TtsService _ttsService;
  
  List<FlashCard> _flashCards = [];
  bool _isLoading = false;
  String _error = '';
  int _currentIndex = 0;
  bool _showAnswer = false;
  
  FlashCardViewModel({
    required FlashCardService flashCardService,
    required TtsService ttsService,
  }) : 
    _flashCardService = flashCardService,
    _ttsService = ttsService;
  
  List<FlashCard> get flashCards => _flashCards;
  bool get isLoading => _isLoading;
  String get error => _error;
  int get currentIndex => _currentIndex;
  bool get showAnswer => _showAnswer;
  FlashCard? get currentCard => _flashCards.isNotEmpty && _currentIndex < _flashCards.length 
      ? _flashCards[_currentIndex] 
      : null;
  bool get hasNext => _currentIndex < _flashCards.length - 1;
  bool get hasPrevious => _currentIndex > 0;
  
  // 노트 ID로 플래시카드 로드
  Future<void> loadFlashCards(String noteId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      _flashCards = await _flashCardService.getFlashCardsByNoteId(noteId);
      _currentIndex = 0;
      _showAnswer = false;
    } catch (e) {
      _error = '플래시카드를 불러오는 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 다음 카드로 이동
  void nextCard() {
    if (hasNext) {
      _currentIndex++;
      _showAnswer = false;
      notifyListeners();
    }
  }
  
  // 이전 카드로 이동
  void previousCard() {
    if (hasPrevious) {
      _currentIndex--;
      _showAnswer = false;
      notifyListeners();
    }
  }
  
  // 답변 표시 토글
  void toggleShowAnswer() {
    _showAnswer = !_showAnswer;
    notifyListeners();
  }
  
  // 카드 학습 상태 업데이트
  Future<void> updateCardStatus(bool known) async {
    if (currentCard == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final updatedCard = currentCard!.copyWith(
        reviewCount: currentCard!.reviewCount + 1,
        lastReviewedAt: DateTime.now(),
        known: known,
      );
      
      await _flashCardService.updateFlashCard(updatedCard);
      
      // 현재 카드 업데이트
      _flashCards[_currentIndex] = updatedCard;
      
      // 자동으로 다음 카드로 이동
      if (hasNext) {
        nextCard();
      }
    } catch (e) {
      _error = '카드 상태 업데이트 중 오류가 발생했습니다: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // 노트 ID로 플래시카드 가져오기
  Future<List<FlashCard>> getFlashCardsByNoteId(String noteId) async {
    return await _flashCardService.getFlashCardsByNoteId(noteId);
  }
  
  // 플래시카드 복습 상태 업데이트
  Future<FlashCard> updateReviewStatus(String flashCardId, bool known) async {
    return await _flashCardService.updateReviewStatus(flashCardId, known);
  }
} 