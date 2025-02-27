import 'package:flutter/material.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/widgets/text_highlighter.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mlw/screens/image_viewer_screen.dart';
import 'package:mlw/models/text_display_mode.dart';
import 'package:mlw/widgets/dictionary_lookup_sheet.dart';
import 'package:mlw/services/translator_service.dart';

class NotePage extends StatefulWidget {
  final note_model.Page page;
  final TextDisplayMode displayMode;
  final bool isHighlightMode;
  final Set<String> highlightedTexts;
  final Function(String) onHighlighted;
  final Function(String) onSpeak;
  final int? currentPlayingIndex;
  final VoidCallback onDeletePage;
  final Function(String) onEditText;

  const NotePage({
    Key? key,
    required this.page,
    required this.displayMode,
    required this.isHighlightMode,
    required this.highlightedTexts,
    required this.onHighlighted,
    required this.onSpeak,
    this.currentPlayingIndex,
    required this.onDeletePage,
    required this.onEditText,
  }) : super(key: key);

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  // ValueNotifier로 변경
  final ValueNotifier<int?> _playingSentenceIndex = ValueNotifier<int?>(null);
  bool _isExpanding = false;
  bool _isMorePressed = false;
  String? _selectedText;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _playingSentenceIndex.dispose();  // ValueNotifier 정리
    super.dispose();
  }

  // 버튼 상태 리셋을 위한 메서드
  void _resetButtonStates() {
    setState(() {
      _isExpanding = false;
      _isMorePressed = false;
    });
  }

  // TTS 재생 처리 메서드 최적화
  Future<void> _handleTTS(String text, int index) async {
    // 이미 재생 중인 문장이 있다면 중지
    if (_playingSentenceIndex.value != null) {
      await widget.onSpeak.call('');  // TTS 중지
    }

    try {
      _playingSentenceIndex.value = index;  // 재생 시작
      
      await widget.onSpeak.call(text);
      
      // 현재 인덱스가 여전히 같은 경우에만 null로 설정
      if (_playingSentenceIndex.value == index) {
        _playingSentenceIndex.value = null;  // 재생 완료
      }
    } catch (e) {
      print('TTS error: $e');
      _playingSentenceIndex.value = null;  // 에러 시에도 초기화
    }
  }

  @override
  Widget build(BuildContext context) {
    print('NotePage - isHighlightMode: ${widget.isHighlightMode}');
    print('NotePage - highlightedTexts: ${widget.highlightedTexts}');
    
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
                            _isExpanding = !_isExpanding;
                          });
                          _openImageViewer(context);
                        },
                      ),
                      // More button
                      _buildActionButton(
                        icon: 'assets/icon/more.svg',
                        onTap: () {
                          setState(() {
                            _isMorePressed = !_isMorePressed;
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
    return Container(
      width: 40,  // 고정 크기
      height: 40,
      margin: const EdgeInsets.only(left: 8),  // 버튼 간격
      child: Material(
        color: ColorTokens.getColor('base.800').withOpacity(0.2),
        shape: const CircleBorder(),  // 원형 모양
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),  // 터치 효과도 원형
          child: Center(  // 아이콘 중앙 정렬
            child: SvgPicture.asset(
              icon,
              width: 24,  // 아이콘 크기
              height: 24,
              colorFilter: ColorFilter.mode(
                ColorTokens.getColor('base.0'),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> _splitChineseText(String text) {
    if (text.isEmpty) return [];
    
    // 중국어는 문장 부호로 분리
    return text
      .split(RegExp(r'[\.!？。，:]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  }

  List<String> _splitKoreanTranslation(String translation) {
    if (translation.isEmpty) return [];

    // 한국어는 문장 단위로 분리하되, 따옴표 내의 내용을 하나로 처리
    List<String> sentences = translation.split(RegExp(r'(?<=[..!?"]) +|(?<=[.!?])\s+'));
    List<String> mergedSentences = [];
    String tempSentence = "";
    bool insideQuote = false;

    for (String sentence in sentences) {
      if (sentence.contains('"')) {
        int quoteCount = sentence.split('"').length - 1;
        insideQuote = (quoteCount % 2 != 0) ? !insideQuote : insideQuote;
      }

      // 따옴표 안의 내용과 밖의 내용을 구분하여 처리
      if (insideQuote) {
        tempSentence += (tempSentence.isEmpty ? "" : ' ') + sentence.trim();
      } else {
        if (tempSentence.isNotEmpty) {
          mergedSentences.add('$tempSentence ${sentence.trim()}');
          tempSentence = "";
        } else {
          mergedSentences.add(sentence.trim());
        }
      }
    }

    if (tempSentence.isNotEmpty) {
      mergedSentences.add(tempSentence);
    }

    return mergedSentences.where((s) => s.isNotEmpty).toList();
  }

  List<(String, String)> _matchTranslations(String chineseText, String koreanTranslation) {
    // 전체 원문과 번역문
    final fullChineseText = chineseText.trim();
    final fullKoreanText = koreanTranslation.trim();
    
    // ! 기준으로 분리
    List<String> chineseSentences = _splitChineseText(fullChineseText);
    List<String> koreanSentences = _splitKoreanTranslation(fullKoreanText);

    // 문장이 하나도 분리되지 않은 경우 전체를 하나의 문장으로 처리
    if (chineseSentences.isEmpty) {
      chineseSentences = [fullChineseText];
    }
    if (koreanSentences.isEmpty) {
      koreanSentences = [fullKoreanText];
    }
    
    List<(String, String)> matchedSentences = [];
    
    for (int i = 0; i < chineseSentences.length; i++) {
      String korean = i < koreanSentences.length ? koreanSentences[i] : fullKoreanText;
      matchedSentences.add((chineseSentences[i], korean));
    }

    return matchedSentences;
  }

  List<Widget> _buildSentences(String originalText, String translatedText) {
    final matchedSentences = _matchTranslations(originalText, translatedText);

    return matchedSentences.map((pair) {
      final (chinese, korean) = pair;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 중국어 문장과 TTS 버튼
          Row(
            children: [
              Expanded(
                child: TextHighlighter(
                  text: chinese,
                  isHighlightMode: widget.isHighlightMode,
                  highlightedTexts: widget.highlightedTexts,
                  onHighlighted: widget.onHighlighted,
                  highlightColor: ColorTokens.getColor('tertiary.200'),
                  style: TypographyTokens.getStyle('body.original'),
                  contextMenuBuilder: null,
                ),
              ),
              // TTS 버튼
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(left: 8),
                child: Material(
                  color: ColorTokens.getColor('primary.25'),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      final index = matchedSentences.indexOf(pair);
                      if (_playingSentenceIndex.value == index) {
                        widget.onSpeak.call('');
                        _playingSentenceIndex.value = null;
                      } else {
                        _handleTTS(chinese, index);
                      }
                    },
                    highlightColor: ColorTokens.getColor('secondary.400').withOpacity(0.1),
                    splashColor: ColorTokens.getColor('secondary.400').withOpacity(0.2),
                    child: Center(
                      child: ValueListenableBuilder<int?>(
                        valueListenable: _playingSentenceIndex,
                        builder: (context, playingIndex, _) {
                          final isPlaying = playingIndex == matchedSentences.indexOf(pair);
                          return SvgPicture.asset(
                            'assets/icon/sound.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              ColorTokens.getColor('secondary.100'),
                              BlendMode.srcIn,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // 한국어 번역문
          if (widget.displayMode != TextDisplayMode.originalOnly && korean.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              korean,
              style: TypographyTokens.getStyle('body.large').copyWith(
                color: ColorTokens.getColor('text.translation'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      );
    }).toList();
  }

  Widget _buildSentence(String text, int index) {
    return ValueListenableBuilder<int?>(
      valueListenable: _playingSentenceIndex,
      builder: (context, playingIndex, child) {
        return TextHighlighter(
          text: text,
          isHighlightMode: widget.isHighlightMode,
          highlightedTexts: widget.highlightedTexts,
          onHighlighted: widget.onHighlighted,
          highlightColor: ColorTokens.getColor('tertiary.200'),
          style: TypographyTokens.getStyle('body.large').copyWith(
            color: ColorTokens.getColor('text.body'),
            height: 1.8,
          ),
          contextMenuBuilder: null,
        );
      },
    );
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
                widget.onEditText.call(widget.page.extractedText);
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
                widget.onDeletePage.call();
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

  void _showDictionaryLookup(BuildContext context, String word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
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