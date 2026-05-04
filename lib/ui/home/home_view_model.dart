import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/sos_event.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/sos_repository.dart';
import '../../data/repositories/contacts_repository.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/storage_service.dart';
import '../auth/auth_view_model.dart';

class HomeViewModel extends ChangeNotifier {
  final AuthViewModel _authViewModel;
  final SosRepository _sosRepository;
  final ContactsRepository _contactsRepository;
  final LocationRepository _locationRepository;
  final FirestoreService _firestoreService;
  final Uuid _uuid = Uuid();

  bool isLocationActive = true;
  int contactsCount = 0;
  bool isSendingAlert = false;
  String? lastMessage;

  HomeViewModel(
    this._authViewModel,
    this._sosRepository,
    this._contactsRepository,
    this._locationRepository,
    this._firestoreService,
    this._audioService,
    this._storageService,
  );

  final AudioService _audioService;
  final StorageService _storageService;
  String? _currentRecordingPath;
  SosEvent? _currentSosEvent;

  bool get isRecordingAudio => _currentRecordingPath != null;

  void setLocationActive(bool value) {
    isLocationActive = value;
    notifyListeners();
  }

  void setContactsCount(int value) {
    contactsCount = value;
    notifyListeners();
  }

  Future<void> triggerSos() async {
    if (isSendingAlert) return;

    final user = _authViewModel.currentUser;
    if (user == null) {
      lastMessage = 'Must be logged in to send SOS';
      notifyListeners();
      return;
    }

    isSendingAlert = true;
    lastMessage = null;
    notifyListeners();

    try {
      double lat = 0.0;
      double lng = 0.0;
      String locationLbl = 'Current Device Location';

      try {
        var permission = await _locationRepository.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await _locationRepository.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final position = await _locationRepository
              .getCurrentPosition()
              .timeout(const Duration(seconds: 10));
          lat = position.latitude;
          lng = position.longitude;
          locationLbl =
              'Current Location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
        } else {
          locationLbl = 'Location Permission Denied';
        }
      } catch (e) {
        debugPrint('Location error during SOS: $e');
        locationLbl = 'Location Unavailable';
      }

      final newEvent = SosEvent(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        locationLabel: locationLbl,
        latitude: lat,
        longitude: lng,
        status: 'Sent',
      );
      _currentSosEvent = newEvent;

      _sosRepository.addEvent(user.id, newEvent).catchError((e) {
        debugPrint('Background sync error: $e');
      });

      // --- New: Send signals to linked contacts ---
      final contacts = await _contactsRepository.getContactsStream(user.id).first;
      final linkedRecipientIds = <String>[];
      
      for (var c in contacts) {
        if (c.uid != null) {
          linkedRecipientIds.add(c.uid!);
        } else if (c.linkedUserEmail != null) {
          // Fallback just in case
          final linkedUser = await _firestoreService.findUserByEmail(c.linkedUserEmail!);
          if (linkedUser != null) {
            linkedRecipientIds.add(linkedUser.id);
          }
        }
      }

      String? alertId;
      if (linkedRecipientIds.isNotEmpty) {
        alertId = await _firestoreService.sendSosSignal(
          user.id,
          user.fullName,
          linkedRecipientIds,
          _locationRepository.currentPosition?.latitude ?? 0.0,
          _locationRepository.currentPosition?.longitude ?? 0.0,
        );
      }

      // Start Recording and Periodic Location Updates
      if (alertId != null) {
        final prefs = await SharedPreferences.getInstance();
        final recordAudio = prefs.getBool('recordAudio') ?? true;
        if (recordAudio) {
          _startEmergencyRecording(user.id, alertId);
        }
        _startLiveLocationUpdates(alertId);
      }

      lastMessage = 'SOS alert triggered successfully';
    } catch (e) {
      lastMessage = 'Failed to send SOS: $e';
    } finally {
      isSendingAlert = false;
      notifyListeners();
    }
  }

  Future<void> broadcastSms() async {
    final user = _authViewModel.currentUser;
    if (user == null) return;

    try {
      final contacts = await _contactsRepository.getContactsStream(user.id).first;
      if (contacts.isEmpty) {
        lastMessage = 'No emergency contacts found. Add some in the Contacts tab.';
        notifyListeners();
        return;
      }

      final position = await _locationRepository.getCurrentPosition().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Location timeout'),
      );

      final lat = position.latitude;
      final lng = position.longitude;
      final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      
      final String phoneNumbers = contacts.map((c) => c.phoneNumber).join(',');
      final String message = 'SOS! I need help. My current location: $googleMapsUrl';
      
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumbers,
        queryParameters: <String, String>{
          'body': message,
        },
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        final String encodedMessage = Uri.encodeComponent(message);
        final String url = 'sms:$phoneNumbers?body=$encodedMessage';
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        } else {
          lastMessage = 'Could not launch SMS app';
          notifyListeners();
        }
      }
    } catch (e) {
      lastMessage = 'Error preparing SMS: $e';
      notifyListeners();
    }
  }

  Future<void> _startEmergencyRecording(String userId, String alertId) async {
    try {
      final path = await _audioService.startRecording();
      if (path != null) {
        _currentRecordingPath = path;
        notifyListeners();

        // Record for 20 seconds then auto-upload
        Timer(const Duration(seconds: 20), () async {
          await _stopAndUploadRecording(userId, alertId);
        });
      }
    } catch (e) {
      debugPrint('Error in emergency recording: $e');
    }
  }

  Future<void> _stopAndUploadRecording(String userId, String alertId) async {
    try {
      final path = await _audioService.stopRecording();
      if (path != null) {
        final downloadUrl = await _storageService.uploadSosAudio(
          userId: userId,
          sosId: alertId,
          filePath: path,
        );
        
        if (downloadUrl != null) {
          debugPrint('Emergency audio uploaded. Cloud Function will link it to alert $alertId');
        }
      }
    } catch (e) {
      debugPrint('Error stopping/uploading recording: $e');
    } finally {
      _currentRecordingPath = null;
      notifyListeners();
    }
  }

  Timer? _locationUpdateTimer;
  void _startLiveLocationUpdates(String alertId) {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (_currentSosEvent == null) {
        timer.cancel();
        return;
      }
      
      final pos = _locationRepository.currentPosition;
      if (pos != null) {
        await _firestoreService.updateAlertLocation(alertId, pos.latitude, pos.longitude);
      }
    });
  }

  void clearMessage() {
    lastMessage = null;
    notifyListeners();
  }
}
