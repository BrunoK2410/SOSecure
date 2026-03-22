import 'package:cloud_firestore/cloud_firestore.dart';

class SosEvent {
  final String id;
  final DateTime timestamp;
  final String locationLabel;
  final double latitude;
  final double longitude;
  final String status;

  const SosEvent({
    required this.id,
    required this.timestamp,
    required this.locationLabel,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  factory SosEvent.fromMap(Map<String, dynamic> data, String documentId) {
    return SosEvent(
      id: documentId,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      locationLabel: data['locationLabel'] as String? ?? 'Unknown Location',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'Sent',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'locationLabel': locationLabel,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }
}
