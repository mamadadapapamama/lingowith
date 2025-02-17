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
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mlw/widgets/custom_button.dart';

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
      backgroundColor: ColorTokens.semantic['surface']?['page'] ?? Colors.white,
      appBar: AppBar(
        title: Text(
          _currentNoteSpace?.name ?? "Loading...",
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
            icon: Icon(Icons.delete_sweep, color: AppColors.deepGreen.withOpacity(0.7)),
            onPressed: () async {
              final shouldDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('노트 전체 삭제'),
                  content: const Text('현재 스페이스의 모든 노트를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('삭제'),
                    ),
                  ],
                ),
              );

              if (shouldDelete == true && _currentNoteSpace != null) {
                try {
                  await _noteRepository.deleteAllSpaceNotes(_currentNoteSpace!.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('모든 노트가 삭제되었습니다.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('노트 삭제 중 오류가 발생했습니다: $e')),
                    );
                  }
                }
              }
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
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    StreamBuilder<List<Note>>(
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
                          return SizedBox(
                            height: MediaQuery.of(context).size.height - 200,
                            child: Center(
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
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 80),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: notes.length,
                            itemBuilder: (context, index) {
                              final note = notes[index];
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
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: CustomButton(
          text: 'Add new note',
          icon: Icon(
            Icons.add,
            size: 24,
            color: ColorTokens.semantic['text']?['primary'] ?? Colors.white,
          ),
          onPressed: () async {
            if (_currentNoteSpace != null) {
              print('Current note space ID: ${_currentNoteSpace!.id}');
              try {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteScreen(
                      spaceId: _currentNoteSpace!.id,
                      userId: userId,
                    ),
                  ),
                );
                print('Returned from NoteScreen');
              } catch (e) {
                print('Navigation error: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('화면 전환 중 오류가 발생했습니다: $e')),
                  );
                }
              }
            } else {
              print('_currentNoteSpace is null');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('노트 스페이스를 불러오는 중입니다.')),
                );
              }
            }
          },
          isPrimary: true,
        ),
      ),
    );
  }
}
