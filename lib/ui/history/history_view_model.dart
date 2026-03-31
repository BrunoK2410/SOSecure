import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../data/models/sos_event.dart';
import '../../data/repositories/sos_repository.dart';
import '../auth/auth_view_model.dart';

class HistoryViewModel extends ChangeNotifier {
  final SosRepository _repository;
  final AuthViewModel _authViewModel;

  StreamSubscription<List<SosEvent>>? _eventsSubscription;
  List<SosEvent> _events = [];

  HistoryViewModel(this._repository, this._authViewModel) {
    _init();
  }

  void _init() {
    _authViewModel.addListener(_onAuthStateChanged);
    _onAuthStateChanged();
  }

  void _onAuthStateChanged() {
    final user = _authViewModel.currentUser;
    if (user != null) {
      _eventsSubscription ??= _repository.getEventsStream(user.id).listen((eventsData) {
        _events = eventsData;
        notifyListeners();
      });
    } else {
      _eventsSubscription?.cancel();
      _eventsSubscription = null;
      _events = [];
      notifyListeners();
    }
  }

  List<SosEvent> get events => _events;
  bool get hasEvents => _events.isNotEmpty;
  int get eventsCount => _events.length;

  @override
  void dispose() {
    _authViewModel.removeListener(_onAuthStateChanged);
    _eventsSubscription?.cancel();
    super.dispose();
  }
}
