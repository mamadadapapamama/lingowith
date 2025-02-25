import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:mlw/data/models/text_display_mode.dart';

class UserSettings {
  final String id;
  final bool darkModeEnabled;
  final bool notificationsEnabled;
  final String preferredLanguage;
  final String translationLanguage;
  final TextDisplayMode displayMode;
  final bool highlightEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettings({
    required this.id,
    this.darkModeEnabled = false,
    this.notificationsEnabled = true,
    this.preferredLanguage = '한국어',
    this.translationLanguage = '중국어',
    this.displayMode = TextDisplayMode.both,
    this.highlightEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      id: map['id'] ?? '',
      darkModeEnabled: map['darkModeEnabled'] ?? false,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      preferredLanguage: map['preferredLanguage'] ?? '한국어',
      translationLanguage: map['translationLanguage'] ?? '중국어',
      displayMode: TextDisplayMode.values[map['displayMode'] ?? 2],
      highlightEnabled: map['highlightEnabled'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'darkModeEnabled': darkModeEnabled,
      'notificationsEnabled': notificationsEnabled,
      'preferredLanguage': preferredLanguage,
      'translationLanguage': translationLanguage,
      'displayMode': displayMode.index,
      'highlightEnabled': highlightEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserSettings.fromJson(String source) => 
      UserSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  String toJson() => json.encode(toMap());

  UserSettings copyWith({
    String? id,
    bool? darkModeEnabled,
    bool? notificationsEnabled,
    String? preferredLanguage,
    String? translationLanguage,
    TextDisplayMode? displayMode,
    bool? highlightEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      id: id ?? this.id,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      translationLanguage: translationLanguage ?? this.translationLanguage,
      displayMode: displayMode ?? this.displayMode,
      highlightEnabled: highlightEnabled ?? this.highlightEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 