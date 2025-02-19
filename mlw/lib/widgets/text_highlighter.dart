import 'package:flutter/material.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';

class TextHighlighter extends StatefulWidget {
  final String text;
  final Function(String) onHighlighted;
  final bool isHighlightMode;
  final TextStyle? style;
  final List<String> highlightedTexts;

  const TextHighlighter({
    Key? key,
    required this.text,
    required this.onHighlighted,
    required this.isHighlightMode,
    required this.highlightedTexts,
    this.style,
  }) : super(key: key);

  @override
  State<TextHighlighter> createState() => _TextHighlighterState();
}

class _TextHighlighterState extends State<TextHighlighter> {
  TextSpan _buildTextSpan(String text, TextStyle baseStyle) {
    List<TextSpan> children = [];
    int currentIndex = 0;

    // Sort highlighted texts by length (longest first) to handle overlapping matches
    final sortedHighlights = List<String>.from(widget.highlightedTexts)
      ..sort((a, b) => b.length.compareTo(a.length));

    while (currentIndex < text.length) {
      bool foundMatch = false;
      for (String highlight in sortedHighlights) {
        int matchIndex = text.indexOf(highlight, currentIndex);
        if (matchIndex == currentIndex) {
          children.add(TextSpan(
            text: highlight,
            style: baseStyle.copyWith(
              backgroundColor: ColorTokens.secondary[200],
            ),
          ));
          currentIndex += highlight.length;
          foundMatch = true;
          break;
        }
      }
      if (!foundMatch) {
        // Find next highlight position
        int nextHighlight = text.length;
        for (String highlight in sortedHighlights) {
          int index = text.indexOf(highlight, currentIndex);
          if (index != -1 && index < nextHighlight) {
            nextHighlight = index;
          }
        }
        // Add non-highlighted text
        children.add(TextSpan(
          text: text.substring(currentIndex, nextHighlight),
          style: baseStyle,
        ));
        currentIndex = nextHighlight;
      }
    }

    return TextSpan(children: children);
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ?? TypographyTokens.getStyle('body').copyWith(
      color: ColorTokens.semantic['text']?['body'],
    );

    return SelectableText.rich(
      _buildTextSpan(widget.text, baseStyle),
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
