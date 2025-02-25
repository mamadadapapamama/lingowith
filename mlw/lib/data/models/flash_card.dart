import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class FlashCard {
  final String id;
  final String noteId;
  final String userId;
  final String front;
  final String back;
  final String pinyin;
  final int reviewCount;
  final bool known;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastReviewedAt;

  FlashCard({
    this.id = '',
    this.noteId = '',
    this.userId = '',
    required this.front,
    required this.back,
    required this.pinyin,
    this.reviewCount = 0,
    this.known = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastReviewedAt,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  factory FlashCard.fromMap(Map<String, dynamic> map, String id) {
    return FlashCard(
      id: id,
      noteId: map['noteId'] ?? '',
      userId: map['userId'] ?? '',
      front: map['front'] ?? '',
      back: map['back'] ?? '',
      pinyin: map['pinyin'] ?? '',
      reviewCount: map['reviewCount'] ?? 0,
      known: map['known'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      lastReviewedAt: map['lastReviewedAt'] != null
          ? (map['lastReviewedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'noteId': noteId,
      'userId': userId,
      'front': front,
      'back': back,
      'pinyin': pinyin,
      'reviewCount': reviewCount,
      'known': known,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastReviewedAt': lastReviewedAt != null
          ? Timestamp.fromDate(lastReviewedAt!)
          : null,
    };
  }

  factory FlashCard.fromJson(String source) => 
      FlashCard.fromMap(json.decode(source) as Map<String, dynamic>, '');
  
  String toJson() => json.encode(toMap());
  
  FlashCard copyWith({
    String? id,
    String? noteId,
    String? userId,
    String? front,
    String? back,
    String? pinyin,
    int? reviewCount,
    bool? known,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastReviewedAt,
  }) {
    return FlashCard(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      userId: userId ?? this.userId,
      front: front ?? this.front,
      back: back ?? this.back,
      pinyin: pinyin ?? this.pinyin,
      reviewCount: reviewCount ?? this.reviewCount,
      known: known ?? this.known,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }
  
  factory FlashCard.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FlashCard(
      id: doc.id,
      noteId: data['noteId'] as String,
      userId: data['userId'] as String,
      front: data['front'] as String,
      back: data['back'] as String,
      pinyin: data['pinyin'] as String? ?? '',
      reviewCount: data['reviewCount'] ?? 0,
      known: data['known'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastReviewedAt: data['lastReviewedAt'] != null
          ? (data['lastReviewedAt'] as Timestamp).toDate()
          : null,
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'noteId': noteId,
      'userId': userId,
      'front': front,
      'back': back,
      'pinyin': pinyin,
      'reviewCount': reviewCount,
      'known': known,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastReviewedAt': lastReviewedAt != null
          ? Timestamp.fromDate(lastReviewedAt!)
          : null,
    };
  }
} 