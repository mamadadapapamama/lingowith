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
  final Function()? onDeletePage;
  final Function(String)? onEditText;
  final Function()? onToggleTranslation;
  final Function()? onToggleHighlight;

  const NotePage({
    Key? key,
    required this.page,
    required this.showTranslation,
    required this.isHighlightMode,
    required this.highlightedTexts,
    required this.onHighlighted,
    required this.onSpeak,
    this.currentPlayingIndex,
    this.onDeletePage,
    this.onEditText,
    this.onToggleTranslation,
    this.onToggleHighlight,
  }) : super(key: key);

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('텍스트 수정'),
              onTap: () {
                Navigator.pop(context);
                if (onEditText != null) {
                  onEditText!(page.extractedText);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('페이지 삭제'),
              onTap: () {
                Navigator.pop(context);
                if (onDeletePage != null) {
                  onDeletePage!();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = page.extractedText.split('\n');
    final translatedLines = page.translatedText.split('\n');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorTokens.secondary[25],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(page.imageUrl),
                    fit: BoxFit.cover,
                    width: 80,
                    height: 80,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ToggleButtons(
                        borderRadius: BorderRadius.circular(8),
                        selectedColor: ColorTokens.primary[400],
                        fillColor: ColorTokens.primary[50],
                        color: ColorTokens.semantic['text']?['body'],
                        constraints: const BoxConstraints(
                          minHeight: 36,
                          minWidth: 36,
                        ),
                        isSelected: [showTranslation, isHighlightMode],
                        onPressed: (int index) {
                          if (index == 0) {
                            onToggleTranslation?.call();
                          } else if (index == 1) {
                            onToggleHighlight?.call();
                          }
                        },
                        children: const [
                          Icon(Icons.translate),
                          Icon(Icons.highlight),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showMoreOptions(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < lines.length; i++) ...[
                  if (lines[i].trim().isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.volume_up,
                            color: ColorTokens.secondary[100],
                          ),
                          onPressed: () => onSpeak(lines[i].trim()),
                          style: IconButton.styleFrom(
                            foregroundColor: ColorTokens.secondary[100],
                            highlightColor: ColorTokens.secondary[300]?.withOpacity(0.2),
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
                                  fontSize: 18,
                                ),
                              ),
                              if (showTranslation && i < translatedLines.length && translatedLines[i].trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    translatedLines[i].trim(),
                                    style: TypographyTokens.getStyle('body').copyWith(
                                      color: ColorTokens.semantic['text']?['translation'],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  if (i < lines.length - 1 && lines[i].trim().isNotEmpty)
                    SizedBox(height: showTranslation ? 12 : 4),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
} 