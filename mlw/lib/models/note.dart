import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String spaceId;
  final String userId;
  final String title;
  final String content;
  final String? imageUrl;
  final String? extractedText;
  final String? translatedText;
  final String? pinyin;
  final List<FlashCard> flashCards;
  final List<String> highlightedTexts;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? testDate;

  Note({
    required this.id,
    required this.spaceId,
    required this.userId,
    required this.title,
    required this.content,
    this.imageUrl,
    this.extractedText,
    this.translatedText,
    this.pinyin,
    this.flashCards = const [],
    this.highlightedTexts = const [],
    required this.createdAt,
    required this.updatedAt,
    this.testDate,
  });

  // Firebase에서 데이터를 가져올 때 사용하는 팩토리 생성자
  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      spaceId: data['spaceId'],
      userId: data['userId'],
      title: data['title'],
      content: data['content'],
      imageUrl: data['imageUrl'],
      extractedText: data['extractedText'],
      translatedText: data['translatedText'],
      pinyin: data['pinyin'],
      flashCards: (data['flashCards'] as List?)
          ?.map((card) => FlashCard.fromFirestore(card as Map<String, dynamic>))
          .toList() ?? [],
      highlightedTexts: List<String>.from(data['highlightedTexts'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      testDate: data['testDate'] != null ? DateTime.fromMillisecondsSinceEpoch(data['testDate']) : null,
    );
  }

  // Firebase에 데이터를 저장할 때 사용하는 메서드
  Map<String, dynamic> toFirestore() {
    return {
      'spaceId': spaceId,
      'userId': userId,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'extractedText': extractedText,
      'translatedText': translatedText,
      'pinyin': pinyin,
      'flashCards': flashCards.map((card) => card.toFirestore()).toList(),
      'highlightedTexts': highlightedTexts,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'testDate': testDate?.millisecondsSinceEpoch,
    };
  }

  // 노트 복사본을 만들면서 특정 필드만 업데이트하는 메서드
  Note copyWith({
    String? id,
    String? spaceId,
    String? userId,
    String? title,
    String? content,
    String? imageUrl,
    String? extractedText,
    String? translatedText,
    String? pinyin,
    List<FlashCard>? flashCards,
    List<String>? highlightedTexts,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? testDate,
  }) {
    return Note(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      extractedText: extractedText ?? this.extractedText,
      translatedText: translatedText ?? this.translatedText,
      pinyin: pinyin ?? this.pinyin,
      flashCards: flashCards ?? this.flashCards,
      highlightedTexts: highlightedTexts ?? this.highlightedTexts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      testDate: testDate ?? this.testDate,
    );
  }

  // toJson 메서드 업데이트
  Map<String, dynamic> toJson() => {
    'id': id,
    'spaceId': spaceId,
    'userId': userId,
    'title': title,
    'content': content,
    'imageUrl': imageUrl,
    'extractedText': extractedText,
    'translatedText': translatedText,
    'pinyin': pinyin,
    'flashCards': flashCards.map((card) => card.toJson()).toList(),
    'highlightedTexts': highlightedTexts,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'testDate': testDate?.toIso8601String(),
  };

  // fromJson 팩토리 메서드 업데이트
  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    spaceId: json['spaceId'] as String,
    userId: json['userId'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    imageUrl: json['imageUrl'] as String?,
    extractedText: json['extractedText'] as String?,
    translatedText: json['translatedText'] as String?,
    pinyin: json['pinyin'] as String?,
    flashCards: (json['flashCards'] as List<dynamic>?)
        ?.map((e) => FlashCard.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    highlightedTexts: (json['highlightedTexts'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [],
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    testDate: json['testDate'] != null 
        ? DateTime.parse(json['testDate'] as String)
        : null,
  );
}

class FlashCard {
  final String id;
  final String noteId;
  final String text;
  final String? translation;
  final String? pinyin;
  final DateTime createdAt;
  final int reviewCount;
  final DateTime? lastReviewedAt;

  FlashCard({
    required this.id,
    required this.noteId,
    required this.text,
    this.translation,
    this.pinyin,
    required this.createdAt,
    this.reviewCount = 0,
    this.lastReviewedAt,
  });

  // Firestore 변환 메서드
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'noteId': noteId,
      'text': text,
      'translation': translation,
      'pinyin': pinyin,
      'createdAt': createdAt,
      'reviewCount': reviewCount,
      'lastReviewedAt': lastReviewedAt,
    };
  }

  factory FlashCard.fromFirestore(Map<String, dynamic> data) {
    return FlashCard(
      id: data['id'],
      noteId: data['noteId'],
      text: data['text'],
      translation: data['translation'],
      pinyin: data['pinyin'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reviewCount: data['reviewCount'] ?? 0,
      lastReviewedAt: data['lastReviewedAt'] != null 
          ? (data['lastReviewedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // JSON 변환 메서드
  Map<String, dynamic> toJson() => {
    'id': id,
    'noteId': noteId,
    'text': text,
    'translation': translation,
    'pinyin': pinyin,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FlashCard.fromJson(Map<String, dynamic> json) => FlashCard(
    id: json['id'],
    noteId: json['noteId'],
    text: json['text'],
    translation: json['translation'],
    pinyin: json['pinyin'],
    createdAt: DateTime.parse(json['createdAt']),
    reviewCount: json['reviewCount'] ?? 0,
    lastReviewedAt: json['lastReviewedAt'] != null 
        ? DateTime.parse(json['lastReviewedAt'])
        : null,
  );

  // 리뷰 카운트를 증가시키는 메서드
  FlashCard incrementReviewCount() {
    return FlashCard(
      id: id,
      noteId: noteId,
      text: text,
      translation: translation,
      pinyin: pinyin,
      createdAt: createdAt,
      reviewCount: reviewCount + 1,
      lastReviewedAt: DateTime.now(),
    );
  }
}
