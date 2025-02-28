import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/models/note_space.dart';
import 'package:mlw/repositories/note_repository.dart';
import 'package:mlw/repositories/note_space_repository.dart';
import 'package:mlw/screens/note_detail_screen.dart';
import 'package:mlw/screens/create_note_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomeScreenLogic {
  final FirebaseAuth auth;
  final NoteRepository noteRepository;
  final NoteSpaceRepository spaceRepository;
  final Function(List<note_model.Note>) onNotesChanged;
  final Function(NoteSpace?) onNoteSpaceChanged;
  final Function(bool) onLoadingChanged;
  final Function(String?) onErrorChanged;
  
  StreamSubscription<List<note_model.Note>>? _notesSubscription;
  NoteSpace? _currentNoteSpace;
  
  HomeScreenLogic({
    required this.auth,
    required this.noteRepository,
    required this.spaceRepository,
    required this.onNotesChanged,
    required this.onNoteSpaceChanged,
    required this.onLoadingChanged,
    required this.onErrorChanged,
  });
  
  void dispose() {
    _notesSubscription?.cancel();
  }
  
  // 캐시에서 데이터 로드
  Future<void> loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedNotesJson = prefs.getString('cached_notes');
      final cachedSpaceJson = prefs.getString('current_note_space');
      
      if (cachedNotesJson != null) {
        final List<dynamic> notesData = jsonDecode(cachedNotesJson);
        final cachedNotes = notesData
            .map((data) => note_model.Note.fromJson(data))
            .toList();
        
        print('캐시에서 ${cachedNotes.length}개 노트 로드됨');
        onNotesChanged(cachedNotes);
      }
      
      if (cachedSpaceJson != null) {
        final spaceData = jsonDecode(cachedSpaceJson);
        final cachedSpace = NoteSpace.fromJson(spaceData);
        
        print('캐시에서 노트 스페이스 로드됨: ${cachedSpace.name}');
        onNoteSpaceChanged(cachedSpace);
        _currentNoteSpace = cachedSpace;
      }
    } catch (e) {
      print('캐시 데이터 로드 오류: $e');
    }
  }
  
  // 현재 노트 스페이스 로드
  Future<void> loadCurrentNoteSpace() async {
    try {
      print('노트 스페이스 로드 시작');
      onLoadingChanged(true);
      
      final user = auth.currentUser;
      if (user == null) {
        print('사용자가 로그인되어 있지 않습니다. 테스트 사용자 ID 사용');
        // 테스트 사용자 ID 사용
        const testUserId = 'test_user_id';
        
        // 테스트 사용자의 노트 스페이스 가져오기
        final spaces = await spaceRepository.getNoteSpaces(testUserId);
        
        NoteSpace? currentSpace;
        if (spaces.isEmpty) {
          // 노트 스페이스가 없으면 기본 스페이스 생성
          final defaultSpace = NoteSpace(
            id: '',
            userId: testUserId,
            name: '기본 스페이스',
            language: 'ko',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          currentSpace = await spaceRepository.createNoteSpace(defaultSpace);
          print('테스트 사용자용 기본 노트 스페이스 생성됨: ${currentSpace.id}');
        } else {
          // 첫 번째 스페이스 사용
          currentSpace = spaces.first;
          print('테스트 사용자의 기존 노트 스페이스 사용: ${currentSpace.id}');
        }
        
        onNoteSpaceChanged(currentSpace);
        _currentNoteSpace = currentSpace;
        
        // 노트 목록 구독
        subscribeToNotes(currentSpace.id);
        
        // 캐시에 저장
        _saveNoteSpaceToCache(currentSpace);
        
        onLoadingChanged(false);
        return;
      }
      
      print('사용자 ID: ${user.uid}');
      // 사용자의 노트 스페이스 가져오기
      final spaces = await spaceRepository.getNoteSpaces(user.uid);
      print('노트 스페이스 개수: ${spaces.length}');
      
      NoteSpace? currentSpace;
      if (spaces.isEmpty) {
        print('노트 스페이스가 없어 기본 스페이스 생성 시작');
        // 노트 스페이스가 없으면 기본 스페이스 생성
        final defaultSpace = NoteSpace(
          id: '',
          userId: user.uid,
          name: '기본 스페이스',
          language: 'ko',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        currentSpace = await spaceRepository.createNoteSpace(defaultSpace);
        print('기본 노트 스페이스 생성됨: ${currentSpace.id}');
      } else {
        print('기존 노트 스페이스 사용');
        // 첫 번째 스페이스 사용
        currentSpace = spaces.first;
        print('기존 노트 스페이스 사용: ${currentSpace.id}');
      }
      
      print('노트 스페이스 로드 완료: ${currentSpace.id}');
      onNoteSpaceChanged(currentSpace);
      _currentNoteSpace = currentSpace;
      
      // 노트 목록 구독
      subscribeToNotes(currentSpace.id);
      
      // 캐시에 저장
      _saveNoteSpaceToCache(currentSpace);
      
    } catch (e) {
      print('노트 스페이스 로드 오류: $e');
      print('스택 트레이스: ${StackTrace.current}');
      onErrorChanged('노트 스페이스 로드 중 오류가 발생했습니다: $e');
      onLoadingChanged(false);
      
      // 오류 발생 시 기본 노트 스페이스 생성
      try {
        print('오류 복구: 기본 노트 스페이스 생성 시도');
        final defaultSpace = NoteSpace(
          id: 'default_space',
          userId: 'test_user_id',
          name: '기본 스페이스',
          language: 'ko',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        onNoteSpaceChanged(defaultSpace);
        _currentNoteSpace = defaultSpace;
        
        // 빈 노트 목록 표시
        onNotesChanged([]);
        onLoadingChanged(false);
      } catch (recoveryError) {
        print('오류 복구 실패: $recoveryError');
      }
    }
  }
  
  // 노트 스페이스를 캐시에 저장
  Future<void> _saveNoteSpaceToCache(NoteSpace noteSpace) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final spaceJson = jsonEncode(noteSpace.toJson());
      await prefs.setString('current_note_space', spaceJson);
      print('노트 스페이스를 캐시에 저장: ${noteSpace.id}');
    } catch (e) {
      print('노트 스페이스 캐시 저장 오류: $e');
    }
  }
  
  // 노트 목록을 캐시에 저장
  Future<void> _saveNotesToCache(List<note_model.Note> notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = jsonEncode(notes.map((note) => note.toJson()).toList());
      await prefs.setString('cached_notes', notesJson);
      print('${notes.length}개 노트를 캐시에 저장');
    } catch (e) {
      print('노트 캐시 저장 오류: $e');
    }
  }
  
  // 노트 목록 구독
  void subscribeToNotes(String spaceId) {
    // 기존 구독 취소
    _notesSubscription?.cancel();
    
    final user = auth.currentUser;
    if (user == null) {
      onNotesChanged([]);
      onLoadingChanged(false);
      return;
    }
    
    print('노트 스트림 구독 시작: $spaceId');
    onLoadingChanged(true);
    
    // 먼저 직접 데이터 로드
    _loadNotesDirectly(spaceId);
    
    // 새로운 스트림 구독
    _notesSubscription = noteRepository
        .getNotes(spaceId)
        .listen(
          (notes) {
            print('노트 스트림 업데이트: ${notes.length}개');
            onNotesChanged(notes);
            onLoadingChanged(false);
            
            // 캐시에 저장
            _saveNotesToCache(notes);
          },
          onError: (e) {
            print('노트 스트림 오류: $e');
            onErrorChanged('노트 목록을 가져오는 중 오류가 발생했습니다: $e');
            onLoadingChanged(false);
          },
        );
  }
  
  // 노트 목록 직접 로드
  Future<void> _loadNotesDirectly(String spaceId) async {
    try {
      print('직접 노트 로드 시작: $spaceId');
      final snapshot = await FirebaseFirestore.instance
          .collection('notes')
          .where('spaceId', isEqualTo: spaceId)
          // .where('isDeleted', isEqualTo: false)  // 이 조건이 문제를 일으킬 수 있음
          .get();
      
      print('노트 쿼리 결과: ${snapshot.docs.length}개');
      
      final notes = snapshot.docs
          .map((doc) => note_model.Note.fromFirestore(doc))
          .where((note) => !(note.isDeleted ?? false))
          .toList();
      
      notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('직접 로드한 노트: ${notes.length}개');
      
      onNotesChanged(notes);
      onLoadingChanged(false);
      
      // 캐시에 저장
      _saveNotesToCache(notes);
    } catch (e) {
      print('노트 직접 로드 오류: $e');
      print('스택 트레이스: ${StackTrace.current}');
      onErrorChanged('노트 목록을 직접 로드하는 중 오류가 발생했습니다: $e');
      onLoadingChanged(false);
    }
  }
  
  // 노트 상세 화면으로 이동
  Future<void> navigateToNoteDetail(BuildContext context, note_model.Note note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(note: note),
      ),
    );
    
    if (result == true) {
      print('노트 상세 화면에서 변경 사항 있음, 노트 목록 새로고침');
      refreshNotes();
    }
  }
  
  // 노트 생성 화면으로 이동
  Future<dynamic> navigateToCreateNote(
    BuildContext context,
    String imageUrl,
    String extractedText,
    String translatedText,
  ) async {
    if (_currentNoteSpace == null) {
      print('노트 스페이스가 없습니다. 노트를 생성할 수 없습니다.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('노트 스페이스가 없습니다. 노트를 생성할 수 없습니다.')),
      );
      return null;
    }
    
    return await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateNoteScreen(
          spaceId: _currentNoteSpace!.id,
          userId: auth.currentUser?.uid ?? 'test_user_id',
          imageUrl: imageUrl,
          extractedText: extractedText,
          translatedText: translatedText,
        ),
      ),
    );
  }
  
  // 노트 생성 결과 처리
  void handleNoteCreated(note_model.Note note) {
    if (note != null) {
      // 노트가 생성된 후 노트 목록을 새로 고침
      refreshNotes();
    } else {
      print('노트 생성 실패: note는 null입니다.');
    }
  }
  
  // 현재 노트 스페이스 가져오기
  Future<NoteSpace?> _getCurrentNoteSpace() async {
    return _currentNoteSpace;
  }
  
  // 현재 노트 목록 가져오기
  Future<List<note_model.Note>> _getCurrentNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedNotesJson = prefs.getString('cached_notes');
      
      if (cachedNotesJson != null) {
        final List<dynamic> notesData = jsonDecode(cachedNotesJson);
        return notesData
            .map((data) => note_model.Note.fromJson(data))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('현재 노트 목록 가져오기 오류: $e');
      return [];
    }
  }
  
  // 노트 상세 화면에서 돌아올 때 호출
  Future<void> refreshNotes() async {
    print('Returned from NoteDetailScreen, refreshing notes');
    
    // 기존 구독 취소 후 새로 구독
    _notesSubscription?.cancel();
    
    final currentSpace = await _getCurrentNoteSpace();
    if (currentSpace != null) {
      try {
        onLoadingChanged(true);
        
        // Firestore에서 직접 데이터 가져오기
        final snapshot = await FirebaseFirestore.instance
            .collection('notes')
            .where('spaceId', isEqualTo: currentSpace.id)
            .get();
        
        final notes = snapshot.docs
            .map((doc) => note_model.Note.fromFirestore(doc))
            .where((note) => !(note.isDeleted ?? false))
            .toList();
        
        notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        print('Firestore에서 직접 로드한 노트: ${notes.length}개');
        
        // 캐시에 노트 추가
        for (var note in notes) {
          noteRepository.updateCache(note);
        }
        
        onNotesChanged(notes);
        onLoadingChanged(false);
        
        // 캐시에 저장
        _saveNotesToCache(notes);
      } catch (e) {
        print('노트 새로고침 오류: $e');
        onLoadingChanged(false);
      }
      
      // 구독 다시 시작
      subscribeToNotes(currentSpace.id);
    }
  }
  
  // 강제 새로고침
  Future<void> forceRefreshNotes() async {
    try {
      onLoadingChanged(true);
      
      // 캐시 초기화
      noteRepository.clearCache();
      
      // 구독 취소
      _notesSubscription?.cancel();
      
      final currentSpace = await _getCurrentNoteSpace();
      if (currentSpace != null) {
        // Firestore에서 직접 데이터 가져오기
        final snapshot = await FirebaseFirestore.instance
            .collection('notes')
            .where('spaceId', isEqualTo: currentSpace.id)
            .get();
        
        final notes = snapshot.docs
            .map((doc) => note_model.Note.fromFirestore(doc))
            .where((note) => !(note.isDeleted ?? false))
            .toList();
        
        notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        print('강제 새로고침: Firestore에서 ${notes.length}개 노트 로드됨');
        
        onNotesChanged(notes);
        onLoadingChanged(false);
        
        // 캐시에 저장
        _saveNotesToCache(notes);
        
        // 구독 다시 시작
        subscribeToNotes(currentSpace.id);
      }
    } catch (e) {
      print('강제 새로고침 오류: $e');
      onLoadingChanged(false);
    }
  }
  
  // 데이터 상태 확인
  Future<void> checkDataState() async {
    try {
      print('\n===== 데이터 상태 확인 =====');
      
      final currentSpace = await _getCurrentNoteSpace();
      print('현재 스페이스: ${currentSpace?.id}, 이름: ${currentSpace?.name}');
      
      final currentNotes = await _getCurrentNotes();
      print('메모리 내 노트 수: ${currentNotes.length}');
      
      // 캐시 상태 확인
      print('노트 캐시 상태: ${noteRepository.getCacheSize()}개 항목');
      
      // Firestore 상태 확인
      if (currentSpace != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('notes')
            .where('spaceId', isEqualTo: currentSpace.id)
            .get();
        
        print('Firestore 내 노트 수: ${snapshot.docs.length}');
        
        for (var doc in snapshot.docs) {
          final data = doc.data();
          print('- 노트: ${doc.id}, 제목: ${data['title']}');
        }
      }
      
      print('===== 데이터 상태 확인 완료 =====\n');
    } catch (e) {
      print('데이터 상태 확인 오류: $e');
    }
  }
  
  // 노트 삭제 메서드 추가
  Future<void> deleteNote(String noteId) async {
    try {
      print('노트 삭제 시작: $noteId');
      onLoadingChanged(true);
      
      // 노트 삭제
      await noteRepository.deleteNote(noteId);
      
      // 노트 목록 새로고침
      refreshNotes();
      
      print('노트 삭제 완료: $noteId');
    } catch (e) {
      print('노트 삭제 오류: $e');
      onErrorChanged('노트 삭제 중 오류가 발생했습니다: $e');
      onLoadingChanged(false);
    }
  }
  
  // 노트 제목 수정 메서드 추가
  Future<void> updateNoteTitle(String noteId, String newTitle) async {
    try {
      print('노트 제목 수정 시작: $noteId, 새 제목: $newTitle');
      onLoadingChanged(true);
      
      // 노트 가져오기
      final note = await noteRepository.getNote(noteId);
      
      // 제목 수정
      final updatedNote = note.copyWith(
        title: newTitle,
        updatedAt: DateTime.now(),
      );
      
      // 노트 업데이트
      await noteRepository.updateNote(updatedNote);
      
      // 노트 목록 새로고침
      refreshNotes();
      
      print('노트 제목 수정 완료: $noteId');
    } catch (e) {
      print('노트 제목 수정 오류: $e');
      onErrorChanged('노트 제목 수정 중 오류가 발생했습니다: $e');
      onLoadingChanged(false);
    }
  }
} 