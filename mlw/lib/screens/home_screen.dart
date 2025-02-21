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

  @override
  void initState() {
    super.initState();
    print('HomeScreen initState called'); // 디버깅용 로그
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
    try {
      final notesStream = _noteRepository.getNotes(spaceId, userId);
      await for (final notes in notesStream) {
        if (mounted) {
          setState(() {
            _notes = notes;
            _isLoading = false;
          });
          break;  // 첫 번째 결과만 받고 스트림 종료
        }
      }
    } catch (e) {
      print('Error loading notes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '노트를 불러오는 중 오류가 발생했습니다.',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showImageSourceActionSheet() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: SvgPicture.asset(
                'assets/icon/addimage.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  ColorTokens.semantic['text']?['body'],
                  BlendMode.srcIn,
                ),
              ),
              title: const Text('Photo library'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: SvgPicture.asset(
                'assets/icon/camera.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  ColorTokens.semantic['text']?['body'],
                  BlendMode.srcIn,
                ),
              ),
              title: const Text('Take photo'),
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

      // Create a new note with the extracted and translated text
      final newNote = note_model.Note(
        id: '',
        spaceId: widget.spaceId,
        userId: widget.userId,
        title: textBlocks.isNotEmpty ? textBlocks.first.text : '',
        pages: [newPage],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await _noteRepository.createNote(newNote);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('새로운 노트가 생성되었습니다')),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 처리 중 오류가 발생했습니다: $e')),
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
                '노트 복제 중 오류가 발생했습니다.',
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
                '노트가 삭제되었습니다.',
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
                '노트 삭제 중 오류가 발생했습니다.',
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
                '노트 제목 수정 중 오류가 발생했습니다.',
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/icon/logo_small.svg',
                width: 71,
                height: 21,
              ),
              const SizedBox(height: 4),
              Text(
                _currentNoteSpace?.name ?? "Loading...",
                style: TypographyTokens.getStyle('heading.h2'),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
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
        floatingActionButton: !_isLoading && _notes.isNotEmpty ? FloatingActionButton.extended(
          onPressed: _showImageSourceActionSheet,
          label: Text(
            'Add Note',
            style: TextStyle(
              color: ColorTokens.semantic['text']['primary'],
            ),
          ),
          backgroundColor: ColorTokens.semantic['surface']['button']['secondary'],
        ) : null,
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

  final translatorService = TranslatorService();
}
