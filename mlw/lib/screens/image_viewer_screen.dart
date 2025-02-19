import 'package:flutter/material.dart';
import 'dart:io';
import 'package:mlw/theme/tokens/color_tokens.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;

  const ImageViewerScreen({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.semantic['surface']?['background'],
      appBar: AppBar(
        backgroundColor: ColorTokens.semantic['surface']?['background'],
        iconTheme: IconThemeData(
          color: ColorTokens.semantic['text']?['body'],
        ),
      ),
      body: Center(
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
    );
  }
} 