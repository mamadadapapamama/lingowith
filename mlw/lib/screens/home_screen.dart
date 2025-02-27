import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/repositories/note_repository.dart';
import 'package:mlw/widgets/note_card.dart';
import 'package:mlw/screens/note_space_settings_screen.dart';
import 'package:mlw/models/note_space.dart';
import 'package:mlw/repositories/note_space_repository.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:mlw/widgets/custom_button.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mlw/services/translator_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mlw/screens/note_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mlw/services/image_processing_service.dart';
import 'package:mlw/constants/app_constants.dart';

class HomeScreen extends StatefulWidget {
  final String? spaceId;
  final String? userId;

  const HomeScreen({
    super.key,
    this.spaceId,
    this.userId,
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final NoteRepository _noteRepository = NoteRepository();
  final NoteSpaceRepository _spaceRepository = NoteSpaceRepository();
  
  NoteSpace? _currentNoteSpace;
  List<note_model.Note> _notes = [];
  bool _isLoading = true;
  String? _error;
  
  // 로딩 메시지를 위한 ValueNotifier 추가
  final ValueNotifier<String> _loadingMessage = ValueNotifier('');
  
  // 서비스 인스턴스 생성
  late ImageProcessingService _imageProcessingService;
  
  @override
  void initState() {
    super.initState();
    print("HomeScreen initState called");
    
    // 이미지 처리 서비스 초기화
    _imageProcessingService = ImageProcessingService(
      translatorService: translatorService,
    );
    
    // 약간의 지연 후 로드 (UI가 먼저 그려지도록)
    Future.delayed(Duration.zero, () {
      _loadCurrentNoteSpace();
      _checkFirestoreData(); // 직접 Firestore 데이터 확인
    });
  }

  Future<void> _loadCurrentNoteSpace() async {
    print("Loading current note space...");
    
    try {
      final userId = widget.userId ?? _auth.currentUser?.uid ?? 'test_user';
      print("User ID: $userId");
      
      // 로딩 상태 표시
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final spaces = await _spaceRepository.getNoteSpaces(userId).first;
      print("Found ${spaces.length} note spaces");
      
      if (spaces.isEmpty) {
        print("No note spaces found, creating default space");
        final defaultSpace = NoteSpace(
          id: '',
          userId: userId,
          name: AppConstants.defaultSpaceName,
          language: AppConstants.defaultLanguage,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        final createdSpace = await _spaceRepository.createNoteSpace(defaultSpace);
        
        if (mounted) {
          setState(() {
            _currentNoteSpace = createdSpace;
          });
          print("Created default space: ${createdSpace.id}");
          _loadNotes();
        }
      } else {
        if (mounted) {
          setState(() {
            _currentNoteSpace = spaces.first;
          });
          print("Using existing space: ${spaces.first.id}");
          _loadNotes();
        }
      }
    } catch (e) {
      print("Error loading note space: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "노트 스페이스 로딩 실패: $e";
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('노트 스페이스 로딩 실패: $e')),
        );
      }
    }
  }

  void _loadNotes() async {
    print("Loading notes...");
    
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final userId = widget.userId ?? _auth.currentUser?.uid ?? 'test_user';
    
    // 수정된 코드: 실제 노트 스페이스 ID 사용
    final spaceId = widget.spaceId ?? _currentNoteSpace?.id;
    
    print("Loading notes for userId: $userId, spaceId: $spaceId");
    
    // 노트 스페이스 ID가 없으면 로드하지 않음
    if (spaceId == null) {
      print("No note space ID available, cannot load notes");
      setState(() {
        _isLoading = false;
        _error = "노트 스페이스 ID가 없습니다";
      });
      return;
    }
    
    try {
      // 직접 Firestore에서 데이터 가져오기
      final snapshot = await FirebaseFirestore.instance
          .collection('notes')
          .where('userId', isEqualTo: userId)
          .where('spaceId', isEqualTo: spaceId)
          .get();
      
      print("Found ${snapshot.docs.length} notes in Firestore");
      
      // 노트 모델로 변환
      final loadedNotes = snapshot.docs.map((doc) {
        try {
          return note_model.Note.fromFirestore(doc);
        } catch (e) {
          print("Error parsing note ${doc.id}: $e");
          return null;
        }
      }).where((note) => note != null).cast<note_model.Note>().toList();
      
      // 메모리에서 정렬
      loadedNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print("Successfully parsed ${loadedNotes.length} notes");
      
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
          _error = e.toString();
          _isLoading = false;
        });
      }
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
    final ImagePicker picker = ImagePicker();
    try {
      if (source == ImageSource.gallery) {
        // 갤러리에서 여러 이미지 선택
        final List<XFile> pickedFiles = await picker.pickMultiImage(
          maxWidth: 1200,
          maxHeight: 1200,
        );
        
        if (pickedFiles.isNotEmpty) {
          if (pickedFiles.length > 1) {
            // 여러 이미지 처리
            _createNoteWithMultipleImages(pickedFiles);
          } else {
            // 단일 이미지 처리
            _createNoteWithImage(File(pickedFiles.first.path));
          }
        }
      } else {
        // 카메라로 촬영
        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1200,
          maxHeight: 1200,
        );
        
        if (pickedFile != null) {
          _createNoteWithImage(File(pickedFile.path));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')),
      );
    }
  }

  Future<void> _deleteNote(note_model.Note note) async {
    try {
      // 디버깅 정보 출력
      print('노트 삭제 시작: ${note.id}');
      
      // 노트 삭제
      await _noteRepository.deleteNote(note.id);
      
      // 상태 업데이트 - 중요: 삭제된 노트를 목록에서 제거
      setState(() {
        _notes.removeWhere((item) => item.id == note.id);
      });
      
      print('노트 삭제 완료: ${note.id}');
      
      // 성공 메시지는 NoteCard에서 이미 표시됨
    } catch (e) {
      print('노트 삭제 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('노트 삭제 중 오류가 발생했습니다: $e')),
      );
    }
  }

  Future<void> _editNoteTitle(note_model.Note note, String currentTitle) async {
    final TextEditingController titleController = TextEditingController(text: currentTitle);
    
    // 다이얼로그 표시
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('노트 제목 변경'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: '새 제목을 입력하세요',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, titleController.text),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    
    // 새 제목이 없거나 기존 제목과 같으면 무시
    if (newTitle == null || newTitle.isEmpty || newTitle == currentTitle) {
      return;
    }
    
    try {
      // 로딩 표시
      setState(() {
        _isLoading = true;
      });
      
      // 디버깅 정보 출력
      print('노트 ID: ${note.id}');
      print('현재 제목: $currentTitle');
      print('새 제목: $newTitle');
      
      // 노트 제목 업데이트
      await _noteRepository.updateNoteTitle(note.id, newTitle);
      
      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('노트 제목이 변경되었습니다')),
      );
      
      // 노트 목록 새로고침
      _loadNotes();
    } catch (e) {
      print('노트 제목 변경 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('노트 제목 변경중 에러가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("HomeScreen build called - notes count: ${_notes.length}");
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorTokens.getColor('base.0'),
        elevation: 0,
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/icon/logo_small.svg',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            Text(
              _currentNoteSpace?.name ?? 'My Notes',
              style: TypographyTokens.getStyle('heading.h3'),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotes,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              if (_currentNoteSpace != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteSpaceSettingsScreen(
                      noteSpace: _currentNoteSpace!,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Text('Error: $_error'))
          : _notes.isEmpty
            ? _buildEmptyState()
            : _buildNotesList(),
      floatingActionButton: FloatingActionButton.extended(
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("HomeScreen didChangeDependencies called");
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print("HomeScreen didUpdateWidget called");
    
    // 위젯이 업데이트되면 노트 다시 로드
    if (oldWidget.spaceId != widget.spaceId || oldWidget.userId != widget.userId) {
      _loadCurrentNoteSpace();
    }
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
              color: ColorTokens.getColor('text.secondary'),
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

  Widget _buildNotesList() {
    print("Building notes list with ${_notes.length} notes");
    
    if (_notes.isEmpty) {
      return _buildEmptyState();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        print("Rendering note at index $index: ${note.title}");
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: NoteCard(
            note: note,
            onDelete: _deleteNote,
            onTitleEdit: _editNoteTitle,
          ),
        );
      },
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
      final imagePath = await _imageProcessingService.saveImageLocally(imageFile);
      final extractedText = await _imageProcessingService.extractTextFromImage(await imageFile.readAsBytes());
      
      // 번역
      loadingMessage.value = 'translating...';
      final translatedText = await _imageProcessingService.translateText(extractedText);
      
      // userId 가져오기
      final userId = widget.userId ?? _auth.currentUser?.uid ?? 'test_user';
      
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
        flashCards: [],
        highlightedTexts: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        knownFlashCards: {},
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

  Future<note_model.Page> _processImage(XFile imageFile, int index, int total) async {
    if (!mounted) return Future.error('Widget not mounted');
    
    // 진행률 업데이트
    _updateProgressDialog(index, total);
    
    final file = File(imageFile.path);
    final imagePath = await _imageProcessingService.saveImageLocally(file);
    final extractedText = await _imageProcessingService.extractTextFromImage(await file.readAsBytes());
    final translatedText = await _imageProcessingService.translateText(extractedText);
    
    return note_model.Page(
      imageUrl: imagePath,
      extractedText: extractedText,
      translatedText: translatedText,
    );
  }

  void _updateProgressDialog(int current, int total) {
    Navigator.of(context).pop(); // 이전 dialog 제거
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ProcessingDialog(
        totalImages: total,
        currentImage: current,
      ),
    );
  }

  Future<void> _createNoteWithMultipleImages(List<XFile> imageFiles) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ProcessingDialog(totalImages: imageFiles.length),
    );

    try {
      List<note_model.Page> pages = [];
      
      // 각 이미지 처리
      for (var i = 0; i < imageFiles.length; i++) {
        final page = await _processImage(imageFiles[i], i + 1, imageFiles.length);
        pages.add(page);
      }
      
      // 노트 생성 및 저장
      final newNote = await _createNoteWithPages(pages);
      
      if (mounted) {
        Navigator.of(context).pop(); // dialog 제거
        _navigateToNoteDetail(newNote);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // dialog 제거
        _showErrorSnackBar('Failed to create a note: $e');
      }
    }
  }

  Future<note_model.Note> _createNoteWithPages(List<note_model.Page> pages) async {
    final userId = widget.userId ?? _auth.currentUser?.uid ?? 'test_user';
    
    final newNote = note_model.Note(
      id: '',
      spaceId: _currentNoteSpace?.id ?? '',
      userId: userId,
      title: 'Note #${_notes.length + 1}',
      content: '',
      pages: pages,
      flashCards: [],
      highlightedTexts: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      knownFlashCards: {},
    );
    
    final createdNote = await _noteRepository.createNote(newNote);
    
    setState(() {
      _notes = [..._notes, createdNote];
    });
    
    return createdNote;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  final translatorService = TranslatorService();

  @override
  void dispose() {
    _loadingMessage.dispose();
    super.dispose();
  }

  Future<void> _checkFirestoreData() async {
    try {
      final userId = widget.userId ?? _auth.currentUser?.uid ?? 'test_user';
      
      print("Directly checking Firestore data for userId: $userId");
      
      // 모든 노트 가져오기 (spaceId 필터 없이)
      final snapshot = await FirebaseFirestore.instance
          .collection('notes')
          .where('userId', isEqualTo: userId)
          .get();
      
      print("Found ${snapshot.docs.length} total notes in Firestore");
      
      // 각 노트의 spaceId 확인
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print("Note in Firestore: ${doc.id}, spaceId: ${data['spaceId']}, title: ${data['title']}");
      }
      
      // 노트 스페이스 확인
      final spacesSnapshot = await FirebaseFirestore.instance
          .collection('note_spaces')
          .where('userId', isEqualTo: userId)
          .get();
      
      print("Found ${spacesSnapshot.docs.length} note spaces in Firestore");
      
      for (var doc in spacesSnapshot.docs) {
        final data = doc.data();
        print("Note space in Firestore: ${doc.id}, name: ${data['name']}");
      }
    } catch (e) {
      print("Error checking Firestore data: $e");
    }
  }

  void _navigateToNoteDetail(note_model.Note note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(note: note),
      ),
    );
    
    if (result == true) {
      print("Returned from NoteDetailScreen, refreshing notes");
      _loadNotes();
    }
  }
}

class _Constants {
  static const defaultSpaceName = 'Chinese book';
  static const defaultLanguage = 'zh';
}
