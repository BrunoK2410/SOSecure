import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/services/firestore_service.dart';

class AlertDetailViewModel extends ChangeNotifier {
  AlertDetailViewModel(this._firestoreService, this.alertId) {
    _initAlertStream();
  }

  final FirestoreService _firestoreService;
  final String alertId;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Map<String, dynamic>? alertData;
  bool isLoading = true;

  void _initAlertStream() {
    _firestoreService.getAlertStream(alertId).listen((data) {
      alertData = data;
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> playAudio(String url) async {
    try {
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
