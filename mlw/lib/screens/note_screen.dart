import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';  // TimeoutException을 위한 import 추가
import 'package:mlw/models/note.dart';
import 'package:mlw/services/note_repository.dart';
import 'package:mlw/screens/note_detail_screen.dart';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:googleapis_auth/auth_io.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mlw/services/translator.dart';

class NoteScreen extends StatefulWidget {
  final String spaceId;  // 노트 스페이스 ID 추가
  final String userId;   // 사용자 ID 추가

  const NoteScreen({
    super.key,
    required this.spaceId,
    required this.userId,
  });

  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  String? _extractedText;
  bool _isProcessing = false;

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
        requestFullMetadata: true,
      );
      
      if (pickedFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지가 선택되지 않았습니다.')),
          );
        }
        return;
      }

      setState(() {
        _image = File(pickedFile.path);
        _isProcessing = true;
      });

      // 이미지 처리를 비동기로 처리
      unawaited(_processImage(pickedFile));
      
    } catch (e) {
      print('Image picking error: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _image = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 선택 중 오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _processImage(XFile pickedFile) async {
    try {
      final imageBytes = await _image!.readAsBytes();
      final text = await _extractTextFromImage(imageBytes);
      
      if (mounted) {
        setState(() {
          _extractedText = text;
          _isProcessing = false;
        });
        await _createNote();
      }
    } catch (e) {
      print('Image processing error: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
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
            imageContext: vision.ImageContext(
              languageHints: ['zh'],
            ),
          ),
        ]);
        
        final response = await api.images.annotate(request)
          .timeout(const Duration(seconds: 30));  // 타임아웃 추가

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

  Future<void> _createNote() async {
    if (_image == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final imagePath = await _saveImageLocally(_image!);
      
      // OCR 텍스트 번역
      String? translatedText;
      if (_extractedText != null) {
        try {
          final lines = _extractedText!.split('\n').where((s) => s.trim().isNotEmpty).toList();
          final translatedLines = await Future.wait(
            lines.map((line) => translatorService.translate(line, from: 'zh', to: 'ko'))
          );
          translatedText = translatedLines.join('\n');
        } catch (e) {
          print('Translation error: $e');
        }
      }
      
      final repository = NoteRepository();
      final newNote = Note(
        id: '',
        spaceId: widget.spaceId,  // 전달받은 spaceId 사용
        userId: widget.userId,     // 전달받은 userId 사용
        title: _extractedText?.split('\n').first ?? '새로운 노트',
        content: '',
        imageUrl: imagePath,
        extractedText: _extractedText,
        translatedText: translatedText,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdNote = await repository.createNote(newNote);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NoteDetailScreen(note: createdNote),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('노트 생성 실패: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새로운 노트'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          if (_image != null)
            Expanded(
              child: Stack(
                children: [
                  Image.file(_image!),
                  if (_isProcessing)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          if (_extractedText != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_extractedText!),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library),
                  onPressed: () => _getImage(ImageSource.gallery),
                  tooltip: '갤러리에서 선택',
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () => _getImage(ImageSource.camera),
                  tooltip: '사진 촬영',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
