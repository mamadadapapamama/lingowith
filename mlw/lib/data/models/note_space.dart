import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:mlw/data/models/text_display_mode.dart';

class NoteSpace {
  final String id;
  final String name;
  final String userId;
  final List<String> noteIds; // 노트 ID 목록
  final String language; // 학습 언어 (예: "Chinese", "Spanish")
  final String translationLanguage; // 번역 언어 (예: "Korean", "English")
  final TextDisplayMode displayMode; // 기본 표시 모드
  final bool ttsEnabled; // TTS 활성화 여부
  final bool sentenceTtsEnabled; // 문장별 TTS 활성화 여부
  final DateTime createdAt;
  final DateTime updatedAt;
  
  NoteSpace({
    required this.id,
    required this.name,
    required this.userId,
    this.noteIds = const [],
    required this.language,
    required this.translationLanguage,
    this.displayMode = TextDisplayMode.both,
    this.ttsEnabled = true,
    this.sentenceTtsEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory NoteSpace.fromMap(Map<String, dynamic> map) {
    return NoteSpace(
      id: map['id'],
      name: map['name'],
      userId: map['userId'],
      noteIds: List<String>.from(map['noteIds'] ?? []),
      language: map['language'],
      translationLanguage: map['translationLanguage'],
      displayMode: TextDisplayMode.values[map['displayMode'] ?? 0],
      ttsEnabled: map['ttsEnabled'] ?? true,
      sentenceTtsEnabled: map['sentenceTtsEnabled'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      'noteIds': noteIds,
      'language': language,
      'translationLanguage': translationLanguage,
      'displayMode': displayMode.index,
      'ttsEnabled': ttsEnabled,
      'sentenceTtsEnabled': sentenceTtsEnabled,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
  
  factory NoteSpace.fromJson(String source) => 
      NoteSpace.fromMap(json.decode(source) as Map<String, dynamic>);
  
  String toJson() => json.encode(toMap());
  
  NoteSpace copyWith({
    String? id,
    String? name,
    String? userId,
    List<String>? noteIds,
    String? language,
    String? translationLanguage,
    TextDisplayMode? displayMode,
    bool? ttsEnabled,
    bool? sentenceTtsEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteSpace(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      noteIds: noteIds ?? this.noteIds,
      language: language ?? this.language,
      translationLanguage: translationLanguage ?? this.translationLanguage,
      displayMode: displayMode ?? this.displayMode,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      sentenceTtsEnabled: sentenceTtsEnabled ?? this.sentenceTtsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 