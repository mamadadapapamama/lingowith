import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/widgets/text_highlighter.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'dart:io';
import 'dart:math';

class NotePage extends StatefulWidget {
  final note_model.Page page;
  final bool showTranslation;
  final bool isHighlightMode;
  final Set<String> highlightedTexts;
  final Function(String) onHighlighted;
  final Function(String) onSpeak;
  final int? currentPlayingIndex;
  final VoidCallback? onDeletePage;
  final Function(String)? onEditText;
  final VoidCallback? onToggleTranslation;
  final VoidCallback? onToggleHighlight;

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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack,
      reverseCurve: Curves.easeInOutBack,
    );

    _animation.addListener(() {
      if (_animation.value >= 0.5 && !_showImage) {
        setState(() => _showImage = true);
      } else if (_animation.value < 0.5 && _showImage) {
        setState(() => _showImage = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleView() {
    if (_controller.isAnimating) return;
    if (_showImage) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
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
                      color: ColorTokens.getColor('secondary.100'),
                    ),
                    onPressed: () => widget.onSpeak(lines[i].trim()),
                    style: IconButton.styleFrom(
                      foregroundColor: ColorTokens.getColor('secondary.100'),
                      highlightColor: ColorTokens.getColor('secondary.300').withOpacity(0.2),
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
                            color: ColorTokens.getColor('text'),
                            fontSize: 18,
                          ),
                        ),
                        if (widget.showTranslation && i < translatedLines.length && translatedLines[i].trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              translatedLines[i].trim(),
                              style: TypographyTokens.getStyle('body').copyWith(
                                color: ColorTokens.getColor('translation'),
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
      ),
    );
  }

  Widget _buildImageContent() {
    final lines = widget.page.extractedText.split('\n');
    final translatedLines = widget.page.translatedText.split('\n');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: FileImage(File(widget.page.imageUrl)),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withOpacity(0.7),
        ),
        padding: const EdgeInsets.all(16),
        child: widget.showTranslation
          ? ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
            )
          : const SizedBox(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleView,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
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
                  Hero(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ToggleButtons(
                          borderRadius: BorderRadius.circular(8),
                          selectedColor: ColorTokens.getColor('primary.400'),
                          fillColor: ColorTokens.getColor('primary.50'),
                          color: ColorTokens.getColor('text'),
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
                  ..rotateY(_animation.value * pi);
                return Transform(
                  transform: transform,
                  alignment: Alignment.center,
                  child: _animation.value >= 0.5 ? _buildImageContent() : _buildTextContent(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 