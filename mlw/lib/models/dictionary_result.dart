class DictionaryResult {
  final String word;          // 검색한 단어
  final String simplified;    // 간체
  final String traditional;   // 번체
  final String pinyin;        // 병음
  final List<String> meanings;// 뜻 목록
  final List<String> examples;// 예문
  final int? hskLevel;       // HSK 레벨

  DictionaryResult({
    required this.word,
    required this.simplified,
    required this.traditional,
    required this.pinyin,
    required this.meanings,
    required this.examples,
    this.hskLevel,
  });
} 