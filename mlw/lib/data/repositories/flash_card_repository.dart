import 'package:mlw/data/datasources/remote/firebase_data_source.dart';
import 'package:mlw/data/models/flash_card.dart';

class FlashCardRepository {
  final FirebaseDataSource _remoteDataSource;
  static const String _flashCardsCollection = 'flashcards';

  FlashCardRepository({
    required FirebaseDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  // 노트 ID로 플래시카드 가져오기
  Future<List<FlashCard>> getFlashCardsByNoteId(String noteId) async {
    try {
      final snapshot = await _remoteDataSource.query(
        _flashCardsCollection,
        filters: [
          ['noteId', '==', noteId],
        ],
        orderBy: 'createdAt',
      );

      return snapshot.docs
          .map((doc) => FlashCard.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('플래시카드를 가져오는 중 오류가 발생했습니다: $e');
    }
  }

  // 사용자 ID로 플래시카드 가져오기
  Future<List<FlashCard>> getFlashCardsByUserId(String userId) async {
    try {
      final snapshot = await _remoteDataSource.query(
        _flashCardsCollection,
        filters: [
          ['userId', '==', userId],
        ],
        orderBy: 'updatedAt',
        descending: true,
      );

      return snapshot.docs
          .map((doc) => FlashCard.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('플래시카드를 가져오는 중 오류가 발생했습니다: $e');
    }
  }

  // 플래시카드 생성
  Future<FlashCard> createFlashCard(FlashCard flashCard) async {
    try {
      final docRef = _remoteDataSource.getCollection(_flashCardsCollection).doc();
      final newFlashCard = flashCard.copyWith(id: docRef.id);
      
      await _remoteDataSource.setDocument(
        _flashCardsCollection,
        docRef.id,
        newFlashCard.toMap(),
      );
      
      return newFlashCard;
    } catch (e) {
      throw Exception('플래시카드를 생성하는 중 오류가 발생했습니다: $e');
    }
  }

  // 플래시카드 업데이트
  Future<void> updateFlashCard(FlashCard flashCard) async {
    try {
      await _remoteDataSource.updateDocument(
        _flashCardsCollection,
        flashCard.id,
        flashCard.toMap(),
      );
    } catch (e) {
      throw Exception('플래시카드를 업데이트하는 중 오류가 발생했습니다: $e');
    }
  }

  // 플래시카드 삭제
  Future<void> deleteFlashCard(String flashCardId) async {
    try {
      await _remoteDataSource.deleteDocument(_flashCardsCollection, flashCardId);
    } catch (e) {
      throw Exception('플래시카드를 삭제하는 중 오류가 발생했습니다: $e');
    }
  }

  // 노트 ID로 플래시카드 삭제
  Future<void> deleteFlashCardsByNoteId(String noteId) async {
    try {
      final flashCards = await getFlashCardsByNoteId(noteId);
      
      for (final flashCard in flashCards) {
        await deleteFlashCard(flashCard.id);
      }
    } catch (e) {
      throw Exception('플래시카드를 삭제하는 중 오류가 발생했습니다: $e');
    }
  }
} 