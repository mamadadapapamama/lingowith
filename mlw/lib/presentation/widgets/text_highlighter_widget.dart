import 'package:flutter/material.dart';

class TextHighlighterWidget extends StatefulWidget {
  final String text;
  final Function(String) onTextSelected;
  final bool highlightEnabled;
  
  const TextHighlighterWidget({
    Key? key,
    required this.text,
    required this.onTextSelected,
    this.highlightEnabled = true,
  }) : super(key: key);

  @override
  State<TextHighlighterWidget> createState() => _TextHighlighterWidgetState();
}

class _TextHighlighterWidgetState extends State<TextHighlighterWidget> {
  String _selectedText = '';
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: widget.highlightEnabled ? _showSelectionMenu : null,
      child: SelectableText(
        widget.text,
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
        ),
        onSelectionChanged: widget.highlightEnabled ? _onSelectionChanged : null,
      ),
    );
  }
  
  void _onSelectionChanged(TextSelection selection, SelectionChangedCause? cause) {
    if (selection.isValid && selection.start != selection.end) {
      _selectedText = widget.text.substring(selection.start, selection.end);
    } else {
      _selectedText = '';
    }
  }
  
  void _showSelectionMenu() {
    if (_selectedText.isEmpty) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + renderBox.size.width,
        position.dy + renderBox.size.height,
      ),
      items: [
        PopupMenuItem(
          child: const Text('번역하기'),
          onTap: () => widget.onTextSelected(_selectedText),
        ),
        PopupMenuItem(
          child: const Text('플래시카드 생성'),
          onTap: () => widget.onTextSelected(_selectedText),
        ),
      ],
    );
  }
} 