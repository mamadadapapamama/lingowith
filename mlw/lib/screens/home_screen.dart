import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/services/note_repository.dart';
import 'package:mlw/widgets/note_card.dart';
import 'package:mlw/screens/note_space_settings_screen.dart';
import 'package:mlw/models/note_space.dart';
import 'package:mlw/repositories/note_space_repository.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:mlw/widgets/custom_button.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:googleapis_auth/auth_io.dart';
import 'package:mlw/services/translator.dart';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mlw/screens/note_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';  // StreamSubscription을 위한 import 추가

class HomeScreen extends StatefulWidget {
  final String spaceId;
  final String userId;

  const HomeScreen({
    super.key,
    required this.spaceId,
    required this.userId,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _ProcessingDialog extends StatelessWidget {
  final int totalImages;
  final int currentImage;

  const _ProcessingDialog({
    required this.totalImages,
    this.currentImage = 0,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentImage / totalImages;
    final percent = (progress * 100).toInt();

    return Dialog(
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                value: progress,
                backgroundColor: ColorTokens.getColor('primary.100'),
                valueColor: AlwaysStoppedAnimation<Color>(
                  ColorTokens.getColor('primary.400'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              currentImage == 0 
                ? 'Analyzing images...'
                : 'Translating... ($currentImage/$totalImages)',
              style: TypographyTokens.getStyle('body.medium').copyWith(
                color: ColorTokens.getColor('text.body'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$percent%',
              style: TypographyTokens.getStyle('heading.h2').copyWith(
                color: ColorTokens.getColor('primary.400'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final NoteRepository _noteRepository = NoteRepository();
  final NoteSpaceRepository _spaceRepository = NoteSpaceRepository();
  NoteSpace? _currentNoteSpace;
  
  // 임시 userId - 나중에 실제 인증된 사용자 ID로 교체
  static const userId = 'test_user';

  File? _image;
  bool _isProcessing = false;
  List<note_model.Note> _notes = [];
  bool _isLoading = true;

  // 로딩 메시지를 위한 ValueNotifier 추가
  final ValueNotifier<String> _loadingMessage = ValueNotifier('');

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  StreamSubscription? _notesSubscription;

  @override
  void initState() {
    super.initState();
    print('HomeScreen initState called');
    _loadCurrentNoteSpace();
  }

  Future<void> _loadCurrentNoteSpace() async {
    try {
      print('Loading note spaces...'); // 디버깅용 로그
      final spaces = await _spaceRepository.getNoteSpaces(userId).first;
      print('Loaded spaces: ${spaces.length}'); // 디버깅용 로그
      
      if (spaces.isEmpty) {
        print('Creating default note space...'); // 디버깅용 로그
        final defaultSpace = NoteSpace(
          id: '',
          userId: userId,
          name: "Chinese book",
          language: "zh",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final createdSpace = await _spaceRepository.createNoteSpace(defaultSpace);
        print('Default space created: ${createdSpace.id}'); // 디버깅용 로그
        
        if (mounted) {
          setState(() {
            _currentNoteSpace = createdSpace;
          });
          _loadNotes(createdSpace.id);
        }
      } else {
        print('Using existing space: ${spaces.first.id}'); // 디버깅용 로그
        if (mounted) {
          setState(() {
            _currentNoteSpace = spaces.first;
          });
          _loadNotes(spaces.first.id);
        }
      }
    } catch (e, stackTrace) {
      print('Error loading note spaces: $e'); // 디버깅용 로그
      print('Stack trace: $stackTrace'); // 디버깅용 로그
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('노트 스페이스 로딩 실패: $e')),
        );
      }
    }
  }

  Future<void> _loadNotes(String spaceId) async {
    await _notesSubscription?.cancel();

    try {
      // 단순화된 쿼리 사용
      _notesSubscription = firestore
          .collection('notes')
          .where('spaceId', isEqualTo: spaceId)
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .listen((snapshot) {
            final loadedNotes = snapshot.docs.map((doc) {
              final note = note_model.Note.fromFirestore(doc);
              print('Note ID: ${note.id}');
              print('Note Title: ${note.title}');
              print('FlashCards count: ${note.flashCards.length}');
              print('FlashCards data: ${note.flashCards}');
              return note;
            }).toList();

            if (mounted) {
              setState(() {
                _notes = loadedNotes;
                _isLoading = false;
              });
            }
          });
    } catch (e) {
      print('Error loading notes: $e');
    }
  }

  void _showImageSourceActionSheet() {
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
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
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
    final ImagePicker _picker = ImagePicker();
    try {
      if (source == ImageSource.gallery) {
        // 갤러리에서 여러 이미지 선택
        final List<XFile> pickedFiles = await _picker.pickMultiImage(
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );

        if (pickedFiles.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No images selected.')),
            );
          }
          return;
        }

        // 첫 번째 이미지로 _image 설정 (UI 표시용)
        _image = File(pickedFiles.first.path);
        
        // 모든 선택된 이미지로 노트 생성
        await _createNoteWithMultipleImages(pickedFiles);
        
      } else {
        // 카메라는 단일 이미지 촬영
        final XFile? pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );

        if (pickedFile == null) {
          print('No image selected.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No image selected.')),
            );
          }
          return;
        }

        final imageFile = File(pickedFile.path);
        if (!await imageFile.exists()) {
          throw Exception('There is no image file.');
        }

        _image = imageFile;  // Set the _image variable
        print('Image selected: ${imageFile.path}');

        await _createNoteWithImage(imageFile);
      }
    } catch (e) {
      print('Image picking error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sorry, something went wrong while choosing an image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 노트 복제 함수
    Future<void> _duplicateNote(note_model.Note note) async {
      try {
        final newNote = note_model.Note(
          id: '',
          spaceId: note.spaceId,
          userId: note.userId,
          title: '${note.title} (복사본)',
          content: note.content,
          pages: note.pages,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final createdNote = await _noteRepository.createNote(newNote);
        if (mounted) {
          setState(() {
            _notes = [..._notes, createdNote];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '노트가 복제되었습니다.',
                style: GoogleFonts.poppins(),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'sorry, something went wrong while duplicating the note.',
                style: GoogleFonts.poppins(),
              ),
            ),
          );
        }
      }
    }

    // 노트 삭제 함수
    Future<void> _deleteNote(note_model.Note note) async {
      try {
        await _noteRepository.deleteNote(note.id);
        if (mounted) {
          setState(() {
            _notes = _notes.where((n) => n.id != note.id).toList();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Your note got deleted.',
                style: GoogleFonts.poppins(),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Something went wrong while deleting the note.',
                style: GoogleFonts.poppins(),
              ),
            ),
          );
        }
      }
    }

    // HomeScreen 클래스 내부에 추가
    Future<void> _updateNoteTitle(note_model.Note note, String newTitle) async {
      try {
        final updatedNote = note.copyWith(
          title: newTitle,
          updatedAt: DateTime.now(),
        );
        
        await _noteRepository.updateNote(updatedNote);
        
        if (mounted) {
          setState(() {
            final index = _notes.indexWhere((n) => n.id == note.id);
            if (index != -1) {
              _notes = List<note_model.Note>.from(_notes)
                ..[index] = updatedNote;
            }
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Something went wrong while editing the note title. Please try again',
                style: GoogleFonts.poppins(),
              ),
            ),
          );
        }
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: ColorTokens.semantic['surface']?['background'],
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: ColorTokens.semantic['surface']?['background'],
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(84),
          child: Container(
            color: ColorTokens.semantic['surface']?['background'],
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 12,
                  bottom: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icon/logo_small.svg',
                          width: 71,
                          height: 21,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentNoteSpace?.name ?? "Loading...",
                          style: TypographyTokens.getStyle('heading.h1').copyWith(
                            color: ColorTokens.semantic['text']?['body'],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: SvgPicture.asset(
                        'assets/icon/profile.svg',
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          ColorTokens.semantic['text']?['body'],
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: _currentNoteSpace == null ? null : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NoteSpaceSettingsScreen(
                              noteSpace: _currentNoteSpace!,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: ColorTokens.getColor('primary.400'),
                ),
              )
            : _notes.isEmpty
                ? Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 84,
                    ),
                    child: _buildEmptyState(),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 80,
                    ),
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: NoteCard(
                          note: note,
                          onDuplicate: _duplicateNote,
                          onDelete: _deleteNote,
                          onTitleEdit: _updateNoteTitle,
                        ),
                      );
                    },
                  ),
        floatingActionButton: !_isLoading && _notes.isNotEmpty 
          ? FloatingActionButton.extended(
              backgroundColor: ColorTokens.getColor('primary.400'),
              onPressed: _showImageSourceActionSheet,
              icon: SvgPicture.asset(
                'assets/icon/addnote.svg',
                colorFilter: ColorFilter.mode(
                  ColorTokens.getColor('base.0'),
                  BlendMode.srcIn,
                ),
              ),
              label: Text(
                'Add note',
                style: TypographyTokens.getStyle('button.medium').copyWith(
                  color: ColorTokens.getColor('base.0'),
                ),
              ),
            )
          : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icon/zero_addnote.svg',
            width: 48,
            height: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Create your first note!',
            style: TypographyTokens.getStyle('heading.h2'),
          ),
          const SizedBox(height: 8),
          Text(
            'Add image to create a new note',
            style: TypographyTokens.getStyle('body.small').copyWith(
              color: ColorTokens.semantic['text']?['description'],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            onPressed: _showImageSourceActionSheet,
            text: 'Create new note',
          ),
        ],
      ),
    );
  }

