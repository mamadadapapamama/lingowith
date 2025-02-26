import 'package:pinyin/pinyin.dart';
import 'package:flutter_open_chinese_convert/flutter_open_chinese_convert.dart';

class PinyinService {
  // 핀인 변환
  Future<String> getPinyin(String text) async {
    return PinyinHelper.getPinyin(text, separator: ' ');
  }
  
  // 간체자 → 번체자 변환
  Future<String> convertToTraditional(String text) async {
    return await ChineseConverter.convert(text, S2T());
  }
  
  // 번체자 → 간체자 변환
  Future<String> convertToSimplified(String text) async {
    return await ChineseConverter.convert(text, T2S());
  }
  
  // 간체자 → 대만식 번체자 변환 (대만 관용어 포함)
  Future<String> convertToTaiwanese(String text) async {
    return await ChineseConverter.convert(text, S2TWp());
  }

  // 여러 텍스트에서 핀인 일괄 생성
  Future<List<String>> getPinyinBatch(List<String> texts) async {
    final results = <String>[];
    
    for (final text in texts) {
      final pinyin = await getPinyin(text);
      results.add(pinyin);
    }
    
    return results;
  }

  // convertToPinyin 메서드 추가
  Future<String> convertToPinyin(String text) async {
    // 실제 구현은 외부 라이브러리나 API를 사용할 수 있습니다
    // 여기서는 간단한 예시로 구현
    
    // 중국어 문자와 핀인 매핑 (일부 예시)
    final Map<String, String> pinyinMap = {
      '你': 'nǐ',
      '好': 'hǎo',
      '我': 'wǒ',
      '是': 'shì',
      '中': 'zhōng',
      '国': 'guó',
      '人': 'rén',
      // 더 많은 매핑 추가 가능
    };
    
    String result = '';
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (pinyinMap.containsKey(char)) {
        result += pinyinMap[char]! + ' ';
      } else {
        result += char;
      }
    }
    
    return result.trim();
  }
}

final pinyinService = PinyinService(); 