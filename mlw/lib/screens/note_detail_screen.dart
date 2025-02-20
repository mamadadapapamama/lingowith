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
import 'package:mlw/screens/flashcard_screen.dart';
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

  @override
  void initState() {
    super.initState();
    highlightedTexts = widget.note.flashCards.map((card) => card.front).toSet();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.note.title,
          style: theme.textTheme.headlineMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.style),
            onPressed: () {
              if (widget.note.flashCards.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FlashCardScreen(
                      flashCards: widget.note.flashCards,
                      noteId: widget.note.id,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('플래시카드가 없습니다')),
                );
              }
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Text(
                '${widget.note.flashCards.length}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: widget.note.pages.isEmpty
          ? Center(
              child: Text(
                '페이지가 없습니다',
                style: theme.textTheme.bodyLarge,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: widget.note.pages.length,
              itemBuilder: (context, index) {
                final page = widget.note.pages[index];
                return Column(
                  children: [
                    NotePage(
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
                      onDeletePage: () {
                        // TODO: Implement page deletion
                      },
                      onEditText: (text) {
                        // TODO: Implement text editing
                      },
                      onToggleTranslation: () {
                        setState(() {
                          showTranslation = !showTranslation;
                        });
                      },
                      onToggleHighlight: () {
                        _toggleHighlightMode();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (isHighlightMode && selectedText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton.extended(
                onPressed: () => _addToFlashcards(selectedText!),
                label: const Text('플래시카드 추가'),
                icon: const Icon(Icons.add),
                backgroundColor: theme.colorScheme.secondary,
              ),
            ),
          FloatingActionButton(
            onPressed: () => _showImageSourceActionSheet(context),
            backgroundColor: theme.colorScheme.secondary,
            child: const Icon(Icons.add_photo_alternate),
          ),
        ],
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
}