  Future<void> _createNoteWithImage(File imageFile) async {
    final ValueNotifier<String> loadingMessage = ValueNotifier('analyzing image...');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ValueListenableBuilder<String>(
          valueListenable: loadingMessage,
          builder: (context, message, _) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: TypographyTokens.getStyle('body.medium').copyWith(
                      color: ColorTokens.getColor('text.body'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    try {
      // 이미지 분석
      loadingMessage.value = 'analyzing image...';
      final imagePath = await _saveImageLocally(imageFile);
      final extractedText = await _extractTextFromImage(await imageFile.readAsBytes());
      
      // 번역
      loadingMessage.value = 'translating...';
      final translatedText = await translatorService.translate(extractedText, from: 'zh', to: 'ko');
      
      // 노트 생성
      loadingMessage.value = 'almost done!';
      final newNote = note_model.Note(
        id: '',
        spaceId: _currentNoteSpace?.id ?? '',
        userId: userId,
        title: 'Note #${_notes.length + 1}',
        content: '',
        pages: [
          note_model.Page(
            imageUrl: imagePath,
            extractedText: extractedText,
            translatedText: translatedText,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdNote = await _noteRepository.createNote(newNote);
      
      if (mounted) {
        Navigator.pop(context);  // 로딩 다이얼로그 닫기
        setState(() {
          _notes = [..._notes, createdNote];
        });
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteDetailScreen(note: createdNote),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      loadingMessage.dispose();
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

  Future<void> _createNoteWithMultipleImages(List<XFile> imageFiles) async {
    // 진행 상태를 표시할 dialog 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ProcessingDialog(
        totalImages: imageFiles.length,
      ),
    );

    try {
      List<note_model.Page> pages = [];
      
      // 각 이미지에 대해 처리
      for (var i = 0; i < imageFiles.length; i++) {
        if (!mounted) return;

        // 진행률 업데이트
        Navigator.of(context).pop(); // 이전 dialog 제거
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _ProcessingDialog(
            totalImages: imageFiles.length,
            currentImage: i + 1,
          ),
        );

        final imageFile = imageFiles[i];
        final file = File(imageFile.path);
        final imagePath = await _saveImageLocally(file);
        final extractedText = await _extractTextFromImage(await file.readAsBytes());
        
        String translatedText = '';
        if (extractedText.isNotEmpty) {
          final lines = extractedText.split('\n').where((s) => s.trim().isNotEmpty).toList();
          final translatedLines = await Future.wait(
            lines.map((line) => translatorService.translate(line, from: 'zh', to: 'ko'))
          );
          translatedText = translatedLines.join('\n');
        }

        pages.add(note_model.Page(
          imageUrl: imagePath,
          extractedText: extractedText,
          translatedText: translatedText,
        ));
      }

      // 모든 페이지를 포함한 새 노트 생성
      final newNote = note_model.Note(
        id: '',
        spaceId: _currentNoteSpace?.id ?? '',
        userId: userId,
        title: 'Note #${_notes.length + 1}',
        content: '',
        pages: pages,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdNote = await _noteRepository.createNote(newNote);

      if (mounted) {
        // dialog 제거
        Navigator.of(context).pop();
        
        setState(() {
          _notes = [..._notes, createdNote];
        });
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteDetailScreen(note: createdNote),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // dialog 제거
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create a note. Please try again.: ${e.toString()}')),
        );
      }
    }
  }

  final translatorService = TranslatorService();

  @override
  void dispose() {
    _notesSubscription?.cancel();
    super.dispose();
  }
}
