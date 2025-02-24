import 'package:cloud_firestore/cloud_firestore.dart';

class FlashCard {
  final String front;
  final String back;
  final String pinyin;
  final String noteId;
  final DateTime createdAt;
  final int reviewCount;
  final DateTime? lastReviewedAt;

  FlashCard({
    required this.front,
    required this.back,
    required this.pinyin,
    required this.noteId,
    required this.createdAt,
    this.reviewCount = 0,
    this.lastReviewedAt,
  });

  factory FlashCard.fromMap(Map<String, dynamic> map) {
    return FlashCard(
      front: map['front'] ?? '',
      back: map['back'] ?? '',
      pinyin: map['pinyin'] ?? '',
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
      'front': front,
      'back': back,
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
      noteId: this.noteId,
      createdAt: this.createdAt,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'front': front,
      'back': back,
      'pinyin': pinyin,
      'noteId': noteId,
      'createdAt': createdAt,
      'reviewCount': reviewCount,
    };
  }

  factory FlashCard.fromFirestore(Map<String, dynamic> data) {
    return FlashCard(
      front: data['front'] ?? '',
      back: data['back'] ?? '',
      pinyin: data['pinyin'] ?? '',
      noteId: data['noteId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reviewCount: data['reviewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'front': front,
      'back': back,
      'pinyin': pinyin,
      'noteId': noteId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FlashCard.fromJson(Map<String, dynamic> json) {
    return FlashCard(
      front: json['front'] as String,
      back: json['back'] as String,
      pinyin: json['pinyin'] as String,
      noteId: json['noteId'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      reviewCount: 0,
    );
  }
}



