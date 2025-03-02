import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/models/flash_card.dart' as flash_card_model;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mlw/widgets/note_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:mlw/models/text_display_mode.dart';
import 'package:mlw/services/pinyin_service.dart';
import 'package:mlw/services/image_processing_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mlw/repositories/note_repository.dart';
import 'package:mlw/screens/flashcard_screen.dart';
import 'package:mlw/services/translator_service.dart';
import 'dart:io';
import 'dart:async';

class NoteDetailScreen extends StatefulWidget {
  final String noteId;
  final String spaceId;
  final String initialTitle;
  final String initialContent;
  final String? initialImageUrl;
  final String? initialTranslatedContent;
  final String initialLanguage;
  
  // 노트 객체로 초기화하는 생성자 추가
  final note_model.Note? note;

  const NoteDetailScreen({
    Key? key,
    this.noteId = '',
    this.spaceId = '',
    this.initialTitle = '',
    this.initialContent = '',
    this.initialImageUrl,
    this.initialTranslatedContent,
    this.initialLanguage = 'ko',
    this.note,
  }) : super(key: key);

  @override
  _NoteDetailScreenState createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool _isHighlightMode = true;
  int? _currentPlayingIndex;
  Set<String> highlightedTexts = {};
  int _currentPageIndex = 0;
  TextDisplayMode _displayMode = TextDisplayMode.both;
  Set<String> _highlightedTexts = {};
  note_model.Note? _note;
  bool _isNoteModified = false;
  final NoteRepository _noteRepository = NoteRepository();
  final TranslatorService _translatorService = TranslatorService();
  final ImageProcessingService _imageService = ImageProcessingService();
  
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _translatedContentController;
  
  String? _imageUrl;
  // 노트 ID와 스페이스 ID를 저장할 변수
  late String _noteId;
  late String _spaceId;
  
  // 디바운스 타이머 추가
  Timer? _saveTimer;
  bool _isLoading = true;
  String? _error;
  bool _isCreatingFlashCard = false;

  @override
  void initState() {
    super.initState();
    
    // 노트 객체가 전달된 경우 해당 객체의 값을 사용
    if (widget.note != null) {
      _note = widget.note;
      _noteId = widget.note!.id;
      _spaceId = widget.note!.spaceId;
      _titleController = TextEditingController(text: widget.note!.title);
      _contentController = TextEditingController(text: widget.note!.content);
      _translatedContentController = TextEditingController(
        text: widget.note!.translatedText,
      );
      _imageUrl = widget.note!.imageUrl;
    } else {
      // 기본 빈 노트 객체 생성
      _note = note_model.Note(
        id: widget.noteId,
        spaceId: widget.spaceId,
        userId: '',
        title: widget.initialTitle,
        content: widget.initialContent,
        imageUrl: widget.initialImageUrl ?? '',
        extractedText: '',
        translatedText: widget.initialTranslatedContent ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDeleted: false,
        flashcardCount: 0,
        reviewCount: 0,
        pages: [],
        flashCards: [],
        knownFlashCards:<String>{},
        highlightedTexts:<String>{},
      );
      // 나머지 초기화 코드...
      _noteId = widget.noteId;
      _spaceId = widget.spaceId;
      _titleController = TextEditingController(text: widget.initialTitle);
      _contentController = TextEditingController(text: widget.initialContent);
      _translatedContentController = TextEditingController(
        text: widget.initialTranslatedContent ?? '',
      );
      _imageUrl = widget.initialImageUrl;
    }
    
    print('NoteDetailScreen initState: $_noteId');
    
    // 노트 데이터 로드
    _loadNote();
  }

