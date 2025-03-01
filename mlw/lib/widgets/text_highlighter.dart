import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mlw/widgets/dictionary_lookup_sheet.dart';

class TextHighlighter extends StatelessWidget {
  final String text;
  final Set<String> highlightedTexts;
  final bool isHighlightMode;
  final Function(String) onHighlighted;
  final TextStyle style;
  final Color highlightColor;

  const TextHighlighter({
    Key? key,
    required this.text,
    required this.highlightedTexts,
    required this.isHighlightMode,
    required this.onHighlighted,
    required this.highlightColor,
    this.style = const TextStyle(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 디버그 로그 추가
    print('TextHighlighter - text: $text');
    print('TextHighlighter - highlightedTexts: $highlightedTexts');
    print('TextHighlighter - isHighlightMode: $isHighlightMode');

    // 텍스트 분할 및 하이라이트 처리
    List<TextSpan> spans = [];
    
    // 하이라이트된 텍스트가 없거나 하이라이트 모드가 아닌 경우
    if (highlightedTexts.isEmpty || !isHighlightMode) {
      spans = [TextSpan(text: text, style: style)];
    } else {
      // 하이라이트 처리
      String remaining = text;
      List<(int, int, String)> highlights = [];
      
      // 모든 하이라이트 위치 찾기
      for (String highlight in highlightedTexts) {
        if (highlight.isEmpty) continue;
        
        int startIndex = 0;
        while (true) {
          int index = text.indexOf(highlight, startIndex);  // remaining -> text로 변경
          if (index == -1) break;
          
          highlights.add((index, index + highlight.length, highlight));
          startIndex = index + 1;
        }
      }
      
      // 위치별로 정렬
      highlights.sort((a, b) => a.$1.compareTo(b.$1));
      
      // 겹치는 하이라이트 제거
      List<(int, int, String)> filteredHighlights = [];
      for (var highlight in highlights) {
        if (filteredHighlights.isEmpty) {
          filteredHighlights.add(highlight);
          continue;
        }
        
        var last = filteredHighlights.last;
        if (highlight.$1 >= last.$2) {
          filteredHighlights.add(highlight);
        }
      }
      
      // 스팬 생성
      int lastIndex = 0;
      for (var highlight in filteredHighlights) {
        if (highlight.$1 > lastIndex) {
          spans.add(TextSpan(
            text: text.substring(lastIndex, highlight.$1),
            style: style,
          ));
        }
        
        spans.add(TextSpan(
          text: highlight.$3,
          style: style.copyWith(
            backgroundColor: highlightColor,
          ),
        ));
        
        lastIndex = highlight.$2;
      }
      
      if (lastIndex < text.length) {
        spans.add(TextSpan(
          text: text.substring(lastIndex),
          style: style,
        ));
      }
    }
    
    // 선택 가능한 텍스트 위젯 생성
    return SelectableText.rich(
      TextSpan(children: spans),
      style: style,
      onSelectionChanged: (selection, cause) {
        if (isHighlightMode && selection.baseOffset != selection.extentOffset) {
          // 텍스트가 선택되었을 때 처리
        }
      },
      contextMenuBuilder: (context, editableTextState) {
        final selectedText = editableTextState.textEditingValue.selection.textInside(editableTextState.textEditingValue.text);
        
        return AdaptiveTextSelectionToolbar(
          anchors: editableTextState.contextMenuAnchors,
          children: [
            // 복사 버튼
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: selectedText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('텍스트가 복사되었습니다')),
                );
                editableTextState.hideToolbar();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: const Text('복사'),
              ),
            ),
            // 하이라이트 버튼
            InkWell(
              onTap: () {
                onHighlighted(selectedText);
                editableTextState.hideToolbar();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: const Text('하이라이트'),
              ),
            ),
          ],
        );
      },
      selectionControls: MaterialTextSelectionControls(),
    );
  }

  // 사전 조회 시트 표시
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

class TextSelectionState {
  final TextSelectionToolbarAnchors contextMenuAnchors;
  final VoidCallback hideToolbar;

  TextSelectionState({
    required this.contextMenuAnchors,
    required this.hideToolbar,
  });
}
