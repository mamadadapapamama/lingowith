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
}

final pinyinService = PinyinService(); 