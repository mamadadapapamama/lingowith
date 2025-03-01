import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mlw/models/flash_card.dart';

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
  
  /// 노트의 삭제 여부
  final bool isDeleted;

  final String imageUrl;
  final String extractedText;
  final String translatedText;

  final int flashcardCount;
  final int reviewCount;
  final DateTime? lastReviewedAt;

  Note({
    required this.id,
    required this.spaceId,
    required this.userId,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.extractedText,
    required this.translatedText,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
    required this.flashcardCount,
    required this.reviewCount,
    this.lastReviewedAt,
    this.pages = const [],
    this.flashCards = const [],
    this.knownFlashCards = const {},
    this.highlightedTexts = const {},
  });

  int get knownFlashCardsCount => knownFlashCards.length;

  int get remainingFlashCardsCount => flashCards.length - knownFlashCardsCount;

  Map<String, dynamic> toJson() {
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
      'imageUrl': imageUrl,
      'extractedText': extractedText,
      'translatedText': translatedText,
      'flashcardCount': flashcardCount,
      'reviewCount': reviewCount,
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
    };
  }

  /// Firestore 문서에서 노트 객체를 생성합니다.
  /// 
  /// [doc]은 Firestore 문서 스냅샷입니다.
  /// 문서 데이터가 유효하지 않은 경우 오류를 기록하고 기본값을 사용합니다.
  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // 페이지 목록 변환
    List<Page> pages = [];
    if (data['pages'] != null) {
      pages = (data['pages'] as List).map((pageData) {
        return Page(
          imageUrl: pageData['imageUrl'] ?? '',
          extractedText: pageData['extractedText'] ?? '',
          translatedText: pageData['translatedText'] ?? '',
        );
      }).toList();
    }
    
    // 플래시카드 목록 변환
    List<FlashCard> flashCards = [];
    if (data['flashCards'] != null) {
      flashCards = (data['flashCards'] as List)
          .map((cardData) => FlashCard.fromJson(cardData))
          .toList();
    }
    
    // 알고 있는 플래시카드 집합 변환
    Set<String> knownFlashCards = {};
    if (data['knownFlashCards'] != null) {
      knownFlashCards = Set<String>.from(data['knownFlashCards'] as List);
    }
    
    // 강조된 텍스트 집합 변환
    Set<String> highlightedTexts = {};
    if (data['highlightedTexts'] != null) {
      highlightedTexts = Set<String>.from(data['highlightedTexts'] as List);
    }
    
    print('로드된 페이지 수: ${pages.length}');
    if (pages.isNotEmpty) {
      print('첫 번째 페이지 이미지 URL: ${pages[0].imageUrl}');
    }
    
    return Note(
      id: doc.id,
      spaceId: data['spaceId'] ?? '',
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      extractedText: data['extractedText'] ?? '',
      translatedText: data['translatedText'] ?? '',
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isDeleted: data['isDeleted'] ?? false,
      flashcardCount: data['flashcardCount'] ?? 0,
      reviewCount: data['reviewCount'] ?? 0,
      lastReviewedAt: data['lastReviewedAt'] is Timestamp
          ? (data['lastReviewedAt'] as Timestamp).toDate()
          : null,
      pages: pages,
      flashCards: flashCards,
      knownFlashCards: knownFlashCards,
      highlightedTexts: highlightedTexts,
    );
  }

  // 빈 노트 생성을 위한 팩토리 메서드
  factory Note.empty() {
    return Note(
      id: '',
      spaceId: '',
      userId: '',
      title: '제목 없음',
      content: '',
      imageUrl: '',
      extractedText: '',
      translatedText: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDeleted: false,
      flashcardCount: 0,
      reviewCount: 0,
      lastReviewedAt: null,
      pages: [],
      flashCards: [],
      knownFlashCards: {},
      highlightedTexts: {},
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
    bool? isDeleted,
    String? imageUrl,
    String? extractedText,
    String? translatedText,
    int? flashcardCount,
    int? reviewCount,
    DateTime? lastReviewedAt,
  }) {
    // 알려진 플래시카드 목록 (기존 + 새로 추가된)
    final Set<String> allKnownCards = {...this.knownFlashCards, ...(knownFlashCards ?? {})};
    
    // 알려진 카드를 제외한 플래시카드 목록 (flashCards가 명시적으로 제공된 경우에만 필터링)
    final List<FlashCard> effectiveCards;
    if (flashCards != null) {
      // 명시적으로 제공된 카드 목록 사용
      effectiveCards = flashCards;
    } else {
      // 기존 카드에서 알려진 카드 제외
      effectiveCards = this.flashCards.where((card) => !allKnownCards.contains(card.front)).toList();
    }
    
    return Note(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      extractedText: extractedText ?? this.extractedText,
      translatedText: translatedText ?? this.translatedText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      flashcardCount: flashcardCount ?? this.flashcardCount,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      pages: pages ?? this.pages,
      flashCards: effectiveCards,
      knownFlashCards: allKnownCards,
      highlightedTexts: highlightedTexts ?? this.highlightedTexts,
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, pages: ${pages.length}, flashCards: ${flashCards.length})';
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      spaceId: json['spaceId'],
      userId: json['userId'],
      title: json['title'],
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      extractedText: json['extractedText'] ?? '',
      translatedText: json['translatedText'] ?? '',
      createdAt: _parseTimestamp(json['createdAt']),
      updatedAt: _parseTimestamp(json['updatedAt']),
      isDeleted: json['isDeleted'] ?? false,
      flashcardCount: json['flashcardCount'] ?? 0,
      reviewCount: json['reviewCount'] ?? 0,
      lastReviewedAt: json['lastReviewedAt'] is Timestamp
          ? (json['lastReviewedAt'] as Timestamp).toDate()
          : null,
      pages: (json['pages'] as List<dynamic>?)
          ?.map((page) => Page.fromJson(page))
          .toList() ?? [],
      flashCards: (json['flashCards'] as List<dynamic>?)
          ?.map((card) => FlashCard.fromJson(card))
          .toList() ?? [],
      knownFlashCards: Set<String>.from(json['knownFlashCards'] ?? []),
      highlightedTexts: Set<String>.from(json['highlightedTexts'] ?? []),
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    }
    return DateTime.now(); // Default value
  }

  // 호환성을 위한 toFirestore 메서드
  Map<String, dynamic> toFirestore() {
    final data = {
      'spaceId': spaceId,
      'userId': userId,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'extractedText': extractedText,
      'translatedText': translatedText,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDeleted': isDeleted,
      'flashcardCount': flashcardCount,
      'reviewCount': reviewCount,
      'pages': pages.map((page) => {
        'imageUrl': page.imageUrl,
        'extractedText': page.extractedText,
        'translatedText': page.translatedText,
      }).toList(),
      'flashCards': flashCards.map((card) => card.toJson()).toList(),
      'knownFlashCards': knownFlashCards.toList(),
      'highlightedTexts': highlightedTexts.toList(),
    };
    
    if (lastReviewedAt != null) {
      data['lastReviewedAt'] = Timestamp.fromDate(lastReviewedAt!);
    }
    
    return data;
  }
}
