import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/emergency_contact.dart';
import '../../data/repositories/contacts_repository.dart';

class ContactsViewModel extends ChangeNotifier {
  final ContactsRepository _repository = ContactsRepository();
  final Uuid _uuid = const Uuid();

  List<EmergencyContact> get contacts => _repository.getContacts();

  bool get hasContacts => contacts.isNotEmpty;

  int get contactsCount => contacts.length;

  void addContact({
    required String name,
    required String phoneNumber,
    required String relationship,
  }) {
    final contact = EmergencyContact(
      id: _uuid.v4(),
      name: name,
      phoneNumber: phoneNumber,
      relationship: relationship,
    );

    _repository.addContact(contact);
    notifyListeners();
  }

  void updateContact({
    required String id,
    required String name,
    required String phoneNumber,
    required String relationship,
  }) {
    final updated = EmergencyContact(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      relationship: relationship,
    );

    _repository.updateContact(updated);
    notifyListeners();
  }

  void deleteContact(String id) {
    _repository.deleteContact(id);
    notifyListeners();
  }
}
