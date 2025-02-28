import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'dart:io';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/screens/note_detail_screen.dart';
import 'package:mlw/widgets/flashcard_counter.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:mlw/screens/home/home_screen.dart';
import 'package:mlw/utils/date_formatter.dart';
import 'package:mlw/screens/flashcard_screen.dart';

class NoteCard extends StatefulWidget {
  final note_model.Note note;
  final VoidCallback onPressed;
  final Function(String) onDelete;
  final Function(String, String) onTitleEdit;
  final VoidCallback? onRefresh;

  const NoteCard({
    Key? key,
    required this.note,
    required this.onPressed,
    required this.onDelete,
    required this.onTitleEdit,
    this.onRefresh,
  }) : super(key: key);

  @override
  _NoteCardState createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  @override
  Widget build(BuildContext context) {
    // 디버그 모드에서만 출력
    assert(() {
      print("Building NoteCard for note: ${widget.note.id}, title: ${widget.note.title}");
      return true;
    }());
    
    return GestureDetector(
      onTap: widget.onPressed,
      child: Card(
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
    if (widget.note.pages.isEmpty) {
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
      final File imageFile = File(widget.note.pages.first.imageUrl);
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
            widget.note.title,
            style: TypographyTokens.getStyle('title.medium'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // 날짜
          Text(
            _formatDate(widget.note.updatedAt),
            style: TypographyTokens.getStyle('body.small').copyWith(
              color: ColorTokens.getColor('text.secondary'),
            ),
          ),
          const SizedBox(height: 8),
          // 플래시카드 카운터
          if (widget.note.flashCards.isNotEmpty) ...[
            FlashcardCounter(
              flashCards: widget.note.flashCards,
              noteTitle: widget.note.title,
              noteId: widget.note.id,
            ),
          ],
          // 액션 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () {
                  widget.onTitleEdit(widget.note.id, widget.note.title);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18),
                onPressed: () {
                  final ctx = context;
                  _handleDelete(ctx);
                },
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

  void _handleDelete(BuildContext context) async {
    try {
      // 사용자 확인 다이얼로그 표시
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('노트 삭제'),
          content: const Text('이 노트를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
      
      // 로딩 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('노트를 삭제하는 중...'))
      );
      
      // 노트 삭제 요청
      await widget.onDelete(widget.note.id);
      
      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('노트가 삭제되었습니다'))
      );
    } catch (e) {
      // 오류 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('노트 삭제 중 오류가 발생했습니다: $e'))
      );
      print('노트 삭제 오류: $e');
    }
  }

  void _navigateToFlashcards() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardScreen.fromParts(
          flashCards: widget.note.flashCards,
          title: widget.note.title,
          noteId: widget.note.id,
        ),
      ),
    );
    
    // 플래시카드 화면에서 true를 반환받으면 홈 화면 새로고침
    if (result == true) {
      // 홈 화면 새로고침 요청 - 콜백 사용
      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }
    }
  }
}
