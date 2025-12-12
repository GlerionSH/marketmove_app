class UserApp {
  final String id;
  final String email;
  final String role;
  final DateTime? createdAt;

  UserApp({
    required this.id,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory UserApp.fromJson(Map<String, dynamic> json) {
    return UserApp(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
    };
  }

  UserApp copyWith({
    String? id,
    String? email,
    String? role,
    DateTime? createdAt,
  }) {
    return UserApp(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
