import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
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

  bool silentSos = false;
  bool confirmBeforeSend = true;
  int? confirmCountdownSeconds;
  String? activeAlertId;
  bool isResolvingAlert = false;

  bool get hasActiveAlert => activeAlertId != null;

  HomeViewModel(
    this._authViewModel,
    this._sosRepository,
    this._contactsRepository,
    this._locationRepository,
    this._firestoreService,
    this._audioService,
    this._storageService,
  ) {
    loadSafetyPrefs();
    _checkExistingActiveAlert();
  }

  final AudioService _audioService;
  final StorageService _storageService;
  String? _currentRecordingPath;
  Timer? _confirmTimer;

  bool get isRecordingAudio => _currentRecordingPath != null;
  bool get isConfirmingSos => confirmCountdownSeconds != null;

  void setLocationActive(bool value) {
    isLocationActive = value;
    notifyListeners();
  }

  void setContactsCount(int value) {
    contactsCount = value;
    notifyListeners();
  }

  Future<void> _checkExistingActiveAlert() async {
    final user = _authViewModel.currentUser;
    if (user == null) return;
    try {
      final existingAlertId = await _firestoreService.getActiveAlertForSender(user.id);
      if (existingAlertId != null) {
        activeAlertId = existingAlertId;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error checking active alert: $e');
    }
  }

  Future<void> loadSafetyPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    silentSos = prefs.getBool('silentSos') ?? false;
    confirmBeforeSend = prefs.getBool('confirmBeforeSend') ?? true;
    notifyListeners();
  }

  /// Called when the SOS hold gesture completes.
  Future<void> onSosHoldCompleted() async {
    if (isSendingAlert || isConfirmingSos) return;

    await loadSafetyPrefs();

    if (confirmBeforeSend) {
      _startConfirmCountdown();
    } else {
      await triggerSos();
    }
  }

  void _startConfirmCountdown() {
    _confirmTimer?.cancel();
    confirmCountdownSeconds = 3;
    notifyListeners();

    _confirmTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = confirmCountdownSeconds;
      if (remaining == null) {
        timer.cancel();
        return;
      }

      if (remaining <= 1) {
        timer.cancel();
        confirmCountdownSeconds = null;
        notifyListeners();
        triggerSos();
      } else {
        confirmCountdownSeconds = remaining - 1;
        notifyListeners();
      }
    });
  }

  void cancelConfirmCountdown() {
    _confirmTimer?.cancel();
    _confirmTimer = null;
    confirmCountdownSeconds = null;
    notifyListeners();
  }

  Future<void> triggerSos() async {
    if (isSendingAlert) return;

    final user = _authViewModel.currentUser;
    if (user == null) {
      if (!silentSos) {
        lastMessage = 'Must be logged in to send SOS';
        notifyListeners();
      }
      return;
    }

    isSendingAlert = true;
    lastMessage = null;
    notifyListeners();

    String eventStatus = 'Sent';

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
          locationLbl = await _reverseGeocode(lat, lng);
        } else {
          locationLbl = 'Location Permission Denied';
        }
      } catch (e) {
        debugPrint('Location error during SOS: $e');
        locationLbl = 'Location Unavailable';
      }

      // If there's an existing active alert, auto-resolve it before starting a new one
      if (activeAlertId != null) {
        final prevAlertId = activeAlertId!;
        _firestoreService.resolveAlert(prevAlertId).catchError((e) {
          debugPrint('Error auto-resolving previous alert $prevAlertId: $e');
        });
        activeAlertId = null;
      }

      // --- Send signals to linked contacts ---
      final contacts = await _contactsRepository.getContactsStream(user.id).first;
      final linkedRecipientIds = <String>[];

      for (var c in contacts) {
        if (c.uid != null) {
          linkedRecipientIds.add(c.uid!);
        } else if (c.linkedUserEmail != null) {
          // Fallback just in case
          final linkedUser =
              await _firestoreService.findUserByEmail(c.linkedUserEmail!);
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
        activeAlertId = alertId;
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

      // Save event with actual status
      final newEvent = SosEvent(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        locationLabel: locationLbl,
        latitude: lat,
        longitude: lng,
        status: eventStatus,
      );

      _sosRepository.addEvent(user.id, newEvent).catchError((e) {
        debugPrint('Background sync error: $e');
      });

      if (!silentSos) {
        lastMessage = 'SOS alert triggered successfully';
      }
    } catch (e) {
      eventStatus = 'Failed';

      // Still save the failed event for history
      final failedEvent = SosEvent(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        locationLabel: 'Unknown',
        latitude: 0.0,
        longitude: 0.0,
        status: eventStatus,
      );
      _sosRepository.addEvent(user.id, failedEvent).catchError((e2) {
        debugPrint('Background sync error: $e2');
      });

      if (!silentSos) {
        lastMessage = 'Failed to send SOS: $e';
      } else {
        debugPrint('Silent SOS failed: $e');
      }
    } finally {
      isSendingAlert = false;
      notifyListeners();
    }
  }

  Future<void> resolveActiveAlert() async {
    if (activeAlertId == null || isResolvingAlert) return;

    isResolvingAlert = true;
    notifyListeners();

    try {
      final alertId = activeAlertId!;
      await _firestoreService.resolveAlert(alertId);

      _locationUpdateTimer?.cancel();
      _locationUpdateTimer = null;
      activeAlertId = null;

      if (!silentSos) {
        lastMessage = 'Alert marked as resolved. Contacts notified that you are safe.';
      }
    } catch (e) {
      debugPrint('Failed to resolve alert: $e');
      if (!silentSos) {
        lastMessage = 'Failed to mark as safe: $e';
      }
    } finally {
      isResolvingAlert = false;
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
      final googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

      final String phoneNumbers = contacts.map((c) => c.phoneNumber).join(',');
      final String message =
          'SOS! I need help. My current location: $googleMapsUrl';

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
          debugPrint(
              'Emergency audio uploaded. Cloud Function will link it to alert $alertId');
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
    _locationUpdateTimer =
        Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (activeAlertId != alertId) {
        timer.cancel();
        return;
      }

      try {
        final pos = await _locationRepository.getCurrentPosition();
        await _firestoreService.updateAlertLocation(
          alertId,
          pos.latitude,
          pos.longitude,
        );
        debugPrint('Live location updated: ${pos.latitude}, ${pos.longitude}');
      } catch (e) {
        debugPrint('Error updating live location: $e');
      }
    });
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.street != null && p.street!.isNotEmpty) p.street!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
          if (p.country != null && p.country!.isNotEmpty) p.country!,
        ];
        if (parts.isNotEmpty) return parts.join(', ');
      }
    } catch (e) {
      debugPrint('Reverse geocoding failed: $e');
    }
    return 'Current device location';
  }

  void clearMessage() {
    lastMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _confirmTimer?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }
}
