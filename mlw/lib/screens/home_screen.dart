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
  
  // 구독 관리를 위한 StreamSubscription 추가
  StreamSubscription<List<note_model.Note>>? _notesSubscription;
  
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
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // 현재 사용자 ID 가져오기
      final user = _auth.currentUser;
      if (user == null) {
        print('로그인된 사용자가 없습니다. 테스트 사용자 ID 사용');
        // 테스트 사용자 ID 사용
        const testUserId = 'test_user_id';
        
        // 스페이스 목록 가져오기
        final spaces = await _spaceRepository.getNoteSpaces(testUserId).first;
        
        // 스페이스가 없으면 기본 스페이스 생성
        if (spaces.isEmpty) {
          final defaultSpace = NoteSpace(
            id: '',
            userId: testUserId,
            name: '기본 스페이스',
            language: 'ko',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          final createdSpace = await _spaceRepository.createNoteSpace(defaultSpace);
          _currentNoteSpace = createdSpace;
        } else {
          // 첫 번째 스페이스 사용
          _currentNoteSpace = spaces.first;
        }
        
        print('현재 노트 스페이스: ${_currentNoteSpace?.name} (${_currentNoteSpace?.id})');
        
        // 노트 목록 스트림 구독
        _subscribeToNotesWithTestUser(testUserId);
        return;
      }
      
      // 로그인 후 사용자 다시 가져오기
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }
      
      // 스페이스 목록 가져오기
      final spaces = await _spaceRepository.getNoteSpaces(currentUser.uid).first;
      
      // 스페이스가 없으면 기본 스페이스 생성 (필수 매개변수 language, updatedAt 추가)
      if (spaces.isEmpty) {
        final defaultSpace = NoteSpace(
          id: '',
          userId: currentUser.uid,
          name: '기본 스페이스',
          language: 'ko',          // 추가된 매개변수: 언어
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(), // 추가된 매개변수: 최근 업데이트 시간
        );
        
        final createdSpace = await _spaceRepository.createNoteSpace(defaultSpace);
        _currentNoteSpace = createdSpace;
      } else {
        // 첫 번째 스페이스 사용
        _currentNoteSpace = spaces.first;
      }
      
      print('현재 노트 스페이스: ${_currentNoteSpace?.name} (${_currentNoteSpace?.id})');
      
      // 노트 목록 스트림 구독 (getNotes 메서드는 이제 userId와 spaceId 두 개의 인자를 받음)
      _subscribeToNotes();
      
    } catch (e) {
      setState(() {
        _error = '노트 스페이스 로드 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
      print('노트 스페이스 로드 오류: $e');
    }
  }

  // 노트 목록 스트림 구독 메서드
  void _subscribeToNotes() {
    // 기존 구독 취소
    _notesSubscription?.cancel();
    
    if (_currentNoteSpace == null) {
      setState(() {
        _notes = [];
        _isLoading = false;
      });
      return;
    }
    
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _notes = [];
        _isLoading = false;
      });
      return;
    }
    
    // 새로운 스트림 구독 (repository의 getNotes는 두 개의 매개변수를 받음)
    _notesSubscription = _noteRepository
        .getNotes(_currentNoteSpace!.id)
        .listen(
          (notes) {
            print('노트 스트림 업데이트: ${notes.length}개');
            
            // 각 노트의 데이터 일관성 확인
            for (var note in notes) {
              // 데이터 일관성 확인 로직 주석 처리 또는 제거
            }
            
            if (mounted) {
              setState(() {
                _notes = notes;
                _isLoading = false;
              });
            }
          },
          onError: (e) {
            print('노트 스트림 오류: $e');
            if (mounted) {
              setState(() {
                _error = '노트 목록 로드 중 오류가 발생했습니다: $e';
                _isLoading = false;
              });
            }
          },
        );
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
      _subscribeToNotes();
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
            onPressed: _subscribeToNotes,
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
    // 구독 취소
    _notesSubscription?.cancel();
    _loadingMessage.dispose();
    super.dispose();
  }

  Future<void> _checkFirestoreData() async {
    try {
      // 모든 노트 확인
      final notesSnapshot = await FirebaseFirestore.instance.collection('notes').get();
      print('Found ${notesSnapshot.docs.length} total notes in Firestore');
      
      for (var doc in notesSnapshot.docs) {
        final data = doc.data();
        print('Note in Firestore: ${doc.id}, spaceId: ${data['spaceId']}, title: ${data['title']}');
      }
      
      // 모든 스페이스 확인
      final spacesSnapshot = await FirebaseFirestore.instance.collection('note_spaces').get();
      print('Found ${spacesSnapshot.docs.length} note spaces in Firestore');
      
      for (var doc in spacesSnapshot.docs) {
        final data = doc.data();
        print('Note space in Firestore: ${doc.id}, name: ${data['name']}');
      }
    } catch (e) {
      print('Error checking Firestore data: $e');
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
      _subscribeToNotes();
    }
  }

  void _subscribeToNotesWithTestUser(String testUserId) {
    // 기존 구독 취소
    _notesSubscription?.cancel();
    
    if (_currentNoteSpace == null) {
      setState(() {
        _notes = [];
        _isLoading = false;
      });
      return;
    }
    
    // 새로운 스트림 구독
    _notesSubscription = _noteRepository
        .getNotes(_currentNoteSpace!.id)
        .listen(
          (notes) {
            print('노트 스트림 업데이트(테스트 사용자): ${notes.length}개');
            
            if (mounted) {
              setState(() {
                _notes = notes;
                _isLoading = false;
              });
            }
          },
          onError: (e) {
            print('노트 스트림 오류: $e');
            if (mounted) {
              setState(() {
                _error = '노트 목록 로드 중 오류가 발생했습니다: $e';
                _isLoading = false;
              });
            }
          },
        );
  }

  // 노트의 spaceId 업데이트
  Future<void> _updateNotesWithMissingSpaceId() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final notesSnapshot = await FirebaseFirestore.instance
          .collection('notes')
          .where('spaceId', isEqualTo: '')
          .get();
      
      print('Found ${notesSnapshot.docs.length} notes with empty spaceId');
      
      if (notesSnapshot.docs.isEmpty) return;
      
      // 스페이스 ID 가져오기
      final spacesSnapshot = await FirebaseFirestore.instance
          .collection('note_spaces')
          .limit(1)
          .get();
      
      if (spacesSnapshot.docs.isEmpty) {
        print('No note spaces found');
        return;
      }
      
      final spaceId = spacesSnapshot.docs.first.id;
      print('Using space ID: $spaceId');
      
      // 각 노트의 spaceId 업데이트
      for (var doc in notesSnapshot.docs) {
        batch.update(doc.reference, {
          'spaceId': spaceId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      print('Updated ${notesSnapshot.docs.length} notes with spaceId: $spaceId');
    } catch (e) {
      print('Error updating notes with missing spaceId: $e');
    }
  }
}

class _Constants {
  static const defaultSpaceName = 'Chinese book';
  static const defaultLanguage = 'zh';
}
