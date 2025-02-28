import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/widgets/note_card.dart';

class HomeScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onRefresh;
  final VoidCallback onCheckDataState;
  final VoidCallback onSettings;
  
  const HomeScreenAppBar({
    Key? key,
    required this.title,
    required this.onRefresh,
    required this.onCheckDataState,
    required this.onSettings,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
          tooltip: '강제 새로고침',
        ),
        IconButton(
          icon: const Icon(Icons.bug_report),
          onPressed: onCheckDataState,
          tooltip: '데이터 상태 확인',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: onSettings,
        ),
      ],
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class NoteGridView extends StatelessWidget {
  final List<note_model.Note> notes;
  final Function(note_model.Note) onNoteTap;
  final VoidCallback? onRefresh;
  
  const NoteGridView({
    Key? key,
    required this.notes,
    required this.onNoteTap,
    this.onRefresh,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    print('NoteGridView 빌드: ${notes.length}개 노트');
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        print('노트 ${index + 1}/${notes.length}: ${note.id}, 제목: ${note.title}');
        return NoteCard(
          note: note,
          onPressed: () => onNoteTap(note),
          onDelete: (id) {
            // 노트 삭제 로직
            print('노트 삭제: $id');
          },
          onTitleEdit: (id, newTitle) {
            // 노트 제목 수정 로직
            print('노트 제목 수정: $id, 새 제목: $newTitle');
          },
          onRefresh: onRefresh,
        );
      },
    );
  }
} 