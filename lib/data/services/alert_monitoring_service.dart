import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../ui/auth/auth_view_model.dart';
import 'firestore_service.dart';
import 'notification_service.dart';

class AlertMonitoringService {
  final AuthViewModel _authViewModel;
  final FirestoreService _firestoreService;
  final NotificationService _notificationService;

  StreamSubscription? _signalsSubscription;
  final Set<String> _seenAlertIds = {};
  DateTime? _monitoringStartedAt;

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

    // Record when this monitoring session started — only alerts AFTER this
    // moment should trigger a notification. This prevents old active alerts
    // from re-notifying every time the app is opened.
    _monitoringStartedAt = DateTime.now();

    debugPrint('Starting Alert Monitoring for user: $userId');

    _signalsSubscription = _firestoreService.getAlertSignalsStream(userId).listen((signals) {
      if (signals.isEmpty) return;

      for (final alert in signals) {
        final alertId = alert['id'] as String?;
        if (alertId == null) continue;

        // Skip alerts we've already shown a notification for this session
        if (_seenAlertIds.contains(alertId)) continue;

        // Skip alerts that existed before we started monitoring
        final ts = alert['timestamp'] as Timestamp?;
        if (ts != null && _monitoringStartedAt != null) {
          if (ts.toDate().isBefore(_monitoringStartedAt!)) {
            // Mark as seen so we don't re-check it
            _seenAlertIds.add(alertId);
            continue;
          }
        }

        _seenAlertIds.add(alertId);
        final senderName = alert['senderName'] as String? ?? 'Someone';

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
    _seenAlertIds.clear();
    _monitoringStartedAt = null;
  }

  void dispose() {
    _authViewModel.removeListener(_onAuthStateChanged);
    _stopMonitoring();
  }
}
