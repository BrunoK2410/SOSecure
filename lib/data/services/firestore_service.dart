import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/emergency_contact.dart';
import '../models/sos_event.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUser(AppUser user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // --- Contacts ---

  Stream<List<EmergencyContact>> getUserContactsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('contacts')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EmergencyContact.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addContact(String uid, EmergencyContact contact) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('contacts')
        .doc(contact.id)
        .set(contact.toMap());
  }

  Future<void> updateContact(String uid, EmergencyContact contact) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('contacts')
        .doc(contact.id)
        .update(contact.toMap());
  }

  Future<void> deleteContact(String uid, String contactId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('contacts')
        .doc(contactId)
        .delete();
  }

  // --- SOS Events ---

  Stream<List<SosEvent>> getUserSosEventsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('sos_events')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SosEvent.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addSosEvent(String uid, SosEvent event) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('sos_events')
        .doc(event.id)
        .set(event.toMap());
  }

  Future<AppUser?> findUserByEmail(String email) async {
    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return AppUser.fromMap(doc.data(), doc.id);
    }
    return null;
  }

  Future<AppUser?> findUserByPhone(String phone) async {
    final snapshot = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return AppUser.fromMap(doc.data(), doc.id);
    }
    return null;
  }

  // --- FCM Notifications ---

  Future<String> sendSosSignal(String senderId, String senderName, List<String> recipientIds, double latitude, double longitude) async {
    final alertId = _firestore.collection('alerts').doc().id;
    await _firestore.collection('alerts').doc(alertId).set({
      'id': alertId,
      'senderId': senderId,
      'senderName': senderName,
      'recipientIds': recipientIds,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'active',
      'audioUrl': null,
    });
    return alertId;
  }

  Future<void> updateAlertAudioUrl(String alertId, String audioUrl) async {
    await _firestore.collection('alerts').doc(alertId).update({
      'audioUrl': audioUrl,
    });
  }

  Future<void> updateAlertLocation(String alertId, double latitude, double longitude) async {
    await _firestore.collection('alerts').doc(alertId).update({
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Stream<Map<String, dynamic>?> getAlertStream(String alertId) {
    return _firestore
        .collection('alerts')
        .doc(alertId)
        .snapshots()
        .map((doc) => doc.data());
  }

  Stream<List<Map<String, dynamic>>> getAlertSignalsStream(String userId) {
    return _firestore
        .collection('alerts')
        .where('recipientIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final cutoff = DateTime.now().subtract(const Duration(minutes: 5));
      return snapshot.docs
          .map((doc) => doc.data())
          .where((data) {
            final ts = data['timestamp'] as Timestamp?;
            if (ts == null) return true; // Server timestamp might be pending initially
            return ts.toDate().isAfter(cutoff);
          })
          .toList();
    });
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _firestore.collection('users').doc(uid).update({'fcmToken': token});
  }

  Future<List<String>> getLinkedContactsTokens(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('contacts')
        .get();
    
    List<String> tokens = [];
    for (var doc in snapshot.docs) {
      final linkedUserEmail = doc.data()['linkedUserEmail'] as String?;
      if (linkedUserEmail != null) {
        final userSnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: linkedUserEmail)
            .get();
        if (userSnapshot.docs.isNotEmpty) {
          final token = userSnapshot.docs.first.data()['fcmToken'] as String?;
          if (token != null) tokens.add(token);
        }
      }
    }
    return tokens;
  }
}
