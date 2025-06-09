## 📱 Flutter Firebase Mini Chat App Prompt

### 🧩 **Project Title**

**SimpleChat**

---

### 🎯 **Objective**

Build a beautiful and functional real-time **chat application** using **Flutter** and **Firebase**, with **email/password authentication**, user profiles, and chat rooms.

---

### 🚀 **Core Features**

#### ✅ Authentication (Firebase Auth)

* Register with email & password
* Login & logout
* Error handling (invalid email, wrong password, etc.)
* Persist login state

#### 🧑‍🤝‍🧑 User Management

* Save user profile data (username, photo URL) on first registration
* View all registered users (for selecting chat recipients)
* Display user's online status (optional, via Firestore or Realtime Database)

#### 💬 Real-Time Chat (Cloud Firestore)

* 1:1 messaging with another user
* Chat rooms created automatically based on users
* Real-time updates using Firestore streams
* Store messages with:

  * Sender ID
  * Timestamp
  * Text content (and later support for image, emoji, etc.)

#### 🖼 UI/UX Design

* Clean, modern chat UI using Flutter widgets like `ListView`, `TextField`, `StreamBuilder`
* Separate screens:

  * Login/Register
  * Home (list of users)
  * Chat (1:1 conversation)
* Optional: Use `flutter_spinkit` or similar for loading indicators

---

### 🗃️ **Data Structure (Cloud Firestore)**

#### `users` collection:

```json
{
  "uid": "user_id",
  "email": "user@example.com",
  "displayName": "John Doe",
  "photoUrl": "https://...",
  "lastSeen": Timestamp,
}
```

#### `chatRooms` collection:

```json
{
  "id": "chatRoomId_user1_user2",
  "participants": ["user1_uid", "user2_uid"],
  "lastMessage": "Hey!",
  "lastTimestamp": Timestamp
}
```

#### `chatRooms/{chatRoomId}/messages` subcollection:

```json
{
  "senderId": "user1_uid",
  "text": "Hello!",
  "timestamp": Timestamp
}
```

---

### 🔧 **Tech Stack**

* **Flutter** (latest stable)
* **Firebase Services**:

  * Firebase Authentication
  * Cloud Firestore
  * Firebase Core
* **Packages**:

  ```yaml
  dependencies:
    flutter:
      sdk: flutter
    firebase_core: ^latest
    firebase_auth: ^latest
    cloud_firestore: ^latest
    provider: ^latest
    flutter_spinkit: ^latest
    cached_network_image: ^latest
  ```

---

### 🧠 **Advanced Features (Optional)**

* Image sending (use Firebase Storage)
* Push notifications (Firebase Cloud Messaging)
* Group chats
* Message read receipts
* Typing indicator
* Status indicator (online/offline)

---

### 📁 **Recommended Folder Structure**

```
lib/
│
├── main.dart
├── models/
│   └── user_model.dart
│   └── message_model.dart
├── screens/
│   └── login_screen.dart
│   └── register_screen.dart
│   └── home_screen.dart
│   └── chat_screen.dart
├── services/
│   └── auth_service.dart
│   └── firestore_service.dart
├── widgets/
│   └── chat_bubble.dart
│   └── user_tile.dart
├── providers/
│   └── auth_provider.dart
│   └── chat_provider.dart
```

---

### 🧪 **Testing**

* Test login/register flows with Firebase emulator or real Firebase project
* Verify real-time chat using two different devices/emulators
* Ensure data is persisted and streams update without refreshing

---

### 📷 **UI Inspiration**

* WhatsApp / Messenger-style layout
* Rounded chat bubbles
* Light & Dark mode support (optional)
* Use `GoogleFonts` for clean text styling

---

### 📌 Summary

> A sleek and responsive Flutter chat app using Firebase for backend. The app includes login/register, user discovery, and real-time messaging features. All interactions are stored in Firestore, and UI updates in real-time using streams. Designed to scale and be a solid base for future chat apps.
