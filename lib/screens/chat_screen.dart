import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/animation_widgets.dart';
// import '../widgets/typing_indicator.dart'; // Commented out as it's not fully implemented

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  // Added WidgetsBindingObserver
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  File? _selectedImage;
  bool _isUploading = false;
  // bool _isTyping = false; // Local typing state, for future implementation
  // bool _peerIsTyping = false; // This would be driven by Firestore listener for future implementation

  ChatProvider? _chatProvider;
  String _lastShownError = '';
  ScaffoldMessengerState?
  _scaffoldMessengerState; // Added for safe ScaffoldMessenger access
  // AppLifecycleState? _lifecycleState; // To track app lifecycle, for future notification enhancements

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Register observer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatProvider = Provider.of<ChatProvider>(context, listen: false);
      _chatProvider?.addListener(_handleChatProviderError);
      _handleChatProviderError(); // Initial check

      // TODO: Implement actual typing indicator logic with Firestore in ChatProvider and listen here.
      // Example: _chatProvider?.setTypingStatus(true); // when user starts typing
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store the ScaffoldMessengerState. This is safer than calling ScaffoldMessenger.of(context)
    // repeatedly, especially in dispose or async callbacks.
    _scaffoldMessengerState = ScaffoldMessenger.of(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // setState(() {
    //   _lifecycleState = state;
    // });
    // TODO: Use this state for more robust notification logic in ChatProvider.
    // ChatProvider could expose a method to update its internal foreground status based on this.
    super.didChangeAppLifecycleState(state);
  }

  void _handleChatProviderError() {
    if (!mounted || _chatProvider == null) return;

    final error = _chatProvider!.error;
    if (error.isNotEmpty &&
        (error.contains('permission-denied') ||
            error.contains('Missing or insufficient permissions'))) {
      // Avoid showing the same error snackbar multiple times in a row
      if (error != _lastShownError) {
        _lastShownError = error;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Check mounted again before showing SnackBar
            _scaffoldMessengerState
                ?.removeCurrentSnackBar(); // Remove any existing snackbar
            _scaffoldMessengerState?.showSnackBar(
              SnackBar(
                content: Text(
                  'Permission Error: ${error.split('.').first}.',
                ), // Show a shorter version
                backgroundColor: Theme.of(context).colorScheme.error,
                action: SnackBarAction(
                  label: 'RETRY',
                  textColor: Theme.of(context).colorScheme.onError,
                  onPressed: () {
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    if (authProvider.user != null &&
                        _chatProvider!.selectedUser != null) {
                      _chatProvider!.createAndLoadChatRoom(
                        authProvider.user!.uid,
                        _chatProvider!.selectedUser!.uid,
                      );
                      _chatProvider?.clearError(); // Clear error on retry
                      _lastShownError = ''; // Reset last shown error
                    }
                  },
                ),
                duration: const Duration(
                  seconds: 10,
                ), // Keep it visible longer for user to react
              ),
            );
          }
        });
      }
    } else if (error.isEmpty) {
      _lastShownError = ''; // Reset if error is cleared
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatProvider?.removeListener(_handleChatProviderError);
    WidgetsBinding.instance.removeObserver(this); // Unregister observer
    // TODO: Update typing status to false when user leaves screen if implemented.
    // Example: _chatProvider?.setTypingStatus(false);
    _scaffoldMessengerState
        ?.removeCurrentSnackBar(); // Clean up snackbar on dispose
    super.dispose();
  }

  void _sendMessage() {
    // Allow sending if there's text OR an image selected
    if (_messageController.text.trim().isEmpty && _selectedImage == null)
      return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.user != null) {
      if (_selectedImage != null) {
        // If there is an image, call _sendMessageWithImage.
        // _sendMessageWithImage will handle sending text along with the image.
        _sendMessageWithImage();
      } else {
        // If no image, just send the text message.
        chatProvider.sendMessage(
          authProvider.user!.uid,
          _messageController.text.trim(),
        );
        _messageController.clear(); // Clear text only if only text was sent
      }
      // Common cleanup for both cases
      chatProvider.clearError();
      _lastShownError = '';

      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _scaffoldMessengerState?.showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _sendMessageWithImage() async {
    // This check is now implicitly handled by _sendMessage, but good for direct calls if any.
    if (_selectedImage == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.user != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        await chatProvider.sendMessageWithImage(
          authProvider.user!.uid,
          _messageController.text.trim(),
          _selectedImage!,
        );

        _messageController.clear();
        setState(() {
          _selectedImage = null;
          _isUploading = false;
        });
        chatProvider.clearError(); // Clear error on successful send
        _lastShownError = ''; // Reset last shown error after successful send

        // Scroll to bottom after sending message
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } catch (e) {
        setState(() {
          _isUploading = false;
        });
        _scaffoldMessengerState?.showSnackBar(
          SnackBar(content: Text('Error sending image: $e')),
        );
      }
    }
  }

  // TODO: Implement full typing indicator logic.
  // The methods below were placeholders and should be replaced with a robust solution
  // involving Firestore updates and listeners, likely managed via ChatProvider.
  // void _updateTypingStatus(bool isTyping) { ... }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    // Use safe navigation for displayName, provide default if null
    String appBarTitle = chatProvider.selectedUser?.displayName ?? 'Chat';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          // Only show info button if a user is actually selected for the chat
          if (chatProvider.selectedUser != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                // Since we checked selectedUser is not null, we can use !
                final selectedUser = chatProvider.selectedUser!;
                String profileTitle = selectedUser.displayName;
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text(profileTitle),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${selectedUser.email}'),
                            // Add more details if available
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                chatProvider.messages.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start the conversation by sending a message',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      itemCount: chatProvider.messages.length,
                      itemBuilder: (context, index) {
                        final message = chatProvider.messages[index];
                        final isMe = message.senderId == authProvider.user?.uid;

                        return FadeInAnimation(
                          delay: Duration(milliseconds: index * 30),
                          duration: const Duration(milliseconds: 300),
                          child: ChatBubble(message: message, isMe: isMe),
                        );
                      },
                    ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Column(
              children: [
                // TODO: Implement a proper TypingIndicator widget here if _peerIsTyping is true.
                // This would be driven by data from ChatProvider, which listens to Firestore.
                // Example: if (chatProvider.isPeerTyping) const TypingIndicator(),

                // Display selected image preview if available
                if (_selectedImage != null)
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    margin: const EdgeInsets.all(8.0),
                    child: Stack(
                      children: [
                        Center(
                          child: Image.file(
                            _selectedImage!,
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = null;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(3),
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.add_photo_alternate,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        _showImageOptions();
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(8.0),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        onChanged: (text) {
                          // Update typing status on text change
                          // _updateTypingStatus(text.isNotEmpty);
                        },
                      ),
                    ),
                    // Consolidated send button logic
                    if (_isUploading)
                      const CircularProgressIndicator()
                    else
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage, // Consolidated send logic
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
