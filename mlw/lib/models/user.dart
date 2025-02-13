class User {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory User.fromFirestore(Map<String, dynamic> data, String id) {
    return User(
      id: id,
      name: data['name'] ?? '',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  User copyWith({
    String? name,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
