import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslatorService {
  // 기본 번역 메서드 (HTTP API 사용)
  Future<String> translate(String text, {String from = 'auto', String to = 'ko'}) async {
    if (text.isEmpty) return '';
    
    try {
      final url = Uri.parse('https://translate.googleapis.com/translate_a/single?client=gtx&sl=$from&tl=$to&dt=t&q=${Uri.encodeComponent(text)}');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final translations = jsonResponse[0] as List;
        
        String translatedText = '';
        for (var translation in translations) {
          if (translation[0] != null) {
            translatedText += translation[0];
          }
        }
        
        return translatedText;
      } else {
        return '(번역없음)';
      }
    } catch (e) {
      print('번역 오류: $e');
      return '(번역없음)';
    }
  }
}

final translatorService = TranslatorService();