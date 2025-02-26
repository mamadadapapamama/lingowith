import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/data/datasources/remote/firebase_data_source.dart';
import 'package:mlw/data/models/flash_card.dart';

class FlashCardRepository {
  final FirebaseDataSource remoteDataSource;
  static const String _collection = 'flash_cards';
  
  FlashCardRepository({required this.remoteDataSource});
  
  // 플래시카드 생성
  Future<FlashCard> createFlashCard(FlashCard flashCard) async {
    try {
      final docRef = await remoteDataSource.addDocument(_collection, flashCard.toMap());
      return flashCard.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('플래시카드를 생성하는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 노트별 플래시카드 목록 조회
  Future<List<FlashCard>> getFlashCardsByNoteId(String noteId) async {
    try {
      final snapshot = await remoteDataSource.getDocuments(
        _collection,
        [
          ['noteId', '==', noteId],
        ],
      );
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return FlashCard.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      throw Exception('노트의 플래시카드 목록을 가져오는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 페이지별 플래시카드 목록 조회
  Future<List<FlashCard>> getFlashCardsByPageId(String pageId) async {
    try {
      final snapshot = await remoteDataSource.getDocuments(
        _collection,
        [
          ['pageId', '==', pageId],
        ],
      );
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return FlashCard.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      throw Exception('페이지의 플래시카드 목록을 가져오는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 사용자별 플래시카드 목록 조회
  Future<List<FlashCard>> getFlashCardsByUserId(String userId) async {
    try {
      final snapshot = await remoteDataSource.getDocuments(
        _collection,
        [
          ['userId', '==', userId],
        ],
      );
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return FlashCard.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      throw Exception('사용자의 플래시카드 목록을 가져오는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 플래시카드 상세 조회
  Future<FlashCard?> getFlashCardById(String id) async {
    try {
      final doc = await remoteDataSource.getDocument(_collection, id);
      if (!doc.exists) {
        return null;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      return FlashCard.fromMap({...data, 'id': doc.id});
    } catch (e) {
      throw Exception('플래시카드를 가져오는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 플래시카드 업데이트
  Future<void> updateFlashCard(FlashCard flashCard) async {
    try {
      await remoteDataSource.updateDocument(
        _collection,
        flashCard.id,
        flashCard.toMap(),
      );
    } catch (e) {
      throw Exception('플래시카드를 업데이트하는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 플래시카드 삭제
  Future<void> deleteFlashCard(String id) async {
    try {
      await remoteDataSource.deleteDocument(_collection, id);
    } catch (e) {
      throw Exception('플래시카드를 삭제하는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 플래시카드 학습 상태 업데이트
  Future<void> updateFlashCardKnownStatus(String id, bool known) async {
    try {
      final flashCard = await getFlashCardById(id);
      if (flashCard == null) {
        throw Exception('플래시카드를 찾을 수 없습니다');
      }
      
      await updateFlashCard(flashCard.copyWith(
        known: known,
        updatedAt: DateTime.now(),
      ));
    } catch (e) {
      throw Exception('플래시카드 학습 상태를 업데이트하는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 노트별 플래시카드 삭제
  Future<void> deleteFlashCardsByNoteId(String noteId) async {
    try {
      final cards = await getFlashCardsByNoteId(noteId);
      
      // 배치 작업으로 모든 카드 삭제
      await remoteDataSource.runBatch((batch) {
        for (final card in cards) {
          batch.delete(
            remoteDataSource.getCollection(_collection).doc(card.id)
          );
        }
      });
    } catch (e) {
      throw Exception('노트의 플래시카드를 삭제하는 중 오류가 발생했습니다: $e');
    }
  }
} 