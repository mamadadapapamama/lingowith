import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:intl/intl.dart';
import 'package:mlw/screens/note_detail_screen.dart';
import 'package:mlw/widgets/flashcard_counter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';

class NoteCard extends StatelessWidget {
  final note_model.Note note;
  final Function(note_model.Note) onDuplicate;
  final Function(note_model.Note) onDelete;
  final Function(note_model.Note, String)? onTitleEdit;

  const NoteCard({
    super.key,
    required this.note,
    required this.onDuplicate,
    required this.onDelete,
    this.onTitleEdit,
  });

  @override
  Widget build(BuildContext context) {
    print("Note title: ${note.title}");
    print("FlashCards count: ${note.flashCards.length}");
    print("FlashCards: ${note.flashCards}");

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NoteDetailScreen(note: note)),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        decoration: BoxDecoration(
          color: ColorTokens.semantic['surface']['base'],
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.semantic['text']['body'].withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  DateFormat('yyyy.MM.dd').format(note.createdAt),
                  style: GoogleFonts.poppins(
                    color: ColorTokens.base[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '| ${note.pages.length} pages',
                  style: GoogleFonts.poppins(
                    color: ColorTokens.base[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: ColorTokens.base[500],
                  ),
                  onPressed: () {
                    showMenu<String>(
                      context: context,
                      position: RelativeRect.fromLTRB(100, 100, 0, 0),
                      items: [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ).then((value) {
                      if (value == 'edit') {
                        onTitleEdit?.call(note, note.title);
                      } else if (value == 'delete') {
                        onDelete(note);
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.pages.isNotEmpty && note.pages.first.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      File(note.pages.first.imageUrl),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title.isNotEmpty
                            ? note.title
                            : note.pages.first.extractedText.split('\n').first,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: ColorTokens.semantic['text']['heading'],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (note.flashCards.isNotEmpty)
                        FlashcardCounter(
                          flashCards: note.flashCards,
                          noteTitle: note.title,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
