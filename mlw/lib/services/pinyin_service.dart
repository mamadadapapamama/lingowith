import 'package:pinyin/pinyin.dart';

class PinyinService {
  Future<String> getPinyin(String text) async {
    try {
      // 음조 표시와 함께 pinyin 변환
      return PinyinHelper.getPinyin(text, 
        separator: " ",  // 공백으로 구분
        format: PinyinFormat.WITH_TONE_MARK  // 음조 표시 포함
      );
    } catch (e) {
      print('Pinyin conversion error: $e');
      return 'pinyin 데이터가 없습니다';
    }
  }
}

final pinyinService = PinyinService(); 