import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mlw/widgets/note_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:mlw/models/text_display_mode.dart';
import 'package:mlw/services/pinyin_service.dart';
import 'package:mlw/widgets/flashcard_counter.dart';
import 'package:mlw/services/image_processing_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mlw/services/translator_service.dart';
import 'package:mlw/screens/flashcard_screen.dart';
import 'package:mlw/repositories/note_repository.dart';


class NoteDetailScreen extends StatefulWidget {
  final note_model.Note note;

  const NoteDetailScreen({Key? key, required this.note}) : super(key: key);

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
  int _flashCardCount = 0;
  late note_model.Note _note;
  late ImageProcessingService _imageProcessingService;
  bool _isTranslating = false;
  String _translatedText = '';
  bool _isNoteModified = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNoteData();
    _isHighlightMode = true;
    _imageProcessingService = ImageProcessingService(
      translatorService: translatorService,
    );
  }

  Future<void> _loadNoteData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      print('노트 데이터 로드 시작: ${widget.note.id}');
      
      final noteRepository = NoteRepository();
      noteRepository.clearCache();
      
      final loadedNote = await noteRepository.getNote(widget.note.id);
      
      setState(() {
        _note = loadedNote;
        _highlightedTexts = Set<String>.from(loadedNote.highlightedTexts);
        _isLoading = false;
      });
      
      print('노트 데이터 로드 완료: ${widget.note.id}');
      
      // 플래시카드 로드
      print('저장된 플래시카드 수: ${_note.flashCards.length}');
    } catch (e) {
      print('노트 데이터 로드 오류: $e');
      setState(() {
        _error = '노트 데이터를 로드하는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("zh-CN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    if (Platform.isIOS) {
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
        ],
      );
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

  void _toggleHighlightMode() {
    setState(() {
      _isHighlightMode = !_isHighlightMode;
      print('Highlight mode toggled: $_isHighlightMode');
    });
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
      _flashCardCount = _highlightedTexts.length;
    });
    
    // Firestore 업데이트
    final updatedNote = _note.copyWith(
      highlightedTexts: Set<String>.from(_highlightedTexts),
      updatedAt: DateTime.now(),
    );
    
    await firestore.collection('notes').doc(_note.id).update(updatedNote.toFirestore());
    
    setState(() {
      _note = updatedNote;
    });
    
    _showMessage('하이라이트가 제거되었습니다');
  }

  Future<void> _addHighlight(String text) async {
    final translatedText = await translatorService.translate(text, 'zh', sourceLanguage: 'ko');
    final pinyin = await pinyinService.getPinyin(text);
    
    final newFlashCard = note_model.FlashCard(
      front: text,
      back: translatedText,
      pinyin: pinyin,
    );

    // 중복 플래시카드 방지
    final List<note_model.FlashCard> updatedFlashCards = [
      ..._note.flashCards.where((card) => card.front != text),
      newFlashCard,
    ];

    final updatedNote = _note.copyWith(
      flashCards: updatedFlashCards,
      highlightedTexts: {..._highlightedTexts, text},
      updatedAt: DateTime.now(),
    );

    // Firestore 업데이트
    await firestore.collection('notes').doc(_note.id).update(updatedNote.toFirestore());

    // UI 업데이트
    setState(() {
      _note = updatedNote;
      _highlightedTexts = Set<String>.from(updatedNote.highlightedTexts);
      _flashCardCount = _highlightedTexts.length;
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

  void _addToFlashcards(String text) async {
    try {
      final translatedText = await translatorService.translate(text, 'zh', sourceLanguage: 'ko');
      final pinyin = await pinyinService.getPinyin(text);
      
      final newFlashCard = note_model.FlashCard(
        front: text,
        back: translatedText,
        pinyin: pinyin,
      );
      
      final List<note_model.FlashCard> updatedFlashCards = [
        ..._note.flashCards,
        newFlashCard,
      ];

      final updatedNote = _note.copyWith(
        flashCards: updatedFlashCards,
        updatedAt: DateTime.now(),
      );
      
      // Firestore 업데이트
      await firestore.collection('notes').doc(_note.id).update(updatedNote.toFirestore());
      
      // UI 업데이트
      setState(() {
        _note = updatedNote;
        _highlightedTexts.add(text);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('플래시카드가 추가되었습니다')),
        );
      }
    } catch (e) {
      print('Error adding flashcard: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('플래시카드 추가 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _editPageText(int pageIndex, String newText) async {
    try {
      final translatedText = await translatorService.translate(newText, 'zh', sourceLanguage: 'ko');
      
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
      
      await firestore.collection('notes').doc(_note.id).update(updatedNote.toFirestore());
      
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
      
      await firestore.collection('notes').doc(_note.id).update(updatedNote.toFirestore());
      
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
      await firestore.collection('notes').doc(_note.id).update(updatedNote.toFirestore());

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
      _isTranslating = true;
      _translatedText = '번역 중...';  // 로딩 표시
    });
    
    try {
      // 사용자 설정에서 대상 언어 가져오기
      final prefs = await SharedPreferences.getInstance();
      final targetLanguage = prefs.getString('target_language') ?? '한국어';
      // 번역 서비스 호출
      final translatedText = await translatorService.translate(text, targetLanguage, sourceLanguage: 'auto');
      
      setState(() {
        _translatedText = translatedText;
        _isTranslating = false;
      });
    } catch (e) {
      print('번역 오류: $e');
      setState(() {
        _translatedText = 'Sorry, an error occurred during translation. Please try again later.';
        _isTranslating = false;
      });
    }
  }

  Future<void> _saveFlashCards() async {
    try {
      print('플래시카드 저장 시작: ${_note.id}, 카드 수: ${_note.flashCards.length}');
      
      // 깊은 복사를 통해 새 객체 생성
      final updatedNote = _note.copyWith(
        flashCards: List<note_model.FlashCard>.from(_note.flashCards),
        updatedAt: DateTime.now(),
      );
      
      // Firestore 업데이트
      await FirebaseFirestore.instance
          .collection('notes')
          .doc(_note.id)
          .update(updatedNote.toFirestore());
      
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
            _note.title,
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
      print('노트 저장 시작: ${_note.id}, 제목: ${_note.title}');
      
      // 깊은 복사를 통해 새 객체 생성
      final updatedNote = _note.copyWith(
        flashCards: List<note_model.FlashCard>.from(_note.flashCards),
        highlightedTexts: Set<String>.from(_highlightedTexts),
        updatedAt: DateTime.now(),
      );
      
      // Firestore 업데이트
      await FirebaseFirestore.instance
          .collection('notes')
          .doc(_note.id)
          .update(updatedNote.toFirestore());
      
      print('노트 저장 완료: ${_note.id}');
      
      // 저장 확인
      final docSnapshot = await FirebaseFirestore.instance
          .collection('notes')
          .doc(_note.id)
          .get();
      
      if (docSnapshot.exists) {
        final savedNote = note_model.Note.fromFirestore(docSnapshot);
        print('저장된 노트: ${savedNote.id}, 제목: ${savedNote.title}');
      }
      
      setState(() {
        _isNoteModified = false;
      });
    } catch (e) {
      print('노트 저장 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('노트 저장 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }
}



