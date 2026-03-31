import '../models/app_user.dart';
import '../models/emergency_contact.dart';
import '../services/firestore_service.dart';

class ContactsRepository {
  final FirestoreService _firestoreService;

  ContactsRepository(this._firestoreService);

  Stream<List<EmergencyContact>> getContactsStream(String userId) {
    return _firestoreService.getUserContactsStream(userId);
  }

  Future<void> addContact(String userId, EmergencyContact contact) async {
    await _firestoreService.addContact(userId, contact);
  }

  Future<void> updateContact(String userId, EmergencyContact contact) async {
    await _firestoreService.updateContact(userId, contact);
  }

  Future<void> deleteContact(String userId, String contactId) async {
    await _firestoreService.deleteContact(userId, contactId);
  }

  Future<AppUser?> findUserByEmail(String email) async {
    return _firestoreService.findUserByEmail(email);
  }
}
