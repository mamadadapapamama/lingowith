import 'package:flutter/material.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' show pi;

class FlashCard extends StatefulWidget {
  final String front;
  final String back;
  final String? pinyin;
  final bool showFront;
  final VoidCallback onFlip;
  final VoidCallback onKeep;
  final VoidCallback onArchive;
  final FlutterTts flutterTts;

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
  });

  @override
  State<FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends State<FlashCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -pi / 2),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: pi / 2, end: 0.0),
        weight: 1.0,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    widget.onFlip();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(widget.front),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          widget.onKeep();
        } else {
          widget.onArchive();
        }
      },
      background: Container(
        color: ColorTokens.getColor('primary.400').withOpacity(0.1),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: SvgPicture.asset(
          'assets/icon/star.svg',
          colorFilter: ColorFilter.mode(
            ColorTokens.getColor('primary.400'),
            BlendMode.srcIn,
          ),
        ),
      ),
      secondaryBackground: Container(
        color: ColorTokens.getColor('secondary.400').withOpacity(0.1),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: SvgPicture.asset(
          'assets/icon/archive.svg',
          colorFilter: ColorFilter.mode(
            ColorTokens.getColor('secondary.400'),
            BlendMode.srcIn,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_animation.value),
              alignment: Alignment.center,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: widget.showFront 
                    ? ColorTokens.getColor('tertiary.100')
                    : ColorTokens.getColor('surface.base'),
                  border: Border.all(
                    color: ColorTokens.getColor('primary.400'),
                    width: 2,
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
                    if (widget.showFront)
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
                          onPressed: () => _speak(widget.front),
                        ),
                      ),
                    
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.showFront ? widget.front : widget.back,
                            style: TypographyTokens.getStyle('heading.h2').copyWith(
                              color: ColorTokens.getColor('text.body'),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (widget.showFront && widget.pinyin != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              widget.pinyin!,
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
            );
          },
        ),
      ),
    );
  }

  Future<void> _speak(String text) async {
    await widget.flutterTts.setLanguage('zh-CN');
    await widget.flutterTts.speak(text);
  }
} 