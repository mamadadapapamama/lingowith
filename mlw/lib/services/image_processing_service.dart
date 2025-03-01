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
  
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Google API 키 로드 등의 초기화 작업
      await _loadServiceAccountKey();
      _initialized = true;
    } catch (e) {
      print('ImageProcessingService 초기화 실패: $e');
    }
  }
  
  Future<String> saveImageLocally(File image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImagePath = '${directory.path}/$fileName';
      
      // 이미지 파일 복사
      await image.copy(savedImagePath);
      
      print('이미지 저장 완료: $savedImagePath');
      
      // 파일 존재 확인
      final savedFile = File(savedImagePath);
      final exists = await savedFile.exists();
      print('저장된 이미지 파일 존재 여부: $exists');
      
      if (!exists) {
        throw Exception('이미지 파일이 저장되지 않았습니다');
      }
      
      return savedImagePath;
    } catch (e) {
      print('이미지 저장 오류: $e');
      throw Exception('이미지 저장 중 오류가 발생했습니다: $e');
    }
  }
  
  Future<String> extractTextFromImage(List<int> imageBytes) async {
    try {
      // 서비스 계정 키 로드
      print('서비스 계정 키 파일 로드 시도...');
      final keyJson = await rootBundle.loadString('assets/service-account-key.json');
      print('서비스 계정 키 파일 로드 성공');
      
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
      print('텍스트 추출 오류: $e');
      return '';
    }
  }
  
  Future<String> translateText(String text, {String from = 'zh', String to = 'ko'}) async {
    if (text.isEmpty) return '';
    
    final lines = text.split('\n').where((s) => s.trim().isNotEmpty).toList();
    final translatedLines = await Future.wait(
      lines.map((line) => translatorService.translate(line, from: from, to: to))
    );
    return translatedLines.join('\n');
  }

  Future<ImageProcessingResult?> processImage(File imageFile) async {
    if (!_initialized) {
      await initialize();
    }
    return _processImageFile(imageFile);
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
      final savedImagePath = await saveImageLocally(imageFile);
      
      // 텍스트 추출
      final imageBytes = await imageFile.readAsBytes();
      final extractedText = await extractTextFromImage(imageBytes);
      if (extractedText.isEmpty) {
        print('이미지에서 텍스트를 추출할 수 없습니다.');
        return null;
      }
      
      print('추출된 텍스트: ${extractedText.substring(0, extractedText.length > 50 ? 50 : extractedText.length)}...');
      
      // 텍스트 번역
      String translatedText = '';
      try {
        // 번역 서비스 초기화 확인
        await translatorService.initialize();
        
        // 텍스트 번역
        translatedText = await translatorService.translateText(extractedText);
        print('번역된 텍스트: ${translatedText.substring(0, translatedText.length > 50 ? 50 : translatedText.length)}...');
      } catch (e) {
        print('텍스트 번역 오류: $e');
        // 번역 실패 시 빈 문자열 사용
        translatedText = '';
      }
      
      print('이미지 처리 완료:');
      print('- 이미지 경로: $savedImagePath');
      print('- 추출된 텍스트 길이: ${extractedText.length}');
      print('- 번역된 텍스트 길이: ${translatedText.length}');
      
      return ImageProcessingResult(
        imageUrl: savedImagePath,
        extractedText: extractedText,
        translatedText: translatedText,
      );
    } catch (e) {
      print('이미지 파일 처리 오류: $e');
      return null;
    }
  }
  
  Future<bool> testGoogleApiAuthentication(String keyJson) async {
    // JSON 파싱 검사
    try {
      final decodedJson = jsonDecode(keyJson);
      print('서비스 계정 키 JSON 확인 완료');
    } catch (e) {
      print('서비스 계정 키 JSON 파싱 오류: $e');
      return false;
    }
    
    // Google API 인증 처리
    try {
      final credentials = ServiceAccountCredentials.fromJson(keyJson);
      final client = await clientViaServiceAccount(
        credentials,
        [vision.VisionApi.cloudVisionScope]
      );
      print('Google API 인증 성공');
      client.close();
      return true;
    } catch (e) {
      print('Google API 인증 실패: $e');
      return false;
    }
  }

  Future<void> _loadServiceAccountKey() async {
    // Implementation of _loadServiceAccountKey method
  }
} 