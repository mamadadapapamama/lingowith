import 'dart:io';
import 'package:flutter/services.dart';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:googleapis_auth/auth_io.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:mlw/services/translator_service.dart';
import 'package:image_picker/image_picker.dart';

class ImageProcessingResult {
  final String imageUrl;
  final String extractedText;
  final String translatedText;
  
  ImageProcessingResult({
    required this.imageUrl,
    required this.extractedText,
    required this.translatedText,
  });
}

class ImageProcessingService {
  final TranslatorService translatorService;
  
  ImageProcessingService({required this.translatorService});
  
  Future<String> saveImageLocally(File image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await image.copy('${directory.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      print('Error saving image: $e');
      rethrow;
    }
  }
  
  Future<String> extractTextFromImage(List<int> imageBytes) async {
    try {
      final keyJson = await rootBundle.loadString('assets/service-account-key.json');
      final credentials = ServiceAccountCredentials.fromJson(keyJson);
      final client = await clientViaServiceAccount(credentials, [vision.VisionApi.cloudVisionScope]);
      final api = vision.VisionApi(client);

      try {
        final request = vision.BatchAnnotateImagesRequest(requests: [
          vision.AnnotateImageRequest(
            image: vision.Image(content: base64Encode(imageBytes)),
            features: [vision.Feature(type: 'TEXT_DETECTION')],
            imageContext: vision.ImageContext(languageHints: ['zh']),
          ),
        ]);

        final response = await api.images.annotate(request)
          .timeout(const Duration(seconds: 30));

        if (response.responses == null || response.responses!.isEmpty) {
          return '';
        }

        final texts = response.responses!.first.textAnnotations;
        if (texts == null || texts.isEmpty) return '';

        final lines = texts.first.description?.split('\n') ?? [];
        final chineseLines = lines.where((line) {
          final hasChineseChar = RegExp(r'[\u4e00-\u9fa5]').hasMatch(line);
          final isOnlyNumbers = RegExp(r'^[0-9\s]*$').hasMatch(line);
          return hasChineseChar && !isOnlyNumbers;
        }).toList();

        return chineseLines.join('\n');
      } finally {
        client.close();
      }
    } catch (e) {
      print('Vision API error: $e');
      return '';
    }
  }
  
  Future<String> translateText(String text, {String from = 'zh', String to = 'ko'}) async {
    if (text.isEmpty) return '';
    
    final lines = text.split('\n').where((s) => s.trim().isNotEmpty).toList();
    final translatedLines = await Future.wait(
      lines.map((line) => translatorService.translate(line, to, sourceLanguage: from))
    );
    return translatedLines.join('\n');
  }

  Future<ImageProcessingResult?> processImage(ImageSource source) async {
    try {
      // 이미지 선택
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile == null) {
        print('이미지를 선택하지 않았습니다.');
        return null;
      }
      
      // 이미지 파일 저장
      final imageFile = File(pickedFile.path);
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await imageFile.copy('${appDir.path}/$fileName');
      // 텍스트 추출: read image file as bytes before processing
      final imageBytes = await savedImage.readAsBytes();
      final extractedText = await extractTextFromImage(imageBytes);
      if (extractedText.isEmpty) {
        print('이미지에서 텍스트를 추출할 수 없습니다.');
        return null;
      }
      
      // 텍스트 번역
      final translatedText = await translateText(extractedText);
      
      return ImageProcessingResult(
        imageUrl: savedImage.path,
        extractedText: extractedText,
        translatedText: translatedText,
      );
    } catch (e) {
      print('이미지 처리 오류: $e');
      return null;
    }
  }

  Future<List<ImageProcessingResult>> processMultipleImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isEmpty) {
      return [];
    }
    
    List<ImageProcessingResult> results = [];
    
    for (var image in images) {
      try {
        // Create a File from XFile path and process it
        final result = await _processImageFile(File(image.path));
        if (result != null) {
          results.add(result);
        }
      } catch (e) {
        print('이미지 처리 오류: $e');
      }
    }
    
    return results;
  }

  Future<ImageProcessingResult?> _processImageFile(File imageFile) async {
    try {
      // 이미지 파일 저장
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await imageFile.copy('${appDir.path}/$fileName');
      
      // 텍스트 추출
      final imageBytes = await savedImage.readAsBytes();
      final extractedText = await extractTextFromImage(imageBytes);
      if (extractedText.isEmpty) {
        print('이미지에서 텍스트를 추출할 수 없습니다.');
        return null;
      }
      
      // 텍스트 번역
      final translatedText = await translateText(extractedText);
      
      return ImageProcessingResult(
        imageUrl: savedImage.path,
        extractedText: extractedText,
        translatedText: translatedText,
      );
    } catch (e) {
      print('이미지 파일 처리 오류: $e');
      return null;
    }
  }
} 