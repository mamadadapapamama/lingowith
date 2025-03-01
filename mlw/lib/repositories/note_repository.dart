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
  
  // 노트 생성
  Future<Note> createNote(Note note) async {
    try {
      print('노트 생성 시작: ${note.title}');
      final docRef = await _notes.add(note.toFirestore());
      
      // ID가 포함된 완전한 노트 객체 생성
      final createdNote = Note(
        id: docRef.id,
        spaceId: note.spaceId,
        userId: note.userId,
        title: note.title,
        content: note.content,
        imageUrl: note.imageUrl,
        extractedText: note.extractedText,
        translatedText: note.translatedText,
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
        isDeleted: note.isDeleted,
        flashCards: note.flashCards,
        knownFlashCards: note.knownFlashCards,
        flashcardCount: note.flashcardCount,
        reviewCount: note.reviewCount,
      );
      
      // 캐시 업데이트
      if (_cacheEnabled) {
        _cache[docRef.id] = createdNote;
      }
      
      print('노트 생성 완료: ${docRef.id}');
      return createdNote;
    } catch (e) {
      print('노트 생성 오류: $e');
      throw Exception('노트 생성 중 오류가 발생했습니다: $e');
    }
  }
  
  // 노트 가져오기
  Future<Note> getNote(String noteId) async {
    try {
      print('노트 가져오기 시작: $noteId');
      
      // 캐시 확인
      if (_cacheEnabled && _cache.containsKey(noteId)) {
        print('캐시에서 노트 반환: $noteId');
        return _cache[noteId]!;
      }
      
      final docSnapshot = await _notes.doc(noteId).get();
      
      if (!docSnapshot.exists) {
        throw Exception('노트를 찾을 수 없습니다: $noteId');
      }
      
      final note = Note.fromFirestore(docSnapshot);
      
      // 캐시 업데이트
      if (_cacheEnabled) {
        _cache[noteId] = note;
      }
      
      print('노트 가져오기 완료: $noteId');
      return note;
    } catch (e) {
      print('노트 가져오기 오류: $e');
      throw Exception('노트를 가져오는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 노트 업데이트
  Future<void> updateNote(Note note) async {
    try {
      print('노트 업데이트 시작: ${note.id}');
      await _notes.doc(note.id).update(note.toFirestore());
      
      // 캐시 업데이트
      if (_cacheEnabled) {
        _cache[note.id] = note;
      }
      
      print('노트 업데이트 완료: ${note.id}');
    } catch (e) {
      print('노트 업데이트 오류: $e');
      throw Exception('노트 업데이트 중 오류가 발생했습니다: $e');
    }
  }
  
  // 노트 삭제 (소프트 삭제)
  Future<void> deleteNote(String noteId) async {
    try {
      print('노트 삭제 시작: $noteId');
      
      // 현재 노트 가져오기
      final note = await getNote(noteId);
      
      // isDeleted 플래그 설정
      final updatedNote = note.copyWith(isDeleted: true);
      
      // 업데이트
      await _notes.doc(noteId).update(updatedNote.toFirestore());
      
      // 캐시 업데이트
      if (_cacheEnabled) {
        _cache[noteId] = updatedNote;
      }
      
      print('노트 삭제 완료: $noteId');
    } catch (e) {
      print('노트 삭제 오류: $e');
      throw Exception('노트 삭제 중 오류가 발생했습니다: $e');
    }
  }
  
  // 노트 영구 삭제
  Future<void> permanentlyDeleteNote(String noteId) async {
    try {
      print('노트 영구 삭제 시작: $noteId');
      await _notes.doc(noteId).delete();
      
      // 캐시에서 제거
      if (_cacheEnabled) {
        _cache.remove(noteId);
      }
      
      print('노트 영구 삭제 완료: $noteId');
    } catch (e) {
      print('노트 영구 삭제 오류: $e');
      throw Exception('노트 영구 삭제 중 오류가 발생했습니다: $e');
    }
  }
  
  // 노트 스페이스의 모든 노트 가져오기 (스트림)
  Stream<List<Note>> getNotes(String spaceId) {
    try {
      print('노트 스트림 시작: $spaceId');
      return _notes
          .where('spaceId', isEqualTo: spaceId)
          .where('isDeleted', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
        final notes = snapshot.docs
            .map((doc) {
              try {
                final note = Note.fromFirestore(doc);
                
                // 캐시 업데이트
                if (_cacheEnabled) {
                  _cache[note.id] = note;
                }
                
                return note;
              } catch (e) {
                print('노트 변환 오류: $e');
                return null;
              }
            })
            .where((note) => note != null)
            .cast<Note>()
            .toList();
        
        // 생성일 기준 내림차순 정렬
        notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        print('스트림 노트 업데이트: ${notes.length}개');
        return notes;
      });
    } catch (e) {
      print('노트 스트림 오류: $e');
      // 오류 발생 시 빈 스트림 반환
      return Stream.value([]);
    }
  }
  
  // 사용자의 모든 노트 가져오기
  Future<List<Note>> getNotesByUser(String userId) async {
    try {
      print('사용자 노트 가져오기 시작: $userId');
      final querySnapshot = await _notes
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .get();
      
      final notes = querySnapshot.docs.map((doc) {
        final note = Note.fromFirestore(doc);
        
        // 캐시 업데이트
        if (_cacheEnabled) {
          _cache[note.id] = note;
        }
        
        return note;
      }).toList();
      
      // 생성일 기준 내림차순 정렬
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('사용자 노트 가져오기 완료: ${notes.length}개');
      return notes;
    } catch (e) {
      print('사용자 노트 가져오기 오류: $e');
      throw Exception('사용자의 노트를 가져오는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 노트 스페이스 생성
  Future<NoteSpace> createNoteSpace(NoteSpace space) async {
    try {
      print('노트 스페이스 생성 시작: ${space.name}');
      final docRef = await _spaces.add(space.toFirestore());
      
      // ID가 포함된 완전한 스페이스 객체 생성
      final createdSpace = NoteSpace(
        id: docRef.id,
        userId: space.userId,
        name: space.name,
        createdAt: space.createdAt,
        updatedAt: space.updatedAt,
        isDeleted: space.isDeleted,
      );
      
      print('노트 스페이스 생성 완료: ${docRef.id}');
      return createdSpace;
    } catch (e) {
      print('노트 스페이스 생성 오류: $e');
      throw Exception('노트 스페이스 생성 중 오류가 발생했습니다: $e');
    }
  }
  
  // 노트 스페이스 가져오기
  Future<NoteSpace> getNoteSpace(String spaceId) async {
    try {
      print('노트 스페이스 가져오기 시작: $spaceId');
      final docSnapshot = await _spaces.doc(spaceId).get();
      
      if (!docSnapshot.exists) {
        throw Exception('노트 스페이스를 찾을 수 없습니다: $spaceId');
      }
      
      final space = NoteSpace.fromFirestore(docSnapshot);
      
      print('노트 스페이스 가져오기 완료: $spaceId');
      return space;
    } catch (e) {
      print('노트 스페이스 가져오기 오류: $e');
      throw Exception('노트 스페이스를 가져오는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 사용자의 모든 노트 스페이스 가져오기
  Future<List<NoteSpace>> getNoteSpacesByUser(String userId) async {
    try {
      print('사용자 노트 스페이스 가져오기 시작: $userId');
      final querySnapshot = await _spaces
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .get();
      
      final spaces = querySnapshot.docs
          .map((doc) => NoteSpace.fromFirestore(doc))
          .toList();
      
      // 생성일 기준 내림차순 정렬
      spaces.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('사용자 노트 스페이스 가져오기 완료: ${spaces.length}개');
      return spaces;
    } catch (e) {
      print('사용자 노트 스페이스 가져오기 오류: $e');
      throw Exception('사용자의 노트 스페이스를 가져오는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 노트 스페이스 업데이트
  Future<void> updateNoteSpace(NoteSpace space) async {
    try {
      print('노트 스페이스 업데이트 시작: ${space.id}');
      await _spaces.doc(space.id).update(space.toFirestore());
      print('노트 스페이스 업데이트 완료: ${space.id}');
    } catch (e) {
      print('노트 스페이스 업데이트 오류: $e');
      throw Exception('노트 스페이스 업데이트 중 오류가 발생했습니다: $e');
    }
  }
  
  // 노트 스페이스 삭제 (소프트 삭제)
  Future<void> deleteNoteSpace(String spaceId) async {
    try {
      print('노트 스페이스 삭제 시작: $spaceId');
      
      // 현재 스페이스 가져오기
      final space = await getNoteSpace(spaceId);
      
      // isDeleted 플래그 설정
      final updatedSpace = space.copyWith(isDeleted: true);
      
      // 업데이트
      await _spaces.doc(spaceId).update(updatedSpace.toFirestore());
      
      print('노트 스페이스 삭제 완료: $spaceId');
    } catch (e) {
      print('노트 스페이스 삭제 오류: $e');
      throw Exception('노트 스페이스 삭제 중 오류가 발생했습니다: $e');
    }
  }
  
  // 플래시카드와 knownFlashCards 간의 일관성 확인
  Future<void> ensureDataConsistency(String noteId) async {
    try {
      print('데이터 일관성 확인 시작: $noteId');
      final docSnapshot = await _notes.doc(noteId).get();
      
      if (docSnapshot.exists) {
        final note = Note.fromFirestore(docSnapshot);
        
        // knownFlashCards가 null이 아닌지 확인
        if (note.knownFlashCards.isNotEmpty) {
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
          print('knownFlashCards가 비어 있습니다: $noteId');
        }
      } else {
        print('노트를 찾을 수 없음: $noteId');
      }
    } catch (e) {
      print('데이터 일관성 확인 오류: $e');
    }
  }
  
  // 안전하게 노트 목록 가져오기 (오류 발생 시 빈 목록 반환)
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