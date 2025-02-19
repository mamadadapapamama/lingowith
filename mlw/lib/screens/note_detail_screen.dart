import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mlw/widgets/text_highlighter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:mlw/services/translator.dart';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:googleapis_auth/auth_io.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/screens/flashcard_screen.dart'; // Import FlashCardScreen
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';

class NoteDetailScreen extends StatefulWidget {
  final note_model.Note note;

  NoteDetailScreen({Key? key, required this.note}) : super(key: key);

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
  Set<String> highlightedTexts = {};  // 하이라이트된 텍스트들을 저장

  @override
  void initState() {
    super.initState();
    // 플래시카드에 있는 텍스트들을 하이라이트된 텍스트 목록에 추가
    highlightedTexts = widget.note.flashCards.map((card) => card.text).toSet();
  }

  Future<void> _speak(String text) async {
    try {
      await _flutterTts.setLanguage('zh-CN');
      await _flutterTts.speak(text);
    } catch (e) {
      print('TTS error: $e');
    }
  }

  void _toggleHighlightMode() {
    setState(() {
      isHighlightMode = !isHighlightMode;
      selectedText = null; // Clear selection when toggling mode
    });
  }

  void _onTextSelected(String text) {
    setState(() {
      selectedText = text;
    });
  }

  void _addToFlashcards(String text) {
    setState(() {
      widget.note.flashCards.add(note_model.FlashCard(
        id: '',
        noteId: widget.note.id,
        text: text,
        createdAt: DateTime.now(),
      ));
      highlightedTexts.add(text);  // 하이라이트된 텍스트 목록에 추가
      selectedText = null;
    });
  }

  Future<bool> _requestPermission(BuildContext context, Permission permission) async {
    if (Platform.isIOS && !await Permission.photos.isRestricted) {
      return true;
    }

    if (await permission.isGranted) {
      return true;
    }
    
    final status = await permission.request();
    
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        final shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('권한 필요'),
            content: const Text('이 기능을 사용하기 위해서는 설정에서 권한을 허용해주세요.'),
            actions: [
              TextButton(
                child: const Text('취소'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text('설정으로 이동'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );
        
        if (shouldOpenSettings == true) {
          await openAppSettings();
        }
      }
      return false;
    }
    
    return status.isGranted;
  }

  Future<void> _pickImage(BuildContext context) async {
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
                _selectImage(context, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Navigator.of(context).pop();
                _selectImage(context, ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectImage(BuildContext context, ImageSource source) async {
    try {
      bool hasPermission;
      if (source == ImageSource.camera) {
        hasPermission = await _requestPermission(context, Permission.camera);
      } else {
        hasPermission = Platform.isIOS 
            ? await _requestPermission(context, Permission.photos)
            : await _requestPermission(context, Permission.storage);
      }

      if (!hasPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지를 선택하려면 권한을 허용해주세요.')),
          );
        }
        return;
      }

      final XFile? pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (pickedFile == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지가 선택되지 않았습니다.')),
          );
        }
        return;
      }

      final imageFile = File(pickedFile.path);
      if (!await imageFile.exists()) {
        throw Exception('선택된 이미지 파일이 존재하지 않습니다.');
      }

      // Process the image
      await _processImage(context, imageFile);
      
    } catch (e) {
      print('Image picking error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _processImage(BuildContext context, File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final text = await _extractTextFromImage(imageBytes);
      
      // Create a new page with the image and extracted text
      final newPage = note_model.Page(
        imageUrl: imageFile.path,
        extractedText: text,
        translatedText: await translatorService.translate(text, from: 'zh', to: 'ko'),
      );

      // Update the note with the new page
      final updatedNote = widget.note.addPage(newPage);

      // Log the new page creation
      print('New page created: ${newPage.imageUrl}');

      // Update Firestore with the updated note
      await firestore.collection('notes').doc(widget.note.id).update(updatedNote.toFirestore());

      // Log Firestore update
      print('Firestore updated with new page');

      // Refresh the UI
      setState(() {
        widget.note.pages.add(newPage);
      });

      // Log UI refresh
      print('UI refreshed with new page');

    } catch (e) {
      print('Image processing error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 처리 중 오류가 발생했습니다: $e')),
        );
      }
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

