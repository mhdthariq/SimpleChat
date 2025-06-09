// File: lib/providers/chat_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart'; // Import NotificationService
import 'dart:io';

class ChatProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService =
      NotificationService(); // Add this
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance; // Add this

  List<UserModel> _users = [];
  List<ChatRoom> _chatRooms = [];
  List<MessageModel> _messages = [];
  String _currentChatRoomId = '';
  UserModel? _selectedUser;
  bool _isLoading = false;
  String _error = '';

  List<UserModel> get users => _users;
  List<ChatRoom> get chatRooms => _chatRooms;
  List<MessageModel> get messages => _messages;
  String get currentChatRoomId => _currentChatRoomId;
  UserModel? get selectedUser => _selectedUser;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Load users
  void loadUsers({String? currentUserId}) {
    try {
      _firestoreService.getUsers(exceptUserId: currentUserId).listen((users) {
        _users = users;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Refresh users (for pull-to-refresh functionality)
  Future<void> refreshUsers({String? currentUserId}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // The Firestore listener will update the users list automatically
      // But setting isLoading provides visual feedback for refresh

      await Future.delayed(const Duration(milliseconds: 500));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load chat rooms for a user
  void loadChatRooms(String userId) {
    try {
      print('Loading chat rooms for user: $userId');

      // First try with the index-requiring query
      _firestoreService
          .getChatRooms(userId)
          .listen(
            (chatRooms) {
              print('Got ${chatRooms.length} chat rooms from Firestore');
              _chatRooms = chatRooms;
              notifyListeners();
            },
            onError: (error) {
              print('Error getting chat rooms: $error');
              if (error.toString().contains('requires an index')) {
                print('''
==========================================================
INDEX ERROR DETECTED: 
This error happens when the required Firestore index doesn't exist.
Please follow the link in the Firebase console to create it.

Falling back to a simpler query without ordering that doesn't require an index.
==========================================================
''');

                // Fallback - try to get chat rooms without ordering
                _loadChatRoomsWithoutOrdering(userId);
              } else {
                // For other errors, just set empty chat rooms
                _chatRooms = [];
                _error = error.toString();
                notifyListeners();
              }
            },
          );
    } catch (e) {
      _error = e.toString();
      _chatRooms = []; // Set empty list on error
      notifyListeners();
    }
  }

  // Fallback method for loading chat rooms without using an index
  void _loadChatRoomsWithoutOrdering(String userId) {
    try {
      // Create a simpler query that doesn't require an index
      FirebaseFirestore.instance
          .collection('chatRooms')
          .where('participants', arrayContains: userId)
          .snapshots()
          .listen(
            (snapshot) {
              List<ChatRoom> rooms = [];
              for (var doc in snapshot.docs) {
                try {
                  rooms.add(ChatRoom.fromJson(doc.data()));
                } catch (e) {
                  print('Error parsing chat room: $e');
                }
              }

              // Sort manually on client side
              rooms.sort((a, b) => b.lastTimestamp.compareTo(a.lastTimestamp));

              _chatRooms = rooms;
              notifyListeners();

              print('Loaded ${rooms.length} chat rooms with fallback method');
            },
            onError: (error) {
              print('Even fallback query failed: $error');
              _chatRooms = [];
              _error = 'Failed to load chat rooms: $error';
              notifyListeners();
            },
          );
    } catch (e) {
      print('Exception in fallback chat room loading: $e');
      _chatRooms = [];
      _error = e.toString();
      notifyListeners();
    }
  }

  // Create or get chat room and load messages
  Future<void> createAndLoadChatRoom(
    String currentUserId,
    String peerId,
  ) async {
    try {
      _isLoading = true;
      _error = ''; // Clear any previous errors
      notifyListeners();

      print(
        'DEBUG: Creating/getting chat room for users: $currentUserId and $peerId',
      );

      try {
        _currentChatRoomId = await _firestoreService.createChatRoom(
          currentUserId,
          peerId,
        );

        print('DEBUG: Chat room ID: $_currentChatRoomId');

        // Get peer user details
        print('DEBUG: Getting peer user details for: $peerId');
        UserModel? peerUser = await _firestoreService.getUser(peerId);
        if (peerUser != null) {
          _selectedUser = peerUser;
          print('DEBUG: Peer user loaded: ${peerUser.displayName}');
        } else {
          print('DEBUG: Failed to load peer user details');
        }

        // Listen to messages
        print(
          'DEBUG: Starting message listener for chat room: $_currentChatRoomId',
        );
        _firestoreService
            .getMessages(_currentChatRoomId)
            .listen(
              (messages) {
                print('DEBUG: Received ${messages.length} messages');
                _messages = messages;
                // Show notification for new messages
                final currentUserId = _firebaseAuth.currentUser?.uid;
                if (messages.isNotEmpty &&
                    messages.first.senderId != currentUserId &&
                    currentUserId != null) {
                  final lastMessage = messages.first;
                  // Check if the app is in the foreground or if the chat screen for this chat room is active
                  // This is a basic check; more sophisticated foreground detection might be needed.
                  // For simplicity, we'll assume for now that if we are listening to messages, the chat is somewhat active.
                  // A more robust solution would involve checking app lifecycle state and current route.

                  _notificationService.showNotification(
                    id:
                        lastMessage.timestamp.millisecondsSinceEpoch %
                        2147483647, // Ensure ID is within integer range
                    title:
                        'New message from ${_selectedUser?.displayName ?? "User"}',
                    body: lastMessage.text,
                    payload:
                        _currentChatRoomId, // Optional: To navigate to chat on tap
                  );
                }
                notifyListeners();
              },
              onError: (error) {
                print('DEBUG ERROR: Failed to get messages: $error');
                _error = 'Failed to load messages: $error';
                notifyListeners();
              },
            );
      } catch (e) {
        // Special handling for permission errors
        if (e.toString().contains('permission-denied')) {
          print('DEBUG ERROR: Permission denied when accessing chat room: $e');
          _error = 'Permission denied: $e. Please check Firestore rules.';

          // Even though we had an error, still set the user so we can retry
          UserModel? peerUser = await _firestoreService.getUser(peerId);
          if (peerUser != null) {
            _selectedUser = peerUser;
          }
        } else {
          rethrow;
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Send a message
  Future<void> sendMessage(String senderId, String message) async {
    try {
      if (_currentChatRoomId.isEmpty) return;

      await _firestoreService.sendMessage(
        _currentChatRoomId,
        senderId,
        message,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Send message with image
  Future<void> sendMessageWithImage(
    String senderId,
    String text,
    File imageFile,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestoreService.sendMessageWithImage(
        _currentChatRoomId,
        senderId,
        text,
        imageFile,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user status
  Future<void> updateUserStatus(String userId, bool isOnline) async {
    try {
      await _firestoreService.updateUserStatus(userId, isOnline);
    } catch (e) {
      // Just log the error instead of updating state to prevent UI issues during logout
      print('Error updating user status: $e');
    }
  }

  // Get peer user from chat room
  UserModel? getPeerUser(String chatRoomId, String currentUserId) {
    try {
      ChatRoom? chatRoom = _chatRooms.firstWhere(
        (room) => room.id == chatRoomId,
      );
      String peerId = chatRoom.participants.firstWhere(
        (id) => id != currentUserId,
      );
      return _users.firstWhere((user) => user.uid == peerId);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  void clearSelectedUser() {
    _selectedUser = null;
    _currentChatRoomId = '';
    _messages = [];
    notifyListeners();
  }
}
