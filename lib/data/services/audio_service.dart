import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  FlutterSoundRecorder? _recorder;
  bool _isRecorderInitialized = false;

  Future<void> _initRecorder() async {
    _recorder = FlutterSoundRecorder();

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    await _recorder!.openRecorder();
    _isRecorderInitialized = true;
  }

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status == PermissionStatus.granted;
  }

  Future<String?> startRecording() async {
    try {
      if (!_isRecorderInitialized) {
        await _initRecorder();
      }

      final Directory tempDir = await getTemporaryDirectory();
      final String path = '${tempDir.path}/sos_action_${DateTime.now().millisecondsSinceEpoch}.aac';

      // Start recording (flutter_sound syntax)
      await _recorder!.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
      );
      
      debugPrint('Recording started at path: $path');
      return path;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return null;
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (!_isRecorderInitialized) return null;
      
      final path = await _recorder!.stopRecorder();
      debugPrint('Recording stopped. File saved at: $path');
      return path;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  Future<bool> isRecording() async {
    return _recorder?.isRecording ?? false;
  }

  void dispose() {
    if (_isRecorderInitialized) {
      _recorder!.closeRecorder();
      _recorder = null;
      _isRecorderInitialized = false;
    }
  }
}
