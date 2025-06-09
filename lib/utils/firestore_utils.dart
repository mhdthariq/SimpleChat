// File: lib/utils/firestore_utils.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/index_helper_screen.dart';

/// A utility class for Firestore related operations and error handling
class FirestoreUtils {
  /// Extracts and returns the index creation URL from a Firestore error message
  static String? extractIndexUrlFromError(String errorMessage) {
    // Extract URL from error message - typically enclosed in ( ) or after 'URL: '
    RegExp regExp = RegExp(r'https://console\.firebase\.google\.com/[^\s\)]+');
    Match? match = regExp.firstMatch(errorMessage);

    if (match != null) {
      return match.group(0);
    }

    return null;
  }

  /// Shows a dialog to help the user create a missing Firestore index
  static void showCreateIndexDialog(BuildContext context, String errorMessage) {
    String? indexUrl = extractIndexUrlFromError(errorMessage);

    // Check if this is specifically a missing index error for chat rooms
    if (errorMessage.contains('index') && errorMessage.contains('chatRooms')) {
      // Navigate to dedicated helper screen instead of showing a dialog
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const IndexHelper()),
      );
      return;
    }

    // For other errors, show the regular dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Firestore Index Required'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This app requires a Firestore index that needs to be created. '
                  'This is a one-time setup that requires Firebase console access.',
                ),
                const SizedBox(height: 16),
                if (indexUrl != null)
                  const Text(
                    'Click the button below to open the Firebase console and create the index:',
                  )
                else
                  const Text(
                    'Please go to Firebase Console > Firestore Database > Indexes and '
                    'create a composite index for the chatRooms collection with fields:\n'
                    '- participants (array-contains)\n'
                    '- lastTimestamp (descending)',
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              if (indexUrl != null)
                ElevatedButton(
                  onPressed: () async {
                    final Uri url = Uri.parse(indexUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Create Index'),
                ),
            ],
          ),
    );
  }

  /// Check if the error is related to permission denied and show appropriate message
  static void handleFirestoreError(BuildContext context, String errorMessage) {
    if (errorMessage.contains('permission-denied') ||
        errorMessage.contains('Missing or insufficient permissions')) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Permission Error'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You do not have permission to access this data.'),
                  SizedBox(height: 16),
                  Text(
                    'This could be due to:\n'
                    '1. Firestore security rules not deployed properly\n'
                    '2. You are not authenticated\n'
                    '3. You do not have access to this specific data',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } else if (errorMessage.contains('requires an index') ||
        errorMessage.contains('FAILED_PRECONDITION')) {
      showCreateIndexDialog(context, errorMessage);
    } else {
      // Generic error handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMessage'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
