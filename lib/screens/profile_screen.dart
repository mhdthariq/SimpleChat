import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io'; // For File type
import 'package:image_picker/image_picker.dart'; // For ImagePicker

import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart'; // Will be needed for updating user doc

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _nameController = TextEditingController(
      text: authProvider.userModel?.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final storageService = StorageService();
    // final firestoreService = FirestoreService(); // Initialize if not done via provider or direct

    String? newPhotoUrl;
    String newDisplayName = _nameController.text.trim();

    try {
      if (_selectedImage != null && authProvider.user?.uid != null) {
        newPhotoUrl = await storageService.uploadProfilePicture(
          authProvider.user!.uid,
          _selectedImage!,
        );
      }

      // TODO: Implement updateUserProfile in AuthProvider
      // This method should handle updating FirebaseAuth display name, photoURL,
      // and the user document in Firestore.
      await authProvider.updateUserProfile(
        displayName: newDisplayName,
        photoUrl:
            newPhotoUrl, // Pass null if not changed, or existing if only name changes
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating profile: \$e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserModel = authProvider.userModel;

    // Determine current photo URL or use selected image for preview
    ImageProvider? profileImageProvider;
    if (_selectedImage != null) {
      profileImageProvider = FileImage(_selectedImage!);
    } else if (currentUserModel?.photoUrl != null &&
        currentUserModel!.photoUrl!.isNotEmpty) {
      profileImageProvider = NetworkImage(currentUserModel.photoUrl!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: profileImageProvider,
                  child:
                      profileImageProvider == null
                          ? Icon(
                            Icons.person,
                            size: 50,
                            color: Theme.of(context).colorScheme.primary,
                          )
                          : null,
                ),
              ),
              TextButton(
                onPressed: _pickImage,
                child: const Text('Change Profile Photo'),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Display Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Display name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save Profile'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// TODO: Add updateUserProfile method to AuthProvider
// It should look something like this:
/*
Future<void> updateUserProfile({String? displayName, String? photoUrl}) async {
  if (_user == null) return;
  _isLoading = true;
  notifyListeners();
  try {
    // Update Firestore (this might be in AuthService or FirestoreService)
    Map<String, dynamic> updates = {};
    if (displayName != null && displayName != _userModel?.displayName) {
      updates['displayName'] = displayName;
    }
    if (photoUrl != null && photoUrl != _userModel?.photoUrl) {
      updates['photoUrl'] = photoUrl;
    }

    if (updates.isNotEmpty) {
      await _authService.updateUserInFirestore(_user!.uid, updates);
    }

    // Update FirebaseAuth User profile
    if (displayName != null && displayName != _user!.displayName) {
      await _user!.updateDisplayName(displayName);
    }
    if (photoUrl != null && photoUrl != _user!.photoURL) {
      await _user!.updatePhotoURL(photoUrl);
    }
    
    // Refresh user data
    await refreshUser(); // This fetches from Firestore and updates _user and _userModel

  } catch (e) {
    _error = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
*/
