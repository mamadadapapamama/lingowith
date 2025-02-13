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

  NoteSpace({
    required this.id,
    required this.userId,
    required this.name,
    required this.language,
    this.isFlashcardEnabled = true,
    this.isTTSEnabled = true,
    this.isPinyinEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Firestore 변환 메서드
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'language': language,
      'isFlashcardEnabled': isFlashcardEnabled,
      'isTTSEnabled': isTTSEnabled,
      'isPinyinEnabled': isPinyinEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory NoteSpace.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoteSpace(
      id: doc.id,
      userId: data['userId'],
      name: data['name'],
      language: data['language'],
      isFlashcardEnabled: data['isFlashcardEnabled'] ?? true,
      isTTSEnabled: data['isTTSEnabled'] ?? true,
      isPinyinEnabled: data['isPinyinEnabled'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
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
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
} 