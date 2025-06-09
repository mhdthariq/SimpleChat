# SimpleChat App

A Firebase-backed Flutter chat application with real-time messaging.

## Recent Enhancements

Several issues were identified and fixed in this update:

### 1. Fixed Theme Transition Error

- Modified the theme configuration in `main.dart` to ensure consistent TextTheme inheritance
- Applied the same base theme for both light and dark modes with proper inheritance configuration

### 2. Improved Firestore Security Rules

- Added comprehensive security rules for users and chat rooms collections
- Enforced proper access controls for read/write operations
- Added specific rules for message subcollections

### 3. Firestore Index Management

- Added proper error handling for missing Firestore index cases
- Implemented a fallback method for loading chat rooms without the composite index
- Created a user-friendly dialog to guide users through index creation

### 4. User Management Improvements

- Fixed issues with users not appearing despite existing in Firebase Auth
- Added Auth-to-Firestore synchronization to ensure user data consistency
- Improved error handling and logging for user data

### 5. Collection Name Consistency

- Standardized collection names across the app (using 'chatRooms' consistently)

## Required Firebase Setup

For the app to work correctly, you need to set up:

1. **Firestore Database**: With collections for users and chat rooms
2. **Firebase Authentication**: Email/password authentication enabled
3. **Firebase Storage**: For profile pictures and chat images
4. **Firestore Index**: A composite index on the `chatRooms` collection:
   - Field 1: `participants` (array-contains)
   - Field 2: `lastTimestamp` (descending)

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
