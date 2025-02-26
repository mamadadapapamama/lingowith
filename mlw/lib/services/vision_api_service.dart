import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis/vision/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class VisionApiService {
  static const _serviceAccountKeyPath = 'assets/service-account-key.json';
  
  Future<String> extractTextFromImage(File imageFile) async {
    try {
      // 서비스 계정 키 로드
      final serviceAccountJson = await rootBundle.loadString(_serviceAccountKeyPath);
      final serviceAccountCredentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
      
      // 인증 클라이언트 생성
      final scopes = [VisionApi.cloudPlatformScope];
      final client = await clientViaServiceAccount(serviceAccountCredentials, scopes);
      
      // Vision API 인스턴스 생성
      final visionApi = VisionApi(client);
      
      // 이미지 파일을 base64로 인코딩
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // API 요청 생성
      final request = AnnotateImageRequest(
        image: Image(content: base64Image),
        features: [Feature(type: 'TEXT_DETECTION', maxResults: 10)],
      );
      
      // API 호출
      final response = await visionApi.images.annotate(
        BatchAnnotateImagesRequest(requests: [request]),
      );
      
      // 결과 처리
      final textAnnotation = response.responses?.first.textAnnotations?.first;
      final extractedText = textAnnotation?.description ?? '';
      
      // 클라이언트 종료
      client.close();
      
      return extractedText;
    } catch (e) {
      throw Exception('이미지에서 텍스트를 추출하는 중 오류가 발생했습니다: $e');
    }
  }
} 