  Future<void> _loadNote() async {
    try {
      setState(() => _isLoading = true);
      
      print('노트 데이터 로드 시작: $_noteId');
      
      // 노트 ID가 비어있으면 로드하지 않음
      if (_noteId.isEmpty) {
        print('노트 ID가 비어있어 로드하지 않음');
        return;
      }
      
      // Firestore에서 최신 데이터 가져오기
      print('Firestore에서 노트 데이터 로드 시작: $_noteId');
      
      try {
        // final을 제거하여 변수를 재할당 가능하게 함
        var loadedNote = await _noteRepository.getNote(_noteId);
        
        print('Firestore에서 노트 데이터 로드 성공');
        print('로드된 노트: ${loadedNote.toString()}');
        print('로드된 노트 페이지 수: ${loadedNote.pages.length}');
        
        // 페이지가 없는 경우 마이그레이션 수행
        if (loadedNote.pages.isEmpty && loadedNote.imageUrl.isNotEmpty) {
          print('페이지가 없지만 이미지 URL이 있습니다. 마이그레이션 수행...');
          
          // 이미지 파일 존재 확인
          final imageFile = File(loadedNote.imageUrl);
          final imageExists = await imageFile.exists();
          print('이미지 파일 존재 여부: $imageExists');
          
          if (imageExists) {
            // 번역 텍스트가 비어있는 경우 번역 시도
            String translatedText = loadedNote.translatedText;
            if (translatedText.isEmpty && loadedNote.extractedText.isNotEmpty) {
              try {
                print('번역 텍스트가 비어있어 번역 시도...');
                await _translatorService.initialize();
                translatedText = await _translatorService.translateText(loadedNote.extractedText);
                print('번역 완료: ${translatedText.substring(0, translatedText.length > 20 ? 20 : translatedText.length)}...');
              } catch (e) {
                print('번역 오류: $e');
              }
            }
            
            // 페이지 생성
            final page = note_model.Page(
              imageUrl: loadedNote.imageUrl,
              extractedText: loadedNote.extractedText,
              translatedText: translatedText,
            );
            
            // 페이지가 추가된 노트 생성
            final updatedNote = loadedNote.copyWith(
              pages: [page],
              translatedText: translatedText,
              updatedAt: DateTime.now(),
            );
            
            // Firestore 업데이트
            await _noteRepository.updateNote(updatedNote);
            
            print('노트 마이그레이션 완료: ${updatedNote.id}');
            print('마이그레이션 후 페이지 수: ${updatedNote.pages.length}');
            
            // 업데이트된 노트 사용
            loadedNote = updatedNote;
          } else {
            print('이미지 파일이 존재하지 않아 마이그레이션을 수행할 수 없습니다');
          }
        }
        
        // 기존 로직 계속 진행...
        if (loadedNote.pages.isNotEmpty) {
          for (int i = 0; i < loadedNote.pages.length; i++) {
            final page = loadedNote.pages[i];
            print('페이지 $i 정보:');
            print('- 이미지 URL: ${page.imageUrl}');
            print('- 추출된 텍스트 길이: ${page.extractedText.length}');
            print('- 번역된 텍스트 길이: ${page.translatedText.length}');
            
            // 번역 텍스트가 비어있는 경우 번역 시도
            if (page.translatedText.isEmpty && page.extractedText.isNotEmpty) {
              try {
                print('페이지 $i의 번역 텍스트가 비어있어 번역 시도...');
                await _translatorService.initialize();
                final translatedText = await _translatorService.translateText(page.extractedText);
                
                // 페이지 목록 업데이트
                final updatedPages = List<note_model.Page>.from(loadedNote.pages);
                updatedPages[i] = note_model.Page(
                  imageUrl: page.imageUrl,
                  extractedText: page.extractedText,
                  translatedText: translatedText,
                );
                
                // 노트 업데이트
                final updatedNote = loadedNote.copyWith(
                  pages: updatedPages,
                  updatedAt: DateTime.now(),
                );
                
                // Firestore 업데이트
                await _noteRepository.updateNote(updatedNote);
                
                // 로드된 노트 업데이트
                loadedNote = updatedNote;
                
                print('페이지 $i 번역 완료');
              } catch (e) {
                print('페이지 $i 번역 오류: $e');
              }
            }
            
            // 이미지 파일이 존재하는지 확인
            final file = File(page.imageUrl);
            final exists = await file.exists();
            print('- 이미지 파일 존재 여부: $exists');
            
            if (!exists) {
              print('- 이미지 파일 경로 문제 발생: ${page.imageUrl}');
            }
          }
        } else {
          print('페이지가 없습니다');
        }
        
        // UI 업데이트
        setState(() {
          _note = loadedNote;
          _titleController.text = loadedNote.title;
          _contentController.text = loadedNote.content;
          _translatedContentController.text = loadedNote.translatedText;
          _imageUrl = loadedNote.imageUrl;
          _highlightedTexts = loadedNote.highlightedTexts;
          _currentPageIndex = 0;
        });
        
        print('노트 데이터 UI 업데이트 완료');
        
      } catch (e) {
        print('Firestore에서 노트 데이터 로드 오류: $e');
        print('스택 트레이스: ${StackTrace.current}');
      }
    } catch (e) {
      print('노트 데이터 로드 오류: $e');
      print('스택 트레이스: ${StackTrace.current}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      print('TTS error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('음성 재생 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _handleTextSelection(String text) async {
    try {
      // 이미 하이라이트된 텍스트인 경우 제거
      if (_highlightedTexts.contains(text)) {
        await _removeHighlight(text);
        return;
      }

      // 새로운 하이라이트 추가
      await _addHighlight(text);
    } catch (e) {
      _handleError('텍스트 처리 중 오류가 발생했습니다', e);
    }
  }

  Future<void> _removeHighlight(String text) async {
    setState(() {
      _highlightedTexts.remove(text);
    });
    
    // Firestore 업데이트
    final updatedNote = _note!.copyWith(
      highlightedTexts: Set<String>.from(_highlightedTexts),
      updatedAt: DateTime.now(),
    );
    
    await firestore.collection('notes').doc(_note!.id).update(updatedNote.toJson());
    
    setState(() {
      _note = updatedNote;
    });
    
    _showMessage('하이라이트가 제거되었습니다');
  }

  Future<void> _addHighlight(String text) async {
    // 올바른 translate 메서드 호출 (이름 있는 매개변수 사용)
    final translatedText = await _translatorService.translate(text, from: 'ko', to: 'zh');
    final pinyin = await pinyinService.getPinyin(text);
    
    final newFlashCard = flash_card_model.FlashCard(
      front: text,
      back: translatedText,
      pinyin: pinyin,
      noteId: _note!.id,
      createdAt: DateTime.now(),
      reviewCount: 0, id: '',
    );

    // 중복 플래시카드 방지
    final List<flash_card_model.FlashCard> updatedFlashCards = [
      ..._note!.flashCards.where((card) => card.front != text),
      newFlashCard,
    ];

    final updatedNote = _note!.copyWith(
      flashCards: updatedFlashCards,
      highlightedTexts: {..._highlightedTexts, text},
      updatedAt: DateTime.now(),
    );

    // Firestore 업데이트
    await firestore.collection('notes').doc(_note!.id).update(updatedNote.toJson());

    // UI 업데이트
    setState(() {
      _note = updatedNote;
      _highlightedTexts = Set<String>.from(updatedNote.highlightedTexts);
    });

    _showMessage('플래시카드에 저장되었습니다');
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _handleError(String message, dynamic error) {
    print('$message: $error');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$message: $error'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<String> getPinyin(String text) async {
    // TODO: pinyin API 연동
    // 임시로 더미 데이터 반환
    return 'mao he gou shi hao peng you';
  }

  Future<void> _editPageText(int pageIndex, String newText) async {
    try {
      final translatedText = await _translatorService.translate(newText, from: 'ko', to: 'zh');
      
      final updatedPage = note_model.Page(
        imageUrl: _note!.pages[pageIndex].imageUrl,
        extractedText: newText,
        translatedText: translatedText,
      );
      
      final updatedPages = List<note_model.Page>.from(_note!.pages);
      updatedPages[pageIndex] = updatedPage;
      
      final updatedNote = _note!.copyWith(
        pages: updatedPages,
        updatedAt: DateTime.now(),
      );
      
      await firestore.collection('notes').doc(_note!.id).update(updatedNote.toJson());
      
      setState(() {
        _note = updatedNote;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('텍스트가 수정되었습니다')),
        );
      }
    } catch (e) {
      print('Error editing page text: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('텍스트 수정 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  void _deletePage(int pageIndex) {
    if (_note == null || pageIndex >= _note!.pages.length) return;
    
    setState(() {
      final updatedPages = List<note_model.Page>.from(_note!.pages);
      updatedPages.removeAt(pageIndex);
      _note = _note!.copyWith(pages: updatedPages);
      
      // 현재 페이지 인덱스 조정
      if (_currentPageIndex >= updatedPages.length) {
        _currentPageIndex = updatedPages.isEmpty ? 0 : updatedPages.length - 1;
      }
    });
    
    // Firestore 업데이트
    _saveNote();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('페이지가 삭제되었습니다')),
    );
  }

  void _showEditDialog(int pageIndex, String text) {
    final textController = TextEditingController(text: text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('텍스트 편집'),
        content: TextField(
          controller: textController,
          maxLines: 10,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editPageText(pageIndex, textController.text);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _translateText(String text) async {
    setState(() {
// 로딩 표시
    });
    
    try {
      // 사용자 설정에서 대상 언어 가져오기
      final prefs = await SharedPreferences.getInstance();
      final targetLanguage = prefs.getString('target_language') ?? '한국어';
      // 번역 서비스 호출
      final translatedText = await _translatorService.translate(text, from: 'auto', to: targetLanguage);
      
      setState(() {
      });
    } catch (e) {
      print('번역 오류: $e');
      setState(() {
      });
    }
  }

  Future<void> _saveFlashCards() async {
    try {
      print('플래시카드 저장 시작: ${_note!.id}, 카드 수: ${_note!.flashCards.length}');
      
      // 깊은 복사를 통해 새 객체 생성
      final updatedNote = _note!.copyWith(
        flashCards: List<flash_card_model.FlashCard>.from(_note!.flashCards),
        updatedAt: DateTime.now(),
      );
      
      // Firestore 업데이트
      await FirebaseFirestore.instance
          .collection('notes')
          .doc(_note!.id)
          .update(updatedNote.toJson());
      
      print('플래시카드 저장 완료: ${_note!.id}');
      
      // 저장 확인
      final docSnapshot = await FirebaseFirestore.instance
          .collection('notes')
          .doc(_note!.id)
          .get();
      
      if (docSnapshot.exists) {
        final savedNote = note_model.Note.fromFirestore(docSnapshot);
        print('저장된 플래시카드 수: ${savedNote.flashCards.length}');
      }
    } catch (e) {
      print('플래시카드 저장 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('플래시카드 저장 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('노트 로딩 중...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('오류')),
        body: Center(child: Text('오류가 발생했습니다: $_error')),
      );
    }
    
    if (_note == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('노트 없음')),
        body: const Center(child: Text('노트를 찾을 수 없습니다')),
      );
    }
    
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildPageContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_note?.title ?? '노트'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _handleBackPress,
      ),
      actions: [
        // 하이라이트 모드 토글 버튼
        IconButton(
          icon: Icon(
            _isHighlightMode ? Icons.highlight : Icons.highlight_off,
            color: _isHighlightMode
                ? ColorTokens.getColor('primary.400')
                : ColorTokens.getColor('text.body'),
          ),
          onPressed: () {
            setState(() {
              _isHighlightMode = !_isHighlightMode;
              print('Highlight mode toggled: $_isHighlightMode');
            });
          },
        ),
      ],
    );
  }

  Widget _buildPageControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 이전 페이지 버튼
          IconButton(
            onPressed: _currentPageIndex > 0
                ? () {
                    setState(() {
                      _currentPageIndex--;
                    });
                  }
                : null,
            icon: Icon(
              Icons.arrow_back_ios,
              color: _currentPageIndex > 0
                  ? Theme.of(context).iconTheme.color
                  : Theme.of(context).disabledColor,
            ),
          ),
          
          // 모드 토글 버튼들
          Row(
            children: [
              // 원문만 보기
              IconButton(
                onPressed: () {
                  setState(() {
                    _displayMode = TextDisplayMode.originalOnly;
                  });
                },
                icon: Icon(
                  Icons.subject,
                  color: _displayMode == TextDisplayMode.originalOnly
                      ? ColorTokens.getColor('primary.400')
                      : ColorTokens.getColor('text.body'),
                ),
              ),
              // 번역만 보기
              IconButton(
                onPressed: () {
                  setState(() {
                    _displayMode = TextDisplayMode.translationOnly;
                  });
                },
                icon: Icon(
                  Icons.translate,
                  color: _displayMode == TextDisplayMode.translationOnly
                      ? ColorTokens.getColor('primary.400')
                      : ColorTokens.getColor('text.body'),
                ),
              ),
              // 둘 다 보기
              IconButton(
                onPressed: () {
                  setState(() {
                    _displayMode = TextDisplayMode.both;
                  });
                },
                icon: Icon(
                  Icons.view_agenda,
                  color: _displayMode == TextDisplayMode.both
                      ? ColorTokens.getColor('primary.400')
                      : ColorTokens.getColor('text.body'),
                ),
              ),
              // TTS 버튼
              IconButton(
                onPressed: () {
                  if (_note!.pages.isNotEmpty) {
                    _speak(_note!.pages[_currentPageIndex].extractedText);
                  }
                },
                icon: Icon(
                  Icons.volume_up,
                  color: _currentPlayingIndex == _currentPageIndex
                      ? ColorTokens.getColor('primary.400')
                      : ColorTokens.getColor('text.body'),
                ),
              ),
            ],
          ),

          // 다음 페이지 버튼
          IconButton(
            onPressed: _currentPageIndex < _note!.pages.length - 1
                ? () {
                    setState(() {
                      _currentPageIndex++;
                    });
                  }
                : null,
            icon: Icon(
              Icons.arrow_forward_ios,
              color: _currentPageIndex < _note!.pages.length - 1
                  ? Theme.of(context).iconTheme.color
                  : Theme.of(context).disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    if (_note == null || _note!.pages.isEmpty) {
      return const Center(child: Text('페이지가 없습니다'));
    }
    
    return NotePage(
      page: _note!.pages[_currentPageIndex],
      displayMode: _displayMode,
      isHighlightMode: _isHighlightMode,
      highlightedTexts: _highlightedTexts,
      onHighlighted: _handleTextSelection,
      onSpeak: _speak,
      currentPlayingIndex: _currentPlayingIndex,
      onDeletePage: () => _deletePage(_currentPageIndex),
      onEditText: (text) => _showEditDialog(_currentPageIndex, text),
      onRetranslate: _retranslate,  // 번역 재시도 콜백 전달
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add,
            size: 64,
            color: ColorTokens.getColor('base.300'),
          ),
          const SizedBox(height: 16),
          Text(
            '페이지가 없습니다',
            style: TypographyTokens.getStyle('heading.h2').copyWith(
              color: ColorTokens.getColor('base.400'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '이미지를 추가하여 새 페이지를 만들어보세요',
            style: TypographyTokens.getStyle('body.medium').copyWith(
              color: ColorTokens.getColor('base.400'),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('이미지 추가'),
            onPressed: _addImage,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _saveFlashCards();
    _flutterTts.stop();
    _titleController.dispose();
    _contentController.dispose();
    _translatedContentController.dispose();
    super.dispose();
  }

  void _handleBackPress() {
    print("Back button pressed, returning to HomeScreen");
    Navigator.pop(context, true); // true를 반환하여 홈 화면에 새로고침 신호 전달
  }

  void _navigateToFlashcardScreen() async {
    print('플래시카드 화면으로 이동: ${_note!.id}');
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardScreen(note: _note!),
      ),
    );
    
    if (result == true) {
      print('플래시카드 화면에서 돌아옴, 노트 데이터 새로고침');
      _loadNote();
    }
  }

  Future<bool> _onWillPop() async {
    print('Back button pressed, returning to HomeScreen');
    
    // 노트 데이터가 변경되었는지 확인
    if (_isNoteModified) {
      // 변경된 노트 저장
      await _saveNote();
    }
    
    // 홈 화면으로 돌아갈 때 true 반환하여 새로고침 신호 전달
    Navigator.pop(context, true);
    return false; // 네비게이션을 직접 처리했으므로 false 반환
  }

  Future<void> _saveNote() async {
    try {
      print('노트 저장 시작: $_noteId');
      
      // 현재 노트가 null이면 저장하지 않음
      if (_note == null) {
        print('노트가 null이어서 저장하지 않음');
        return;
      }
      
      // 현재 노트 복사본 생성 및 업데이트
      final updatedNote = _note!.copyWith(
        title: _titleController.text,
        content: _contentController.text,
        translatedText: _translatedContentController.text,
        updatedAt: DateTime.now(),
        highlightedTexts: _highlightedTexts,
      );
      
      await _noteRepository.updateNote(updatedNote);
      
      setState(() {
        _note = updatedNote;
        _isNoteModified = false;
      });
      
      print('노트 저장 완료: ${updatedNote.id}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('노트가 저장되었습니다')),
      );
    } catch (e) {
      print('노트 저장 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('노트 저장 중 오류가 발생했습니다: $e')),
      );
    }
  }

  void _scheduleNoteSave() {
    // 이전 타이머 취소
    _saveTimer?.cancel();
    
    // 새 타이머 설정 (500ms 후 저장)
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveNote();
    });
  }

  Future<void> _addImage() async {
    if (_note == null) return;
    
    try {
      setState(() => _isLoading = true);
      
      // 이미지 선택 및 처리
      final result = await _imageService.pickAndProcessImage();
      
      if (result == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      // 새 페이지 생성
      final newPage = note_model.Page(
        imageUrl: result.imageUrl,
        extractedText: result.extractedText,
        translatedText: result.translatedText,
      );
      
      // 노트 업데이트
      final updatedNote = await _noteRepository.addPage(_note!, newPage);
      
      setState(() {
        _note = updatedNote;
        _currentPageIndex = updatedNote.pages.length - 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 추가 중 오류가 발생했습니다: $e')),
      );
    }
  }

  Future<void> _retranslate(String text) async {
    if (_note == null || _note!.pages.isEmpty || text.isEmpty) return;
    
    try {
      setState(() => _isLoading = true);
      
      // 번역 서비스 초기화
      await _translatorService.initialize();
      
      // 텍스트 번역
      final translatedText = await _translatorService.translateText(text);
      
      // 현재 페이지 업데이트
      final currentPage = _note!.pages[_currentPageIndex];
      final updatedPage = note_model.Page(
        imageUrl: currentPage.imageUrl,
        extractedText: currentPage.extractedText,
        translatedText: translatedText,
      );
      
      // 노트 업데이트
      final updatedNote = await _noteRepository.updatePage(_note!, _currentPageIndex, updatedPage);
      
      setState(() {
        _note = updatedNote;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('번역이 완료되었습니다')),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('번역 중 오류가 발생했습니다: $e')),
      );
    }
  }

  Future<void> _createFlashCard(String text) async {
    if (text.isEmpty || _note == null) return;
    
    try {
      setState(() {
        _isCreatingFlashCard = true;
      });
      
      // 번역 서비스 초기화
      await _translatorService.initialize();
      
      // 텍스트 번역
      final translatedText = await _translatorService.translate(text);
      
      // 병음 생성
      final pinyinService = PinyinService();
      final pinyin = await pinyinService.getPinyin(text);
      
      // 플래시카드 생성
      final newFlashCard = flash_card_model.FlashCard(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // 고유 ID 생성
        front: text,
        back: translatedText,
        pinyin: pinyin,
        createdAt: DateTime.now(),
      );
      
      // 노트에 플래시카드 추가
      final updatedNote = await _noteRepository.addFlashCard(_note!, newFlashCard);
      
      setState(() {
        _note = updatedNote;
        _isCreatingFlashCard = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('플래시카드가 추가되었습니다')),
      );
    } catch (e) {
      setState(() {
        _isCreatingFlashCard = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('플래시카드 생성 중 오류가 발생했습니다: $e')),
      );
    }
  }
}



