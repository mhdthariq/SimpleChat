// File: lib/widgets/user_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';

class UserTile extends StatelessWidget {
  final UserModel user;
  final ChatRoom? chatRoom;
  final bool isUserList;
  final VoidCallback onTap;

  const UserTile({
    super.key,
    required this.user,
    this.chatRoom,
    this.isUserList = true,
    required this.onTap,
  });

  String _formatLastSeen(Timestamp timestamp) {
    DateTime lastSeen = timestamp.toDate();
    DateTime now = DateTime.now();
    Duration difference = now.difference(lastSeen);

    if (difference.inMinutes < 5) {
      return 'Online';
    } else if (difference.inHours < 24) {
      return DateFormat('h:mm a').format(lastSeen);
    } else {
      return DateFormat('MMM d').format(lastSeen);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child:
            user.photoUrl.isNotEmpty
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    user.photoUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                )
                : Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
      title: Text(
        user.displayName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        isUserList
            ? _formatLastSeen(user.lastSeen)
            : chatRoom != null
            ? chatRoom!.lastMessage.isEmpty
                ? 'No messages yet'
                : chatRoom!.lastMessage
            : '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing:
          isUserList
              ? null
              : chatRoom != null
              ? Text(_formatLastSeen(chatRoom!.lastTimestamp))
              : null,
      onTap: onTap,
    );
  }
}
