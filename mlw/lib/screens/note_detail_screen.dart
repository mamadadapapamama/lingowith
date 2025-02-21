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
  final translatorService = TranslatorService();

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
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
                      onEditText: (String newText) async {
                        try {
                          // Get the current page
                          final currentPage = widget.note.pages[index];
                          
                          // Translate the new text
                          final translatedText = await translatorService.translate(
                            newText,
                            from: 'zh',
                            to: 'ko',
                          );

                          // Create a single TextBlock for now (simplified version)
                          final textBlock = note_model.TextBlock(
                            text: newText,
                            translation: translatedText,
                            x: 0,
                            y: 0,
                            width: 0,
                            height: 0,
                          );

                          // Create updated page with new text block
                          final updatedPage = note_model.Page(
                            imageUrl: currentPage.imageUrl,
                            textBlocks: [textBlock],
                          );

                          // Update the pages list
                          final updatedPages = List<note_model.Page>.from(widget.note.pages)
                            ..[index] = updatedPage;

                          // Update the note with the new pages
                          final updatedNote = widget.note.copyWith(
                            pages: updatedPages,
                            updatedAt: DateTime.now(),
                          );

                          // Update in Firestore
                          await firestore.collection('notes').doc(widget.note.id)
                            .update(updatedNote.toFirestore());

                          if (mounted) {
                            setState(() {
                              widget.note.pages[index] = updatedPage;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('텍스트가 수정되었습니다')),
                            );
                          }
                        } catch (e) {
                          print('Error editing text: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('텍스트 수정 중 오류가 발생했습니다: $e')),
                            );
                          }
                        }
                      },
                      onDeletePage: () async {
                        try {
                          // Remove the page from the note
                          final updatedPages = List<note_model.Page>.from(widget.note.pages)
                            ..removeAt(index);
                          
                          // Update the note with the new pages list
                          final updatedNote = widget.note.copyWith(
                            pages: updatedPages,
                            updatedAt: DateTime.now(),
                          );

                          // Update in Firestore
                          await firestore.collection('notes').doc(widget.note.id)
                            .update(updatedNote.toFirestore());

                          if (mounted) {
                            setState(() {
                              widget.note.pages.removeAt(index);
                            });
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
          FloatingActionButton(
            onPressed: () => _showImageSourceActionSheet(context),
            backgroundColor: ColorTokens.semantic['surface']['button']['secondary'],
            child: SvgPicture.asset(
              'assets/icon/addimage.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                ColorTokens.semantic['text']['primary'],
                BlendMode.srcIn,
              ),
            ),
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

  Future<List<note_model.TextBlock>> _extractTextFromImage(List<int> imageBytes) async {
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
          return [];
        }

        final texts = response.responses!.first.textAnnotations;
        if (texts == null || texts.isEmpty) return [];

        // Skip the first annotation which contains the entire text
        final blocks = texts.skip(1).where((block) {
          final text = block.description ?? '';
          // Only include blocks with Chinese characters
          return RegExp(r'[\u4e00-\u9fa5]').hasMatch(text);
        }).toList();

        // Translate all blocks at once
        final textsToTranslate = blocks.map((block) => block.description ?? '').toList();
        final translations = await translatorService.translateBatch(textsToTranslate, from: 'zh', to: 'ko');

        // Create TextBlocks with translations
        return List.generate(blocks.length, (index) {
          final block = blocks[index];
          final boundingBox = block.boundingPoly?.vertices;
          
          // Calculate position and size from bounding box
          double x = 0, y = 0, width = 0, height = 0;
          if (boundingBox != null && boundingBox.length == 4) {
            x = boundingBox[0].x?.toDouble() ?? 0;
            y = boundingBox[0].y?.toDouble() ?? 0;
            width = ((boundingBox[1].x ?? 0) - (boundingBox[0].x ?? 0)).toDouble();
            height = ((boundingBox[2].y ?? 0) - (boundingBox[0].y ?? 0)).toDouble();
          }

          return note_model.TextBlock(
            text: block.description ?? '',
            translation: translations[index],
            x: x,
            y: y,
            width: width,
            height: height,
          );
        });

      } finally {
        client.close();
      }
    } catch (e) {
      print('Vision API error: $e');
      rethrow;
    }
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
      
      // Extract text and get translations
      final textBlocks = await _extractTextFromImage(await imageFile.readAsBytes());

      // Create a new page
      final newPage = note_model.Page(
        imageUrl: imagePath,
        textBlocks: textBlocks,
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
}

