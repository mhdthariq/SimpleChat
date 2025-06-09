// File: lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get all users
  Stream<List<UserModel>> getUsers({String? exceptUserId}) {
    try {
      print('Fetching users from Firestore, excluding: $exceptUserId');

      // First query to debug
      _firestore
          .collection('users')
          .get()
          .then((snapshot) {
            print('Raw users count from Firestore: ${snapshot.docs.length}');
            for (var doc in snapshot.docs) {
              print(
                'User found in Firestore: ${doc.id} - ${doc.data()['displayName']}',
              );
            }
          })
          .catchError((error) {
            print('Error in debug fetch: $error');
          });

      // Main query with improved error handling
      return _firestore
          .collection('users')
          .orderBy('displayName')
          .snapshots()
          .handleError((error) {
            print('Error fetching users: $error');
            // Return empty stream instead of empty list
            return Stream.value(
              <QueryDocumentSnapshot<Map<String, dynamic>>>[],
            );
          })
          .map((snapshot) {
            print(
              'Users snapshot received with ${snapshot.docs.length} documents',
            );
            List<UserModel> users = [];

            for (var doc in snapshot.docs) {
              try {
                print('Processing user: ${doc.id}');
                Map<String, dynamic> data = doc.data();
                users.add(UserModel.fromJson(data));
                print('Successfully added user: ${data['displayName']}');
              } catch (e) {
                print('Error parsing user document ${doc.id}: $e');
                // Try a more manual approach if parsing fails
                try {
                  UserModel user = UserModel(
                    uid: doc.id,
                    email: doc.data()['email'] ?? '',
                    displayName: doc.data()['displayName'] ?? 'Unknown User',
                    photoUrl: doc.data()['photoUrl'] ?? '',
                    lastSeen: doc.data()['lastSeen'] ?? Timestamp.now(),
                  );
                  users.add(user);
                  print('Added user with manual parsing: ${user.displayName}');
                } catch (e2) {
                  print('Failed even with manual parsing: $e2');
                }
              }
            }

            // Filter out the current user if exceptUserId is provided
            if (exceptUserId != null) {
              users = users.where((user) => user.uid != exceptUserId).toList();
              print(
                'After filtering out current user: ${users.length} users remain',
              );
            }

            // Sort by display name
            users.sort((a, b) => a.displayName.compareTo(b.displayName));

            return users;
          });
    } catch (e) {
      print('Error setting up users stream: $e');
      return Stream.value([]);
    }
  }

  // Get single user
  Future<UserModel?> getUser(String uid) async {
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

  // Create or get a chat room for two users
  Future<String> createChatRoom(String currentUserId, String peerId) async {
    try {
      print(
        'DEBUG: Creating/getting chat room for users $currentUserId and $peerId',
      );

      // Sort user IDs to ensure consistent chat room IDs
      List<String> ids = [currentUserId, peerId];
      ids.sort(); // Sort alphabetically
      String chatRoomId = 'chatRoom_${ids[0]}_${ids[1]}';

      print('DEBUG: Generated chat room ID: $chatRoomId');

      try {
        // Check if the chat room already exists
        print('DEBUG: Checking if chat room already exists...');
        DocumentSnapshot chatRoomDoc =
            await _firestore.collection('chatRooms').doc(chatRoomId).get();

        if (!chatRoomDoc.exists) {
          print('DEBUG: Chat room does not exist, creating new one...');
          // Create a new chat room
          ChatRoom newChatRoom = ChatRoom(
            id: chatRoomId,
            participants: [currentUserId, peerId],
            lastMessage: '',
            lastTimestamp: Timestamp.now(),
          );

          await _firestore
              .collection('chatRooms')
              .doc(chatRoomId)
              .set(newChatRoom.toJson());

          print('DEBUG: New chat room created successfully');
        } else {
          print('DEBUG: Chat room already exists');
        }
      } catch (error) {
        // Handle permission errors by forcing creation
        if (error.toString().contains('permission-denied')) {
          print(
            'DEBUG: Permission error accessing chat room, trying direct creation',
          );
          // Direct creation without checking first - this should work with the updated security rules
          ChatRoom newChatRoom = ChatRoom(
            id: chatRoomId,
            participants: [currentUserId, peerId],
            lastMessage: '',
            lastTimestamp: Timestamp.now(),
          );

          await _firestore
              .collection('chatRooms')
              .doc(chatRoomId)
              .set(newChatRoom.toJson());

          print('DEBUG: Direct chat room creation attempted');
        } else {
          print('DEBUG ERROR: Error accessing chat room: $error');
          throw error;
        }
      }

      return chatRoomId;
    } catch (error) {
      print('DEBUG CRITICAL ERROR: Failed in createChatRoom: $error');
      rethrow;
    }
  }

  // Get chat rooms for a user
  Stream<List<ChatRoom>> getChatRooms(String userId) {
    try {
      print('Fetching chat rooms for user: $userId');

      return _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: userId)
          .orderBy('lastTimestamp', descending: true)
          .snapshots()
          .handleError((error) {
            print('Error getting chat rooms: $error');
            if (error.toString().contains('The query requires an index')) {
              print('''
==========================================================
FIRESTORE INDEX ERROR: 
The query requires a composite index that needs to be created.
Please create the required Firestore index by clicking the link in the error message above.

Alternatively, you can create it manually:
1. Go to Firebase Console > Firestore Database > Indexes
2. Add a composite index:
   - Collection: chatRooms
   - Fields: 
     * participants (array-contains)
     * lastTimestamp (descending)
   - Query scope: Collection
==========================================================
              ''');
            }
            return Stream.value(
              <QueryDocumentSnapshot<Map<String, dynamic>>>[],
            );
          })
          .map((snapshot) {
            print(
              'Chat rooms snapshot received with ${snapshot.docs.length} documents',
            );
            return snapshot.docs
                .map((doc) {
                  try {
                    print('Processing chat room: ${doc.id}');
                    return ChatRoom.fromJson(doc.data());
                  } catch (e) {
                    print('Error parsing chat room ${doc.id}: $e');
                    // Return null for failed entries
                    return null;
                  }
                })
                .where((room) => room != null) // Filter out nulls
                .cast<ChatRoom>() // Cast to non-nullable
                .toList();
          });
    } catch (e) {
      print('Error setting up chat rooms stream: $e');
      // Return empty stream on error
      return Stream.value([]);
    }
  }

  // Send a message
  Future<void> sendMessage(
    String chatRoomId,
    String senderId,
    String message,
  ) async {
    try {
      // Create message
      MessageModel newMessage = MessageModel(
        senderId: senderId,
        text: message,
        timestamp: Timestamp.now(),
      );

      // Add message to subcollection
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(newMessage.toJson());

      // Update the chat room's last message and timestamp
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'lastMessage': message,
        'lastTimestamp': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get messages for a chat room
  Stream<List<MessageModel>> getMessages(String chatRoomId) {
    print('DEBUG: Setting up messages listener for chat room: $chatRoomId');

    try {
      return _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .handleError((error) {
            print('DEBUG ERROR: Error getting messages: $error');

            // Check for permission errors specifically
            if (error.toString().contains('permission-denied') ||
                error.toString().contains(
                  'Missing or insufficient permissions',
                )) {
              print(
                'DEBUG SECURITY ERROR: Permission denied. Check Firestore security rules.',
              );
              print(
                'DEBUG INFO: Attempted to access: chatRooms/$chatRoomId/messages',
              );
            }

            // Return empty list instead of crashing
            return Stream.value(
              <QueryDocumentSnapshot<Map<String, dynamic>>>[],
            );
          })
          .map((snapshot) {
            print(
              'DEBUG: Received ${snapshot.docs.length} messages for chat room: $chatRoomId',
            );
            return snapshot.docs
                .map((doc) => MessageModel.fromJson(doc.data()))
                .toList();
          });
    } catch (e) {
      print('DEBUG CRITICAL ERROR: Error setting up messages stream: $e');
      return Stream.value(<MessageModel>[]); // Return empty stream on error
    }
  }

  // Update user online status
  Future<void> updateUserStatus(String userId, bool isOnline) async {
    try {
      // Check if user document exists first
      DocumentSnapshot docSnap =
          await _firestore.collection('users').doc(userId).get();
      if (docSnap.exists) {
        await _firestore.collection('users').doc(userId).update({
          'lastSeen': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error updating user status: $e');
      // Don't rethrow to prevent app crashes during status updates
    }
  }

  // Upload image to Firebase Storage
  Future<String?> uploadImage(File imageFile) async {
    try {
      // Create a unique file name
      String fileName =
          'images/${DateTime.now().millisecondsSinceEpoch}_${imageFile.uri.pathSegments.last}';

      // Upload the file to Firebase Storage
      TaskSnapshot snapshot = await _storage.ref(fileName).putFile(imageFile);

      // Get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Upload chat image to Firebase Storage
  Future<String?> uploadChatImage(
    String chatRoomId,
    String senderId,
    File imageFile,
  ) async {
    try {
      // Create a unique file name
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$senderId.jpg';

      // Reference to storage
      Reference storageRef = _storage.ref().child(
        'chat_images/$chatRoomId/$fileName',
      );

      // Upload image
      UploadTask uploadTask = storageRef.putFile(imageFile);

      // Get download URL
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading chat image: $e');
      return null;
    }
  }

  // Send message with image
  Future<void> sendMessageWithImage(
    String chatRoomId,
    String senderId,
    String text,
    File imageFile,
  ) async {
    try {
      // Upload image first
      String? imageUrl = await uploadChatImage(chatRoomId, senderId, imageFile);

      // Create message
      MessageModel message = MessageModel(
        senderId: senderId,
        text: text,
        timestamp: Timestamp.now(),
        imageUrl: imageUrl,
      );

      // Add message to Firestore
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(message.toJson());

      // Update chat room with last message
      await _firestore.collection('chatRooms').doc(chatRoomId).update({
        'lastMessage': text.isEmpty ? 'Image' : text,
        'lastTimestamp': Timestamp.now(),
      });
    } catch (e) {
      print('Error sending message with image: $e');
      rethrow;
    }
  }
}
