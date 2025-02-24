import 'package:cloud_firestore/cloud_firestore.dart';

class Page {
  final String imageUrl;
  final String extractedText;
  final String translatedText;

  const Page({
    required this.imageUrl,
    required this.extractedText,
    required this.translatedText,
  });

  factory Page.fromJson(Map<String, dynamic> json) {
    return Page(
      imageUrl: json['imageUrl'] as String,
      extractedText: json['extractedText'] as String,
      translatedText: json['translatedText'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'extractedText': extractedText,
      'translatedText': translatedText,
    };
  }
}

class FlashCard {
  final String front;
  final String back;
  final String pinyin;
  final int reviewCount;
  final DateTime? lastReviewedAt;

  const FlashCard({
    required this.front,
    required this.back,
    required this.pinyin,
    this.reviewCount = 0,
    this.lastReviewedAt,
  });

  factory FlashCard.fromJson(Map<String, dynamic> json) {
    return FlashCard(
      front: json['front'] as String,
      back: json['back'] as String,
      pinyin: json['pinyin'] as String,
      reviewCount: json['reviewCount'] as int? ?? 0,
      lastReviewedAt: json['lastReviewedAt'] != null 
          ? (json['lastReviewedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'front': front,
      'back': back,
      'pinyin': pinyin,
      'reviewCount': reviewCount,
      'lastReviewedAt': lastReviewedAt != null 
          ? Timestamp.fromDate(lastReviewedAt!)
          : null,
    };
  }

  FlashCard copyWith({
    String? front,
    String? back,
    String? pinyin,
    int? reviewCount,
    DateTime? lastReviewedAt,
  }) {
    return FlashCard(
      front: front ?? this.front,
      back: back ?? this.back,
      pinyin: pinyin ?? this.pinyin,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  FlashCard incrementReviewCount() {
    return copyWith(
      reviewCount: reviewCount + 1,
      lastReviewedAt: DateTime.now(),
    );
  }
}

class Note {
  final String id;
  final String spaceId;
  final String userId;
  final String title;
  final String content;
  final List<Page> pages;
  final List<FlashCard> flashCards;
  final Set<String> highlightedTexts;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.spaceId,
    required this.userId,
    required this.title,
    this.content = '',
    required this.pages,
    List<FlashCard>? flashCards,
    Set<String>? highlightedTexts,
    required this.createdAt,
    required this.updatedAt,
  }) : 
    flashCards = flashCards ?? [],
    highlightedTexts = highlightedTexts ?? const <String>{};

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String? ?? '',
      spaceId: json['spaceId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      pages: (json['pages'] as List<dynamic>?)
          ?.map((e) => Page.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
      flashCards: (json['flashCards'] as List<dynamic>?)
          ?.map((e) => FlashCard.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
      highlightedTexts: Set<String>.from(json['highlightedTexts'] as List<dynamic>? ?? const []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spaceId': spaceId,
      'userId': userId,
      'title': title,
      'content': content,
      'pages': pages.map((e) => e.toJson()).toList(),
      'flashCards': flashCards.map((e) => e.toJson()).toList(),
      'highlightedTexts': highlightedTexts.toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // flashCards 데이터를 가져오는 부분 확인
    final flashCardsData = data['flashCards'] as List<dynamic>?;
    final flashCards = flashCardsData?.map((cardData) {
      return FlashCard.fromJson(cardData as Map<String, dynamic>);
    }).toList() ?? [];

    return Note(
      id: doc.id,
      spaceId: data['spaceId'] ?? '',
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      pages: (data['pages'] as List<dynamic>?)?.map((pageData) {
        return Page.fromJson(pageData as Map<String, dynamic>);
      }).toList() ?? [],
      flashCards: flashCards,  // 여기서 flashCards가 제대로 할당되어야 함
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore에서는 id를 별도로 관리
    return json;
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
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, pages: ${pages.length}, flashCards: ${flashCards.length})';
  }
}
