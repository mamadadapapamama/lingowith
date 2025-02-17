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
import 'package:permission_handler/permission_handler.dart';

class NoteScreen extends StatefulWidget {
  final String spaceId;
  final String userId;

  const NoteScreen({
    super.key,
    required this.spaceId,
    required this.userId,
  });

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final ImagePicker _picker = ImagePicker();
  final NoteRepository _noteRepository = NoteRepository();
  File? _image;
  String? _extractedText;
  bool _isProcessing = false;

  Future<bool> _requestPermission(Permission permission) async {
    // iOS에서는 시뮬레이터에서 항상 권한이 있다고 가정
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      bool hasPermission;
      if (source == ImageSource.camera) {
        hasPermission = await _requestPermission(Permission.camera);
      } else {
        hasPermission = Platform.isIOS 
            ? await _requestPermission(Permission.photos)
            : await _requestPermission(Permission.storage);
      }

      if (!hasPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지를 선택하려면 권한을 허용해주세요.')),
          );
        }
        return;
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (pickedFile == null) {
        if (mounted) {
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

      setState(() {
        _image = imageFile;
        _isProcessing = true;
      });

      await _processImage(pickedFile);
      
    } catch (e) {
      print('Image picking error: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _image = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')),
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

      final createdNote = await _noteRepository.createNote(newNote);
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
  void initState() {
    super.initState();
    print('NoteScreen initialized');
    print('spaceId: ${widget.spaceId}');
    print('userId: ${widget.userId}');
    
    // 권한 체크를 미리 수행
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final cameraStatus = await Permission.camera.status;
      final photosStatus = Platform.isIOS 
          ? await Permission.photos.status
          : await Permission.storage.status;
      
      print('Camera permission status: $cameraStatus');
      print('Photos/Storage permission status: $photosStatus');
    } catch (e) {
      print('Error checking permissions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('Building NoteScreen');
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
                  Image.file(
                    _image!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('Image error: $error');
                      return const Center(
                        child: Text('이미지를 불러올 수 없습니다.'),
                      );
                    },
                  ),
                  if (_isProcessing)
                    Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
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
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('갤러리'),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('카메라'),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
