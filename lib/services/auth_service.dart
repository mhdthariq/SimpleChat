// File: lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create a user in Firestore
      await _createUserInFirestore(result.user!.uid, email, displayName);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Create a user document in Firestore
  Future<void> _createUserInFirestore(
    String uid,
    String email,
    String displayName,
  ) async {
    UserModel newUser = UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: '',
      lastSeen: Timestamp.now(),
    );

    await _firestore.collection('users').doc(uid).set(newUser.toJson());
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user document exists, create if it doesn't
      DocumentSnapshot docSnap =
          await _firestore.collection('users').doc(result.user!.uid).get();
      if (!docSnap.exists) {
        // Create a new user document
        await _createUserInFirestore(
          result.user!.uid,
          email,
          email.split('@')[0], // Simple display name from email
        );
      } else {
        // Just update last seen
        await _firestore.collection('users').doc(result.user!.uid).update({
          'lastSeen': Timestamp.now(),
        });
      }

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Update last seen before signing out
      if (currentUser != null) {
        // Check if user document exists first
        DocumentSnapshot docSnap =
            await _firestore.collection('users').doc(currentUser!.uid).get();
        if (docSnap.exists) {
          await _firestore.collection('users').doc(currentUser!.uid).update({
            'lastSeen': Timestamp.now(),
          });
        }
      }
      await _auth.signOut();
    } catch (e) {
      print('Error during sign out: $e');
      rethrow;
    }
  }

  // Get user from Firestore
  Future<UserModel?> getUserFromFirestore(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Sync Auth users with Firestore
  Future<void> syncAuthUsersWithFirestore() async {
    try {
      print('Starting Auth to Firestore sync...');

      // Get current user to keep track of progress
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('No current user - cannot sync users');
        return;
      }

      print('Checking user in Firestore: ${currentUser.uid}');

      // Check if the current user exists in Firestore
      DocumentSnapshot docSnap =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (!docSnap.exists) {
        print('Current user not found in Firestore - adding user document');

        // Create user document
        await _createUserInFirestore(
          currentUser.uid,
          currentUser.email ?? 'no-email',
          currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User',
        );

        print('User document created for: ${currentUser.uid}');
      } else {
        print('User already exists in Firestore: ${currentUser.uid}');

        // Update lastSeen timestamp
        await _firestore.collection('users').doc(currentUser.uid).update({
          'lastSeen': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error syncing Auth users with Firestore: $e');
      rethrow;
    }
  }
}
