import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../models/user_model.dart';
import '../widgets/user_tile.dart'; // Ensured UserTile import
import '../utils/page_routes.dart';
import '../utils/firestore_utils.dart';
import 'chat_screen.dart';
import 'profile_screen.dart'; // Ensured ProfileScreen import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isUsersView = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.user != null) {
      chatProvider.loadUsers(currentUserId: authProvider.user!.uid);
      chatProvider.loadChatRooms(authProvider.user!.uid);
      chatProvider.updateUserStatus(authProvider.user!.uid, true);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && authProvider.user != null) {
          chatProvider.refreshUsers(currentUserId: authProvider.user!.uid);
        }
      });
    } else {
      chatProvider.loadUsers();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.user != null) {
      if (state == AppLifecycleState.resumed) {
        chatProvider.updateUserStatus(authProvider.user!.uid, true);
        chatProvider.refreshUsers(currentUserId: authProvider.user!.uid);
        chatProvider.loadChatRooms(authProvider.user!.uid);
      } else {
        chatProvider.updateUserStatus(authProvider.user!.uid, false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _openChatScreen(UserModel peerUser) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.user != null) {
      chatProvider
          .createAndLoadChatRoom(authProvider.user!.uid, peerUser.uid)
          .then((_) {
            if (mounted) {
              // Added mounted check
              Navigator.push(
                context,
                PageRoutes.slideRoute(const ChatScreen()),
              );
            }
          });
    }
  }

  void _signOut() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      if (authProvider.user != null) {
        await chatProvider.updateUserStatus(authProvider.user!.uid, false);
      }
      chatProvider.clearSelectedUser();
      await authProvider.signOut();
    } catch (e) {
      if (mounted) {
        // Added mounted check
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
      }
    }
  }

  void _showErrorDialog(String errorMessage) {
    if (mounted) {
      // Added mounted check
      FirestoreUtils.handleFirestoreError(context, errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    if (chatProvider.error.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog(chatProvider.error);
        chatProvider.clearError();
      });
    }

    List<UserModel> filteredUsers =
        chatProvider.users
            .where((user) => user.uid != authProvider.user?.uid)
            .toList();
    filteredUsers.sort((a, b) => a.displayName.compareTo(b.displayName));

    return Scaffold(
      appBar: AppBar(
        title: const Text('SimpleChat'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final userModel = authProvider.userModel;
              final firebaseUser = authProvider.user;
              ImageProvider? profileImageProvider;
              String initial = '?'; // Default initial

              // Check for profile picture URL
              if (userModel?.photoUrl?.isNotEmpty ?? false) {
                profileImageProvider = NetworkImage(userModel!.photoUrl!);
              }
              // Else, check for display name initial
              else if (userModel?.displayName?.isNotEmpty ?? false) {
                initial = userModel!.displayName![0].toUpperCase();
              }
              // Else, check for email initial
              else if (firebaseUser?.email?.isNotEmpty ?? false) {
                initial = firebaseUser!.email![0].toUpperCase();
              }

              return IconButton(
                icon: CircleAvatar(
                  radius: 18,
                  backgroundImage: profileImageProvider,
                  backgroundColor:
                      profileImageProvider == null
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.transparent,
                  child:
                      profileImageProvider == null
                          ? Text(
                            initial,
                            style: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : null,
                ),
                tooltip: 'Profile',
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRoutes.slideRoute(const ProfileScreen()),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
          IconButton(icon: const Icon(Icons.exit_to_app), onPressed: _signOut),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isUsersView = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      decoration: BoxDecoration(
                        color:
                            _isUsersView
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12.0),
                          bottomLeft: Radius.circular(12.0),
                        ),
                      ),
                      child: Text(
                        'Users',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              _isUsersView
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isUsersView = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      decoration: BoxDecoration(
                        color:
                            !_isUsersView
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12.0),
                          bottomRight: Radius.circular(12.0),
                        ),
                      ),
                      child: Text(
                        'Chats',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              !_isUsersView
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _isUsersView
                    ? _buildUsersList(filteredUsers)
                    : _buildChatsList(authProvider, chatProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<UserModel> users) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    Future<void> handleRefresh() async {
      if (authProvider.user != null) {
        await chatProvider.refreshUsers(currentUserId: authProvider.user!.uid);
      } else {
        await chatProvider.refreshUsers();
      }
    }

    Widget content;
    if (users.isEmpty) {
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text('No users found', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text(
                    'Pull down to refresh',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      content = ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: users.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final user = users[index];
          return UserTile(
            user: user,
            isUserList: true,
            onTap: () => _openChatScreen(user),
          );
        },
      );
    }

    return Stack(
      children: [
        RefreshIndicator(onRefresh: handleRefresh, child: content),
        if (chatProvider.isLoading)
          Container(
            color: Colors.black.withOpacity(0.1),
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChatsList(AuthProvider authProvider, ChatProvider chatProvider) {
    Future<void> handleRefresh() async {
      if (authProvider.user != null) {
        chatProvider.loadChatRooms(authProvider.user!.uid);
        await chatProvider.refreshUsers(currentUserId: authProvider.user!.uid);
      }
    }

    Widget content;
    if (chatProvider.chatRooms.isEmpty) {
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_outlined,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text('No chats yet', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text(
                    'Start a conversation with a user',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      content = ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: chatProvider.chatRooms.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final chatRoom = chatProvider.chatRooms[index];
          final peerUser = chatProvider.getPeerUser(
            chatRoom.id,
            authProvider.user!.uid,
          );

          if (peerUser == null) {
            return const SizedBox.shrink();
          }

          return UserTile(
            user: peerUser,
            chatRoom: chatRoom,
            isUserList: false,
            onTap: () => _openChatScreen(peerUser),
          );
        },
      );
    }

    return Stack(
      children: [
        RefreshIndicator(onRefresh: handleRefresh, child: content),
        if (chatProvider.isLoading)
          Container(
            color: Colors.black.withOpacity(0.1),
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}
