import 'package:googleapis/translate/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class PinyinService {
  Future<String> getPinyin(String text) async {
    try {
      final keyJson = await rootBundle.loadString('assets/service-account-key.json');
      final jsonMap = json.decode(keyJson);
      final projectId = jsonMap['project_id'] as String;
      final credentials = ServiceAccountCredentials.fromJson(keyJson);
      final client = await clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/cloud-translation'],
      );
      final api = TranslateApi(client);

      try {
        final parent = 'projects/$projectId/locations/global';
        final request = TranslateTextRequest(
          contents: [text],
          sourceLanguageCode: 'zh',
          targetLanguageCode: 'zh',  // 중국어로 설정
        );

        final response = await api.projects.locations.translateText(request, parent);

        if (response.translations == null || response.translations!.isEmpty) {
          throw Exception('No translation result');
        }

        // 번역 결과에서 pinyin 추출
        final pinyin = response.translations!.first.glossaryConfig?.glossary ?? '';
        return pinyin.isNotEmpty ? pinyin : text;  // pinyin이 없으면 원문 반환
      } finally {
        client.close();
      }
    } catch (e) {
      print('Pinyin conversion error: $e');
      return text;  // 오류 발생 시 원문 반환
    }
  }
}

final pinyinService = PinyinService(); 