import 'package:cloud_firestore/cloud_firestore.dart';

class Page {
  final String imageUrl;
  final String extractedText;
  final String translatedText;

  Page({
    required this.imageUrl,
    required this.extractedText,
    required this.translatedText,
  });

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'extractedText': extractedText,
      'translatedText': translatedText,
    };
  }

  factory Page.fromJson(Map<String, dynamic> json) {
    return Page(
      imageUrl: json['imageUrl'] as String? ?? '',
      extractedText: json['extractedText'] as String? ?? '',
      translatedText: json['translatedText'] as String? ?? '',
    );
  }
}

class FlashCard {
  final String front;
  final String back;
  final String pinyin;

  FlashCard({
    required this.front,
    required this.back,
    required this.pinyin,
  });

  Map<String, dynamic> toJson() {
    return {
      'front': front,
      'back': back,
      'pinyin': pinyin,
    };
  }

  factory FlashCard.fromJson(Map<String, dynamic> json) {
    return FlashCard(
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
      pinyin: json['pinyin'] as String? ?? '',
    );
  }
}

/// 노트 모델 클래스
/// 
/// 사용자가 생성한 노트를 나타내며, 여러 페이지와 플래시카드를 포함할 수 있습니다.
/// Firestore 데이터베이스와 연동되어 저장 및 로드됩니다.
class Note {
  /// 노트의 고유 식별자
  final String id;
  
  /// 노트가 속한 스페이스의 ID
  final String spaceId;
  
  /// 노트 소유자의 사용자 ID
  final String userId;
  
  /// 노트의 제목
  final String title;
  
  /// 노트의 내용
  final String content;
  
  /// 노트의 페이지 목록
  final List<Page> pages;
  
  /// 노트의 플래시카드 목록
  final List<FlashCard> flashCards;
  
  /// 노트에서 강조된 텍스트 목록
  final Set<String> highlightedTexts;
  
  /// 노트에서 알려진 플래시카드 목록
  final Set<String> knownFlashCards;
  
  /// 노트의 생성 시간
  final DateTime createdAt;
  
  /// 노트의 업데이트 시간
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.spaceId,
    required this.userId,
    this.title = '',
    this.content = '',
    this.pages = const [],
    this.flashCards = const [],
    this.highlightedTexts = const {},
    this.knownFlashCards = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  int get knownFlashCardsCount => knownFlashCards.length;

  int get remainingFlashCardsCount => flashCards.length - knownFlashCardsCount;

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'spaceId': spaceId,
      'userId': userId,
      'title': title,
      'content': content,
      'pages': pages.map((page) => page.toJson()).toList(),
      'flashCards': flashCards.map((card) => card.toJson()).toList(),
      'highlightedTexts': highlightedTexts.toList(),
      'knownFlashCards': knownFlashCards.toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Firestore 문서에서 노트 객체를 생성합니다.
  /// 
  /// [doc]은 Firestore 문서 스냅샷입니다.
  /// 문서 데이터가 유효하지 않은 경우 오류를 기록하고 기본값을 사용합니다.
  factory Note.fromFirestore(DocumentSnapshot doc) {
    try {
      if (!doc.exists) {
        print('노트 문서가 존재하지 않음: ${doc.id}');
        return Note.empty(id: doc.id);
      }
      
      final data = doc.data() as Map<String, dynamic>?;
      
      if (data == null) {
        print('노트 데이터가 null임: ${doc.id}');
        return Note.empty(id: doc.id);
      }
      
      print('노트 데이터 로드 시작: ${doc.id}');
      
      // 타임스탬프 처리
      final Timestamp? createdAtTimestamp = data['createdAt'] as Timestamp?;
      final Timestamp? updatedAtTimestamp = data['updatedAt'] as Timestamp?;
      
      // 페이지 처리
      List<Page> pages = [];
      try {
        final List<dynamic>? pagesData = data['pages'] as List<dynamic>?;
        pages = pagesData?.map((pageData) => 
          Page.fromJson(pageData as Map<String, dynamic>)
        ).toList() ?? [];
      } catch (e) {
        print('페이지 데이터 파싱 오류: $e');
      }
      
      // 플래시카드 처리
      List<FlashCard> flashCards = [];
      try {
        final List<dynamic>? flashCardsData = data['flashCards'] as List<dynamic>?;
        flashCards = flashCardsData?.map((cardData) => 
          FlashCard.fromJson(cardData as Map<String, dynamic>)
        ).toList() ?? [];
      } catch (e) {
        print('플래시카드 데이터 파싱 오류: $e');
      }
      
      // 하이라이트된 텍스트 처리
      Set<String> highlightedTexts = {};
      try {
        final List<dynamic>? highlightedTextsData = data['highlightedTexts'] as List<dynamic>?;
        highlightedTexts = Set<String>.from(
          highlightedTextsData?.map((item) => item.toString()) ?? []
        );
      } catch (e) {
        print('하이라이트 텍스트 파싱 오류: $e');
      }
      
      // knownFlashCards 처리
      Set<String> knownFlashCards = {};
      try {
        final List<dynamic>? knownCardsData = data['knownFlashCards'] as List<dynamic>?;
        knownFlashCards = Set<String>.from(knownCardsData?.map((item) => item.toString()) ?? []);
      } catch (e) {
        print('알고 있는 플래시카드 파싱 오류: $e');
      }
      
      print('노트 데이터 로드 완료: ${doc.id}');
      return Note(
        id: doc.id,
        spaceId: data['spaceId'] as String? ?? '',
        userId: data['userId'] as String? ?? '',
        title: data['title'] as String? ?? '',
        content: data['content'] as String? ?? '',
        pages: pages,
        flashCards: flashCards,
        highlightedTexts: highlightedTexts,
        knownFlashCards: knownFlashCards,
        createdAt: createdAtTimestamp?.toDate() ?? DateTime.now(),
        updatedAt: updatedAtTimestamp?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      print('노트 파싱 오류 (${doc.id}): $e');
      print('스택 트레이스: ${StackTrace.current}');
      return Note.empty(id: doc.id);
    }
  }

  // 빈 노트 생성을 위한 팩토리 메서드
  factory Note.empty({String id = ''}) {
    return Note(
      id: id,
      spaceId: '',
      userId: '',
      title: 'Error loading note',
      content: '',
      pages: [],
      flashCards: [],
      highlightedTexts: {},
      knownFlashCards: {},
    );
  }

  Note copyWith({
    String? id,
    String? spaceId,
    String? userId,
    String? title,
    String? content,
    List<Page>? pages,
    List<FlashCard>? flashCards,
    Set<String>? highlightedTexts,
    Set<String>? knownFlashCards,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      pages: pages ?? this.pages,
      flashCards: flashCards ?? this.flashCards.where((card) => 
        !knownFlashCards!.contains(card.front)).toList(),
      highlightedTexts: highlightedTexts ?? this.highlightedTexts,
      knownFlashCards: knownFlashCards ?? this.knownFlashCards,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, pages: ${pages.length}, flashCards: ${flashCards.length})';
  }
}
