import 'package:mlw/models/dictionary_result.dart';

class DictionaryService {
  Future<DictionaryResult> lookup(String word) async {
    // TODO: 실제 API 연동
    // 현재는 더미 데이터 반환
    return DictionaryResult(
      word: word,
      simplified: word,
      traditional: word,
      pinyin: "pinyin",
      meanings: ["의미1", "의미2"],
      examples: ["예문1", "예문2"],
      hskLevel: 3,
    );
  }
} 