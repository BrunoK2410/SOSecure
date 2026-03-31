class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final String? uid;
  final String? linkedUserEmail;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.uid,
    this.linkedUserEmail,
  });

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? relationship,
    String? uid,
    String? linkedUserEmail,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      uid: uid ?? this.uid,
      linkedUserEmail: linkedUserEmail ?? this.linkedUserEmail,
    );
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> data, String documentId) {
    return EmergencyContact(
      id: documentId,
      name: data['name'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      relationship: data['relationship'] as String? ?? '',
      uid: data['uid'] as String?,
      linkedUserEmail: data['linkedUserEmail'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
    };
    if (uid != null) {
      map['uid'] = uid;
    }
    if (linkedUserEmail != null) {
      map['linkedUserEmail'] = linkedUserEmail;
    }
    return map;
  }
}
