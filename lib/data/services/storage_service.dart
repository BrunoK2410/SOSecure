import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadSosAudio({
    required String userId,
    required String sosId,
    required String filePath,
  }) async {
    try {
      final File file = File(filePath);
      if (!await file.exists()) {
        debugPrint('File does not exist: $filePath');
        return null;
      }

      // Create a reference to 'sos_audio/[userId]/[sosId].m4a'
      final Reference ref = _storage
          .ref()
          .child('sos_audio')
          .child(userId)
          .child('$sosId.m4a');

      // Upload the file
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'audio/m4a'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('Audio uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading audio to Firebase Storage: $e');
      return null;
    }
  }
}
