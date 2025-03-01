import 'package:flutter/material.dart';
import 'package:mlw/models/flash_card.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';  // Platform 클래스를 위한 import 추가

class FlashcardWidget extends StatefulWidget {
  final FlashCard flashCard;
  final VoidCallback onDone;

  const FlashcardWidget({
    Key? key,
    required this.flashCard,
    required this.onDone,
  }) : super(key: key);

  @override
  _FlashcardWidgetState createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget> {
  bool _showFront = true;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTTS();
  }

  Future<void> _initTTS() async {
    await _flutterTts.setLanguage("zh-CN");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    if (Platform.isIOS) {
      try {
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playAndRecord,
          [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          ],
        );
      } catch (e) {
        print('iOS 오디오 설정 오류: $e');
      }
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _flipCard() {
    setState(() {
      _showFront = !_showFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ColorTokens.getColor('primary.100'),
                ColorTokens.getColor('primary.50'),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _showFront ? widget.flashCard.front : widget.flashCard.back,
                style: TypographyTokens.getStyle('heading.h1'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_showFront) ...[
                Text(
                  widget.flashCard.pinyin,
                  style: TypographyTokens.getStyle('body.large').copyWith(
                    color: ColorTokens.getColor('text.secondary'),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                IconButton(
                  icon: Icon(
                    Icons.volume_up,
                    color: ColorTokens.getColor('primary.400'),
                    size: 32,
                  ),
                  onPressed: () => _speak(widget.flashCard.front),
                ),
              ],
              const SizedBox(height: 32),
              Text(
                _showFront ? '탭하여 뜻 보기' : '탭하여 단어 보기',
                style: TypographyTokens.getStyle('body.small').copyWith(
                  color: ColorTokens.getColor('text.secondary'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '위로 스와이프하여 완료 표시',
                style: TypographyTokens.getStyle('body.small').copyWith(
                  color: ColorTokens.getColor('success.400'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
} 