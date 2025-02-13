import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart';
import 'package:mlw/services/note_repository.dart';
import 'package:mlw/widgets/note_card.dart';
import 'package:mlw/screens/note_screen.dart';
import 'package:mlw/styles/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mlw/screens/note_space_settings_screen.dart';
import 'package:mlw/models/note_space.dart';
import 'package:mlw/repositories/note_space_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NoteRepository _noteRepository = NoteRepository();
  final NoteSpaceRepository _spaceRepository = NoteSpaceRepository();
  NoteSpace? _currentNoteSpace;
  
  // 임시 userId - 나중에 실제 인증된 사용자 ID로 교체
  static const userId = 'test_user';

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
          name: "중국어 노트",
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
        }
      } else {
        print('Using existing space: ${spaces.first.id}'); // 디버깅용 로그
        if (mounted) {
          setState(() {
            _currentNoteSpace = spaces.first;
          });
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

  @override
  Widget build(BuildContext context) {
    // 노트 복제 함수
    Future<void> duplicateNote(Note note) async {
      final newNote = Note(
        id: '',
        spaceId: note.spaceId,
        userId: note.userId,
        title: '${note.title} (복사본)',
        content: note.content,
        flashCards: note.flashCards,
        highlightedTexts: note.highlightedTexts,
        extractedText: note.extractedText,
        translatedText: note.translatedText,
        pinyin: note.pinyin,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        await _noteRepository.createNote(newNote);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('노트가 복제되었습니다.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('노트 복제 실패: $e')),
          );
        }
      }
    }

    // 노트 삭제 함수
    Future<void> deleteNote(Note note) async {
      try {
        await _noteRepository.deleteNote(note.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('노트가 삭제되었습니다.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('노트 삭제 실패: $e')),
          );
        }
      }
    }

    // HomeScreen 클래스 내부에 추가
    Future<void> updateNoteTitle(Note note, String newTitle) async {
      try {
        final updatedNote = note.copyWith(
          title: newTitle,
          updatedAt: DateTime.now(),
        );
        await _noteRepository.updateNote(updatedNote);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('제목 수정 실패: $e')),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _currentNoteSpace?.name ?? "Loading...",  // 노트 스페이스 이름 표시
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.deepGreen,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppColors.deepGreen.withOpacity(0.7)),
            onPressed: () {
              // TODO: 검색 기능 구현
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.deepGreen.withOpacity(0.7)),
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
      body: _currentNoteSpace == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Note>>(
              stream: _noteRepository.getNotes(userId, _currentNoteSpace!.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final notes = snapshot.data!;
                
                if (notes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_add,
                          size: 60,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '노트가 없습니다.\n새로운 노트를 추가해보세요!',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    // 테스트 예정 메시지 (실제로는 Note 모델에 이 정보가 포함되어야 함)
                    final bool hasTestSchedule = note.title.contains('家人');
                    final String testMessage = hasTestSchedule ? 'Test tomorrow!' : '';
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: NoteCard(
                        note: note,
                        hasTestSchedule: hasTestSchedule,
                        testMessage: testMessage,
                        onDuplicate: duplicateNote,
                        onDelete: deleteNote,
                        onTitleEdit: updateNoteTitle,
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentNoteSpace == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('노트 스페이스를 먼저 로드해주세요')),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteScreen(
                spaceId: _currentNoteSpace!.id,
                userId: userId,
              ),
            ),
          );
        },
        backgroundColor: AppColors.neonGreen,
        shape: const CircleBorder(),
        child: Icon(Icons.add, color: AppColors.deepGreen),
      ),
    );
  }
}
