import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

/// A utility class for diagnosing and fixing Firestore permissions issues
class PermissionChecker {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Tests various Firestore operations and reports issues
  static Future<bool> checkPermissions(BuildContext context) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _showMessage(
          context,
          'Not authenticated',
          'You need to sign in first.',
        );
        return false;
      }

      final String userId = currentUser.uid;
      bool allTestsPassed = true;

      // Step 1: Check if user is in Firestore
      print('DEBUG PERMISSION CHECK: Checking user document...');
      bool userExists = await _checkUserExists(userId);

      if (!userExists) {
        allTestsPassed = false;
        print(
          'DEBUG PERMISSION CHECK: User document does not exist, creating it...',
        );
        await _createUserDocument(currentUser);
      }

      // Step 2: Check if chat rooms collection is accessible
      print('DEBUG PERMISSION CHECK: Testing chat rooms access...');
      bool chatRoomsAccessible = await _testChatRoomsAccess(userId);
      if (!chatRoomsAccessible) {
        allTestsPassed = false;
      }

      // Step 3: Check if chat room messages are accessible
      print('DEBUG PERMISSION CHECK: Testing chat room messages access...');
      bool messagesAccessible = await _testChatRoomMessagesAccess(userId);
      if (!messagesAccessible) {
        allTestsPassed = false;
      }

      // Results
      if (allTestsPassed) {
        print('DEBUG PERMISSION CHECK: All permission tests passed!');
        // _showMessage(
        //   context,
        //   'Permission Check Passed',
        //   'All Firestore permissions are working correctly.',
        // ); // Commented out to prevent UI message
      } else {
        print('DEBUG PERMISSION CHECK: Some permission tests failed');
        _showMessage(
          context,
          'Permission Issues Detected',
          'Some Firestore operations failed. Check logs for details.',
        );
      }

      return allTestsPassed;
    } catch (e) {
      print('DEBUG PERMISSION CHECK ERROR: $e');
      _showMessage(context, 'Error Running Tests', 'Error: $e');
      return false;
    }
  }

  /// Checks if the user document exists in Firestore
  static Future<bool> _checkUserExists(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      print('DEBUG PERMISSION CHECK: User document exists: ${doc.exists}');
      return doc.exists;
    } catch (e) {
      print('DEBUG PERMISSION CHECK ERROR: Failed to check if user exists: $e');
      return false;
    }
  }

  /// Creates a user document if it doesn't exist
  static Future<bool> _createUserDocument(User user) async {
    try {
      // Get some basic information from Firebase Auth
      UserModel newUser = UserModel(
        uid: user.uid,
        email: user.email ?? 'no-email',
        displayName: user.displayName ?? user.email?.split('@')[0] ?? 'User',
        photoUrl: user.photoURL ?? '',
        lastSeen: Timestamp.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(newUser.toJson());
      print('DEBUG PERMISSION CHECK: Successfully created user document');
      return true;
    } catch (e) {
      print('DEBUG PERMISSION CHECK ERROR: Failed to create user document: $e');
      return false;
    }
  }

  /// Tests access to the chatRooms collection
  static Future<bool> _testChatRoomsAccess(String userId) async {
    try {
      print(
        'DEBUG PERMISSION CHECK: Testing read access to chatRooms collection...',
      );
      // Try a simple query first
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('chatRooms')
              .where('participants', arrayContains: userId)
              .limit(1)
              .get();

      print(
        'DEBUG PERMISSION CHECK: Successfully accessed chatRooms collection. Found ${querySnapshot.docs.length} rooms.',
      );

      // Test creating a diagnostic chat room if no rooms exist
      if (querySnapshot.docs.isEmpty) {
        print(
          'DEBUG PERMISSION CHECK: No chat rooms found. Creating a test room...',
        );
        String testRoomId =
            'test_room_${DateTime.now().millisecondsSinceEpoch}';

        await _firestore.collection('chatRooms').doc(testRoomId).set({
          'id': testRoomId,
          'participants': [userId],
          'lastMessage': 'Test message',
          'lastTimestamp': Timestamp.now(),
        });

        // Clean up after test
        await Future.delayed(Duration(seconds: 2));
        await _firestore.collection('chatRooms').doc(testRoomId).delete();
        print(
          'DEBUG PERMISSION CHECK: Test chat room created and deleted successfully',
        );
      }

      return true;
    } catch (e) {
      print(
        'DEBUG PERMISSION CHECK ERROR: Failed to access chatRooms collection: $e',
      );
      return false;
    }
  }

  /// Tests access to messages subcollection in chatRooms
  static Future<bool> _testChatRoomMessagesAccess(String userId) async {
    try {
      print('DEBUG PERMISSION CHECK: Testing access to chat room messages...');

      // First, get a room or create a test room
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('chatRooms')
              .where('participants', arrayContains: userId)
              .limit(1)
              .get();

      String roomId;
      bool isTestRoom = false;

      if (querySnapshot.docs.isEmpty) {
        // Create a test room with the user ID in the document ID for testing pattern matching
        roomId = 'test_${userId}_${DateTime.now().millisecondsSinceEpoch}';
        isTestRoom = true;

        await _firestore.collection('chatRooms').doc(roomId).set({
          'id': roomId,
          'participants': [userId],
          'lastMessage': 'Test message',
          'lastTimestamp': Timestamp.now(),
        });
        print('DEBUG PERMISSION CHECK: Created test room with ID: $roomId');
      } else {
        roomId = querySnapshot.docs.first.id;
        print('DEBUG PERMISSION CHECK: Using existing room with ID: $roomId');
      }

      // Try to access messages subcollection
      print(
        'DEBUG PERMISSION CHECK: Testing read access to messages subcollection...',
      );
      QuerySnapshot messagesSnapshot =
          await _firestore
              .collection('chatRooms')
              .doc(roomId)
              .collection('messages')
              .limit(5)
              .get();

      print(
        'DEBUG PERMISSION CHECK: Successfully accessed messages. Found ${messagesSnapshot.docs.length} messages.',
      );

      // Try to write a test message
      print(
        'DEBUG PERMISSION CHECK: Testing write access to messages subcollection...',
      );
      DocumentReference messageRef = await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .add({
            'senderId': userId,
            'text': 'Permission test message',
            'timestamp': Timestamp.now(),
            'isTest': true,
          });

      print(
        'DEBUG PERMISSION CHECK: Successfully wrote test message with ID: ${messageRef.id}',
      );

      // Clean up after test
      await messageRef.delete();
      print('DEBUG PERMISSION CHECK: Deleted test message');

      if (isTestRoom) {
        await _firestore.collection('chatRooms').doc(roomId).delete();
        print('DEBUG PERMISSION CHECK: Deleted test room');
      }

      return true;
    } catch (e) {
      print(
        'DEBUG PERMISSION CHECK ERROR: Failed to access chat room messages: $e',
      );
      return false;
    }
  }

  /// Shows a message to the user
  static void _showMessage(BuildContext context, String title, String message) {
    // Show a snackbar instead of a dialog to be less intrusive
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
