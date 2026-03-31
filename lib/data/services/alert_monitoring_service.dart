import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../ui/auth/auth_view_model.dart';
import 'firestore_service.dart';
import 'notification_service.dart';

class AlertMonitoringService {
  final AuthViewModel _authViewModel;
  final FirestoreService _firestoreService;
  final NotificationService _notificationService;

  StreamSubscription? _signalsSubscription;
  String? _lastAlertId;

  AlertMonitoringService(
    this._authViewModel,
    this._firestoreService,
    this._notificationService,
  ) {
    _init();
  }

  void _init() {
    _authViewModel.addListener(_onAuthStateChanged);
    _onAuthStateChanged();
  }

  void _onAuthStateChanged() {
    if (_authViewModel.isLoggedIn) {
      _startMonitoring();
    } else {
      _stopMonitoring();
    }
  }

  void _startMonitoring() {
    final userId = _authViewModel.currentUser?.id;
    if (userId == null || _signalsSubscription != null) return;

    debugPrint('Starting Alert Monitoring for user: $userId');
    
    _signalsSubscription = _firestoreService.getAlertSignalsStream(userId).listen((signals) {
      if (signals.isEmpty) return;

      // The stream gets the latest alerts. We only show if it's a "new" alert
      // for this session to avoid double-notifying.
      final latestAlert = signals.last;
      final alertId = latestAlert['id'] as String?;

      if (alertId != null && alertId != _lastAlertId) {
        _lastAlertId = alertId;
        final senderName = latestAlert['senderName'] as String? ?? 'Someone';
        
        debugPrint('New SOS Signal received from $senderName!');
        
        _notificationService.showEmergencyNotification(
          title: '🚨 EMERGENCY SOS',
          body: '$senderName has triggered an SOS alert! Tap to see their location.',
          payload: alertId,
        );
      }
    });
  }

  void _stopMonitoring() {
    debugPrint('Stopping Alert Monitoring');
    _signalsSubscription?.cancel();
    _signalsSubscription = null;
    _lastAlertId = null;
  }

  void dispose() {
    _authViewModel.removeListener(_onAuthStateChanged);
    _stopMonitoring();
  }
}
