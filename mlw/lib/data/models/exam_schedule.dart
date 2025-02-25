import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class ExamSchedule {
  final String id;
  final String userId;
  final String noteId;
  final String title;
  final String description;
  final DateTime examDate;
  final bool reminderEnabled;
  final List<DateTime> reminderTimes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  ExamSchedule({
    this.id = '',
    required this.userId,
    required this.noteId,
    required this.title,
    this.description = '',
    required this.examDate,
    this.reminderEnabled = true,
    this.reminderTimes = const [],
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory ExamSchedule.fromMap(Map<String, dynamic> map) {
    return ExamSchedule(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      noteId: map['noteId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      examDate: (map['examDate'] as Timestamp).toDate(),
      reminderEnabled: map['reminderEnabled'] ?? true,
      reminderTimes: (map['reminderTimes'] as List?)
          ?.map((time) => (time as Timestamp).toDate())
          .toList() ?? [],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'noteId': noteId,
      'title': title,
      'description': description,
      'examDate': Timestamp.fromDate(examDate),
      'reminderEnabled': reminderEnabled,
      'reminderTimes': reminderTimes.map((time) => Timestamp.fromDate(time)).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
  
  factory ExamSchedule.fromJson(String source) => 
      ExamSchedule.fromMap(json.decode(source) as Map<String, dynamic>);
  
  String toJson() => json.encode(toMap());
  
  ExamSchedule copyWith({
    String? id,
    String? userId,
    String? noteId,
    String? title,
    String? description,
    DateTime? examDate,
    bool? reminderEnabled,
    List<DateTime>? reminderTimes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamSchedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      noteId: noteId ?? this.noteId,
      title: title ?? this.title,
      description: description ?? this.description,
      examDate: examDate ?? this.examDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 