import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mlw/widgets/note_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mlw/services/translator.dart';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:googleapis_auth/auth_io.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/screens/flash_card_screen.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mlw/models/text_display_mode.dart';
import 'package:mlw/models/flash_card.dart';
import 'package:mlw/services/pinyin_service.dart';


class NoteDetailScreen extends StatefulWidget {
  final note_model.Note note;

  const NoteDetailScreen({Key? key, required this.note}) : super(key: key);

  @override
  _NoteDetailScreenState createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool showTranslation = true;
  bool isHighlightMode = false;
  String? selectedText;
  int? _currentPlayingIndex;
  Set<String> highlightedTexts = {};
  int _currentPageIndex = 0;
  TextDisplayMode _displayMode = TextDisplayMode.both;

  @override
  void initState() {
    super.initState();
    highlightedTexts = widget.note.flashCards.map((card) => card.front).toSet();
    _initTTS();
  }

  Future<void> _initTTS() async {
    try {
      await _flutterTts.setLanguage('zh-CN');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      if (Platform.isIOS) {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.ambient,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
        );
      }
    } catch (e) {
      print('TTS initialization error: $e');
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
      isHighlightMode = !isHighlightMode;
      selectedText = null;
    });
  }

  void _onTextSelected(String text) async {
    try {
      if (highlightedTexts.contains(text)) {
        return;
      }

      final translatedText = await translatorService.translate(text, from: 'zh', to: 'ko');
      final pinyin = await pinyinService.getPinyin(text);
      
      final newFlashCard = note_model.FlashCard(
        front: text,
        back: translatedText,
        pinyin: pinyin,
      );

      // 노트 업데이트
      final updatedFlashCards = [...widget.note.flashCards, newFlashCard];
      final updatedNote = widget.note.copyWith(
        flashCards: updatedFlashCards,
        updatedAt: DateTime.now(),
      );

      // Firestore 업데이트
      await firestore.collection('notes').doc(widget.note.id).update(updatedNote.toFirestore());

      // UI 업데이트
      setState(() {
        widget.note.flashCards.add(newFlashCard);
        highlightedTexts.add(text);
      });

      // 알림 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('플래시카드에 저장되었습니다'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error saving flashcard: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('플래시카드 저장 중 오류가 발생했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<String> getPinyin(String text) async {
    // TODO: pinyin API 연동
    // 임시로 더미 데이터 반환
    return 'mao he gou shi hao peng you';
  }

  void _addToFlashcards(String text) async {
    try {
      final translatedText = await translatorService.translate(text, from: 'zh', to: 'ko');
      final pinyin = await pinyinService.getPinyin(text);
      
      final newFlashCard = note_model.FlashCard(
        front: text,
        back: translatedText,
        pinyin: pinyin,
      );
      
      final updatedNote = widget.note.copyWith(
        flashCards: [...widget.note.flashCards, newFlashCard],
        updatedAt: DateTime.now(),
      );
      
      // Update Firestore
      await firestore.collection('notes').doc(widget.note.id).update(updatedNote.toFirestore());
      
      // Update local state
      setState(() {
        widget.note.flashCards.add(newFlashCard);
        highlightedTexts.add(text);
        selectedText = null;
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
      // Translate the new text
      final translatedText = await translatorService.translate(newText, from: 'zh', to: 'ko');
      
      // Create a new page with updated text
      final updatedPage = note_model.Page(
        imageUrl: widget.note.pages[pageIndex].imageUrl,
        extractedText: newText,
        translatedText: translatedText,
      );
      
      // Update the note with the new page
      final updatedPages = List<note_model.Page>.from(widget.note.pages);
      updatedPages[pageIndex] = updatedPage;
      
      final updatedNote = widget.note.copyWith(
        pages: updatedPages,
        updatedAt: DateTime.now(),
      );
      
      // Update in Firestore
      await firestore.collection('notes').doc(widget.note.id).update(updatedNote.toFirestore());
      
      setState(() {
        widget.note.pages[pageIndex] = updatedPage;
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
      final updatedPages = List<note_model.Page>.from(widget.note.pages)
        ..removeAt(pageIndex);
      
      final updatedNote = widget.note.copyWith(
        pages: updatedPages,
        updatedAt: DateTime.now(),
      );
      
      // Update in Firestore
      await firestore.collection('notes').doc(widget.note.id).update(updatedNote.toFirestore());
      
      setState(() {
        widget.note.pages.removeAt(pageIndex);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                color: ColorTokens.getColor('text.body'),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  Text(
                    widget.note.title,
                    style: TypographyTokens.getStyle('body.medium').copyWith(
                      color: ColorTokens.getColor('text.body'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${_currentPageIndex + 1}/${widget.note.pages.length} pages)',
                    style: TypographyTokens.getStyle('body.small').copyWith(
                      color: ColorTokens.getColor('base.400'),
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Stack(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _openFlashCards,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ColorTokens.getColor('tertiary.400'),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  'assets/icon/flashcard_color.svg',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.note.flashCards.length.toString(),
                                  style: TypographyTokens.getStyle('button.small').copyWith(
                                    color: ColorTokens.getColor('secondary.500'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Ripple effect overlay for tertiary.500 on tap
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _openFlashCards,
                            borderRadius: BorderRadius.circular(8),
                            highlightColor: ColorTokens.getColor('tertiary.500').withOpacity(0.1),
                            splashColor: ColorTokens.getColor('tertiary.500').withOpacity(0.2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Progress bar
            Stack(
              children: [
                // 배경 바
                Container(
                  width: double.infinity,
                  height: 4,
                  color: ColorTokens.getColor('base.200'),
                ),
                // 진행률 바
                Container(
                  width: MediaQuery.of(context).size.width * 
                    (widget.note.pages.isEmpty ? 0 : (_currentPageIndex + 1) / widget.note.pages.length),
                  height: 4,
                  color: ColorTokens.getColor('secondary.400'),
                ),
              ],
            ),
            // 페이지 컨텐츠
            Expanded(
              child: PageView.builder(
                itemCount: widget.note.pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = widget.note.pages[index];
                  return NotePage(
                    page: page,
                    displayMode: _displayMode,
                    isHighlightMode: isHighlightMode,
                    highlightedTexts: highlightedTexts,
                    onHighlighted: _onTextSelected,
                    onSpeak: (text) {
                      setState(() {
                        _currentPlayingIndex = index;
                      });
                      _speak(text);
                    },
                    currentPlayingIndex: _currentPlayingIndex,
                    onDeletePage: () => _deletePage(index),
                    onEditText: (text) => _showEditDialog(index, text),
                  );
                },
              ),
            ),

            // 하단 컨트롤 바
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -1),
                    blurRadius: 8,
                  ),
                ],
              ),
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
                          if (widget.note.pages.isNotEmpty) {
                            _speak(widget.note.pages[_currentPageIndex].extractedText);
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
                    onPressed: _currentPageIndex < widget.note.pages.length - 1
                        ? () {
                            setState(() {
                              _currentPageIndex++;
                            });
                          }
                        : null,
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: _currentPageIndex < widget.note.pages.length - 1
                          ? Theme.of(context).iconTheme.color
                          : Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImageSourceActionSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.of(context).pop();
                _addNewPage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Navigator.of(context).pop();
                _addNewPage(ImageSource.camera);
              },
            ),
          ],
        ),
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

      // Save the image locally
      final imagePath = await _saveImageLocally(imageFile);
      
      // Extract text from the image
      final extractedText = await _extractTextFromImage(await imageFile.readAsBytes());
      
      // Translate the extracted text
      String translatedText = '';
      if (extractedText.isNotEmpty) {
        translatedText = await translatorService.translate(extractedText, from: 'zh', to: 'ko');
      }

      // Create a new page
      final newPage = note_model.Page(
        imageUrl: imagePath,
        extractedText: extractedText,
        translatedText: translatedText,
      );

      // Update the note with the new page
      final updatedNote = widget.note.copyWith(
        pages: [...widget.note.pages, newPage],
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      await firestore.collection('notes').doc(widget.note.id).update(updatedNote.toFirestore());

      if (mounted) {
        setState(() {
          widget.note.pages.add(newPage);
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

  Future<String> _saveImageLocally(File image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await image.copy('${directory.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      print('Error saving image: $e');
      rethrow;
    }
  }

  Future<String> _extractTextFromImage(List<int> imageBytes) async {
    try {
      final keyJson = await rootBundle.loadString('assets/service-account-key.json');
      final credentials = ServiceAccountCredentials.fromJson(keyJson);
      final client = await clientViaServiceAccount(credentials, [vision.VisionApi.cloudVisionScope]);
      final api = vision.VisionApi(client);

      try {
        final request = vision.BatchAnnotateImagesRequest(requests: [
          vision.AnnotateImageRequest(
            image: vision.Image(content: base64Encode(imageBytes)),
            features: [vision.Feature(type: 'TEXT_DETECTION')],
            imageContext: vision.ImageContext(languageHints: ['zh']),
          ),
        ]);
        
        final response = await api.images.annotate(request)
          .timeout(const Duration(seconds: 30));

        if (response.responses == null || response.responses!.isEmpty) {
          return '';
        }

        final texts = response.responses!.first.textAnnotations;
        if (texts == null || texts.isEmpty) return '';

        final lines = texts.first.description?.split('\n') ?? [];
        final chineseLines = lines.where((line) {
          final hasChineseChar = RegExp(r'[\u4e00-\u9fa5]').hasMatch(line);
          final isOnlyNumbers = RegExp(r'^[0-9\s]*$').hasMatch(line);
          return hasChineseChar && !isOnlyNumbers;
        }).toList();

        return chineseLines.join('\n');
      } finally {
        client.close();
      }
    } catch (e) {
      print('Vision API error: $e');
      rethrow;
    }
  }

  void _openFlashCards() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashCardScreen(
          flashCards: widget.note.flashCards,
          title: widget.note.title,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}


