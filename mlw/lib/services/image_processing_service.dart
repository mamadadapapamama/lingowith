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
  static final ImageProcessingService _instance = ImageProcessingService._internal();
  
  factory ImageProcessingService() {
    return _instance;
  }
  
  ImageProcessingService._internal();
  
  final TranslatorService _translatorService = TranslatorService();
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Google API 키 로드 등의 초기화 작업
      await _loadServiceAccountKey();
      await _translatorService.initialize();
      _initialized = true;
    } catch (e) {
      print('ImageProcessingService 초기화 실패: $e');
      throw Exception('이미지 처리 서비스 초기화 중 오류가 발생했습니다: $e');
    }
  }
  
  // 이미지 선택 및 처리
  Future<ImageProcessingResult?> pickAndProcessImage({ImageSource source = ImageSource.gallery}) async {
    if (!_initialized) {
      await initialize();
    }
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image == null) {
        return null;  // 사용자가 취소함
      }
      
      return await processImage(File(image.path));
    } catch (e) {
      print('이미지 선택 및 처리 오류: $e');
      return null;
    }
  }
  
  // 이미지 처리
  Future<ImageProcessingResult?> processImage(File imageFile) async {
    if (!_initialized) {
      await initialize();
    }
    
    try {
      // 이미지 파일 저장
      final savedImagePath = await saveImageLocally(imageFile);
      
      // 텍스트 추출
      final imageBytes = await imageFile.readAsBytes();
      final extractedText = await extractTextFromImage(imageBytes);
      
      if (extractedText.isEmpty) {
        print('이미지에서 텍스트를 추출할 수 없습니다.');
        return ImageProcessingResult(
          imageUrl: savedImagePath,
          extractedText: '',
          translatedText: '',
        );
      }
      
      // 텍스트 번역
      final translatedText = await _translatorService.translateText(extractedText);
      
      return ImageProcessingResult(
        imageUrl: savedImagePath,
        extractedText: extractedText,
        translatedText: translatedText,
      );
    } catch (e) {
      print('이미지 처리 오류: $e');
      return null;
    }
  }
  
  // 이미지 로컬 저장
  Future<String> saveImageLocally(File image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImagePath = '${directory.path}/$fileName';
      
      // 이미지 파일 복사
      await image.copy(savedImagePath);
      
      // 파일 존재 확인
      final savedFile = File(savedImagePath);
      final exists = await savedFile.exists();
      
      if (!exists) {
        throw Exception('이미지 파일이 저장되지 않았습니다');
      }
      
      return savedImagePath;
    } catch (e) {
      print('이미지 저장 오류: $e');
      throw Exception('이미지 저장 중 오류가 발생했습니다: $e');
    }
  }
  
  // 텍스트 추출
  Future<String> extractTextFromImage(List<int> imageBytes) async {
    try {
      // 서비스 계정 키 로드
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
      print('텍스트 추출 오류: $e');
      return '';
    }
  }
  
  Future<void> _loadServiceAccountKey() async {
    // 서비스 계정 키 로드 및 검증
    try {
      final keyJson = await rootBundle.loadString('assets/service-account-key.json');
      final decodedJson = jsonDecode(keyJson);
      print('서비스 계정 키 로드 성공');
    } catch (e) {
      print('서비스 계정 키 로드 오류: $e');
      throw Exception('서비스 계정 키를 로드할 수 없습니다: $e');
    }
  }
} 