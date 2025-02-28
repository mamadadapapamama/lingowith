import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/models/note.dart';

class NoteRepository {
  final FirebaseFirestore _firestore;
  
  // 캐시 관리 개선
  final Map<String, Note> _cache = {};
  bool _cacheEnabled = true;
  
  NoteRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  // 캐시 활성화/비활성화 메서드
  void enableCache() {
    _cacheEnabled = true;
  }
  
  void disableCache() {
    _cacheEnabled = false;
  }
  
  // 캐시 초기화
  void clearCache() {
    _cache.clear();
    print('노트 캐시 초기화됨');
  }
  
  // 캐시 크기 반환 메서드 추가
  int getCacheSize() {
    return _cache.length;
  }
  
  // 캐시에 노트 추가 메서드
  void updateCache(Note note) {
    if (_cacheEnabled) {
      _cache[note.id] = note;
      print('캐시 업데이트: ${note.id}, 제목: ${note.title}');
    }
  }
  
  // 캐시 내용 출력
  void printCacheContents() {
    print('===== 캐시 내용 =====');
    _cache.forEach((id, note) {
      print('캐시된 노트: $id, 제목: ${note.title}');
    });
    print('=====================');
  }
  
  // 노트 생성 메서드 개선
  Future<Note> createNote(Note note) async {
    try {
      print('노트 생성 시작: ${note.title}');
      final docRef = await _firestore.collection('notes').add(note.toFirestore());
      final doc = await docRef.get();
      final createdNote = Note.fromFirestore(doc);
      
      // 캐시에 저장
      if (_cacheEnabled) {
        _cache[createdNote.id] = createdNote;
      }
      
      print('노트 생성 완료: ${createdNote.id}, 제목: ${createdNote.title}');
      return createdNote;
    } catch (e) {
      print('노트 생성 오류: $e');
      rethrow;
    }
  }
  
  // 노트 업데이트 메서드 개선
  Future<void> updateNote(Note note) async {
    try {
      print('노트 업데이트 시작: ${note.id}, 제목: ${note.title}');
      await _firestore.collection('notes').doc(note.id).update(note.toFirestore());
      
      // 캐시 업데이트
      if (_cacheEnabled) {
        _cache[note.id] = note;
      }
      
      print('노트 업데이트 완료: ${note.id}');
    } catch (e) {
      print('노트 업데이트 오류: $e');
      rethrow;
    }
  }
  
  // 노트 가져오기 메서드 개선
  Future<Note> getNote(String noteId) async {
    try {
      print('노트 가져오기 시작: $noteId');
      
      // 캐시에서 확인
      if (_cacheEnabled && _cache.containsKey(noteId)) {
        print('노트 캐시에서 로드: $noteId');
        return _cache[noteId]!;
      }
      
      // Firestore에서 가져오기
      final doc = await _firestore.collection('notes').doc(noteId).get();
      if (!doc.exists) {
        throw Exception('노트를 찾을 수 없음: $noteId');
      }
      
      final note = Note.fromFirestore(doc);
      
      // 캐시에 저장
      if (_cacheEnabled) {
        _cache[noteId] = note;
      }
      
      print('노트 Firestore에서 로드: $noteId, 제목: ${note.title}');
      return note;
    } catch (e) {
      print('노트 가져오기 오류: $e');
      rethrow;
    }
  }
  
  // 노트 목록 스트림 개선
  Stream<List<Note>> getNotes(String spaceId) {
    print('노트 스트림 구독 시작: spaceId=$spaceId');
    
    return _firestore
        .collection('notes')
        .where('spaceId', isEqualTo: spaceId)
        .snapshots()
        .map((snapshot) {
          print('Firestore 쿼리 결과: ${snapshot.docs.length}개 노트');
          
          final notes = snapshot.docs.map((doc) {
            final note = Note.fromFirestore(doc);
            
            // 캐시 업데이트
            if (_cacheEnabled) {
              _cache[note.id] = note;
            }
            
            return note;
          }).where((note) => note.isDeleted != true).toList();
          
          // 클라이언트 측에서 정렬
          notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          print('필터링 후 반환할 노트: ${notes.length}개');
          return notes;
        });
  }

  Future<List<Note>> getNotesList(String userId, String spaceId) async {
    print("Repository: Getting notes for userId: $userId, spaceId: $spaceId");
    
    try {
      final snapshot = await _firestore
          .collection('notes')
          .where('userId', isEqualTo: userId)
          .where('spaceId', isEqualTo: spaceId)
          .get();
      
      print("Repository: Found ${snapshot.docs.length} documents");
      
      final notes = snapshot.docs.map((doc) {
        try {
          final note = Note.fromFirestore(doc);
          print("Successfully parsed note: ${note.id}, title: ${note.title}");
          return note;
        } catch (e) {
          print("Error parsing note ${doc.id}: $e");
          return null;
        }
      }).where((note) => note != null).cast<Note>().toList();
      
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print("Repository: Returning ${notes.length} valid notes");
      return notes;
    } catch (e) {
      print("Repository error: $e");
      rethrow;
    }
  }

  Future<void> deleteNote(String id) async {
    await _firestore.collection('notes').doc(id).delete();
  }

  Future<void> updateNoteTitle(String id, String title) async {
    await _firestore.collection('notes').doc(id).update({
      'title': title,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateHighlightedTexts(String id, Set<String> highlightedTexts) async {
    await _firestore.collection('notes').doc(id).update({
      'highlightedTexts': highlightedTexts.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFlashCards(String id, List<FlashCard> flashCards) async {
    await _firestore.collection('notes').doc(id).update({
      'flashCards': flashCards.map((card) => card.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateKnownFlashCards(String id, Map<String, bool> knownFlashCards) async {
    await _firestore.collection('notes').doc(id).update({
      'knownFlashCards': knownFlashCards,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFlashCard(String noteId, int index, FlashCard updatedCard) async {
    try {
      final note = await getNote(noteId);
      final updatedFlashCards = List<FlashCard>.from(note.flashCards);
      if (index < updatedFlashCards.length) {
        updatedFlashCards[index] = updatedCard;
        
        final updatedNote = note.copyWith(
          flashCards: updatedFlashCards,
          updatedAt: DateTime.now(),
        );
        
        await updateNote(updatedNote);
      }
    } catch (e) {
      print('Error updating flash card: $e');
      rethrow;
    }
  }

  // 노트 스페이스의 모든 노트 관찰하기 (getNotes와 동일한 기능)
  Stream<List<Note>> watchNotes(String spaceId) {
    return getNotes(spaceId);
  }

  // 모든 노트 가져오기 (필터링 없이)
  Future<void> _loadAllNotes() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('notes').get();
      print('Firebase에 총 ${snapshot.docs.length}개의 노트가 있습니다.');
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('노트 ID: ${doc.id}, 제목: ${data['title']}, 사용자: ${data['userId']}, 스페이스: ${data['spaceId']}');
      }
    } catch (e) {
      print('모든 노트 로드 오류: $e');
    }
  }
} 