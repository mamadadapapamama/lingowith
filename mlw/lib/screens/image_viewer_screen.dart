import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:mlw/theme/tokens/color_tokens.dart';

class ImageViewerScreen extends StatefulWidget {
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
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  final _transformationController = TransformationController();
  late Size _imageSize;
  bool _isImageLoaded = false;
  List<String> _translations = [];

  @override
  void initState() {
    super.initState();
    _loadImage();
    _translations = widget.translatedText
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
  }

  Future<void> _loadImage() async {
    final image = Image.file(File(widget.imageUrl));
    final completer = Completer<void>();
    
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((info, _) {
        setState(() {
          _imageSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
          _isImageLoaded = true;
        });
        completer.complete();
      })
    );
    
    await completer.future;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

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
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              child: Stack(
                children: [
                  Image.file(
                    File(widget.imageUrl),
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
                  if (_isImageLoaded)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _translations.map((translation) => 
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                translation,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: ColorTokens.semantic['text']?['translation'],
                                ),
                              ),
                            )
                          ).toList(),
                        ),
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