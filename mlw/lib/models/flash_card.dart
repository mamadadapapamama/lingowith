import 'package:cloud_firestore/cloud_firestore.dart';

class FlashCard {
  final String id;
  final String originalText;
  final String translatedText;
  final String? pinyin;
  final String noteId;
  final DateTime createdAt;
  final int reviewCount;
  final DateTime? lastReviewedAt;

  FlashCard({
    required this.id,
    required this.originalText,
    required this.translatedText,
    this.pinyin,
    required this.noteId,
    DateTime? createdAt,
    this.reviewCount = 0,
    this.lastReviewedAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory FlashCard.fromMap(Map<String, dynamic> map) {
    return FlashCard(
      id: map['id'] ?? '',
      originalText: map['originalText'] ?? '',
      translatedText: map['translatedText'] ?? '',
      pinyin: map['pinyin'],
      noteId: map['noteId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      reviewCount: map['reviewCount'] ?? 0,
      lastReviewedAt: map['lastReviewedAt'] != null 
          ? (map['lastReviewedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalText': originalText,
      'translatedText': translatedText,
      'pinyin': pinyin,
      'noteId': noteId,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewCount': reviewCount,
      'lastReviewedAt': lastReviewedAt != null 
          ? Timestamp.fromDate(lastReviewedAt!)
          : null,
    };
  }

  FlashCard copyWith({
    String? originalText,
    String? translatedText,
    String? pinyin,
    int? reviewCount,
    DateTime? lastReviewedAt,
  }) {
    return FlashCard(
      id: id,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      pinyin: pinyin ?? this.pinyin,
      noteId: noteId,
      createdAt: createdAt,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'originalText': originalText,
      'translatedText': translatedText,
      'pinyin': pinyin,
      'noteId': noteId,
      'createdAt': createdAt,
      'reviewCount': reviewCount,
    };
  }

  factory FlashCard.fromFirestore(Map<String, dynamic> data) {
    return FlashCard(
      id: data['id'] ?? '',
      originalText: data['originalText'] ?? '',
      translatedText: data['translatedText'] ?? '',
      pinyin: data['pinyin'],
      noteId: data['noteId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reviewCount: data['reviewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'originalText': originalText,
    'translatedText': translatedText,
    'pinyin': pinyin,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FlashCard.fromJson(Map<String, dynamic> json) => FlashCard(
    id: json['id'] as String,
    originalText: json['originalText'] as String,
    translatedText: json['translatedText'] as String,
    pinyin: json['pinyin'] as String?,
    noteId: '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    reviewCount: 0,
  );
}



