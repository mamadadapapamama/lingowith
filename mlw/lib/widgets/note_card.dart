import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:mlw/theme/tokens/color_tokens.dart';

class NoteCard extends StatefulWidget {
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

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _isEditing = false;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(12), // spacing-300
      decoration: BoxDecoration(
        color: ColorTokens.semantic['surface']!['base'], // surface/base
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
          // Date and Test Schedule
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(widget.note.createdAt),
                style: GoogleFonts.poppins(
                  color: ColorTokens.base[400], // base/400
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (widget.hasTestSchedule)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorTokens.primary[50], // primary/50
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Test in ${widget.testMessage}',
                    style: TextStyle(
                      color: ColorTokens.primary[400], // primary/400
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8), // spacing-200
          
          // Note Image
          if (widget.note.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(
                File(widget.note.imageUrl!),
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 8), // spacing-200

          // Title
          Text(
            widget.note.title,
            style: GoogleFonts.poppins(
              color: ColorTokens.semantic['text']!['body'], // text/body
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          // Translation
          if (widget.note.translatedText != null)
            Text(
              widget.note.translatedText!,
              style: GoogleFonts.inter(
                color: ColorTokens.semantic['text']!['body'], // text/body
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          
          // Flash Cards Count
          if (widget.note.flashCards.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: ColorTokens.primary[50], // primary/50
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.style,
                    size: 16,
                    color: ColorTokens.secondary[400], // secondary/400
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.note.flashCards.length.toString(),
                    style: GoogleFonts.inter(
                      color: ColorTokens.secondary[400], // secondary/400
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
