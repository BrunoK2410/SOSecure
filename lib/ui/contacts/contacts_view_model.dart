import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/app_user.dart';
import '../../data/models/emergency_contact.dart';
import '../../data/repositories/contacts_repository.dart';
import '../auth/auth_view_model.dart';

class ContactsViewModel extends ChangeNotifier {
  final ContactsRepository _repository;
  final AuthViewModel _authViewModel;
  final Uuid _uuid = const Uuid();

  StreamSubscription<List<EmergencyContact>>? _contactsSubscription;
  List<EmergencyContact> _contacts = [];

  ContactsViewModel(this._repository, this._authViewModel) {
    _init();
  }

  void _init() {
    _authViewModel.addListener(_onAuthStateChanged);
    _onAuthStateChanged();
  }

  void _onAuthStateChanged() {
    final user = _authViewModel.currentUser;
    if (user != null) {
      _contactsSubscription ??= _repository.getContactsStream(user.id).listen((contactsData) {
        _contacts = contactsData;
        notifyListeners();
      });
    } else {
      _contactsSubscription?.cancel();
      _contactsSubscription = null;
      _contacts = [];
      notifyListeners();
    }
  }

  List<EmergencyContact> get contacts => _contacts;
  bool get hasContacts => _contacts.isNotEmpty;
  int get contactsCount => _contacts.length;

  Future<AppUser?> findUserByEmail(String email) async {
    if (email.isEmpty) return null;
    return await _repository.findUserByEmail(email);
  }

  Future<AppUser?> findUserById(String uid) async {
    if (uid.isEmpty) return null;
    return await _repository.findUserById(uid);
  }

  Future<void> inviteContact(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final String message = 'Hi! I added you as an emergency contact on SOSecure. Download the app to receive instant alerts: https://sosecure.app';
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      debugPrint('Could not launch SMS for invitation');
    }
  }

  Future<void> addContact({
    required String name,
    required String phoneNumber,
    required String relationship,
    String? uid,
    String? linkedUserEmail,
  }) async {
    final user = _authViewModel.currentUser;
    if (user == null) return;

    final contact = EmergencyContact(
      id: _uuid.v4(),
      name: name,
      phoneNumber: phoneNumber,
      relationship: relationship,
      uid: uid,
      linkedUserEmail: linkedUserEmail,
    );

    await _repository.addContact(user.id, contact);
  }

  Future<void> updateContact({
    required String id,
    required String name,
    required String phoneNumber,
    required String relationship,
    String? uid,
    String? linkedUserEmail,
  }) async {
    final user = _authViewModel.currentUser;
    if (user == null) return;

    final updated = EmergencyContact(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      relationship: relationship,
      uid: uid,
      linkedUserEmail: linkedUserEmail,
    );

    await _repository.updateContact(user.id, updated);
  }

  Future<void> deleteContact(String id) async {
    final user = _authViewModel.currentUser;
    if (user == null) return;

    await _repository.deleteContact(user.id, id);
  }

  @override
  void dispose() {
    _authViewModel.removeListener(_onAuthStateChanged);
    _contactsSubscription?.cancel();
    super.dispose();
  }
}
