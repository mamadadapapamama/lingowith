import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/models/note.dart';
import 'package:mlw/models/note_space.dart';

class NoteRepository {
  final FirebaseFirestore _firestore;
  
  // 캐시 관리 개선
  final Map<String, Note> _cache = {};
  bool _cacheEnabled = true;
  
  NoteRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  // 컬렉션 참조를 getter로 만들어 재사용
  CollectionReference<Map<String, dynamic>> get _notes => 
      _firestore.collection('notes');
  
  CollectionReference<Map<String, dynamic>> get _spaces => 
      _firestore.collection('note_spaces');
  
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
      final docRef = await _notes.add(note.toFirestore());
      
      // 생성된 노트 가져오기
      final doc = await docRef.get();
      final createdNote = Note.fromFirestore(doc);
      
      // 캐시에 저장
      if (_cacheEnabled) {
        _cache[createdNote.id] = createdNote;
      }
      
      print('노트 생성 완료: ${createdNote.id}');
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
      await _notes.doc(note.id).update(note.toFirestore());
      
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
      final doc = await _notes.doc(noteId).get();
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
    
    return _notes
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
      final snapshot = await _notes
          .where('userId', isEqualTo: userId)
          .where('spaceId', isEqualTo: spaceId)
          .get();
      
      print("Repository: Found ${snapshot.docs.length} documents");
      
