import 'package:cloud_firestore/cloud_firestore.dart';

class Page {
  final String imageUrl;
  final String extractedText;
  final String translatedText;
  
  Page({
    required this.imageUrl,
    required this.extractedText,
    required this.translatedText,
  });
  
  factory Page.fromMap(Map<String, dynamic> map) {
    return Page(
      imageUrl: map['imageUrl'] as String,
      extractedText: map['extractedText'] as String,
      translatedText: map['translatedText'] as String,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'extractedText': extractedText,
      'translatedText': translatedText,
    };
  }
  
  Page copyWith({
    String? imageUrl,
    String? extractedText,
    String? translatedText,
  }) {
    return Page(
      imageUrl: imageUrl ?? this.imageUrl,
      extractedText: extractedText ?? this.extractedText,
      translatedText: translatedText ?? this.translatedText,
    );
  }
} 