import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:mlw/screens/flash_card_screen.dart';
import 'package:mlw/models/note.dart' as note_model;

class FlashcardCounter extends StatelessWidget {
  final List<note_model.FlashCard> flashCards;
  final String noteTitle;
  final bool isInteractive;
  final bool alwaysShow;  // 추가: 항상 보여줄지 여부

  const FlashcardCounter({
    Key? key,
    required this.flashCards,
    required this.noteTitle,
    this.isInteractive = true,
    this.alwaysShow = false,  // 기본값은 false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // alwaysShow가 false이고 flashCards가 비어있으면 숨김
    if (!alwaysShow && flashCards.isEmpty) return const SizedBox.shrink();

    Widget counter = Container(
      padding: const EdgeInsets.symmetric(
        vertical: 4,  // spacing-100
        horizontal: 12,  // spacing-300
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
            flashCards.length.toString(),
            style: TypographyTokens.getStyle('button.small').copyWith(
              color: ColorTokens.getColor('text.body'),
            ),
          ),
        ],
      ),
    );

    if (!isInteractive) return counter;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FlashCardScreen(
                flashCards: flashCards,
                title: noteTitle,
              ),
            ),
          );
        },
        child: counter,
      ),
    );
  }
} 