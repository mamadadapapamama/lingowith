import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'dart:io';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/screens/note_detail_screen.dart';
import 'package:mlw/widgets/flashcard_counter.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:mlw/screens/home_screen.dart';
import 'package:mlw/utils/date_formatter.dart';

class NoteCard extends StatelessWidget {
  final note_model.Note note;
  final Function(note_model.Note) onDuplicate;
  final Function(note_model.Note) onDelete;
  final Function(note_model.Note, String) onTitleEdit;

  const NoteCard({
    Key? key,
    required this.note,
    required this.onDuplicate,
    required this.onDelete,
    required this.onTitleEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 디버그 모드에서만 출력
    assert(() {
      print("Building NoteCard for note: ${note.id}, title: ${note.title}");
      return true;
    }());
    
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(note: note),
            ),
          ).then((_) {
            // 홈 화면 새로고침 요청
            final homeScreen = context.findAncestorWidgetOfExactType<HomeScreen>();
            if (homeScreen != null) {
              // 홈 화면의 _loadNotes 메서드 직접 호출
              (homeScreen as dynamic)._loadNotes();
            }
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            _buildTextSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    if (note.pages.isEmpty) {
      // 페이지가 없는 경우 기본 이미지 표시
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: ColorTokens.getColor('primary.50'),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Center(
          child: Icon(
            Icons.note,
            size: 48,
            color: ColorTokens.getColor('primary.300'),
          ),
        ),
      );
    }

    // 첫 번째 페이지의 이미지 표시
    try {
      final File imageFile = File(note.pages.first.imageUrl);
      if (!imageFile.existsSync()) {
        // 파일이 존재하지 않는 경우 기본 이미지 표시
        return Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: ColorTokens.getColor('primary.50'),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: 36,
                  color: ColorTokens.getColor('primary.300'),
                ),
                const SizedBox(height: 4),
                Text(
                  'Image not found',
                  style: TypographyTokens.getStyle('body.small').copyWith(
                    color: ColorTokens.getColor('primary.300'),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        child: SizedBox(
          height: 120,
          width: double.infinity,
          child: Image.file(
            imageFile,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading image: $error');
              // 이미지 로드 실패 시 기본 이미지 표시
              return Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: ColorTokens.getColor('primary.50'),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 36,
                        color: ColorTokens.getColor('primary.300'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Failed to load image',
                        style: TypographyTokens.getStyle('body.small').copyWith(
                          color: ColorTokens.getColor('primary.300'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      // 예외 발생 시 기본 이미지 표시
      print('Error loading image: $e');
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: ColorTokens.getColor('primary.50'),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error,
                size: 36,
                color: ColorTokens.getColor('primary.300'),
              ),
              const SizedBox(height: 4),
              Text(
                'Error loading image',
                style: TypographyTokens.getStyle('body.small').copyWith(
                  color: ColorTokens.getColor('primary.300'),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildTextSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Text(
            note.title,
            style: TypographyTokens.getStyle('title.medium'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // 날짜
          Text(
            _formatDate(note.updatedAt),
            style: TypographyTokens.getStyle('body.small').copyWith(
              color: ColorTokens.getColor('text.secondary'),
            ),
          ),
          const SizedBox(height: 8),
          // 플래시카드 카운터
          if (note.flashCards.isNotEmpty) ...[
            FlashcardCounter(
              flashCards: note.flashCards,
              noteTitle: note.title,
              noteId: note.id,
            ),
          ],
          // 액션 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => onTitleEdit(note, note.title),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () => onDuplicate(note),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18),
                onPressed: () => onDelete(note),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormatter.formatDate(date);
  }
}
