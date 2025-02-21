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

  @override
  void dispose() {
    for (var recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<TextSpan> spans = [];
    final RegExp pattern = RegExp(r'[\u4e00-\u9fa5]+'); // Chinese characters pattern
    final matches = pattern.allMatches(widget.text);
    int lastEnd = 0;

    for (var match in matches) {
      // Add non-Chinese text before the match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: widget.text.substring(lastEnd, match.start),
          style: widget.style,
        ));
      }

      // Add Chinese text with gesture recognizer
      final chineseText = match.group(0)!;
      final isHighlighted = widget.highlightedTexts.contains(chineseText);
      final isSelected = _selectedText == chineseText;

      final recognizer = TapGestureRecognizer()
        ..onTapDown = widget.isHighlightMode ? (details) {
          setState(() {
            _selectedText = chineseText;
          });
          widget.onHighlighted(chineseText);
        } : null;

      _recognizers.add(recognizer);

      spans.add(TextSpan(
        text: chineseText,
        style: (widget.style ?? TypographyTokens.getStyle('body.medium')).copyWith(
          backgroundColor: isHighlighted
              ? ColorTokens.secondary[200]?.withOpacity(0.2)
              : isSelected && widget.isHighlightMode
                  ? ColorTokens.secondary[200]?.withOpacity(0.1)
                  : Colors.transparent,
        ),
        recognizer: widget.isHighlightMode ? recognizer : null,
      ));

      lastEnd = match.end;
    }

    // Add any remaining text
    if (lastEnd < widget.text.length) {
      spans.add(TextSpan(
        text: widget.text.substring(lastEnd),
        style: widget.style,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
