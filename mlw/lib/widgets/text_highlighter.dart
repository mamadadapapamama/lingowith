import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mlw/widgets/dictionary_lookup_sheet.dart';

class TextHighlighter extends StatelessWidget {
  final String text;
  final bool isHighlightMode;
  final Set<String> highlightedTexts;
  final Function(String) onHighlighted;
  final Color highlightColor;
  final TextStyle style;

  const TextHighlighter({
    Key? key,
    required this.text,
    required this.isHighlightMode,
    required this.highlightedTexts,
    required this.onHighlighted,
    required this.highlightColor,
    required this.style,
    Widget Function(BuildContext, EditableTextState)? contextMenuBuilder,
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
      contextMenuBuilder: (context, editableTextState) {
        try {
          final TextEditingValue value = editableTextState.textEditingValue;
          final TextSelection selection = value.selection;
          
          if (selection.isCollapsed || 
              selection.baseOffset < 0 || 
              selection.extentOffset > text.length) {
            return Container();
          }
          
          final String selectedText = value.text.substring(
            selection.baseOffset, 
            selection.extentOffset
          );
          
          print('Selected text: $selectedText');
          print('Is highlight mode: $isHighlightMode');
          
          return AdaptiveTextSelectionToolbar(
            anchors: editableTextState.contextMenuAnchors,
            children: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: selectedText));
                  editableTextState.hideToolbar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Text copied')),
                  );
                },
                child: const Text('Copy'),
              ),
              // 항상 하이라이트 버튼 표시 (조건 검사 제거)
              TextButton(
                onPressed: () {
                  print('Highlight button pressed for: $selectedText');
                  onHighlighted(selectedText);
                  editableTextState.hideToolbar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Text highlighted')),
                  );
                },
                child: const Text('Highlight'),
              ),
              TextButton(
                onPressed: () {
                  _showDictionaryLookup(context, selectedText);
                  editableTextState.hideToolbar();
                },
                child: const Text('Dictionary'),
              ),
            ],
          );
        } catch (e) {
          print('Error in context menu: $e');
          return Container();
        }
      },
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
