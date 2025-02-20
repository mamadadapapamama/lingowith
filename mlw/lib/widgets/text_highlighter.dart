import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';

class TextHighlighter extends StatefulWidget {
  final String text;
  final Function(String) onHighlighted;
  final bool isHighlightMode;
  final Set<String> highlightedTexts;
  final TextStyle? style;

  const TextHighlighter({
    super.key,
    required this.text,
    required this.onHighlighted,
    required this.isHighlightMode,
    required this.highlightedTexts,
    this.style,
  });

  @override
  State<TextHighlighter> createState() => _TextHighlighterState();
}

class _TextHighlighterState extends State<TextHighlighter> {
  String _selectedText = '';
  final List<TapGestureRecognizer> _recognizers = [];

  void _onSelectionChanged(String text) {
    setState(() {
      _selectedText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final words = widget.text.split(' ');
    
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final isHighlighted = widget.highlightedTexts.contains(word);
      final isSelected = _selectedText == word;
      
      TapGestureRecognizer? recognizer;
      if (widget.isHighlightMode) {
        recognizer = TapGestureRecognizer();
        recognizer.onTapDown = (details) {
          _onSelectionChanged(word);
        };
        recognizer.onTapUp = (details) {
          if (_selectedText.isNotEmpty) {
            widget.onHighlighted(_selectedText);
            _onSelectionChanged('');
          }
        };
        recognizer.onTapCancel = () {
          _onSelectionChanged('');
        };
        _recognizers.add(recognizer);
      }
      
      spans.add(
        TextSpan(
          text: word,
          style: (widget.style ?? TypographyTokens.getStyle('body.medium')).copyWith(
            backgroundColor: isHighlighted
                ? ColorTokens.getColor('highlight')
                : isSelected && widget.isHighlightMode
                    ? ColorTokens.getColor('highlight').withOpacity(0.5)
                    : Colors.transparent,
          ),
          recognizer: recognizer,
        ),
      );
      
      if (i < words.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }

    return RichText(
      text: TextSpan(
        children: spans,
      ),
    );
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }
}
