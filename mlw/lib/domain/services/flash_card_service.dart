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
    required String pageId,
    required String front,
    required String back,
    String pinyin = '',
    String context = '',
  }) async {
    final now = DateTime.now();
    
    // 핀인이 제공되지 않은 경우 자동 생성 (중국어인 경우)
    String finalPinyin = pinyin;
    if (pinyin.isEmpty && _isChinese(front)) {
      finalPinyin = await _pinyinService.convertToPinyin(front);
    }
    
    final flashCard = FlashCard(
      id: '',
      userId: userId,
      noteId: noteId,
      pageId: pageId,
      front: front,
      back: back,
      pinyin: finalPinyin,
      context: context,
      known: false,
      createdAt: now,
      updatedAt: now,
    );
    
    return await _repository.createFlashCard(flashCard);
  }
  
  // 텍스트에서 플래시카드 자동 생성
  Future<List<FlashCard>> createFlashCardsFromText({
    required String userId,
    required String noteId,
    required String pageId,
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    // 텍스트를 단어 또는 구문으로 분리
    final words = _extractWords(text, sourceLanguage);
    final flashCards = <FlashCard>[];
    
    for (final word in words) {
      if (word.trim().isEmpty) continue;
      
      try {
        // 단어 번역
        final translation = await _translatorService.translate(
          word,
          sourceLanguage,
          targetLanguage,
        );
        
        // 핀인 생성 (중국어인 경우)
        String pinyin = '';
        if (sourceLanguage.toLowerCase() == 'zh-cn' || 
            sourceLanguage.toLowerCase() == 'chinese') {
          pinyin = await _pinyinService.convertToPinyin(word);
        }
        
        // 플래시카드 생성
        final flashCard = await createFlashCard(
          userId: userId,
          noteId: noteId,
          pageId: pageId,
          front: word,
          back: translation,
          pinyin: pinyin,
          context: _extractContext(text, word),
        );
        
        flashCards.add(flashCard);
      } catch (e) {
        print('단어 처리 중 오류 발생: $e');
        // 오류가 발생해도 계속 진행
      }
    }
    
    return flashCards;
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
  
  // 중국어 텍스트인지 확인
  bool _isChinese(String text) {
    // 간체 중국어 유니코드 범위: 0x4E00-0x9FFF
    final chineseRegex = RegExp(r'[\u4e00-\u9fff]');
    return chineseRegex.hasMatch(text);
  }
  
  // 텍스트에서 단어 추출
  List<String> _extractWords(String text, String language) {
    if (language.toLowerCase() == 'zh-cn' || 
        language.toLowerCase() == 'chinese') {
      // 중국어는 각 문자를 개별 단어로 취급
      return _extractChineseWords(text);
    } else {
      // 다른 언어는 공백으로 분리
      return text.split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .toList();
    }
  }
  
  // 중국어 텍스트에서 단어 추출
  List<String> _extractChineseWords(String text) {
    // 중국어 문자 추출 (한자만)
    final chineseRegex = RegExp(r'[\u4e00-\u9fff]+');
    final matches = chineseRegex.allMatches(text);
    
    final words = <String>[];
    for (final match in matches) {
      final word = match.group(0)!;
      // 각 문자를 개별 단어로 추가
      for (int i = 0; i < word.length; i++) {
        words.add(word[i]);
      }
    }
    
    return words;
  }
  
  // 단어의 문맥 추출
  String _extractContext(String text, String word) {
    final wordIndex = text.indexOf(word);
    if (wordIndex == -1) return '';
    
    // 단어 앞뒤로 최대 20자까지 문맥으로 추출
    final startIndex = (wordIndex - 20).clamp(0, text.length);
    final endIndex = (wordIndex + word.length + 20).clamp(0, text.length);
    
    return text.substring(startIndex, endIndex);
  }
} 