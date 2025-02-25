import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:mlw/data/models/page.dart';
import 'package:mlw/data/models/flash_card.dart';

class Note {
  final String id;
  final String spaceId;
  final String userId;
  final String title;
  final String content;
  final List<Page> pages;
  final List<FlashCard> flashCards;
  final List<String> highlightedTexts;
  final List<String> knownFlashCards;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Note({
    required this.id,
    required this.spaceId,
    required this.userId,
    required this.title,
    required this.content,
    required this.pages,
    required this.flashCards,
    required this.highlightedTexts,
    required this.knownFlashCards,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Note.fromMap(Map<String, dynamic> map, String id) {
    return Note(
      id: id,
      spaceId: map['spaceId'] ?? 'default_space',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      pages: List<Page>.from(map['pages'] ?? []),
      flashCards: List<FlashCard>.from(map['flashCards'] ?? []),
      highlightedTexts: List<String>.from(map['highlightedTexts'] ?? []),
      knownFlashCards: List<String>.from(map['knownFlashCards'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'spaceId': spaceId,
      'userId': userId,
      'title': title,
      'content': content,
      'pages': pages.map((page) => page.toMap()).toList(),
      'flashCards': flashCards.map((card) => {
        'front': card.front,
        'back': card.back,
        'pinyin': card.pinyin,
        'known': card.known,
      }).toList(),
      'highlightedTexts': highlightedTexts,
      'knownFlashCards': knownFlashCards,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
  
  factory Note.fromJson(String source) => 
      Note.fromMap(json.decode(source) as Map<String, dynamic>, '');
  
  String toJson() => json.encode(toMap());
  
  Note copyWith({
    String? id,
    String? spaceId,
    String? userId,
    String? title,
    String? content,
    List<Page>? pages,
    List<FlashCard>? flashCards,
    List<String>? highlightedTexts,
    List<String>? knownFlashCards,
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
      knownFlashCards: knownFlashCards ?? this.knownFlashCards,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Firestore 문서에서 객체 생성
  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // 페이지 목록 변환
    final List<Page> pages = [];
    if (data['pages'] != null) {
      final pagesList = data['pages'] as List<dynamic>;
      pages.addAll(pagesList.map((pageData) => 
        Page.fromMap(pageData as Map<String, dynamic>)
      ));
    }
    
    // 플래시카드 목록 변환
    final List<FlashCard> flashCards = [];
    if (data['flashCards'] != null) {
      final cardsList = data['flashCards'] as List<dynamic>;
      flashCards.addAll(cardsList.map((cardData) {
        final map = cardData as Map<String, dynamic>;
        return FlashCard(
          front: map['front'] as String,
          back: map['back'] as String,
          pinyin: map['pinyin'] as String? ?? '',
          known: map['known'] as bool? ?? false,
        );
      }));
    }
    
    // 하이라이트된 텍스트 목록 변환
    final List<String> highlightedTexts = [];
    if (data['highlightedTexts'] != null) {
      final textsList = data['highlightedTexts'] as List<dynamic>;
      highlightedTexts.addAll(textsList.map((text) => text as String));
    }
    
    // 알고 있는 플래시카드 ID 목록 변환
    final List<String> knownFlashCards = [];
    if (data['knownFlashCards'] != null) {
      final idsList = data['knownFlashCards'] as List<dynamic>;
      knownFlashCards.addAll(idsList.map((id) => id as String));
    }
    
    return Note(
      id: doc.id,
      spaceId: data['spaceId'] as String? ?? 'default_space',
      userId: data['userId'] as String,
      title: data['title'] as String,
      content: data['content'] as String? ?? '',
      pages: pages,
      flashCards: flashCards,
      highlightedTexts: highlightedTexts,
      knownFlashCards: knownFlashCards,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  
  // Firestore 저장용 Map 변환
  Map<String, dynamic> toFirestore() {
    return {
      'spaceId': spaceId,
      'userId': userId,
      'title': title,
      'content': content,
      'pages': pages.map((page) => page.toMap()).toList(),
      'flashCards': flashCards.map((card) => {
        'front': card.front,
        'back': card.back,
        'pinyin': card.pinyin,
        'known': card.known,
      }).toList(),
      'highlightedTexts': highlightedTexts,
      'knownFlashCards': knownFlashCards,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
} 