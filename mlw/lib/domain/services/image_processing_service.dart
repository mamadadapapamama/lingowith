import 'dart:io';
import 'package:mlw/services/translator.dart';
import 'package:mlw/services/pinyin_service.dart';
// import 'package:google_ml_kit/google_ml_kit.dart'; // 주석 처리
// import 'package:firebase_storage/firebase_storage.dart'; // 주석 처리
import 'package:path/path.dart' as path;
// import 'package:uuid/uuid.dart'; // 주석 처리
import 'package:mlw/core/di/service_locator.dart' show FirebaseStorage, Reference, UploadTask, TaskSnapshot;
import 'package:mlw/services/vision_api_service.dart'; // Vision API 서비스 추가

class TextRecognizer {
  Future<RecognizedText> processImage(InputImage inputImage) async {
    // 임시 구현: 고정된 텍스트 반환
    return RecognizedText("这是从图像中提取的文本。\n这是第二行。");
  }
  
  void close() {
    // 리소스 해제 로직
  }
}

class RecognizedText {
  final String text;
  
  RecognizedText(this.text);
}

class InputImage {
  final File file;
  
  InputImage.fromFile(this.file);
}

class GoogleMlKit {
  static final vision = VisionApi();
}

class VisionApi {
  TextRecognizer textRecognizer() {
    return TextRecognizer();
  }
}

// UUID 임시 구현
class Uuid {
  const Uuid();
  
  String v4() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

class ImageProcessingService {
  final TranslatorService _translatorService;
  final PinyinService _pinyinService;
  final FirebaseStorage _storage;
  final TextRecognizer _textRecognizer;
  final VisionApiService? _visionApiService; // Vision API 서비스 추가
  
  ImageProcessingService({
    required TranslatorService translatorService,
    required PinyinService pinyinService,
    required FirebaseStorage storage,
    VisionApiService? visionApiService, // 선택적 매개변수로 추가
  }) : 
    _translatorService = translatorService,
    _pinyinService = pinyinService,
    _storage = storage,
    _visionApiService = visionApiService,
    _textRecognizer = GoogleMlKit.vision.textRecognizer();
  
  // 이미지에서 텍스트 추출
  Future<String> extractTextFromImage(File imageFile) async {
    try {
      // Vision API 서비스가 있으면 사용, 없으면 로컬 구현 사용
      if (_visionApiService != null) {
        return await _visionApiService!.extractTextFromImage(imageFile);
      } else {
        final inputImage = InputImage.fromFile(imageFile);
        final recognizedText = await _textRecognizer.processImage(inputImage);
        return recognizedText.text;
      }
    } catch (e) {
      throw Exception('이미지에서 텍스트를 추출하는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 텍스트 번역
  Future<String> translateText(String text, {String from = 'zh', String to = 'ko'}) async {
    if (text.isEmpty) return '';
    
    final lines = text.split('\n').where((s) => s.trim().isNotEmpty).toList();
    final translatedLines = await Future.wait(
      lines.map((line) => _translatorService.translate(line, from, to))
    );
    return translatedLines.join('\n');
  }
  
  // 중국어 텍스트에 핀인 추가
  Future<String> addPinyinToText(String text) async {
    try {
      return await _pinyinService.convertToPinyin(text);
    } catch (e) {
      throw Exception('핀인을 추가하는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 이미지 업로드 및 URL 반환
  Future<String> uploadImage(File imageFile, String userId) async {
    try {
      final fileName = '${userId}_${const Uuid().v4()}.${imageFile.path.split('.').last}';
      final storageRef = _storage.ref().child('images/$fileName');
      
      final uploadTask = await storageRef.putFile(imageFile);
      final snapshot = await uploadTask.onComplete;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('이미지를 업로드하는 중 오류가 발생했습니다: $e');
    }
  }
  
  // 이미지 처리 파이프라인 (추출 + 번역 + 핀인)
  Future<Map<String, String>> processImage(
    File imageFile,
    String userId,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    try {
      // 이미지 업로드
      final imageUrl = await uploadImage(imageFile, userId);
      
      // 텍스트 추출
      final extractedText = await extractTextFromImage(imageFile);
      
      // 텍스트 번역
      final translatedText = await translateText(
        extractedText,
        from: sourceLanguage,
        to: targetLanguage,
      );
      
      // 핀인 추가 (중국어인 경우)
      String pinyinText = '';
      if (sourceLanguage.toLowerCase() == 'zh-cn' || 
          sourceLanguage.toLowerCase() == 'chinese') {
        pinyinText = await addPinyinToText(extractedText);
      }
      
      return {
        'imageUrl': imageUrl,
        'originalText': extractedText,
        'translatedText': translatedText,
        'pinyinText': pinyinText,
      };
    } catch (e) {
      throw Exception('이미지 처리 중 오류가 발생했습니다: $e');
    }
  }
  
  // 리소스 해제
  void dispose() {
    _textRecognizer.close();
  }
} 