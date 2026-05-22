import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: kSpacing8),
        children: [
          _ChatThreadTile(
            name: 'Aarav',
            chatId: 'chat_dk_aarav',
            isOnline: true,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New chat coming soon.')),
          );
        },
        backgroundColor: kGuruPrimary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ChatThreadTile extends StatelessWidget {
  final String name;
  final String chatId;
  final bool isOnline;

  const _ChatThreadTile({
    required this.name,
    required this.chatId,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final chatService = context.read<ChatService>();

    return InkWell(
      onTap: () => context.push('/chat/$chatId'),
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: kSpacing16, vertical: kSpacing4),
        padding: const EdgeInsets.all(kSpacing16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kGuruNeutral300.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                AppAvatar(name: name, size: 48),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: kColorSuccess,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: kSpacing12),
            Expanded(
              child: StreamBuilder<MessageModel?>(
                stream: chatService.watchLastMessage(chatId),
                builder: (context, snapshot) {
                  final lastMsg = snapshot.data;
                  final preview = lastMsg?.text ??
                      'Initiate a chat with your trainer';
                  final timestamp = lastMsg?.createdAt;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (timestamp != null)
                            Text(
                              timestamp.toRelative(),
                              style: textTheme.bodySmall?.copyWith(
                                color: kGuruNeutral500,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: kSpacing4),
                      Text(
                        preview,
                        style: textTheme.bodySmall?.copyWith(
                          color: lastMsg == null
                              ? kGuruPrimary.withValues(alpha: 0.7)
                              : kGuruNeutral500,
                          fontStyle: lastMsg == null
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
