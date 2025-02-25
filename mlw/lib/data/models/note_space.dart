import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class NoteSpace {
  final String id;
  final String userId;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  NoteSpace({
    this.id = '',
    required this.userId,
    required this.name,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory NoteSpace.fromMap(Map<String, dynamic> map) {
    return NoteSpace(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
  
  factory NoteSpace.fromJson(String source) => 
      NoteSpace.fromMap(json.decode(source) as Map<String, dynamic>);
  
  String toJson() => json.encode(toMap());
  
  NoteSpace copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteSpace(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 