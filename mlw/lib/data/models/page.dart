import 'package:cloud_firestore/cloud_firestore.dart';

class Page {
  final String id;
  final String noteId;
  final String userId;
  final String imageUrl; // 이미지 경로 또는 URL
  final String originalText; // 추출된 원문 텍스트
  final String translatedText; // 번역된 텍스트
  final String pinyinText; // 중국어 핀인 (중국어인 경우)
  final List<int> highlightedPositions; // 하이라이트된 단어 위치
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Page({
    required this.id,
    required this.noteId,
    required this.userId,
    required this.imageUrl,
    this.originalText = '',
    this.translatedText = '',
    this.pinyinText = '',
    this.highlightedPositions = const [],
    required this.createdAt,
    required this.updatedAt,
  });
  
  Page copyWith({
    String? id,
    String? noteId,
    String? userId,
    String? imageUrl,
    String? originalText,
    String? translatedText,
    String? pinyinText,
    List<int>? highlightedPositions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Page(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      pinyinText: pinyinText ?? this.pinyinText,
      highlightedPositions: highlightedPositions ?? this.highlightedPositions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'noteId': noteId,
      'userId': userId,
      'imageUrl': imageUrl,
      'originalText': originalText,
      'translatedText': translatedText,
      'pinyinText': pinyinText,
      'highlightedPositions': highlightedPositions,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
  
  factory Page.fromMap(Map<String, dynamic> map) {
    return Page(
      id: map['id'],
      noteId: map['noteId'],
      userId: map['userId'],
      imageUrl: map['imageUrl'],
      originalText: map['originalText'] ?? '',
      translatedText: map['translatedText'] ?? '',
      pinyinText: map['pinyinText'] ?? '',
      highlightedPositions: List<int>.from(map['highlightedPositions'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }
} 