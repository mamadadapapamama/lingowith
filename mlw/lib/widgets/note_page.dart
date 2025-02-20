import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/widgets/text_highlighter.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'dart:io';

class NotePage extends StatelessWidget {
  final note_model.Page page;
  final bool showTranslation;
  final bool isHighlightMode;
  final List<String> highlightedTexts;
  final Function(String) onHighlighted;
  final Function(String) onSpeak;
  final int? currentPlayingIndex;

  const NotePage({
    Key? key,
    required this.page,
    required this.showTranslation,
    required this.isHighlightMode,
    required this.highlightedTexts,
    required this.onHighlighted,
    required this.onSpeak,
    this.currentPlayingIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lines = page.extractedText.split('\n');
    final translatedLines = page.translatedText.split('\n');

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: ColorTokens.semantic['border']?['base'] ?? Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(page.imageUrl),
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
              ),
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < lines.length; i++) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton(
                          icon: Icon(
                            Icons.volume_up,
                            color: currentPlayingIndex == i 
                              ? ColorTokens.secondary[200]
                              : ColorTokens.secondary[100],
                          ),
                          onPressed: () => onSpeak(lines[i].trim()),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextHighlighter(
                              text: lines[i].trim(),
                              onHighlighted: onHighlighted,
                              isHighlightMode: isHighlightMode,
                              highlightedTexts: highlightedTexts,
                              style: TypographyTokens.getStyle('body').copyWith(
                                color: ColorTokens.semantic['text']?['body'],
                              ),
                            ),
                            if (showTranslation && i < translatedLines.length && translatedLines[i].trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  translatedLines[i].trim(),
                                  style: TypographyTokens.getButtonStyle(isSmall: true).copyWith(
                                    color: ColorTokens.semantic['text']?['translation'],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (i < lines.length - 1)
                    const SizedBox(height: 12),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
} 