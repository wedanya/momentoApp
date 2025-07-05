class User {
  final int? id; // SQLite usually uses auto-incrementing integer IDs
  final String email;
  final String hashedPassword; // Store hashed password, not plain text

  User({this.id, required this.email, required this.hashedPassword});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'hashed_password': hashedPassword,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      hashedPassword: map['hashed_password'],
    );
  }

  @override
  String toString() {
    return 'User{id: $id, email: $email, hashedPassword: $hashedPassword}';
  }
}