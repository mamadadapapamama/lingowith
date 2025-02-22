import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mlw/widgets/text_highlighter.dart';
import 'package:mlw/widgets/note_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mlw/services/translator.dart';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:googleapis_auth/auth_io.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/screens/flash_card_screen.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:mlw/repositories/note_repository.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  void _onTextSelected(String text) {
    setState(() {
      selectedText = text;
    });
  }

  void _addToFlashcards(String text) async {
    try {
      final translation = await translatorService.translate(text, from: 'zh', to: 'ko');
      
      final newFlashCard = note_model.FlashCard(
        front: text,
        back: translation,
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
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.note.title,
                      style: theme.textTheme.headlineMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (widget.note.flashCards.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FlashCardScreen(
                              flashCards: widget.note.flashCards,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.style,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.note.flashCards.length}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            if (widget.note.pages.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Page ${_currentPageIndex + 1} of ${widget.note.pages.length}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: ((_currentPageIndex + 1) / widget.note.pages.length),
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

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
                    showTranslation: showTranslation,
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
                color: theme.scaffoldBackgroundColor,
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
                          ? theme.iconTheme.color
                          : theme.disabledColor,
                    ),
                  ),
                  
                  // 모드 토글 버튼
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            showTranslation = !showTranslation;
                          });
                        },
                        icon: Icon(
                          Icons.translate,
                          color: showTranslation
                              ? theme.colorScheme.primary
                              : theme.disabledColor,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (widget.note.pages.isNotEmpty) {
                            _speak(widget.note.pages[_currentPageIndex].extractedText);
                          }
                        },
                        icon: Icon(
                          Icons.volume_up,
                          color: _currentPlayingIndex == _currentPageIndex
                              ? theme.colorScheme.primary
                              : theme.iconTheme.color,
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
                          ? theme.iconTheme.color
                          : theme.disabledColor,
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

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}

