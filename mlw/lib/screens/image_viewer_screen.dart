import 'package:flutter/material.dart';
import 'dart:io';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/models/note.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String extractedText;
  final String translatedText;

  const ImageViewerScreen({
    super.key,
    required this.imageUrl,
    required this.extractedText,
    required this.translatedText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.semantic['surface']?['background'],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: ColorTokens.semantic['text']?['body'],
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                File(imageUrl),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      '이미지를 불러올 수 없습니다.',
                      style: TextStyle(
                        color: ColorTokens.semantic['text']?['body'],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (extractedText.isNotEmpty && translatedText.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      extractedText,
                      style: TextStyle(
                        fontSize: 16,
                        color: ColorTokens.semantic['text']?['body'],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      translatedText,
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorTokens.semantic['text']?['translation'],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
} 