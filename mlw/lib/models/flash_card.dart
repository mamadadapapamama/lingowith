import 'package:cloud_firestore/cloud_firestore.dart';

class FlashCard {
  final String id;
  final String front;  // 원문 (중국어)
  final String back;   // 번역 (한국어)
  final String pinyin; // 병음
  final DateTime createdAt;
  final DateTime? lastReviewedAt;
  final int reviewCount;
  final String? noteId;
  
  const FlashCard({
    required this.id,
    required this.front,
    required this.back,
    required this.pinyin,
    required this.createdAt,
    this.lastReviewedAt,
    this.reviewCount = 0,
    this.noteId,
  });
  
  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'front': front,
      'back': back,
      'pinyin': pinyin,
      'createdAt': createdAt.toIso8601String(),
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'reviewCount': reviewCount,
      'noteId': noteId,
    };
  }
  
  // JSON에서 변환
  factory FlashCard.fromJson(Map<String, dynamic> json) {
    return FlashCard(
      id: json['id'] as String,
      front: json['front'] as String,
      back: json['back'] as String,
      pinyin: json['pinyin'] as String,
      createdAt: json['createdAt'] is String 
          ? DateTime.parse(json['createdAt'] as String)
          : (json['createdAt'] as DateTime),
      lastReviewedAt: json['lastReviewedAt'] != null
          ? (json['lastReviewedAt'] is String 
              ? DateTime.parse(json['lastReviewedAt'] as String)
              : (json['lastReviewedAt'] as DateTime))
          : null,
      reviewCount: json['reviewCount'] as int? ?? 0,
      noteId: json['noteId'] as String?,
    );
  }
  
  // 복사 메서드
  FlashCard copyWith({
    String? id,
    String? front,
    String? back,
    String? pinyin,
    DateTime? createdAt,
    DateTime? lastReviewedAt,
    int? reviewCount,
    String? noteId,
  }) {
    return FlashCard(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      pinyin: pinyin ?? this.pinyin,
      createdAt: createdAt ?? this.createdAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      reviewCount: reviewCount ?? this.reviewCount,
      noteId: noteId ?? this.noteId,
    );
  }
  
  factory FlashCard.fromFirestore(Map<String, dynamic> data) {
    return FlashCard(
      id: data['id'] as String,
      front: data['front'] as String,
      back: data['back'] as String,
      pinyin: data['pinyin'] as String,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      lastReviewedAt: data['lastReviewedAt'] != null
          ? (data['lastReviewedAt'] is Timestamp 
              ? (data['lastReviewedAt'] as Timestamp).toDate() 
              : null)
          : null,
      reviewCount: data['reviewCount'] as int? ?? 0,
      noteId: data['noteId'] as String?,
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'front': front,
      'back': back,
      'pinyin': pinyin,
      'createdAt': createdAt,
      'lastReviewedAt': lastReviewedAt,
      'reviewCount': reviewCount,
      'noteId': noteId,
    };
  }
  
  FlashCard incrementReviewCount() {
    return copyWith(
      reviewCount: reviewCount + 1,
      lastReviewedAt: DateTime.now(),
    );
  }
  
  @override
  String toString() {
    return 'FlashCard(id: $id, front: $front, back: $back)';
  }
}



