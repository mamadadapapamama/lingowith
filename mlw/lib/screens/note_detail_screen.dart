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

class NoteDetailScreen extends StatefulWidget {
  final note_model.Note note;

  NoteDetailScreen({Key? key, required this.note}) : super(key: key);

  @override
  _NoteDetailScreenState createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage('zh-CN');
    await _flutterTts.speak(text);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: widget.note.pages.length,
          itemBuilder: (context, index) {
            final page = widget.note.pages[index];
            bool showTranslation = false; // Default to false to show only detected text
            final lines = page.extractedText.split('\n'); // Split text into lines
            final translatedLines = page.translatedText.split('\n');
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.file(
                      File(page.imageUrl),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                    ),
                    const SizedBox(height: 8),
                    for (int i = 0; i < lines.length; i++) ...[
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.volume_up),
                            onPressed: () => _speak(lines[i].trim()),
                          ),
                          Expanded(
                            child: Text(
                              lines[i].trim(),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                      if (showTranslation && i < translatedLines.length) ...[
                        const SizedBox(height: 8),
                        Text(
                          translatedLines[i].trim(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        ToggleButtons(
                          children: const [
                            Icon(Icons.translate),
                            Icon(Icons.text_fields),
                            Icon(Icons.highlight),
                          ],
                          isSelected: [showTranslation, false, false],
                          onPressed: (int index) {
                            if (index == 0) {
                              // Toggle translation visibility
                              setState(() {
                                showTranslation = !showTranslation;
                              });
                            } else if (index == 2) {
                              // Enable highlight mode
                              setState(() {
                                // Logic to enable highlight mode
                              });
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.edit),
                                    title: const Text('Edit'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      // Logic to edit detected text
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.delete),
                                    title: const Text('Delete'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      // Logic to delete page
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _pickImage(context);
        },
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

