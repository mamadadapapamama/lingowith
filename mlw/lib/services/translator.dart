import 'package:googleapis/translate/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class TranslatorService {
  Future<String> translate(String text, {String from = 'zh', String to = 'ko'}) async {
    try {
      final keyJson = await rootBundle.loadString('assets/service-account-key.json');
      print('Service account loaded'); // 디버깅

      final jsonMap = json.decode(keyJson);
      final projectId = jsonMap['project_id'] as String;
      print('Project ID: $projectId'); // 디버깅

      final credentials = ServiceAccountCredentials.fromJson(keyJson);
      final client = await clientViaServiceAccount(
        credentials, 
        ['https://www.googleapis.com/auth/cloud-translation'],  // 스코프 변경
      );
      print('Client authenticated'); // 디버깅

      final api = TranslateApi(client);
      final parent = 'projects/$projectId/locations/global';  // location 추가
      
      final request = TranslateTextRequest(
        contents: [text],
        sourceLanguageCode: from,
        targetLanguageCode: to,
      );
      
      print('Sending translation request...'); // 디버깅
      final response = await api.projects.locations.translateText(request, parent);
      print('Translation response: $response'); // 디버깅

      return response.translations?.first.translatedText ?? '';
    } catch (e, stackTrace) {
      print('Translation error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

final translatorService = TranslatorService(); 