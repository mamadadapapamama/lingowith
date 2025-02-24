import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:mlw/widgets/dictionary_lookup_sheet.dart';

class TextHighlighter extends StatelessWidget {
  final String text;
  final bool isHighlightMode;
  final Set<String> highlightedTexts;
  final Function(String) onHighlighted;
  final TextStyle style;
  final Color? highlightColor;
  final Function(BuildContext, String, TextSelectionState)? contextMenuBuilder;

  const TextHighlighter({
    Key? key,
    required this.text,
    required this.isHighlightMode,
    required this.highlightedTexts,
    required this.onHighlighted,
    required this.style,
    this.highlightColor,
    this.contextMenuBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<TextSpan> spans = [];
    final RegExp pattern = RegExp(r'[\u4e00-\u9fa5]+'); // Chinese characters pattern
    final matches = pattern.allMatches(text);
    int lastEnd = 0;

    for (var match in matches) {
      // Add non-Chinese text before the match
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: style,
        ));
      }

      // Add Chinese text with highlight
      final chineseText = match.group(0)!;
      final isHighlighted = highlightedTexts.contains(chineseText);

      spans.add(TextSpan(
        text: chineseText,
        style: style.copyWith(
          backgroundColor: isHighlighted 
            ? ColorTokens.getColor('tertiary.200')  // 하이라이트된 단어
            : null,
        ),
      ));

      lastEnd = match.end;
    }

    // Add any remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: style,
      ));
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      contextMenuBuilder: (context, editableTextState) {
        final selectedText = editableTextState.textEditingValue.selection.textInside(text);
        
        // 중국어 문자가 포함된 경우에만 특별 메뉴 표시
        if (RegExp(r'[\u4e00-\u9fa5]').hasMatch(selectedText)) {
          return AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: [
              // 복사 버튼
              ContextMenuButtonItem(
                label: 'Copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: selectedText));
                  editableTextState.hideToolbar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('텍스트가 복사되었습니다')),
                  );
                },
              ),
              // 사전 검색 버튼
              ContextMenuButtonItem(
                label: 'Look up',
                onPressed: () {
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
                        word: selectedText,
                        scrollController: scrollController,
                      ),
                    ),
                  );
                  editableTextState.hideToolbar();
                },
              ),
              // 하이라이트 버튼 (이미 하이라이트되지 않은 경우에만)
              if (!highlightedTexts.contains(selectedText))
                ContextMenuButtonItem(
                  label: 'Highlight',
                  onPressed: () {
                    onHighlighted(selectedText);  // 하이라이트 및 플래시카드 추가
                    editableTextState.hideToolbar();
                  },
                ),
            ],
          );
        }

        // 중국어가 아닌 경우 기본 메뉴
        return AdaptiveTextSelectionToolbar.editableText(
          editableTextState: editableTextState,
        );
      },
    );
  }
}

class TextSelectionState {
  final TextSelectionToolbarAnchors contextMenuAnchors;
  final VoidCallback hideToolbar;

  TextSelectionState({
    required this.contextMenuAnchors,
    required this.hideToolbar,
  });
}
