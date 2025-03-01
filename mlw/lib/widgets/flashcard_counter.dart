import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:mlw/screens/flashcard_screen.dart';
import 'package:mlw/models/note.dart' as note_model;
import 'package:mlw/models/flash_card.dart';

class FlashcardCounter extends StatelessWidget {
  final List<FlashCard> flashCards;
  final String noteTitle;
  final String noteId; // 노트 ID 추가
  final int knownCount;
  final bool isInteractive;
  final bool alwaysShow;
  final VoidCallback? onTap;

  const FlashcardCounter({
    Key? key,
    required this.flashCards,
    required this.noteTitle,
    required this.noteId, // 필수 파라미터로 추가
    this.knownCount = 0,
    this.isInteractive = true,
    this.alwaysShow = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('FlashcardCounter - flashCards count: ${flashCards.length}');
    print('FlashcardCounter - known cards: $knownCount');
    
    if (!alwaysShow && flashCards.isEmpty) {
      return const SizedBox.shrink();
    }

    // 남은 카드 수 계산
    final remainingCards = flashCards.length - knownCount;
    
    // 남은 카드가 없으면 표시하지 않음
    if (remainingCards <= 0 && !alwaysShow) {
      return const SizedBox.shrink();
    }

    Widget counter = Container(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: ColorTokens.getColor('tertiary.400'),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icon/flashcard_color.svg',
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 1),
          Text(
            '$remainingCards 플래시카드',
            style: TypographyTokens.getStyle('button.small').copyWith(
              color: ColorTokens.getColor('text.body'),
            ),
          ),
        ],
      ),
    );

    if (!isInteractive || remainingCards <= 0) return counter;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap ?? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FlashcardScreen.fromParts(
                flashCards: flashCards,
                title: noteTitle,
                noteId: noteId,
              ),
            ),
          );
        },
        child: counter,
      ),
    );
  }
} 