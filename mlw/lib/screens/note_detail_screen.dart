import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/models/flash_card.dart' as flash_card_model;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mlw/widgets/note_page.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:mlw/models/text_display_mode.dart';
import 'package:mlw/services/pinyin_service.dart';
import 'package:mlw/widgets/flashcard_counter.dart';
import 'package:mlw/services/image_processing_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mlw/repositories/note_repository.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:mlw/screens/flashcard_screen.dart';
import 'package:mlw/services/translator_service.dart';

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
  late note_model.Note _note;
  late ImageProcessingService _imageProcessingService;
  bool _isNoteModified = false;
  final NoteRepository _noteRepository = NoteRepository();
  final TranslatorService _translatorService = TranslatorService();
  
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _translatedContentController;
  
  String? _imageUrl;
  // 노트 ID와 스페이스 ID를 저장할 변수
  late String _noteId;
  late String _spaceId;
  
  @override
  void initState() {
    super.initState();
    
    // 노트 객체가 전달된 경우 해당 객체의 값을 사용
    if (widget.note != null) {
      _noteId = widget.note!.id;
      _spaceId = widget.note!.spaceId;
      _titleController = TextEditingController(text: widget.note!.title);
      _contentController = TextEditingController(text: widget.note!.content);
      _translatedContentController = TextEditingController(
        text: widget.note!.translatedText,
      );
      _imageUrl = widget.note!.imageUrl;
    } else {
      // 개별 필드가 전달된 경우 해당 값을 사용
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
    _loadNoteData();
    _imageProcessingService = ImageProcessingService(
      translatorService: _translatorService,
    );
  }

  Future<void> _loadNoteData() async {
    try {
      print('노트 데이터 로드 시작: $_noteId');
      setState(() {
      });
      
      // 노트 ID가 비어있으면 로드하지 않음
      if (_noteId.isEmpty) {
        print('노트 ID가 비어있어 로드하지 않음');
        setState(() {
        });
        return;
      }
      
      // 캐시에서 먼저 확인
      final prefs = await SharedPreferences.getInstance();
      final cachedNoteJson = prefs.getString('note_$_noteId');
      
      if (cachedNoteJson != null) {
        print('캐시에서 노트 데이터 로드: $_noteId');
        final noteData = jsonDecode(cachedNoteJson);
        
        setState(() {
          _titleController.text = noteData['title'] ?? widget.initialTitle;
          _contentController.text = noteData['content'] ?? widget.initialContent;
          _translatedContentController.text = noteData['translatedText'] ?? widget.initialTranslatedContent ?? '';
          _imageUrl = noteData['imageUrl'] ?? widget.initialImageUrl;
        });
        
        print('캐시에서 노트 데이터 로드 완료');
      }
      
      // Firestore에서 최신 데이터 가져오기
      print('Firestore에서 노트 데이터 로드 시작: $_noteId');
      
      try {
        final noteDoc = await FirebaseFirestore.instance
            .collection('notes')
            .doc(_noteId)
            .get();
        
        if (noteDoc.exists) {
          final noteData = noteDoc.data();
          if (noteData != null) {
            print('Firestore에서 노트 데이터 로드 성공');
            
            setState(() {
              _titleController.text = noteData['title'] ?? widget.initialTitle;
              _contentController.text = noteData['content'] ?? widget.initialContent;
              _translatedContentController.text = noteData['translatedText'] ?? widget.initialTranslatedContent ?? '';
              _imageUrl = noteData['imageUrl'] ?? widget.initialImageUrl;
            });
            
            // 캐시에 저장
            await prefs.setString('note_$_noteId', jsonEncode(noteData));
            
            print('노트 데이터 캐시에 저장 완료');
          } else {
            print('노트 데이터가 null입니다');
            setState(() {
            });
          }
        } else {
          print('노트 문서가 존재하지 않습니다');
          setState(() {
          });
        }
      } catch (e) {
        print('Firestore에서 노트 데이터 로드 오류: $e');
        setState(() {
        });
      }
    } catch (e) {
      print('노트 데이터 로드 오류: $e');
      print('스택 트레이스: ${StackTrace.current}');
      setState(() {
      });
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
    final updatedNote = _note.copyWith(
      highlightedTexts: Set<String>.from(_highlightedTexts),
      updatedAt: DateTime.now(),
    );
    
    await firestore.collection('notes').doc(_note.id).update(updatedNote.toJson());
    
    setState(() {
      _note = updatedNote;
    });
    
    _showMessage('하이라이트가 제거되었습니다');
  }

  Future<void> _addHighlight(String text) async {
    final translatedText = await _translatorService.translate(text, from: 'ko', to: 'zh');
    final pinyin = await pinyinService.getPinyin(text);
    
    final newFlashCard = flash_card_model.FlashCard(
      front: text,
      back: translatedText,
      pinyin: pinyin,
      noteId: _note.id,
      createdAt: DateTime.now(),
      reviewCount: 0,
    );

    // 중복 플래시카드 방지
    final List<flash_card_model.FlashCard> updatedFlashCards = [
      ..._note.flashCards.where((card) => card.front != text),
      newFlashCard,
    ];

    final updatedNote = _note.copyWith(
      flashCards: updatedFlashCards,
      highlightedTexts: {..._highlightedTexts, text},
      updatedAt: DateTime.now(),
    );

    // Firestore 업데이트
    await firestore.collection('notes').doc(_note.id).update(updatedNote.toJson());

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
        imageUrl: _note.pages[pageIndex].imageUrl,
        extractedText: newText,
        translatedText: translatedText,
      );
      
      final updatedPages = List<note_model.Page>.from(_note.pages);
      updatedPages[pageIndex] = updatedPage;
      
      final updatedNote = _note.copyWith(
        pages: updatedPages,
        updatedAt: DateTime.now(),
      );
      
      await firestore.collection('notes').doc(_note.id).update(updatedNote.toJson());
      
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

  Future<void> _deletePage(int pageIndex) async {
    try {
      final updatedPages = List<note_model.Page>.from(_note.pages)
        ..removeAt(pageIndex);
      
      final updatedNote = _note.copyWith(
        pages: updatedPages,
        updatedAt: DateTime.now(),
      );
      
      await firestore.collection('notes').doc(_note.id).update(updatedNote.toJson());
      
      setState(() {
        _note = updatedNote;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('페이지가 삭제되었습니다')),
        );
      }
    } catch (e) {
      print('Error deleting page: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('페이지 삭제 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  void _showEditDialog(int pageIndex, String currentText) {
    final textController = TextEditingController(text: currentText);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '텍스트 수정',
          style: TextStyle(
            color: ColorTokens.semantic['text']['body'],
          ),
        ),
        content: TextField(
          controller: textController,
          maxLines: null,
          decoration: InputDecoration(
            hintText: '중국어 텍스트를 입력하세요',
            hintStyle: TextStyle(
              color: ColorTokens.semantic['text']['body'].withOpacity(0.5),
            ),
          ),
          style: TextStyle(
            color: ColorTokens.semantic['text']['body'],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '취소',
              style: TextStyle(
                color: ColorTokens.semantic['text']['body'],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editPageText(pageIndex, textController.text);
            },
            child: Text(
              '저장',
              style: TextStyle(
                color: ColorTokens.semantic['text']['body'],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewPage(ImageSource source) async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지가 선택되지 않았습니다')),
          );
        }
        return;
      }

      final imageFile = File(pickedFile.path);
      if (!await imageFile.exists()) {
        throw Exception('선택된 이미지 파일이 존재하지 않습니다');
      }

      // 이미지 처리 서비스 사용
      final imagePath = await _imageProcessingService.saveImageLocally(imageFile);
      final extractedText = await _imageProcessingService.extractTextFromImage(await imageFile.readAsBytes());
      final translatedText = await _imageProcessingService.translateText(extractedText);

      // 새 페이지 생성
      final newPage = note_model.Page(
        imageUrl: imagePath,
        extractedText: extractedText,
        translatedText: translatedText,
      );

      // 노트 업데이트
      final updatedNote = _note.copyWith(
        pages: [..._note.pages, newPage],
        updatedAt: DateTime.now(),
      );

      // Firestore 업데이트
      await firestore.collection('notes').doc(_note.id).update(updatedNote.toJson());

      if (mounted) {
        setState(() {
          _note = updatedNote;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('새로운 페이지가 추가되었습니다')),
        );
      }
    } catch (e) {
      print('Error adding new page: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('페이지 추가 중 오류가 발생했습니다: $e')),
        );
      }
    }
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
      print('플래시카드 저장 시작: ${_note.id}, 카드 수: ${_note.flashCards.length}');
      
      // 깊은 복사를 통해 새 객체 생성
      final updatedNote = _note.copyWith(
        flashCards: List<flash_card_model.FlashCard>.from(_note.flashCards),
        updatedAt: DateTime.now(),
      );
      
      // Firestore 업데이트
      await FirebaseFirestore.instance
          .collection('notes')
          .doc(_note.id)
          .update(updatedNote.toJson());
      
      print('플래시카드 저장 완료: ${_note.id}');
      
      // 저장 확인
      final docSnapshot = await FirebaseFirestore.instance
          .collection('notes')
          .doc(_note.id)
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
    print('NoteDetailScreen build: $_noteId');
    // 알고 있는 카드를 제외한 활성 플래시카드만 필터링
    final activeFlashCards = _note.flashCards.where(
      (card) => !_note.knownFlashCards.contains(card.front)
    ).toList();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _note.pages.isEmpty
                  ? Center(
                      child: Text(
                        '페이지가 없습니다. 새 페이지를 추가하세요.',
                        style: TextStyle(
                          color: ColorTokens.semantic['text']['body'],
                        ),
                      ),
                    )
                  : NotePage(
                      page: _note.pages[_currentPageIndex],
                      displayMode: _displayMode,
                      isHighlightMode: _isHighlightMode,
                      highlightedTexts: _highlightedTexts,
                      onHighlighted: _handleTextSelection,
                      onSpeak: (text) {
                        setState(() {
                          _currentPlayingIndex = _currentPageIndex;
                        });
                        _speak(text);
                      },
                      currentPlayingIndex: _currentPlayingIndex,
                      onDeletePage: () => _deletePage(_currentPageIndex),
                      onEditText: (text) => _showEditDialog(_currentPageIndex, text),
                    ),
              ),
              _buildPageControls(),
              if (activeFlashCards.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: FlashcardCounter(
                    flashCards: activeFlashCards,
                    noteTitle: _note.title,
                    noteId: _note.id,
                    knownCount: 0, // 이미 필터링했으므로 0으로 설정
                    onTap: _navigateToFlashcardScreen,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: _handleBackPress,
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Text(
            _titleController.text,
            style: TypographyTokens.getStyle('heading.h1').copyWith(
              color: ColorTokens.getColor('text.body'),
            ),
          ),
        ],
      ),
      actions: [
        // 페이지 숫자 표시
        Text(
          '${_currentPageIndex + 1}/${_note.pages.length} pages',
          style: TypographyTokens.getStyle('body.small').copyWith(
            color: ColorTokens.getColor('base.400'),
          ),
        ),
        const SizedBox(width: 8),  // 8px 간격
        // 플래시카드 카운터 업데이트
        FlashcardCounter(
          flashCards: _note.flashCards,
          noteTitle: _note.title,
          noteId: _note.id,
          alwaysShow: true,
        ),
        const SizedBox(width: 8),  // 우측 여백
        // 하이라이트 모드 상태 확인 버튼
        IconButton(
          icon: Icon(
            _isHighlightMode ? Icons.highlight : Icons.highlight_off,
            color: _isHighlightMode ? Colors.amber : Colors.grey,
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
                  if (_note.pages.isNotEmpty) {
                    _speak(_note.pages[_currentPageIndex].extractedText);
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
            onPressed: _currentPageIndex < _note.pages.length - 1
                ? () {
                    setState(() {
                      _currentPageIndex++;
                    });
                  }
                : null,
            icon: Icon(
              Icons.arrow_forward_ios,
              color: _currentPageIndex < _note.pages.length - 1
                  ? Theme.of(context).iconTheme.color
                  : Theme.of(context).disabledColor,
            ),
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
    print('플래시카드 화면으로 이동: ${_note.id}');
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardScreen(note: _note),
      ),
    );
    
    if (result == true) {
      print('플래시카드 화면에서 돌아옴, 노트 데이터 새로고침');
      _loadNoteData();
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
      setState(() {
      });
      
      final updatedNote = note_model.Note(
        id: _noteId,
        spaceId: _spaceId,
        userId: widget.note?.userId ?? '',
        title: _titleController.text,
        flashcardCount: widget.note?.flashcardCount ?? 0,
        reviewCount: widget.note?.reviewCount ?? 0,
        content: _contentController.text,
        imageUrl: _imageUrl ?? '',
        extractedText: widget.note?.extractedText ?? '',
        translatedText: _translatedContentController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDeleted: false,
      );
      
      await _noteRepository.updateNote(updatedNote);
      print('노트 저장 완료: ${updatedNote.id}');
      
      setState(() {
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('노트가 저장되었습니다')),
      );
    } catch (e) {
      print('노트 저장 오류: $e');
      setState(() {
      });
    }
  }
}



