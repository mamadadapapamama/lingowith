import 'package:mlw/data/repositories/flash_card_repository.dart';
import 'package:mlw/data/models/flash_card.dart';
import 'package:mlw/services/translator.dart';
import 'package:mlw/services/pinyin_service.dart';

class FlashCardService {
  final FlashCardRepository _repository;
  final TranslatorService _translatorService;
  final PinyinService _pinyinService;
  
  FlashCardService({
    required FlashCardRepository repository,
    required TranslatorService translatorService,
    required PinyinService pinyinService,
  }) : 
    _repository = repository,
    _translatorService = translatorService,
    _pinyinService = pinyinService;
  
  // 노트 ID로 플래시카드 목록 조회
  Future<List<FlashCard>> getFlashCardsByNoteId(String noteId) async {
    return await _repository.getFlashCardsByNoteId(noteId);
  }
  
  // 사용자 ID로 플래시카드 목록 조회
  Future<List<FlashCard>> getFlashCardsByUserId(String userId) async {
    return await _repository.getFlashCardsByUserId(userId);
  }
  
  // 노트 ID로 플래시카드 개수 조회
  Future<int> getFlashCardCountByNoteId(String noteId) async {
    final cards = await _repository.getFlashCardsByNoteId(noteId);
    return cards.length;
  }
  
  // 플래시카드 생성
  Future<FlashCard> createFlashCard({
    required String userId,
    required String noteId,
    required String front,
    required String back,
    String? pinyin,
  }) async {
    final now = DateTime.now();
    
    // 핀인이 제공되지 않은 경우 자동 생성 (중국어인 경우)
    String finalPinyin = pinyin ?? '';
    if (pinyin == null && front.isNotEmpty) {
      try {
        finalPinyin = await _pinyinService.getPinyin(front);
      } catch (e) {
        print('핀인 생성 오류: $e');
      }
    }
    
    final flashCard = FlashCard(
      id: '',
      userId: userId,
      noteId: noteId,
      front: front,
      back: back,
      pinyin: finalPinyin,
      reviewCount: 0,
      known: false,
      createdAt: now,
      updatedAt: now,
      lastReviewedAt: null,
    );
    
    return await _repository.createFlashCard(flashCard);
  }
  
  // 텍스트에서 플래시카드 자동 생성
  Future<List<FlashCard>> createFlashCardsFromText({
    required String userId,
    required String noteId,
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    // 실제 구현은 필요할 때 추가
    return [];
  }
  
  // 플래시카드 업데이트
  Future<FlashCard> updateFlashCard(FlashCard flashCard) async {
    await _repository.updateFlashCard(flashCard);
    return flashCard;
  }
  
  // 플래시카드 삭제
  Future<void> deleteFlashCard(String flashCardId) async {
    await _repository.deleteFlashCard(flashCardId);
  }
  
  // 노트 ID로 플래시카드 삭제
  Future<void> deleteFlashCardsByNoteId(String noteId) async {
    await _repository.deleteFlashCardsByNoteId(noteId);
  }
  
  // 플래시카드 복습 상태 업데이트
  Future<FlashCard> updateReviewStatus(
    String flashCardId, 
    bool known,
  ) async {
    final flashCards = await _repository.getFlashCardsByUserId('');
    final flashCard = flashCards.firstWhere((card) => card.id == flashCardId);
    
    final updatedCard = flashCard.copyWith(
      reviewCount: flashCard.reviewCount + 1,
      known: known,
      lastReviewedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await _repository.updateFlashCard(updatedCard);
    return updatedCard;
  }
} 