import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:mlw/data/models/page.dart';
import 'package:mlw/data/models/flash_card.dart';
import 'package:mlw/data/models/text_display_mode.dart';
import 'package:mlw/domain/models/note.dart' as domain;

class Note {
  final String id;
  final String userId;
  final String noteSpaceId;
  final String title;
  final String content;
  final List<String> pageIds;
  final List<dynamic> pages;
  final List<dynamic> flashCards;
  final List<dynamic> highlightedTexts;
  final List<dynamic> knownFlashCards;
  final int flashCardCount;
  final TextDisplayMode displayMode;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Note({
    required this.id,
    required this.userId,
    required this.noteSpaceId,
    required this.title,
    this.content = '',
    this.pageIds = const [],
    this.pages = const [],
    this.flashCards = const [],
    this.highlightedTexts = const [],
    this.knownFlashCards = const [],
    this.flashCardCount = 0,
    this.displayMode = TextDisplayMode.both,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Note.fromMap(Map<String, dynamic> map) {
    // FlashCard 변환 로직 수정
    final List<FlashCard> flashCards = [];
    if (map['flashCards'] != null) {
      final cardsList = map['flashCards'] as List<dynamic>;
      flashCards.addAll(cardsList.map((cardData) {
        final map = cardData as Map<String, dynamic>;
        return FlashCard(
          id: map['id'] ?? '',
          noteId: map['noteId'] ?? '',
          pageId: map['pageId'] ?? '',
          userId: map['userId'] ?? '',
          front: map['front'] as String,
          back: map['back'] as String,
          pinyin: map['pinyin'] as String? ?? '',
          createdAt: map['createdAt'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) 
            : DateTime.now(),
          updatedAt: map['updatedAt'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt']) 
            : DateTime.now(),
        );
      }));
    }
    
    // 페이지 목록 변환
    final List<Page> pages = [];
    if (map['pages'] != null) {
      final pagesList = map['pages'] as List<dynamic>;
      pages.addAll(pagesList.map((pageData) => 
        Page.fromMap(pageData as Map<String, dynamic>)
      ));
    }
    
    // 하이라이트된 텍스트 목록 변환
    final List<String> highlightedTexts = [];
    if (map['highlightedTexts'] != null) {
      final textsList = map['highlightedTexts'] as List<dynamic>;
      highlightedTexts.addAll(textsList.map((text) => text as String));
    }
    
    // 알고 있는 플래시카드 ID 목록 변환
    final List<String> knownFlashCards = [];
    if (map['knownFlashCards'] != null) {
      final idsList = map['knownFlashCards'] as List<dynamic>;
      knownFlashCards.addAll(idsList.map((id) => id as String));
    }
    
    return Note(
      id: map['id'],
      userId: map['userId'],
      noteSpaceId: map['noteSpaceId'] ?? 'default_space',
      title: map['title'],
      content: map['content'] ?? '',
      pageIds: pages.map((page) => page.id).toList(),
      pages: pages.map((page) => page.toMap()).toList(),
      flashCards: flashCards.map((card) => card.toMap()).toList(),
      highlightedTexts: highlightedTexts,
      knownFlashCards: knownFlashCards,
      flashCardCount: flashCards.length,
      displayMode: TextDisplayMode.values[map['displayMode'] ?? 0],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'noteSpaceId': noteSpaceId,
      'title': title,
      'content': content,
      'pageIds': pageIds,
      'pages': pages,
      'flashCards': flashCards,
      'highlightedTexts': highlightedTexts,
      'knownFlashCards': knownFlashCards,
      'flashCardCount': flashCardCount,
      'displayMode': displayMode.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
  
  factory Note.fromJson(String source) => 
      Note.fromMap(json.decode(source) as Map<String, dynamic>);
  
  String toJson() => json.encode(toMap());
  
  Note copyWith({
    String? id,
    String? userId,
    String? noteSpaceId,
    String? title,
    String? content,
    List<String>? pageIds,
    List<dynamic>? pages,
    List<dynamic>? flashCards,
    List<dynamic>? highlightedTexts,
    List<dynamic>? knownFlashCards,
    int? flashCardCount,
    TextDisplayMode? displayMode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      noteSpaceId: noteSpaceId ?? this.noteSpaceId,
      title: title ?? this.title,
      content: content ?? this.content,
      pageIds: pageIds ?? this.pageIds,
      pages: pages ?? this.pages,
      flashCards: flashCards ?? this.flashCards,
      highlightedTexts: highlightedTexts ?? this.highlightedTexts,
      knownFlashCards: knownFlashCards ?? this.knownFlashCards,
      flashCardCount: flashCardCount ?? this.flashCardCount,
      displayMode: displayMode ?? this.displayMode,
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
          id: map['id'] ?? '',
          noteId: map['noteId'] ?? doc.id,
          pageId: map['pageId'] ?? '',
          userId: map['userId'] ?? data['userId'],
          front: map['front'] as String,
          back: map['back'] as String,
          pinyin: map['pinyin'] as String? ?? '',
          known: map['known'] as bool? ?? false,
          createdAt: map['createdAt'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']) 
            : DateTime.now(),
          updatedAt: map['updatedAt'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt']) 
            : DateTime.now(),
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
      userId: data['userId'] as String,
      noteSpaceId: data['noteSpaceId'] as String? ?? 'default_space',
      title: data['title'] as String,
      content: data['content'] ?? '',
      pageIds: pages.map((page) => page.id).toList(),
      pages: pages.map((page) => page.toMap()).toList(),
      flashCards: flashCards.map((card) => card.toMap()).toList(),
      highlightedTexts: highlightedTexts,
      knownFlashCards: knownFlashCards,
      flashCardCount: flashCards.length,
      displayMode: TextDisplayMode.values[data['displayMode'] ?? 0],
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updatedAt'] ?? 0),
    );
  }
  
  // Firestore 저장용 Map 변환
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'noteSpaceId': noteSpaceId,
      'title': title,
      'content': content,
      'pageIds': pageIds,
      'pages': pages,
      'flashCards': flashCards,
      'highlightedTexts': highlightedTexts,
      'knownFlashCards': knownFlashCards,
      'flashCardCount': flashCardCount,
      'displayMode': displayMode.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
} 
