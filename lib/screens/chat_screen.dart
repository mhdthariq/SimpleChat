import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/animation_widgets.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/permission_error_dialog.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  File? _selectedImage;
  bool _isUploading = false;
  bool _isTyping = false;
  bool _peerIsTyping = false; // This would normally be updated from Firestore
  bool _hasPermissionError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Check for permission issues on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForPermissionIssues();
    });
  }

  void _checkForPermissionIssues() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // Listen for error changes in the chat provider
    if (chatProvider.error.contains('permission-denied') ||
        chatProvider.error.contains('Missing or insufficient permissions')) {
      setState(() {
        _hasPermissionError = true;
        _errorMessage = chatProvider.error;
      });
      _showPermissionErrorDialog();
    }
  }

  void _showPermissionErrorDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => PermissionErrorDialog(
            errorMessage: _errorMessage,
            onRetry: () {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final chatProvider = Provider.of<ChatProvider>(
                context,
                listen: false,
              );

              if (authProvider.user != null &&
                  chatProvider.selectedUser != null) {
                // Retry loading the chat room
                chatProvider.createAndLoadChatRoom(
                  authProvider.user!.uid,
                  chatProvider.selectedUser!.uid,
                );
                setState(() {
                  _hasPermissionError = false;
                });
              }
            },
          ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.user != null) {
      chatProvider.sendMessage(
        authProvider.user!.uid,
        _messageController.text.trim(),
      );
      _messageController.clear();

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending image: $e')));
      }
    }
  }

  void _updateTypingStatus(bool isTyping) {
    if (_isTyping != isTyping) {
      setState(() {
        _isTyping = isTyping;
      });

      // Here we would normally update Firestore to indicate the user is typing
      // For now, we'll just simulate the peer typing when we're typing
      if (isTyping) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _peerIsTyping = true;
            });

            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _peerIsTyping = false;
                });
              }
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    // Check for errors in real-time
    if (chatProvider.error.contains('permission-denied') ||
        chatProvider.error.contains('Missing or insufficient permissions')) {
      if (!_hasPermissionError) {
        setState(() {
          _hasPermissionError = true;
          _errorMessage = chatProvider.error;
        });
        // Only show the dialog if we just detected the error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPermissionErrorDialog();
        });
      }
    }

    if (_hasPermissionError) {
      return Scaffold(
        appBar: AppBar(
          title: Text(chatProvider.selectedUser?.displayName ?? 'Chat'),
          actions: [
            IconButton(
              icon: const Icon(Icons.security),
              tooltip: 'Fix Permission Issues',
              onPressed: () {
                _showPermissionErrorDialog();
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Permission Error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                onPressed: () {
                  if (authProvider.user != null &&
                      chatProvider.selectedUser != null) {
                    // Retry loading the chat room
                    setState(() {
                      _hasPermissionError = false;
                    });
                    chatProvider.createAndLoadChatRoom(
                      authProvider.user!.uid,
                      chatProvider.selectedUser!.uid,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(chatProvider.selectedUser?.displayName ?? 'Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // User profile info could go here
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
                          _updateTypingStatus(text.isNotEmpty);
                        },
                      ),
                    ),
                    IconButton(
                      icon:
                          _isUploading
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Icon(
                                _selectedImage != null
                                    ? Icons.send
                                    : Icons.send,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                      onPressed:
                          _isUploading
                              ? null
                              : () {
                                if (_selectedImage != null) {
                                  _sendMessageWithImage();
                                } else {
                                  _sendMessage();
                                }
                              },
                    ),
                  ],
                ),
                // Peer typing indicator
                if (_peerIsTyping) TypingIndicator(isTyping: _peerIsTyping),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
