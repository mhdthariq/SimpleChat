# SimpleChat App

A Firebase-backed Flutter chat application with real-time messaging, profile customization, and image sharing.

## Key Features

- Real-time Messaging: Send and receive messages instantly using Firebase Firestore.
- User Authentication: Secure email/password authentication via Firebase Auth.
- Profile Pictures: Users can upload and display profile pictures, stored in Firebase Storage.
- Image Sharing in Chat: Send images within chat messages.
- Emoji Support: Integrated emoji picker for expressive messaging.
- User Presence: (Basic structure, further implementation planned)
- Typing Indicators: (Planned for future implementation)
- Push Notifications: (Basic setup for foreground, further enhancements planned)
- Theme Customization: Light and dark mode support.
- Firebase App Check: Enhanced security by verifying app integrity.

## Recent Enhancements (as of June 2025)

This section highlights significant updates and fixes:

### 1. Core Functionality & Firebase Integration

- **Firebase Storage for Profile Pictures**:
  - Implemented robust Firebase Storage rules (`storage.rules`) to allow public read for profile pictures and authenticated write for a user's own pictures.
  - Updated `StorageService` to use the correct path (`profile_pictures/{userId}/...`) aligning with new rules.
- **Firebase App Check Integration**:
  - Added `firebase_app_check` dependency.
  - Initialized Firebase App Check in `main.dart` using `AndroidProvider.debug` for debug mode and `AndroidProvider.playIntegrity` for release.
  - Users need to add the debug token (from console output) to Firebase App Check settings and potentially SHA fingerprints to the Firebase project for Play Integrity to work in release.
- **Firestore Security Rules & Indexing**:
  - Improved Firestore security rules (`firestore.rules`) for users, chat rooms, and messages.
  - Enhanced error handling for missing Firestore indexes, with guidance for users.
- **User Management**:
  - Addressed issues with Auth-to-Firestore user data synchronization.

### 2. UI/UX Improvements

- **Emoji Picker**:
  - Added `emoji_picker_flutter` dependency.
  - Integrated an emoji picker into the `ChatScreen`, allowing users to easily add emojis to their messages.
  - Managed keyboard and picker visibility for a smooth user experience.
- **Error Handling & Stability**:
  - Fixed "Looking up a deactivated widget's ancestor is unsafe" error in `ChatScreen` by caching `ScaffoldMessengerState`.
  - Refined error display for permission issues, providing a retry mechanism.
- **Permissions**:
  - Removed the intrusive "Permission Check Passed" UI dialog for a cleaner experience.
- **Theme**:
  - Fixed theme transition errors by ensuring consistent `TextTheme` inheritance in `main.dart`.

### 3. Android Specific

- **`SecurityException` Fix**: Added `android:enableOnBackInvokedCallback="true"` to `AndroidManifest.xml`.
- **SHA Fingerprints**: Users are guided to add SHA-1 and SHA-256 fingerprints to their Firebase project settings for full Firebase services integration on Android.

### 4. Development & Security

- **`.gitignore` Updates**: Enhanced `.gitignore` files (root and `android/`) to exclude potentially sensitive files like `secrets.json`, `.env*`, and `secrets.properties`.
- **Nullable Fields**: Updated `UserModel`'s `photoUrl` to be nullable, with corresponding changes in services and UI components.

## Required Firebase Setup

For the app to work correctly, ensure your Firebase project is configured with:

1. **Firebase Authentication**:
   - Email/Password sign-in method enabled.
2. **Firestore Database**:
   - Native mode.
   - Appropriate security rules (see `firestore.rules` in this project).
   - **Composite Index**: For `chatRooms` collection:
     - Field 1: `participants` (Array Contains)
     - Field 2: `lastTimestamp` (Descending)
3. **Firebase Storage**:
   - Default bucket created.
   - Appropriate security rules (see `storage.rules` in this project).
4. **Firebase App Check**:
   - Enable for your project.
   - For Android, register your app with Play Integrity.
   - During development, add the debug token (printed in the Flutter console on first run with App Check) to the "Apps" section of App Check in the Firebase console.
   - Add your app's SHA-1 and SHA-256 fingerprints to your Firebase project settings (Project settings > Your apps > Android app).
5. **`google-services.json`**:
   - Download the `google-services.json` file from your Firebase project settings and place it in the `android/app/` directory. Ensure it's updated after adding SHA fingerprints.

## Key Dependencies

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_storage`
- `firebase_app_check`
- `provider` (for state management)
- `image_picker`
- `emoji_picker_flutter`
- `permission_handler`
- `flutter_local_notifications`
- (See `pubspec.yaml` for a full list)

## Getting Started

This project is a Flutter application. To get started:

1. **Clone the repository.**
2. **Ensure you have Flutter SDK installed.**
3. **Set up your Firebase project** as described in the "Required Firebase Setup" section.
4. Place your `google-services.json` in `android/app/`.
5. Run `flutter pub get` to install dependencies.
6. Run `flutter run` to launch the application on an emulator or device.

### Flutter Resources

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
