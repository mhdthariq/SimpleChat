import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p; // For getting file extension
import 'package:flutter/foundation.dart'; // Import foundation for kDebugMode

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    try {
      String fileExtension = p.extension(imageFile.path);
      Reference ref = _storage
          .ref()
          .child(
            'profile_pictures',
          ) // Changed 'user_profiles' to 'profile_pictures'
          .child(userId)
          .child('profile_picture$fileExtension');

      UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/${fileExtension.substring(1)}',
        ), // e.g. image/jpeg, image/png
      );

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading profile picture: $e');
      }
      rethrow; // Re-throw the exception to be handled by the caller
    }
  }

  // Optional: Delete profile picture (if needed for updates)
  Future<void> deleteProfilePicture(String userId, String fileName) async {
    try {
      Reference ref = _storage
          .ref()
          .child(
            'profile_pictures',
          ) // Changed 'user_profiles' to 'profile_pictures'
          .child(userId)
          .child(fileName); // You'd need to store/construct the full file name
      await ref.delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting profile picture: $e');
      }
      rethrow; // Re-throw the exception to be handled by the caller
    }
  }
}
