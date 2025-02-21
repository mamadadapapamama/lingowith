import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/repositories/note_repository.dart';
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
import 'package:flutter_svg/flutter_svg.dart';

class NoteScreen extends StatefulWidget {
  final String userId;
  final String spaceId;

  const NoteScreen({
    Key? key,
    required this.userId,
    required this.spaceId,
  }) : super(key: key);

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final ImagePicker _picker = ImagePicker();
  final _noteRepository = NoteRepository();
  final translatorService = TranslatorService();
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

      // Create a new note
      final newNote = note_model.Note(
        id: '',
        spaceId: widget.spaceId,
        userId: widget.userId,
        title: textBlocks.isNotEmpty ? textBlocks.first.text : '',
        content: '',
        pages: [newPage],
        flashCards: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await _noteRepository.createNote(newNote);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('새로운 노트가 추가되었습니다')),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')),
        );
      }
    }
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
