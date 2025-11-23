class Employee {
  final String id;
  final String email;
  final String password;
  final DateTime createdAt;
  final bool isActive;

  Employee({
    required this.id,
    required this.email,
    required this.password,
    required this.createdAt,
    this.isActive = true,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Create from JSON
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      email: json['email'],
      password: json['password'],
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'] ?? true,
    );
  }

  // Copy with method for updates
  Employee copyWith({
    String? id,
    String? email,
    String? password,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Employee(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}