  final translatorService = TranslatorService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.semantic['surface']?['background'],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: ColorTokens.semantic['text']?['body'],
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.note.title,
          style: TypographyTokens.getStyle('h1').copyWith(
            color: ColorTokens.semantic['text']?['heading'],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.style,
              color: ColorTokens.semantic['text']?['body'],
            ),
            onPressed: () {
              if (widget.note.flashCards.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FlashCardScreen(flashCards: widget.note.flashCards),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No flashcards available.')),
                );
              }
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: ColorTokens.primary[100],
              child: Text(
                '${widget.note.flashCards.length}',
                style: GoogleFonts.poppins(
                  color: ColorTokens.primary[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: widget.note.pages.length,
          itemBuilder: (context, index) {
            final page = widget.note.pages[index];
            final lines = page.extractedText.split('\n');
            final translatedLines = page.translatedText.split('\n');
            return Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: ColorTokens.semantic['border']?['base'] ?? Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(page.imageUrl),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (int i = 0; i < lines.length; i++) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.volume_up,
                                  color: _currentPlayingIndex == i 
                                    ? ColorTokens.secondary[200]
                                    : ColorTokens.secondary[100],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _currentPlayingIndex = i;
                                  });
                                  _speak(lines[i].trim());
                                },
                              ),
                              Expanded(
                                child: TextHighlighter(
                                  text: lines[i].trim(),
                                  onHighlighted: _onTextSelected,
                                  isHighlightMode: isHighlightMode,
                                  highlightedTexts: highlightedTexts.toList(),
                                  style: TypographyTokens.getStyle('body').copyWith(
                                    color: ColorTokens.semantic['text']?['body'],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (showTranslation && i < translatedLines.length && translatedLines[i].trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 56, top: 4, bottom: 8),
                              child: Text(
                                translatedLines[i].trim(),
                                style: TypographyTokens.getButtonStyle(isSmall: true).copyWith(
                                  color: ColorTokens.semantic['text']?['translation'],
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (i < lines.length - 1)
                        const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ToggleButtons(
                          borderRadius: BorderRadius.circular(8),
                          selectedColor: ColorTokens.primary[400],
                          fillColor: ColorTokens.primary[50],
                          color: ColorTokens.semantic['text']?['body'],
                          constraints: const BoxConstraints(
                            minHeight: 36,
                            minWidth: 36,
                          ),
                          isSelected: [showTranslation, false, isHighlightMode],
                          onPressed: (int index) {
                            setState(() {
                              if (index == 0) {
                                showTranslation = !showTranslation;
                              } else if (index == 2) {
                                _toggleHighlightMode();
                              }
                            });
                          },
                          children: const [
                            Icon(Icons.translate),
                            Icon(Icons.text_fields),
                            Icon(Icons.highlight),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isHighlightMode)
            FloatingActionButton.extended(
              onPressed: selectedText != null 
                  ? () {
                      _addToFlashcards(selectedText!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('플래시카드가 추가되었습니다')),
                      );
                    } 
                  : null,
              label: const Text('플래시카드 추가'),
              icon: const Icon(Icons.add),
              backgroundColor: selectedText != null 
                  ? (ColorTokens.semantic['surface']?['button-primary'] as Color?) ?? Colors.orange
                  : Colors.grey,
            ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _showImageSourceActionSheet,
            child: const Icon(Icons.add_photo_alternate),
            backgroundColor: (ColorTokens.semantic['surface']?['button-primary'] as Color?) ?? Colors.orange,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _showImageSourceActionSheet() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(
                '갤러리에서 선택',
                style: GoogleFonts.poppins(),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _addNewPage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(
                '카메라로 촬영',
                style: GoogleFonts.poppins(),
              ),
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
            SnackBar(content: Text(
              '이미지가 선택되지 않았습니다.',
              style: GoogleFonts.poppins(),
            )),
          );
        }
        return;
      }

      final imageFile = File(pickedFile.path);
      if (!await imageFile.exists()) {
        throw Exception('선택된 이미지 파일이 존재하지 않습니다.');
      }

      // Save the image locally
      final imagePath = await _saveImageLocally(imageFile);
      
      // Extract text from the image
      final extractedText = await _extractTextFromImage(await imageFile.readAsBytes());
      
      // Translate the extracted text
      String translatedText = '';
      if (extractedText.isNotEmpty) {
        final lines = extractedText.split('\n').where((s) => s.trim().isNotEmpty).toList();
        final translatedLines = await Future.wait(
          lines.map((line) => translatorService.translate(line, from: 'zh', to: 'ko'))
        );
        translatedText = translatedLines.join('\n');
      }

      // Create a new page
      final newPage = note_model.Page(
        imageUrl: imagePath,
        extractedText: extractedText,
        translatedText: translatedText,
      );

      // Update the note with the new page
      final updatedPages = [...widget.note.pages, newPage];
      final updatedNote = widget.note.copyWith(
        pages: updatedPages,
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      await firestore.collection('notes').doc(widget.note.id).update(updatedNote.toFirestore());

      if (mounted) {
        setState(() {
          widget.note.pages.add(newPage);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            '새로운 페이지가 추가되었습니다.',
            style: GoogleFonts.poppins(),
          )),
        );
      }

    } catch (e) {
      print('Error adding new page: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            '페이지 추가 중 오류가 발생했습니다: $e',
            style: GoogleFonts.poppins(),
          )),
        );
      }
    }
  }
}

