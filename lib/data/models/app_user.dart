class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? fcmToken;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.fcmToken,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String documentId) {
    return AppUser(
      id: documentId,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      fcmToken: data['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'fullName': fullName,
      'email': email,
    };
    if (phone != null) map['phone'] = phone;
    if (fcmToken != null) map['fcmToken'] = fcmToken;
    return map;
  }
}
