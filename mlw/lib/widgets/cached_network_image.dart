import 'package:flutter/material.dart';
import 'dart:io';
import 'package:mlw/utils/logger.dart';

/// 로컬 파일 이미지를 캐싱하여 표시하는 위젯
///
/// 이미지 로딩 상태, 오류 상태를 처리하고 적절한 UI를 표시합니다.
class CachedFileImage extends StatefulWidget {
  final String filePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  
  const CachedFileImage({
    Key? key,
    required this.filePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);
  
  @override
  State<CachedFileImage> createState() => _CachedFileImageState();
}

class _CachedFileImageState extends State<CachedFileImage> {
  File? _cachedFile;
  bool _isLoading = true;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    _loadImage();
  }
  
  Future<void> _loadImage() async {
    try {
      // 로컬 파일 확인
      final file = File(widget.filePath);
      if (await file.exists()) {
        if (mounted) {
          setState(() {
            _cachedFile = file;
            _isLoading = false;
          });
        }
        return;
      }
      
      // URL 처리 (간단한 방식)
      if (widget.filePath.startsWith('http')) {
        // URL 처리는 별도의 패키지 없이는 복잡하므로 오류 상태로 처리
        Logger.log('URL 이미지는 지원하지 않습니다: ${widget.filePath}');
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
        return;
      }
      
      // 파일이 존재하지 않고 URL도 아닌 경우
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Error loading image', e);
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_hasError || _cachedFile == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: Icon(Icons.error),
        ),
      );
    }
    
    return Image.file(
      _cachedFile!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: const Center(
            child: Icon(Icons.broken_image),
          ),
        );
      },
    );
  }
} 