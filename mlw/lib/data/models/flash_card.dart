import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class FlashCard {
  final String id;
  final String noteId;
  final String pageId;
  final String userId;
  final String front; // 원문 단어
  final String back; // 번역된 단어
  final String pinyin; // 핀인 (중국어인 경우)
  final String context; // 단어가 사용된 문맥
  final bool known; // 학습 완료 여부
  final int reviewCount;
  final DateTime? lastReviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  FlashCard({
    required this.id,
    required this.noteId,
    required this.pageId,
    required this.userId,
    required this.front,
    required this.back,
    this.pinyin = '',
    this.context = '',
    this.known = false,
    this.reviewCount = 0,
    this.lastReviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  
  FlashCard copyWith({
    String? id,
    String? noteId,
    String? pageId,
    String? userId,
    String? front,
    String? back,
    String? pinyin,
    String? context,
    bool? known,
    int? reviewCount,
    DateTime? lastReviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlashCard(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      pageId: pageId ?? this.pageId,
      userId: userId ?? this.userId,
      front: front ?? this.front,
      back: back ?? this.back,
      pinyin: pinyin ?? this.pinyin,
      context: context ?? this.context,
      known: known ?? this.known,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'noteId': noteId,
      'pageId': pageId,
      'userId': userId,
      'front': front,
      'back': back,
      'pinyin': pinyin,
      'context': context,
      'known': known,
      'reviewCount': reviewCount,
      'lastReviewedAt': lastReviewedAt?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
  
  factory FlashCard.fromMap(Map<String, dynamic> map) {
    return FlashCard(
      id: map['id'],
      noteId: map['noteId'],
      pageId: map['pageId'],
      userId: map['userId'],
      front: map['front'],
      back: map['back'],
      pinyin: map['pinyin'] ?? '',
      context: map['context'] ?? '',
      known: map['known'] ?? false,
      reviewCount: map['reviewCount'] ?? 0,
      lastReviewedAt: map['lastReviewedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['lastReviewedAt']) : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  factory FlashCard.fromJson(String source) => 
      FlashCard.fromMap(json.decode(source) as Map<String, dynamic>);
  
  String toJson() => json.encode(toMap());
  
  factory FlashCard.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FlashCard(
      id: doc.id,
      noteId: data['noteId'] as String,
      pageId: data['pageId'] as String,
      userId: data['userId'] as String,
      front: data['front'] as String,
      back: data['back'] as String,
      pinyin: data['pinyin'] as String? ?? '',
      context: data['context'] as String? ?? '',
      known: data['known'] as bool? ?? false,
      reviewCount: data['reviewCount'] ?? 0,
      lastReviewedAt: data['lastReviewedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(data['lastReviewedAt']) : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updatedAt']),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'noteId': noteId,
      'pageId': pageId,
      'userId': userId,
      'front': front,
      'back': back,
      'pinyin': pinyin,
      'context': context,
      'known': known,
      'reviewCount': reviewCount,
      'lastReviewedAt': lastReviewedAt?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
} 