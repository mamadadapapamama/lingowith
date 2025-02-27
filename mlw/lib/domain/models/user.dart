import 'dart:convert';

class User {
  final String id;
  final String? name;
  final String? email;
  final String? photoUrl;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? preferences;

  User({
    required this.id,
    this.name,
    this.email,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
    this.preferences,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? createdAt,
    String? updatedAt,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'preferences': preferences,
    };
  }

  factory User.fromJson(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      name: map['name'],
      email: map['email'],
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      preferences: map['preferences'] != null 
          ? Map<String, dynamic>.from(map['preferences'])
          : null,
    );
  }

  String toJsonString() => json.encode(toJson());

  factory User.fromJsonString(String source) => User.fromJson(json.decode(source));

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, photoUrl: $photoUrl, createdAt: $createdAt, updatedAt: $updatedAt, preferences: $preferences)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is User &&
      other.id == id &&
      other.name == name &&
      other.email == email &&
      other.photoUrl == photoUrl &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      email.hashCode ^
      photoUrl.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
  }
} 