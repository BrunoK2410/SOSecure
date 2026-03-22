class AppUser {
  final String id;
  final String fullName;
  final String email;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String documentId) {
    return AppUser(
      id: documentId,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
    };
  }
}
