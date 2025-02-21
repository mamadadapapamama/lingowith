import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/widgets/text_highlighter.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mlw/screens/image_viewer_screen.dart';

class NotePage extends StatefulWidget {
  final note_model.Page page;
  final bool showTranslation;
  final bool isHighlightMode;
  final Set<String> highlightedTexts;
  final Function(String)? onHighlighted;
  final Function(String)? onSpeak;
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
    this.onHighlighted,
    this.onSpeak,
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
  late AnimationController _animation;
  bool _isFlipped = false;
  List<String> _sentences = [];
  List<String> _translations = [];
  int? _playingSentenceIndex;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeSentences();
  }

  void _initializeSentences() {
    _sentences = widget.page.extractedText.split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();
    _translations = widget.page.translatedText.split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  @override
  void didUpdateWidget(NotePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page.extractedText != widget.page.extractedText ||
        oldWidget.page.translatedText != widget.page.translatedText) {
      _initializeSentences();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  void _flip() {
    setState(() {
      if (_isFlipped) {
        _animation.reverse();
      } else {
        _animation.forward();
      }
      _isFlipped = !_isFlipped;
    });
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit, color: ColorTokens.semantic['text']['body']),
            title: Text(
              'Edit Text',
              style: TypographyTokens.getStyle('body.medium').copyWith(
                color: ColorTokens.semantic['text']['body'],
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              widget.onEditText?.call(widget.page.extractedText);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: ColorTokens.semantic['text']['body']),
            title: Text(
              'Delete Page',
              style: TypographyTokens.getStyle('body.medium').copyWith(
                color: ColorTokens.semantic['text']['body'],
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              widget.onDeletePage?.call();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSentence(String text, String? translation, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.isHighlightMode
                    ? TextHighlighter(
                        text: text,
                        style: TypographyTokens.getStyle('heading.h2').copyWith(
                          color: ColorTokens.semantic['text']['body'],
                        ),
                        highlightedTexts: widget.highlightedTexts,
                        onHighlighted: widget.onHighlighted ?? (_) {},
                        isHighlightMode: widget.isHighlightMode,
                      )
                    : Text(
                        text,
                        style: TypographyTokens.getStyle('heading.h2').copyWith(
                          color: ColorTokens.semantic['text']['body'],
                        ),
                      ),
                if (widget.showTranslation && translation != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    translation,
                    style: TypographyTokens.getStyle('body.small').copyWith(
                      color: ColorTokens.semantic['text']['translation'],
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: SvgPicture.asset(
              'assets/icon/sound.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                _playingSentenceIndex == index
                    ? ColorTokens.secondary[400]!
                    : ColorTokens.secondary[200]!,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () {
              setState(() {
                _playingSentenceIndex = index;
              });
              widget.onSpeak?.call(text);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _sentences.length; i++)
            _buildSentence(
              _sentences[i],
              i < _translations.length ? _translations[i] : null,
              i,
            ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    return Transform(
      transform: Matrix4.identity()..rotateY(_animation.value >= 0.5 ? pi : 0),
      alignment: Alignment.center,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
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
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(widget.page.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.flip_camera_android),
              onPressed: _flip,
              style: IconButton.styleFrom(
                backgroundColor: ColorTokens.semantic['surface']['base'],
                foregroundColor: ColorTokens.semantic['text']['primary'],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: Container(
        decoration: BoxDecoration(
          color: ColorTokens.semantic['surface']['base'],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_animation.value * pi);
            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: _animation.value >= 0.5
                ? Stack(
                    children: [
                      _buildImageContent(),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: IconButton(
                          icon: const Icon(Icons.flip_camera_android),
                          onPressed: _flip,
                          style: IconButton.styleFrom(
                            backgroundColor: ColorTokens.semantic['surface']['base'],
                            foregroundColor: ColorTokens.semantic['text']['primary'],
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
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
                                    selectedColor: ColorTokens.semantic['text']['primary'],
                                    fillColor: ColorTokens.secondary[400],
                                    color: ColorTokens.secondary[300],
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
                                    borderColor: ColorTokens.base[300],
                                    selectedBorderColor: ColorTokens.base[300],
                                    renderBorder: true,
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
                      _buildTextContent(),
                    ],
                  ),
            );
          },
        ),
      ),
    );
  }
} 