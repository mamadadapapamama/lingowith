import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/widgets/text_highlighter.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mlw/screens/image_viewer_screen.dart';
import 'package:mlw/screens/note_detail_screen.dart';
import 'package:mlw/models/text_display_mode.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:mlw/widgets/dictionary_lookup_sheet.dart';

class NotePage extends StatefulWidget {
  final note_model.Page page;
  final TextDisplayMode displayMode;
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
    required this.displayMode,
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
  bool _isExpanding = false;
  bool _isMorePressed = false;
  int? _playingSentenceIndex;  // 현재 재생 중인 문장 인덱스
  String? _selectedText;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // 버튼 상태 리셋을 위한 메서드
  void _resetButtonStates() {
    setState(() {
      _isExpanding = false;
      _isMorePressed = false;
    });
  }

  // TTS 재생 처리 메서드
  void _handleTTS(String text, int index) {
    setState(() {
      _playingSentenceIndex = index;  // 재생 시작
    });
    
    widget.onSpeak?.call(text).then((_) {
      if (mounted) {
        setState(() {
          _playingSentenceIndex = null;  // 재생 완료
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(  // 페이지 배경색 추가
      color: ColorTokens.getColor('base.0'),
      child: Column(
        children: [
          // Image section with buttons
          SizedBox(
            width: double.infinity,
            child: Stack(
              children: [
                // Image
                AspectRatio(
                  aspectRatio: 4/3,
                  child: Image.file(
                    File(widget.page.imageUrl),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Buttons overlay
                Positioned(
                  top: 16,
                  right: 16,
                  child: Row(
                    children: [
                      // Expand button
                      _buildActionButton(
                        icon: 'assets/icon/expand.svg',
                        onTap: () {
                          setState(() {
                            _isExpanding = true;
                          });
                          _openImageViewer(context);
                        },
                      ),
                      // More button
                      _buildActionButton(
                        icon: 'assets/icon/more.svg',
                        onTap: () {
                          setState(() {
                            _isMorePressed = true;
                          });
                          _showMoreOptions();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Text content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(  // Container 대신 Padding 사용
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildSentences(widget.page.extractedText, widget.page.translatedText),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: ColorTokens.getColor('base.800').withOpacity(0.2),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        highlightColor: ColorTokens.getColor('base.800').withOpacity(0.6),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SvgPicture.asset(
            icon,
            colorFilter: ColorFilter.mode(
              ColorTokens.getColor('base.0'),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSentences(String originalText, String translatedText) {
    // 원문 텍스트 전처리
    final processedOriginalText = originalText
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .join('\n');


    // 문장 단위로 분리 (중국어 구분자: 。, ，, ：, ！)
    final originalSentences = processedOriginalText
      .split(RegExp(r'[。，：！]'))  // 중국어 구분자로 분리
      .map((sentence) {
        return sentence
          .trim()
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll('  ', ' ');
      })
      .where((sentence) => sentence.isNotEmpty)
      .toList();

    // 번역 텍스트 전처리 (한글 구분자: ., ,, :, !)
    final translatedSentences = translatedText
      .split(RegExp(r'[.,:]|!'))  // 한글 구분자로 분리
      .map((sentence) => sentence.trim())
      .where((sentence) => sentence.isNotEmpty)
      .toList();
    
    List<Widget> widgets = [];
    
    for (var i = 0; i < originalSentences.length; i++) {
      final int currentIndex = i;
      
      // Container를 먼저 추가하고 그 안에서 조건부 렌더링
      widgets.add(
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 원문 텍스트 (originalOnly 또는 both 모드일 때만 표시)
              if (widget.displayMode != TextDisplayMode.translationOnly)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SelectableText(
                        '${originalSentences[i]}${_getOriginalPunctuation(i, processedOriginalText)}',
                        style: TypographyTokens.getStyle('heading.h3').copyWith(
                          color: ColorTokens.getColor('text.body'),
                          backgroundColor: widget.highlightedTexts.contains(originalSentences[i])
                            ? ColorTokens.getColor('tertiary.400')
                            : Colors.transparent,
                        ),
                        contextMenuBuilder: (context, editableTextState) {
                          final Offset globalPosition = editableTextState.contextMenuAnchors.primaryAnchor;
                          
                          return Stack(
                            children: [
                              Positioned(
                                left: globalPosition.dx,
                                top: globalPosition.dy - 48,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: ColorTokens.getColor('base.0'),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              final String selectedText = editableTextState.textEditingValue.selection
                                                  .textInside(editableTextState.textEditingValue.text);
                                              Clipboard.setData(ClipboardData(text: selectedText));
                                              editableTextState.hideToolbar();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('텍스트가 복사되었습니다'),
                                                  duration: Duration(seconds: 1),
                                                ),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            ),
                                            child: Text(
                                              'Copy',
                                              style: TypographyTokens.getStyle('body.small').copyWith(
                                                color: ColorTokens.getColor('text.body'),
                                              ),
                                            ),
                                          ),
                                          Container(width: 1, height: 24, color: ColorTokens.getColor('base.200')),
                                          TextButton(
                                            onPressed: () {
                                              final String selectedText = editableTextState.textEditingValue.selection
                                                  .textInside(editableTextState.textEditingValue.text);
                                              widget.onHighlighted(selectedText);
                                              editableTextState.hideToolbar();
                                            },
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            ),
                                            child: Text(
                                              'Highlight',
                                              style: TypographyTokens.getStyle('body.small').copyWith(
                                                color: ColorTokens.getColor('text.body'),
                                              ),
                                            ),
                                          ),
                                          Container(width: 1, height: 24, color: ColorTokens.getColor('base.200')),
                                          TextButton(
                                            onPressed: () {
                                              final String selectedText = editableTextState.textEditingValue.selection
                                                  .textInside(editableTextState.textEditingValue.text);
                                              _showDictionaryLookup(context, selectedText);
                                              editableTextState.hideToolbar();
                                            },
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            ),
                                            child: Text(
                                              'Look Up',
                                              style: TypographyTokens.getStyle('body.small').copyWith(
                                                color: ColorTokens.getColor('text.body'),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _playingSentenceIndex == currentIndex
                          ? ColorTokens.getColor('secondary.400')
                          : ColorTokens.getColor('primary.25'),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.volume_up,
                          size: 16,
                          color: _playingSentenceIndex == currentIndex
                            ? ColorTokens.getColor('base.0')
                            : ColorTokens.getColor('secondary.100'),
                        ),
                        onPressed: () => _handleTTS(originalSentences[currentIndex], currentIndex),
                      ),
                    ),
                  ],
                ),
              // 번역 텍스트 (translationOnly 또는 both 모드일 때만 표시)
              if (widget.displayMode != TextDisplayMode.originalOnly && i < translatedSentences.length)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    translatedSentences[i],
                    style: TypographyTokens.getStyle('body.small').copyWith(
                      color: ColorTokens.getColor('text.translation'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

      // 문장 사이의 간격
      if (i < originalSentences.length - 1) {
        widgets.add(const SizedBox(height: 16));
      }
    }
    
    return widgets;
  }

  // 원문의 구분자를 찾아 반환하는 헬퍼 메서드
  String _getOriginalPunctuation(int index, String originalText) {
    final punctuations = RegExp(r'[。，：！]').allMatches(originalText).toList();
    if (index < punctuations.length) {
      return punctuations[index].group(0) ?? '。';
    }
    return '。';
  }

  void _showMoreOptions() async {
    await showModalBottomSheet(
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
    _resetButtonStates();  // 모달 닫힐 때 상태 리셋
  }

  void _openImageViewer(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(
          imageUrl: widget.page.imageUrl,
          extractedText: widget.page.extractedText,
          translatedText: widget.page.translatedText,
        ),
      ),
    );
    _resetButtonStates();  // 화면 복귀 시 상태 리셋
  }

  void _showTextOptions(BuildContext context, String text) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: ColorTokens.getColor('base.0'),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.content_copy,
                  color: ColorTokens.getColor('text.body'),
                ),
                title: Text(
                  'Copy',
                  style: TypographyTokens.getStyle('body.medium').copyWith(
                    color: ColorTokens.getColor('text.body'),
                  ),
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: text));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('텍스트가 복사되었습니다')),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.highlight,
                  color: ColorTokens.getColor('text.body'),
                ),
                title: Text(
                  'Highlight',
                  style: TypographyTokens.getStyle('body.medium').copyWith(
                    color: ColorTokens.getColor('text.body'),
                  ),
                ),
                onTap: () {
                  widget.onHighlighted(text);
                  Navigator.pop(context);
                },
                tileColor: widget.highlightedTexts.contains(text)
                  ? ColorTokens.getColor('tertiary.200')
                  : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDictionaryLookup(BuildContext context, String word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => DictionaryLookupSheet(
          word: word,
          scrollController: scrollController,
        ),
      ),
    );
  }
} 