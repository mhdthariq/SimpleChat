// File: lib/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String _error = '';

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isAuthenticated => _user != null;
  bool get needsProfileSetup =>
      _user != null &&
      (_user!.displayName == null || _user!.displayName!.isEmpty);

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      if (user != null) {
        _fetchUserModel();

        // Also make sure user exists in Firestore
        _authService
            .syncAuthUsersWithFirestore()
            .then((_) {
              if (kDebugMode) {
                print('Auth to Firestore sync completed successfully');
              }
            })
            .catchError((error) {
              if (kDebugMode) {
                print('Auth to Firestore sync error: $error');
              }
            });
      } else {
        _userModel = null;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchUserModel() async {
    if (_user != null) {
      try {
        _userModel = await _authService.getUserFromFirestore(_user!.uid);
        notifyListeners();
      } catch (e) {
        _error = e.toString();
        notifyListeners();
      }
    }
  }

  Future<void> refreshUser() async {
    if (_user != null) {
      await _user!.reload();
      _user =
          _authService.currentUser; // Corrected to use the currentUser getter
      await _fetchUserModel(); // This will update _userModel with new data from Firestore
      notifyListeners();
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      await _authService.signInWithEmailAndPassword(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      await _authService.registerWithEmailAndPassword(
        email,
        password,
        displayName,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateUserProfile({
    required String displayName,
    String?
    photoUrl, // This can be null if only display name is changed, or if it's being removed.
  }) async {
    if (_user == null) return;

    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      Map<String, dynamic> firestoreUpdates = {};
      bool authProfileNeedsUpdate = false;

      // Prepare Firestore updates
      if (displayName != _userModel?.displayName) {
        firestoreUpdates['displayName'] = displayName;
      }
      // If photoUrl is explicitly provided (even if null to clear it), update Firestore.
      // If photoUrl is not provided (i.e., it's an optional parameter that wasn't passed),
      // we don't touch the photoUrl in Firestore unless it's different from the current one.
      if (photoUrl != _userModel?.photoUrl) {
        // This handles new URL, changed URL, or clearing URL
        firestoreUpdates['photoUrl'] = photoUrl;
      }

      // Update Firestore document if there are changes
      if (firestoreUpdates.isNotEmpty) {
        await _authService.updateUserProfile(
          _user!.uid,
          firestoreUpdates,
        ); // Corrected: was calling updateUserInFirestore
      }

      // Check if Firebase Auth profile needs update
      if (displayName != _user!.displayName) {
        await _user!.updateDisplayName(displayName);
        authProfileNeedsUpdate = true;
      }
      if (photoUrl != _user!.photoURL) {
        // Handles new URL, changed URL, or clearing URL
        await _user!.updatePhotoURL(photoUrl);
        authProfileNeedsUpdate = true;
      }

      // Refresh user data from both Auth and Firestore
      // This will reload _user (which reflects Auth changes) and then _fetchUserModel (which reflects Firestore changes)
      await refreshUser();
    } catch (e) {
      _error = e.toString();
      // Potentially rethrow or handle more gracefully if partial updates occurred
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}
