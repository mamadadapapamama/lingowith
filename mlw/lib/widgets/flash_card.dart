import 'package:flutter/material.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FlashCard extends StatelessWidget {
  final String front;
  final String back;
  final String? pinyin;
  final bool showFront;
  final VoidCallback onFlip;
  final VoidCallback onKeep;
  final VoidCallback onArchive;
  final FlutterTts flutterTts;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const FlashCard({
    super.key,
    required this.front,
    required this.back,
    this.pinyin,
    required this.showFront,
    required this.onFlip,
    required this.onKeep,
    required this.onArchive,
    required this.flutterTts,
    this.onNext,
    this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onFlip,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: showFront 
                  ? ColorTokens.getColor('tertiary.100')
                  : ColorTokens.getColor('surface.base'),
                border: Border.all(
                  color: ColorTokens.getColor('primary.400'),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: ColorTokens.getColor('text.body').withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // TTS 버튼
                  if (showFront)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: SvgPicture.asset(
                          'assets/icon/sound.svg',
                          colorFilter: ColorFilter.mode(
                            ColorTokens.getColor('primary.400'),
                            BlendMode.srcIn,
                          ),
                        ),
                        onPressed: () => _speak(front),
                      ),
                    ),
                  
                  // Keep/Archive 버튼
                  if (!showFront)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: onKeep,
                            icon: SvgPicture.asset(
                              'assets/icon/star.svg',
                              colorFilter: ColorFilter.mode(
                                ColorTokens.getColor('primary.400'),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: onArchive,
                            icon: SvgPicture.asset(
                              'assets/icon/archive.svg',
                              colorFilter: ColorFilter.mode(
                                ColorTokens.getColor('secondary.400'),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // 카드 내용
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          showFront ? front : back,
                          style: TypographyTokens.getStyle('heading.h2').copyWith(
                            color: ColorTokens.getColor('text.body'),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (showFront && pinyin != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            pinyin!,
                            style: TypographyTokens.getStyle('body.large').copyWith(
                              color: ColorTokens.getColor('text.translation'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Bottom Navigation Bar with arrows
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: onPrevious,
                icon: SvgPicture.asset(
                  'assets/icon/arrow-left.svg',
                  colorFilter: ColorFilter.mode(
                    onPrevious != null 
                      ? ColorTokens.getColor('text.body')
                      : ColorTokens.getColor('text.disabled'),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: SvgPicture.asset(
                  'assets/icon/arrow-right.svg',
                  colorFilter: ColorFilter.mode(
                    onNext != null 
                      ? ColorTokens.getColor('text.body')
                      : ColorTokens.getColor('text.disabled'),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage('zh-CN');
    await flutterTts.speak(text);
  }
} 