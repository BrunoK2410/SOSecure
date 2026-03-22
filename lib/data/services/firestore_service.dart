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
}
