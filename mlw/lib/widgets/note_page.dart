import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/widgets/text_highlighter.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mlw/screens/image_viewer_screen.dart';

class NotePage extends StatefulWidget {
  final note_model.Page page;
  final bool showTranslation;
  final bool isHighlightMode;
  final Set<String> highlightedTexts;
  final Function(String) onHighlighted;
  final Function(String)? onSpeak;
  final int? currentPlayingIndex;
  final VoidCallback? onDeletePage;
  final Function(String)? onEditText;

  const NotePage({
    Key? key,
    required this.page,
    required this.showTranslation,
    required this.isHighlightMode,
    required this.highlightedTexts,
    required this.onHighlighted,
    this.onSpeak,
    this.currentPlayingIndex,
    this.onDeletePage,
    this.onEditText,
  }) : super(key: key);

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 상단 more 버튼
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: Icon(
              Icons.more_vert,
              color: ColorTokens.getColor('text.body'),
            ),
            onPressed: _showMoreOptions,
          ),
        ),
        
        // 이미지 영역
        AspectRatio(
          aspectRatio: 4/3,
          child: GestureDetector(
            onTap: () => _openImageViewer(context),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: ColorTokens.getColor('border.base'),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(widget.page.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        
        // 텍스트 영역
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 원문 텍스트
                TextHighlighter(
                  text: widget.page.extractedText,
                  style: TypographyTokens.getStyle('body.large').copyWith(
                    color: ColorTokens.getColor('text.body'),
                  ),
                  highlightedTexts: widget.highlightedTexts,
                  isHighlightMode: widget.isHighlightMode,
                  onHighlighted: widget.onHighlighted,
                ),
                if (widget.showTranslation) ...[
                  const SizedBox(height: 16),
                  // 번역 텍스트
                  Text(
                    widget.page.translatedText,
                    style: TypographyTokens.getStyle('body.medium').copyWith(
                      color: ColorTokens.getColor('text.translation'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.edit,
                color: ColorTokens.getColor('text.body'),
              ),
              title: Text(
                'Edit Text',
                style: TypographyTokens.getStyle('body.medium').copyWith(
                  color: ColorTokens.getColor('text.body'),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onEditText?.call(widget.page.extractedText);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: ColorTokens.getColor('text.body'),
              ),
              title: Text(
                'Delete Page',
                style: TypographyTokens.getStyle('body.medium').copyWith(
                  color: ColorTokens.getColor('text.body'),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onDeletePage?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openImageViewer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(
          imageUrl: widget.page.imageUrl,
          extractedText: widget.page.extractedText,
          translatedText: widget.page.translatedText,
        ),
      ),
    );
  }
} 