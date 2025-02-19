import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mlw/screens/note_detail_screen.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final Function(Note) onDuplicate;
  final Function(Note) onDelete;
  final Function(Note, String)? onTitleEdit;

  const NoteCard({
    super.key,
    required this.note,
    required this.onDuplicate,
    required this.onDelete,
    this.onTitleEdit,
  });

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  void _showEditDialog(BuildContext context) {
    final titleController = TextEditingController(text: note.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Note',
          style: GoogleFonts.poppins(
            color: ColorTokens.getColor('text'),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: GoogleFonts.poppins(
                  color: ColorTokens.getColor('text'),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: ColorTokens.getColor('text'),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              onTitleEdit?.call(note, titleController.text);
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: ColorTokens.getColor('primary.400'),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Note',
          style: GoogleFonts.poppins(
            color: ColorTokens.getColor('text'),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Do you want to delete this note?',
          style: GoogleFonts.poppins(
            color: ColorTokens.getColor('text'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'No',
              style: GoogleFonts.poppins(
                color: ColorTokens.getColor('text'),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              onDelete(note);
              Navigator.pop(context);
            },
            child: Text(
              'Yes',
              style: GoogleFonts.poppins(
                color: ColorTokens.getColor('primary.400'),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteDetailScreen(note: note),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        decoration: BoxDecoration(
          color: ColorTokens.getColor('surface'),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.getColor('text').withOpacity(0.05),
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
                  _formatDate(note.createdAt),
                  style: GoogleFonts.poppins(
                    color: ColorTokens.getColor('disabled'),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '| ${note.pages.length} pages',
                  style: GoogleFonts.poppins(
                    color: ColorTokens.getColor('disabled'),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: ColorTokens.getColor('text'),
                  ),
                  onPressed: () {
                    showMenu(
                      context: context,
                      position: RelativeRect.fromLTRB(100, 100, 0, 0),
                      items: [
                        PopupMenuItem(
                          child: Text(
                            'Edit',
                            style: GoogleFonts.poppins(
                              color: ColorTokens.getColor('text'),
                            ),
                          ),
                          value: 'edit',
                        ),
                        PopupMenuItem(
                          child: Text(
                            'Delete',
                            style: GoogleFonts.poppins(
                              color: ColorTokens.getColor('text'),
                            ),
                          ),
                          value: 'delete',
                        ),
                      ],
                    ).then((value) {
                      if (value == 'edit') {
                        _showEditDialog(context);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(context);
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
                        note.title.isNotEmpty ? note.title : note.pages.first.extractedText.split('\n').first,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: ColorTokens.getColor('text'),
                        ),
                      ),
                      if (note.pages.isNotEmpty && note.pages.first.translatedText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          note.pages.first.translatedText.split('\n').first,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: ColorTokens.getColor('description'),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (note.flashCards.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorTokens.getColor('primary.50'),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.style,
                      size: 16,
                      color: ColorTokens.getColor('primary.400'),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      note.flashCards.length.toString(),
                      style: GoogleFonts.poppins(
                        color: ColorTokens.getColor('primary.400'),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
