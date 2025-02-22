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
                      Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorTokens.getColor('base.800').withOpacity(0.7),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isExpanding = true;
                              });
                              _openImageViewer(context);
                            },
                            customBorder: const CircleBorder(),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/icon/expand.svg',
                                width: 24,
                                height: 24,
                                colorFilter: ColorFilter.mode(
                                  _isExpanding 
                                    ? ColorTokens.getColor('secondary.400')
                                    : ColorTokens.getColor('base.200'),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // More button
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorTokens.getColor('base.800').withOpacity(0.7),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isMorePressed = true;
                              });
                              _showMoreOptions();
                            },
                            customBorder: const CircleBorder(),
                            child: Icon(
                              Icons.more_vert,
                              color: _isMorePressed 
                                ? ColorTokens.getColor('secondary.400')
                                : ColorTokens.getColor('base.200'),
                              size: 24,
                            ),
                          ),
                        ),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildSentences(widget.page.extractedText, widget.page.translatedText),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSentences(String originalText, String translatedText) {
    // 원문 텍스트 전처리
    final processedOriginalText = originalText
      .split('\n')  // 줄바꿈으로 분리
      .map((line) => line.trim())  // 각 줄의 앞뒤 공백 제거
      .where((line) => line.isNotEmpty)  // 빈 줄 제거
      .join('\n');  // 다시 합치기

    // 문장 단위로 분리 (중국어는 。로 구분)
    final originalSentences = processedOriginalText
      .split('。')
      .map((sentence) {
        // 문장 정리
        return sentence
          .trim()  // 앞뒤 공백 제거
          .replaceAll(RegExp(r'\s+'), ' ')  // 연속된 공백을 하나로
          .replaceAll('  ', ' ');  // 두 칸 공백을 한 칸으로
      })
      .where((sentence) => sentence.isNotEmpty)  // 빈 문장 제거
      .toList();

    // 번역 텍스트 전처리 (한글은 마침표로 구분)
    final translatedSentences = translatedText
      .split('.')
      .map((sentence) => sentence.trim())
      .where((sentence) => sentence.isNotEmpty)
      .toList();
    
    List<Widget> widgets = [];
    
    for (var i = 0; i < originalSentences.length; i++) {
      if (widget.displayMode != TextDisplayMode.translationOnly) {
        final int currentIndex = i;  // closure를 위해 현재 인덱스 저장
        widgets.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,  // Row의 크기를 내용물 크기에 맞춤
            children: [
              Text(
                '${originalSentences[i]}。',
                style: TypographyTokens.getStyle('heading.h3').copyWith(
                  color: ColorTokens.getColor('text.body'),
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
        );
      }

      // 번역 텍스트 (translationOnly 또는 both 모드일 때만 표시)
      if (widget.displayMode != TextDisplayMode.originalOnly && i < translatedSentences.length) {
        widgets.add(
          Padding(
            padding: widget.displayMode == TextDisplayMode.both
              ? const EdgeInsets.only(left: 16, bottom: 16, top: 4)  // spacing 4px
              : const EdgeInsets.only(left: 16, bottom: 16),
            child: Text(
              translatedSentences[i],
              style: TypographyTokens.getStyle('body.small').copyWith(
                color: ColorTokens.getColor('text.translation'),
              ),
            ),
          ),
        );
      }

      // 문장 사이의 간격
      if (i < originalSentences.length - 1) {
        widgets.add(const SizedBox(height: 16));
      }
    }
    
    return widgets;
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
} 