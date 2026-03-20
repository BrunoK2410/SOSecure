import '../models/emergency_contact.dart';

class ContactsRepository {
  final List<EmergencyContact> _contacts = [
    const EmergencyContact(
      id: '1',
      name: 'John Doe',
      phoneNumber: '+385 91 123 4567',
      relationship: 'Brother',
    ),
    const EmergencyContact(
      id: '2',
      name: 'Emma Wilson',
      phoneNumber: '+385 98 765 4321',
      relationship: 'Friend',
    ),
  ];

  List<EmergencyContact> getContacts() {
    return List.unmodifiable(_contacts);
  }

  void addContact(EmergencyContact contact) {
    _contacts.add(contact);
  }

  void updateContact(EmergencyContact updatedContact) {
    final index = _contacts.indexWhere((c) => c.id == updatedContact.id);
    if (index == -1) return;
    _contacts[index] = updatedContact;
  }

  void deleteContact(String id) {
    _contacts.removeWhere((c) => c.id == id);
  }
}
