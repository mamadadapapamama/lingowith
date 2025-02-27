class SimpleTranslatorService {
  // 간단한 중국어-한국어 사전 확장
  final Map<String, String> _zhToKo = {
    '你好': '안녕하세요',
    '谢谢': '감사합니다',
    '再见': '안녕히 가세요',
    '我': '나',
    '你': '너',
    '是': '이다',
    '不': '아니다',
    '学习': '공부하다',
    '中文': '중국어',
    '韩语': '한국어',
    '英语': '영어',
    '日语': '일본어',
    '汉语': '중국어',
    '语言': '언어',
    '词典': '사전',
    '翻译': '번역',
    '单词': '단어',
    '句子': '문장',
    '发音': '발음',
    '写作': '작문',
    '阅读': '독해',
    '听力': '듣기',
    '说话': '말하기',
    '语法': '문법',
    '词汇': '어휘',
    // 더 많은 단어 추가...
  };
  
  // 간단한 중국어-영어 사전 확장
  final Map<String, String> _zhToEn = {
    '你好': 'Hello',
    '谢谢': 'Thank you',
    '再见': 'Goodbye',
    '我': 'I',
    '你': 'You',
    '是': 'is/am/are',
    '不': 'not',
    '学习': 'study',
    '中文': 'Chinese',
    '韩语': 'Korean',
    '英语': 'English',
    '日语': 'Japanese',
    '汉语': 'Chinese',
    '语言': 'language',
    '词典': 'dictionary',
    '翻译': 'translation',
    '单词': 'word',
    '句子': 'sentence',
    '发音': 'pronunciation',
    '写作': 'writing',
    '阅读': 'reading',
    '听力': 'listening',
    '说话': 'speaking',
    '语法': 'grammar',
    '词汇': 'vocabulary',
    // 더 많은 단어 추가...
  };
  
  Future<String> translate(String text, String targetLanguage) async {
    if (text.isEmpty) return '';
    
    try {
      // 대상 언어에 따라 사전 선택
      final dictionary = targetLanguage.toLowerCase() == '한국어' 
          ? _zhToKo 
          : _zhToEn;
      
      // 사전에 있는 단어인지 확인
      if (dictionary.containsKey(text)) {
        return dictionary[text]!;
      }
      
      // 없으면 원문 반환
      return '($text)';
    } catch (e) {
      print('간단 번역 중 오류 발생: $e');
      return '(번역없음)';
    }
  }
}

final simpleTranslatorService = SimpleTranslatorService(); 