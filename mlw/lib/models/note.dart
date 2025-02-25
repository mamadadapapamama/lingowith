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
  
  /// 노트의 생성 시간
  final DateTime createdAt;
  
  /// 노트의 업데이트 시간
  final DateTime updatedAt;
  
  /// 노트에서 알려진 플래시카드 목록
  final Map<String, bool> knownFlashCards;

  Note({
    required this.id,
    required this.spaceId,
    required this.userId,
    required this.title,
    required this.content,
    required this.pages,
    required this.flashCards,
    required this.highlightedTexts,
    required this.createdAt,
    required this.updatedAt,
    required this.knownFlashCards,
  });

  int get knownFlashCardsCount => knownFlashCards.values.where((known) => known).length;

  int get remainingFlashCardsCount => flashCards.length - knownFlashCardsCount;

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'spaceId': spaceId,
      'title': title,
      'content': content,
      'pages': pages.map((page) => page.toJson()).toList(),
      'flashCards': flashCards.map((card) => card.toJson()).toList(),
      'highlightedTexts': highlightedTexts.toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'knownFlashCards': knownFlashCards.map((key, value) => 
        MapEntry(key, value ? Timestamp.fromDate(DateTime.now()) : null)),
    };
  }

  /// Firestore 문서에서 노트 객체를 생성합니다.
  /// 
  /// [doc]은 Firestore 문서 스냅샷입니다.
  /// 문서 데이터가 유효하지 않은 경우 오류를 기록하고 기본값을 사용합니다.
  factory Note.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      print("Parsing note from Firestore: ${doc.id}");
      
      // null 체크 추가
      final String id = doc.id;
      final String userId = data['userId'] as String? ?? '';
      final String spaceId = data['spaceId'] as String? ?? '';
      final String title = data['title'] as String? ?? '';
      final String content = data['content'] as String? ?? '';
      
      // 안전하게 데이터 추출
      final List<dynamic> pagesData = data['pages'] as List<dynamic>? ?? [];
      final List<dynamic> flashCardsData = data['flashCards'] as List<dynamic>? ?? [];
      final List<dynamic> highlightedTextsData = data['highlightedTexts'] as List<dynamic>? ?? [];
      
      // 타임스탬프 처리
      final Timestamp? createdAtTimestamp = data['createdAt'] as Timestamp?;
      final Timestamp? updatedAtTimestamp = data['updatedAt'] as Timestamp?;
      
      // knownFlashCards 처리
      final Map<String, dynamic> rawKnownCards = data['knownFlashCards'] as Map<String, dynamic>? ?? {};
      final Map<String, bool> knownCards = {};
      
      rawKnownCards.forEach((key, value) {
        knownCards[key] = value as bool? ?? false;
      });
      
      return Note(
        id: id,
        spaceId: spaceId,
        userId: userId,
        title: title,
        content: content,
        pages: pagesData.map((pageData) {
          return Page.fromJson(pageData as Map<String, dynamic>? ?? {});
        }).toList(),
        flashCards: flashCardsData.map((cardData) {
          return FlashCard.fromJson(cardData as Map<String, dynamic>? ?? {});
        }).toList(),
        highlightedTexts: Set<String>.from(
          highlightedTextsData.map((item) => item.toString())
        ),
        createdAt: createdAtTimestamp?.toDate() ?? DateTime.now(),
        updatedAt: updatedAtTimestamp?.toDate() ?? DateTime.now(),
        knownFlashCards: knownCards,
      );
    } catch (e) {
      print("Error parsing note ${doc.id}: $e");
      // 기본 Note 반환
      return Note(
        id: doc.id,
        spaceId: '',
        userId: '',
        title: 'Error loading note',
        content: '',
        pages: [],
        flashCards: [],
        highlightedTexts: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        knownFlashCards: {},
      );
    }
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
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, bool>? knownFlashCards,
  }) {
    return Note(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      pages: pages ?? this.pages,
      flashCards: flashCards ?? this.flashCards,
      highlightedTexts: highlightedTexts ?? this.highlightedTexts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      knownFlashCards: knownFlashCards ?? this.knownFlashCards,
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, pages: ${pages.length}, flashCards: ${flashCards.length})';
  }
}
