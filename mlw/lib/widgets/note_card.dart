import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart';
import 'package:mlw/screens/note_detail_screen.dart';
import 'package:mlw/theme/app_theme.dart';
import 'package:mlw/styles/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';

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

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _finishEditing() {
    if (_isEditing) {
      setState(() {
        _isEditing = false;
      });
      if (widget.onTitleEdit != null && _titleController.text != widget.note.title) {
        widget.onTitleEdit!(widget.note, _titleController.text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(
          color: AppColors.neonGreen,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(note: widget.note),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.note.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(widget.note.imageUrl!),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatDate(widget.note.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        if (widget.hasTestSchedule)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9BE36D).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.testMessage,
                              style: const TextStyle(
                                color: Color(0xFF9BE36D),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'duplicate') {
                              widget.onDuplicate(widget.note);
                            } else if (value == 'delete') {
                              widget.onDelete(widget.note);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'duplicate',
                              child: Text('복제'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('삭제'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing)
                      TextField(
                        controller: _titleController,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepGreen,
                        ),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onSubmitted: (_) => _finishEditing(),
                        autofocus: true,
                      )
                    else
                      GestureDetector(
                        onTap: _startEditing,
                        child: Text(
                          widget.note.title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepGreen,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (widget.note.translatedText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.note.translatedText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildCardCount(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF9BE36D).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.style,
            size: 16,
            color: Color(0xFF9BE36D),
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.note.flashCards.length} cards',
            style: const TextStyle(
              color: Color(0xFF9BE36D),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
