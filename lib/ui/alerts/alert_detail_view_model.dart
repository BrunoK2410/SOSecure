import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/services/firestore_service.dart';

class AlertDetailViewModel extends ChangeNotifier {
  AlertDetailViewModel(this._firestoreService, this.alertId) {
    _initAlertStream();
    _initAudioListeners();
  }

  final FirestoreService _firestoreService;
  final String alertId;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Map<String, dynamic>? alertData;
  bool isLoading = true;

  // Audio state
  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool isAudioLoading = false;
  bool isAudioLoaded = false;

  StreamSubscription? _playingSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _processingSubscription;

  void _initAlertStream() {
    _firestoreService.getAlertStream(alertId).listen((data) {
      alertData = data;
      isLoading = false;
      notifyListeners();
    });
  }

  void _initAudioListeners() {
    _playingSubscription = _audioPlayer.playingStream.listen((playing) {
      isPlaying = playing;
      notifyListeners();
    });

    _positionSubscription = _audioPlayer.positionStream.listen((pos) {
      position = pos;
      notifyListeners();
    });

    _durationSubscription = _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        duration = dur;
        notifyListeners();
      }
    });

    _processingSubscription = _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
      }
    });
  }

  Future<void> loadAndPlayAudio(String url) async {
    if (isAudioLoaded) {
      await togglePlayPause();
      return;
    }

    isAudioLoading = true;
    notifyListeners();

    try {
      await _audioPlayer.setUrl(url);
      isAudioLoaded = true;
      isAudioLoading = false;
      notifyListeners();
      await _audioPlayer.play();
    } catch (e) {
      isAudioLoading = false;
      notifyListeners();
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> seekTo(Duration target) async {
    await _audioPlayer.seek(target);
  }

  String formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _playingSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _processingSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
