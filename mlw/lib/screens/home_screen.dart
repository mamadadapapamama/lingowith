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
      final loadedNotes = await notesStream.first;
      if (mounted) {
        setState(() {
          _notes = loadedNotes;
          _isLoading = false;
        });
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
                  ColorTokens.getColor('text'),
                  BlendMode.srcIn,
                ),
              ),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: SvgPicture.asset(
                'assets/icon/addnote.svg',
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  ColorTokens.getColor('text'),
                  BlendMode.srcIn,
                ),
              ),
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
      print('Attempting to pick image from: $source');
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
            const SnackBar(content: Text('이미지가 선택되지 않았습니다.')),
          );
        }
        return;
      }

      final imageFile = File(pickedFile.path);
      if (!await imageFile.exists()) {
        throw Exception('선택된 이미지 파일이 존재하지 않습니다.');
      }

      _image = imageFile;  // Set the _image variable
      print('Image selected: ${imageFile.path}');

      await _createNote();

    } catch (e) {
      print('Image picking error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')),
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
        systemNavigationBarColor: ColorTokens.getColor('background'),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: ColorTokens.getColor('background'),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(84),
          child: Container(
            color: ColorTokens.getColor('background'),
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
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            color: ColorTokens.getColor('text'),
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
                          ColorTokens.getColor('text'),
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
        floatingActionButton: !_isLoading && _notes.isNotEmpty ? FloatingActionButton(
          onPressed: () {
            print('Add new note button pressed');
            _showImageSourceActionSheet();
          },
          child: SvgPicture.asset(
            'assets/icon/addimage.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              ColorTokens.getColor('text'),
              BlendMode.srcIn,
            ),
          ),
          backgroundColor: ColorTokens.getColor('button-primary'),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
            'assets/images/zero_addnote.svg',
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
              color: ColorTokens.getColor('description'),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            onPressed: _showImageSourceActionSheet,
            text: 'Add image',
            icon: SvgPicture.asset(
              'assets/images/zero_addnote.svg',
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(
                ColorTokens.getColor('primary.400'),
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createNote() async {
    if (_image == null) {
      print('No image to create note with.');
      return;
    }

    print('Starting note creation process...');

    setState(() {
      _isProcessing = true;
    });

    try {
      // Save the image locally and get the path
      final imagePath = await _saveImageLocally(_image!);
      print('Image saved at: $imagePath');

      // Extract text from the image
      final extractedText = await _extractTextFromImage(await _image!.readAsBytes());
      print('Extracted text: $extractedText');

      // Translate the extracted text
      String? translatedText;
      if (extractedText != null) {
        try {
          final lines = extractedText.split('\n').where((s) => s.trim().isNotEmpty).toList();
          final translatedLines = await Future.wait(
            lines.map((line) => translatorService.translate(line, from: 'zh', to: 'ko'))
          );
          translatedText = translatedLines.join('\n');
          print('Translated text: $translatedText');
        } catch (e) {
          print('Translation error: $e');
        }
      }

      // Create a new page with the image and extracted text
      final newPage = note_model.Page(
        imageUrl: imagePath,
        extractedText: extractedText ?? '',
        translatedText: translatedText ?? '',
      );

      // Create a new note with the extracted and translated text
      final newNote = note_model.Note(
        id: '',
        spaceId: _currentNoteSpace?.id ?? '',
        userId: userId,
        title: 'Note #${_notes.length + 1}',  // Auto-generate title
        content: '',
        pages: [newPage], // Add the new page to the note
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('Creating note in Firestore...');
      final createdNote = await _noteRepository.createNote(newNote);
      print('Note created with ID: ${createdNote.id}');

      if (mounted) {
        setState(() {
          _notes = [..._notes, createdNote];
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('노트가 생성되었습니다.')),
        );
      }

      // Navigate to NoteDetailScreen after creating the note
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteDetailScreen(note: createdNote),
          ),
        );
      }
    } catch (e) {
      print('Note creation error: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('노트 생성 실패: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
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

  final translatorService = TranslatorService();
}
