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
  final bool hasTestSchedule;
  final String testMessage;
  final Function(Note) onDuplicate;
  final Function(Note) onDelete;
  final Function(Note, String)? onTitleEdit;

  const NoteCard({
    super.key,
    required this.note,
    required this.hasTestSchedule,
    required this.testMessage,
    required this.onDuplicate,
    required this.onDelete,
    this.onTitleEdit,
  });

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  void _showEditDialog(BuildContext context) {
    final titleController = TextEditingController(text: note.title);
    final translationController = TextEditingController(text: note.translatedText);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: translationController,
              decoration: const InputDecoration(labelText: 'Translation'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onTitleEdit?.call(note, titleController.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showEditDialog(context);
            },
            child: const Text('Edit'),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              onDelete(note);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Note'),
        content: Text('Do you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              onDelete(note);
              Navigator.pop(context);
            },
            child: Text('Yes'),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ColorTokens.semantic['surface']?['base'] ?? Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: ColorTokens.base[800]!.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with date and test schedule
            Row(
              children: [
                Text(
                  _formatDate(note.createdAt),
                  style: GoogleFonts.poppins(
                    color: ColorTokens.base[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                if (hasTestSchedule)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorTokens.primary[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Test in 1 day',
                      style: GoogleFonts.poppins(
                        color: ColorTokens.primary[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () {
                    showMenu(
                      context: context,
                      position: RelativeRect.fromLTRB(100, 100, 0, 0),
                      items: [
                        PopupMenuItem(
                          child: Text('Edit'),
                          value: 'edit',
                        ),
                        PopupMenuItem(
                          child: Text('Delete'),
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

            // Content row with image and text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      File(note.imageUrl!),
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
                        note.title,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: ColorTokens.semantic['text']?['body'],
                        ),
                      ),
                      if (note.translatedText != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          note.translatedText!.split('\n').first,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: ColorTokens.base[600],
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

            // Flash card count
            if (note.flashCards.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorTokens.primary[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.style,
                      size: 16,
                      color: ColorTokens.primary[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      note.flashCards.length.toString(),
                      style: GoogleFonts.poppins(
                        color: ColorTokens.primary[400],
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
