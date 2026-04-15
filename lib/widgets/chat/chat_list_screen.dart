
// lib/screens/chat/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/test_chat_provider.dart';
import '../../providers/auth_provider.dart';
import 'chat_list_tile.dart';
import '../../core/themes/color_palette.dart';
import '../../screens/chat/chat_detail_screen.dart';
import '../../screens/chat/new_message_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final chatProvider = Provider.of<TestChatProvider>(context, listen: false);
    chatProvider.loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<TestChatProvider>(context);
    final currentUserId = authProvider.user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: ColorPalette.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewMessageScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (chatProvider.totalUnread > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: ColorPalette.primaryGreen.withOpacity(0.1),
              child: Text(
                '${chatProvider.totalUnread} unread message${chatProvider.totalUnread > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: ColorPalette.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: chatProvider.conversations.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: chatProvider.conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = chatProvider.conversations[index];
                        return ChatListTile(
                          conversation: conversation,
                          currentUserId: currentUserId,
                          onTap: () {
                            chatProvider.selectConversation(conversation.id);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailScreen(
                                  conversationId: conversation.id,
                                  conversation: conversation,
                                ),
                              ),
                            ).then((_) {
                              chatProvider.selectConversation('');
                              chatProvider.loadUnreadCounts();
                            });
                          },
                          onDelete: () => _showDeleteDialog(context, conversation.id),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewMessageScreen(),
            ),
          );
        },
        backgroundColor: ColorPalette.primaryGreen,
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with a vendor or admin',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewMessageScreen(),
                ),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('New Message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, String conversationId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Conversation'),
          content: const Text('Are you sure you want to delete this conversation?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final chatProvider = Provider.of<TestChatProvider>(context, listen: false);
                await chatProvider.deleteConversation(conversationId);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
