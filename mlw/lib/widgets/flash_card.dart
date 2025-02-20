import 'package:flutter/material.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';

class FlashCard extends StatelessWidget {
  final String front;
  final String back;
  final bool showFront;

  const FlashCard({
    super.key,
    required this.front,
    required this.back,
    required this.showFront,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColorTokens.getColor('surface'),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: ColorTokens.getColor('text').withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            showFront ? front : back,
            style: TypographyTokens.getStyle('body.large').copyWith(
              color: ColorTokens.getColor('text'),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            showFront ? 'Chinese' : 'Korean',
            style: TypographyTokens.getStyle('body.small').copyWith(
              color: ColorTokens.getColor('description'),
            ),
          ),
        ],
      ),
    );
  }
} 