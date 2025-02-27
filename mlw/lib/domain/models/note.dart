import 'dart:convert';

class Note {
  final String id;
  final String title;
  final String content;
  final String userId;
  final String? createdAt;
  final String? updatedAt;
  final List<String>? tags;
  final List<String> pageIds;
  
  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.userId,
    this.createdAt,
    this.updatedAt,
    this.tags,
    this.pageIds = const [],
  });
  
  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? userId,
    String? createdAt,
    String? updatedAt,
    List<String>? tags,
    List<String>? pageIds,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      pageIds: pageIds ?? this.pageIds,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'tags': tags,
      'pageIds': pageIds,
    };
  }
  
  factory Note.fromJson(Map<String, dynamic> map) {
    return Note(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      userId: map['userId'] ?? '',
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      tags: map['tags'] != null 
          ? List<String>.from(map['tags'])
          : null,
      pageIds: map['pageIds'] != null 
          ? List<String>.from(map['pageIds'])
          : [],
    );
  }
  
  String toJsonString() => json.encode(toJson());
  
  factory Note.fromJsonString(String source) => Note.fromJson(json.decode(source));
  
  @override
  String toString() {
    return 'Note(id: $id, title: $title, content: $content, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt, tags: $tags, pageIds: $pageIds)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Note &&
      other.id == id &&
      other.title == title &&
      other.content == content &&
      other.userId == userId &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      listEquals(other.tags, tags) &&
      listEquals(other.pageIds, pageIds);
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
      title.hashCode ^
      content.hashCode ^
      userId.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      tags.hashCode ^
      pageIds.hashCode;
  }
} 