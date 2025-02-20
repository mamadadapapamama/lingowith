import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/widgets/text_highlighter.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'dart:io';

class NotePage extends StatefulWidget {
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

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showImage = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleView() {
    setState(() {
      _showImage = !_showImage;
      if (_showImage) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

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
                if (widget.onEditText != null) {
                  widget.onEditText!(widget.page.extractedText);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('페이지 삭제'),
              onTap: () {
                Navigator.pop(context);
                if (widget.onDeletePage != null) {
                  widget.onDeletePage!();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    final lines = widget.page.extractedText.split('\n');
    final translatedLines = widget.page.translatedText.split('\n');

    return Column(
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
                  onPressed: () => widget.onSpeak(lines[i].trim()),
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
                        onHighlighted: widget.onHighlighted,
                        isHighlightMode: widget.isHighlightMode,
                        highlightedTexts: widget.highlightedTexts,
                        style: TypographyTokens.getStyle('body').copyWith(
                          color: ColorTokens.semantic['text']?['body'],
                          fontSize: 18,
                        ),
                      ),
                      if (widget.showTranslation && i < translatedLines.length && translatedLines[i].trim().isNotEmpty)
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
            SizedBox(height: widget.showTranslation ? 12 : 4),
        ],
      ],
    );
  }

  Widget _buildImageContent() {
    final lines = widget.page.extractedText.split('\n');
    final translatedLines = widget.page.translatedText.split('\n');

    return Stack(
      children: [
        Image.file(
          File(widget.page.imageUrl),
          fit: BoxFit.contain,
          width: double.infinity,
        ),
        if (widget.showTranslation)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: lines.length,
                itemBuilder: (context, i) {
                  if (lines[i].trim().isEmpty) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lines[i].trim(),
                          style: TypographyTokens.getStyle('body').copyWith(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        if (i < translatedLines.length && translatedLines[i].trim().isNotEmpty)
                          Text(
                            translatedLines[i].trim(),
                            style: TypographyTokens.getStyle('body').copyWith(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                GestureDetector(
                  onTap: _toggleView,
                  child: Hero(
                    tag: widget.page.imageUrl,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(widget.page.imageUrl),
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                      ),
                    ),
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
                        isSelected: [widget.showTranslation, widget.isHighlightMode],
                        onPressed: (int index) {
                          if (index == 0) {
                            widget.onToggleTranslation?.call();
                          } else if (index == 1) {
                            widget.onToggleHighlight?.call();
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
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final transform = Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_animation.value * 3.14);
              return Transform(
                transform: transform,
                alignment: Alignment.center,
                child: _showImage ? _buildImageContent() : _buildTextContent(),
              );
            },
          ),
        ],
      ),
    );
  }
} 