import 'package:flutter/material.dart';
import 'package:mlw/styles/app_colors.dart';

class TextHighlighter extends StatefulWidget {
  final String text;
  final Function(String) onHighlighted;
  final bool isHighlightMode;

  const TextHighlighter({
    Key? key,
    required this.text,
    required this.onHighlighted,
    required this.isHighlightMode,
  }) : super(key: key);

  @override
  State<TextHighlighter> createState() => _TextHighlighterState();
}

class _TextHighlighterState extends State<TextHighlighter> {
  @override
  Widget build(BuildContext context) {
    return SelectableText(
      widget.text,
      style: TextStyle(
        fontSize: 16,
        color: AppColors.deepGreen,
      ),
      onSelectionChanged: widget.isHighlightMode ? (selection, cause) {
        if (selection.baseOffset != selection.extentOffset) {
          final selectedText = widget.text.substring(
            selection.start,
            selection.end,
          );
          widget.onHighlighted(selectedText);
        }
      } : null,
    );
  }
}