      final notes = snapshot.docs.map((doc) {
        try {
          final note = Note.fromFirestore(doc);
          
          // 캐시 업데이트
          if (_cacheEnabled) {
            _cache[note.id] = note;
          }
          
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
    try {
      print('노트 삭제 시작: $id');
      await _notes.doc(id).delete();
      
      // 캐시에서도 삭제
      if (_cacheEnabled) {
        _cache.remove(id);
      }
      
      print('노트 삭제 완료: $id');
    } catch (e) {
      print('노트 삭제 오류: $e');
      rethrow;
    }
  }

  Future<void> updateNoteTitle(String id, String title) async {
    try {
      print('노트 제목 업데이트 시작: $id, 새 제목: $title');
      await _notes.doc(id).update({
        'title': title,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // 캐시 업데이트
      if (_cacheEnabled && _cache.containsKey(id)) {
        final note = _cache[id]!;
        _cache[id] = note.copyWith(
          title: title,
          updatedAt: DateTime.now(),
        );
      }
      
      print('노트 제목 업데이트 완료: $id');
    } catch (e) {
      print('노트 제목 업데이트 오류: $e');
      rethrow;
    }
  }

  Future<void> updateHighlightedTexts(String id, Set<String> highlightedTexts) async {
    try {
      print('하이라이트된 텍스트 업데이트 시작: $id');
      await _notes.doc(id).update({
        'highlightedTexts': highlightedTexts.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('하이라이트된 텍스트 업데이트 완료: $id');
    } catch (e) {
      print('하이라이트된 텍스트 업데이트 오류: $e');
      rethrow;
    }
  }

  Future<void> updateFlashCards(String id, List<FlashCard> flashCards) async {
    try {
      print('플래시카드 업데이트 시작: $id, 카드 수: ${flashCards.length}');
      await _notes.doc(id).update({
        'flashCards': flashCards.map((card) => card.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('플래시카드 업데이트 완료: $id');
    } catch (e) {
      print('플래시카드 업데이트 오류: $e');
      rethrow;
    }
  }

  Future<void> updateKnownFlashCards(String id, Map<String, bool> knownFlashCards) async {
    try {
      print('알고 있는 플래시카드 업데이트 시작: $id');
      await _notes.doc(id).update({
        'knownFlashCards': knownFlashCards,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('알고 있는 플래시카드 업데이트 완료: $id');
    } catch (e) {
      print('알고 있는 플래시카드 업데이트 오류: $e');
      rethrow;
    }
  }

  Future<void> updateFlashCard(String noteId, int index, FlashCard updatedCard) async {
    try {
      print('개별 플래시카드 업데이트 시작: $noteId, 인덱스: $index');
      final note = await getNote(noteId);
      final updatedFlashCards = List<FlashCard>.from(note.flashCards);
      
      if (index < updatedFlashCards.length) {
        updatedFlashCards[index] = updatedCard;
        
        final updatedNote = note.copyWith(
          flashCards: updatedFlashCards,
          updatedAt: DateTime.now(),
        );
        
        await updateNote(updatedNote);
        print('개별 플래시카드 업데이트 완료: $noteId, 인덱스: $index');
      } else {
        print('플래시카드 인덱스 범위 초과: $index, 최대: ${updatedFlashCards.length - 1}');
      }
    } catch (e) {
      print('개별 플래시카드 업데이트 오류: $e');
      rethrow;
    }
  }

  // 노트 스페이스 관련 메서드
  Stream<List<NoteSpace>> watchNoteSpaces(String userId) {
    print('노트 스페이스 스트림 구독 시작: userId=$userId');
    
    return _spaces
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Firestore 쿼리 결과: ${snapshot.docs.length}개 노트 스페이스');
          
          final spaces = snapshot.docs
              .map((doc) => NoteSpace.fromFirestore(doc))
              .toList();
          
          print('반환할 노트 스페이스: ${spaces.length}개');
          return spaces;
        });
  }

  Future<List<NoteSpace>> getNoteSpaces(String userId) async {
    try {
      print('노트 스페이스 가져오기 시작: $userId');
      final snapshot = await _spaces
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      print('노트 스페이스 쿼리 결과: ${snapshot.docs.length}개');
      
      final spaces = snapshot.docs
          .map((doc) => NoteSpace.fromFirestore(doc))
          .toList();
      
      print('반환할 노트 스페이스: ${spaces.length}개');
      return spaces;
    } catch (e) {
      print('노트 스페이스 가져오기 오류: $e');
      return [];
    }
  }

  Future<NoteSpace> createNoteSpace(NoteSpace noteSpace) async {
    try {
      print('노트 스페이스 생성 시작: ${noteSpace.name}');
      final docRef = await _spaces.add(noteSpace.toFirestore());
      
      // 생성된 노트 스페이스 가져오기
      final doc = await docRef.get();
      final createdSpace = NoteSpace.fromFirestore(doc);
      
      print('노트 스페이스 생성 완료: ${createdSpace.id}');
      return createdSpace;
    } catch (e) {
      print('노트 스페이스 생성 오류: $e');
      rethrow;
    }
  }

  Future<void> updateNoteSpace(NoteSpace noteSpace) async {
    try {
      print('노트 스페이스 업데이트 시작: ${noteSpace.id}, 이름: ${noteSpace.name}');
      await _spaces.doc(noteSpace.id).update(noteSpace.toFirestore());
      
      print('노트 스페이스 업데이트 완료: ${noteSpace.id}');
    } catch (e) {
      print('노트 스페이스 업데이트 오류: $e');
      rethrow;
    }
  }

  Future<void> deleteNoteSpace(String id) async {
    try {
      print('노트 스페이스 삭제 시작: $id');
      await _spaces.doc(id).delete();
      
      print('노트 스페이스 삭제 완료: $id');
    } catch (e) {
      print('노트 스페이스 삭제 오류: $e');
      rethrow;
    }
  }

  Future<void> deleteAllSpaceNotes(String spaceId) async {
    try {
      print('스페이스의 모든 노트 삭제 시작: $spaceId');
      final batch = _firestore.batch();
      final notesSnapshot = await _notes
          .where('spaceId', isEqualTo: spaceId)
          .get();
      
      print('삭제할 노트 수: ${notesSnapshot.docs.length}');
      
      for (var doc in notesSnapshot.docs) {
        batch.delete(doc.reference);
        
        // 캐시에서도 삭제
        if (_cacheEnabled) {
          _cache.remove(doc.id);
        }
      }
      
      await batch.commit();
      print('스페이스의 모든 노트 삭제 완료: $spaceId');
    } catch (e) {
      print('스페이스의 모든 노트 삭제 오류: $e');
      rethrow;
    }
  }

  // 특정 사용자의 모든 노트 삭제
  Future<void> deleteAllUserNotes(String userId) async {
    try {
      print('사용자의 모든 노트 삭제 시작: $userId');
      final batch = _firestore.batch();
      final snapshots = await _notes.where('userId', isEqualTo: userId).get();
      
      print('삭제할 노트 수: ${snapshots.docs.length}');
      
      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
        
        // 캐시에서도 삭제
        if (_cacheEnabled) {
          _cache.remove(doc.id);
        }
      }
      
      await batch.commit();
      print('사용자의 모든 노트 삭제 완료: $userId');
    } catch (e) {
      print('사용자의 모든 노트 삭제 오류: $e');
      rethrow;
    }
  }

  Future<void> ensureDataConsistency(String noteId) async {
    try {
      print('데이터 일관성 확인 시작: $noteId');
      final docSnapshot = await _notes.doc(noteId).get();
      
      if (docSnapshot.exists) {
        final note = Note.fromFirestore(docSnapshot);
        
        // 플래시카드와 knownFlashCards 간의 일관성 확인
        final updatedFlashCards = note.flashCards
            .where((card) => !note.knownFlashCards.contains(card.front))
            .toList();
        
        // 데이터가 일관되지 않으면 업데이트
        if (updatedFlashCards.length != note.flashCards.length) {
          print('데이터 불일치 발견, 업데이트 중...');
          await _notes.doc(noteId).update({
            'flashCards': updatedFlashCards.map((card) => card.toJson()).toList(),
          });
          
          // 캐시 업데이트
          if (_cacheEnabled && _cache.containsKey(noteId)) {
            final updatedNote = note.copyWith(flashCards: updatedFlashCards);
            _cache[noteId] = updatedNote;
          }
          
          print('데이터 일관성 복구 완료');
        } else {
          print('데이터 일관성 확인 완료: 문제 없음');
        }
      } else {
        print('노트를 찾을 수 없음: $noteId');
      }
    } catch (e) {
      print('데이터 일관성 확인 오류: $e');
    }
  }

  // 캐시 무효화
  void invalidateCache(String noteId) {
    if (_cacheEnabled && _cache.containsKey(noteId)) {
      _cache.remove(noteId);
      print('캐시 무효화: $noteId');
    }
  }

  Future<List<Note>> getNotesSafely(String spaceId) async {
    try {
      print('안전하게 노트 목록 가져오기 시작: $spaceId');
      final snapshot = await _notes
          .where('spaceId', isEqualTo: spaceId)
          .get();
      
      print('쿼리 결과: ${snapshot.docs.length}개 노트');
      
      final notes = snapshot.docs.map((doc) {
        final note = Note.fromFirestore(doc);
        
        // 캐시 업데이트
        if (_cacheEnabled) {
          _cache[note.id] = note;
        }
        
        return note;
      }).toList();
      
      // 삭제되지 않은 노트만 필터링
      final filteredNotes = notes.where((note) => note.isDeleted != true).toList();
      
      // 생성일 기준 내림차순 정렬
      filteredNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('필터링 후 반환할 노트: ${filteredNotes.length}개');
      return filteredNotes;
    } catch (e) {
      print('안전하게 노트 목록 가져오기 오류: $e');
      // 오류 발생 시 캐시된 데이터 반환 또는 빈 목록 반환
      return [];
    }
  }
} 