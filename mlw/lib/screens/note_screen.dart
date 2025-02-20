import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/services/note_repository.dart';
import 'package:mlw/screens/note_detail_screen.dart';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:googleapis_auth/auth_io.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mlw/services/translator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  void initState() {
    super.initState();
    print('NoteScreen initialized');
    print('spaceId: ${widget.spaceId}');
    print('userId: ${widget.userId}');
    
    _checkPermissions();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showImageSourceActionSheet();
    });
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

  Future<bool> _requestPermission(Permission permission) async {
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
            title: Text(
              '권한 필요',
              style: TypographyTokens.getStyle('heading.h2').copyWith(
                color: ColorTokens.getColor('text.body'),
              ),
            ),
            content: Text(
              '이 기능을 사용하기 위해서는 설정에서 권한을 허용해주세요.',
              style: TypographyTokens.getStyle('body.medium').copyWith(
                color: ColorTokens.getColor('text.body'),
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  '취소',
                  style: TypographyTokens.getStyle('button.medium').copyWith(
                    color: ColorTokens.getColor('text.body'),
                  ),
                ),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: Text(
                  '설정으로 이동',
                  style: TypographyTokens.getStyle('button.medium').copyWith(
                    color: ColorTokens.getColor('primary.400'),
                    fontWeight: FontWeight.w600,
                  ),
                ),
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

  Future<void> _showImageSourceActionSheet() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: ColorTokens.getColor('text.body'),
              ),
              title: Text(
                '갤러리에서 선택',
                style: TypographyTokens.getStyle('body.medium').copyWith(
                  color: ColorTokens.getColor('text.body'),
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: ColorTokens.getColor('text.body'),
              ),
              title: Text(
                '카메라로 촬영',
                style: TypographyTokens.getStyle('body.medium').copyWith(
                  color: ColorTokens.getColor('text.body'),
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
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
            SnackBar(
              content: Text(
                '이미지를 선택하려면 권한을 허용해주세요.',
                style: GoogleFonts.poppins(),
              ),
            ),
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
            SnackBar(
              content: Text(
                '이미지가 선택되지 않았습니다.',
                style: GoogleFonts.poppins(),
              ),
            ),
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
          SnackBar(
            content: Text(
              '이미지 선택 중 오류가 발생했습니다: $e',
              style: GoogleFonts.poppins(),
            ),
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
          SnackBar(
            content: Text(
              '이미지 처리 중 오류가 발생했습니다: $e',
              style: GoogleFonts.poppins(),
            ),
          ),
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

  Future<void> _createNote() async {
    if (_image == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final imagePath = await _saveImageLocally(_image!);
      
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
      
      final newPage = note_model.Page(
        imageUrl: imagePath,
        extractedText: _extractedText ?? '',
        translatedText: translatedText ?? '',
      );

      final newNote = note_model.Note(
        id: '',
        spaceId: widget.spaceId,
        userId: widget.userId,
        title: _extractedText?.split('\n').first ?? '새로운 노트',
        content: '',
        pages: [newPage],
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
          SnackBar(
            content: Text(
              '노트 생성 실패: $e',
              style: GoogleFonts.poppins(),
            ),
          ),
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
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: ColorTokens.getColor('surface.background'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '새 노트',
          style: TypographyTokens.getStyle('heading.h2').copyWith(
            color: ColorTokens.getColor('text.body'),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: ColorTokens.getColor('text.body'),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: ColorTokens.getColor('primary.400'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '이미지 처리 중...',
                    style: TypographyTokens.getStyle('body.medium').copyWith(
                      color: ColorTokens.getColor('text.body'),
                    ),
                  ),
                ],
              ),
            )
          : _image == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: ColorTokens.getColor('text.disabled'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '이미지를 선택하세요',
                        style: TypographyTokens.getStyle('body.large').copyWith(
                          color: ColorTokens.getColor('text.body'),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_image != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 200,
                                color: ColorTokens.getColor('surface.base'),
                                child: Center(
                                  child: Text(
                                    '이미지를 불러올 수 없습니다.',
                                    style: TypographyTokens.getStyle('body.medium').copyWith(
                                      color: ColorTokens.getColor('text.body'),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      if (_extractedText != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ColorTokens.getColor('surface.base'),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: ColorTokens.getColor('border.base'),
                            ),
                          ),
                          child: Text(
                            _extractedText!,
                            style: TypographyTokens.getStyle('body.medium').copyWith(
                              color: ColorTokens.getColor('text.body'),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
      bottomNavigationBar: _image != null && !_isProcessing
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(
                          Icons.photo_library,
                          color: ColorTokens.getColor('text.primary'),
                        ),
                        label: Text(
                          '갤러리',
                          style: TypographyTokens.getStyle('button.medium').copyWith(
                            color: ColorTokens.getColor('text.primary'),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorTokens.getColor('surface.button-primary'),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(
                          Icons.camera_alt,
                          color: ColorTokens.getColor('text.primary'),
                        ),
                        label: Text(
                          '카메라',
                          style: TypographyTokens.getStyle('button.medium').copyWith(
                            color: ColorTokens.getColor('text.primary'),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorTokens.getColor('surface.button-primary'),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
