import 'package:cloud_firestore/cloud_firestore.dart';

class NoteSpace {
  final String id;
  final String userId;
  final String name;        // e.g. "중국어 노트", "스페인어 노트"
  final String language;    // 'zh', 'ja', 'ko' 등
  final bool isFlashcardEnabled;
  final bool isTTSEnabled;
  final bool isPinyinEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  const NoteSpace({
    required this.id,
    required this.userId,
    required this.name,
    required this.language,
    this.isFlashcardEnabled = true,
    this.isTTSEnabled = true,
    this.isPinyinEnabled = true,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  factory NoteSpace.fromJson(Map<String, dynamic> json) {
    return NoteSpace(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      language: json['language'] as String,
      createdAt: json['createdAt'] is String 
          ? DateTime.parse(json['createdAt'] as String)
          : (json['createdAt'] as DateTime),
      updatedAt: json['updatedAt'] is String 
          ? DateTime.parse(json['updatedAt'] as String)
          : (json['updatedAt'] as DateTime),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'language': language,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Firestore 변환 메서드
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'language': language,
      'isFlashcardEnabled': isFlashcardEnabled,
      'isTTSEnabled': isTTSEnabled,
      'isPinyinEnabled': isPinyinEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDeleted': isDeleted,
    };
  }

  factory NoteSpace.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoteSpace(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      language: data['language'] ?? 'zh',
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  // 설정을 업데이트하기 위한 copyWith 메서드
  NoteSpace copyWith({
    String? id,
    String? userId,
    String? name,
    String? language,
    bool? isFlashcardEnabled,
    bool? isTTSEnabled,
    bool? isPinyinEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return NoteSpace(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      language: language ?? this.language,
      isFlashcardEnabled: isFlashcardEnabled ?? this.isFlashcardEnabled,
      isTTSEnabled: isTTSEnabled ?? this.isTTSEnabled,
      isPinyinEnabled: isPinyinEnabled ?? this.isPinyinEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  String toString() {
    return 'NoteSpace(id: $id, userId: $userId, name: $name, language: $language)';
  }
} 