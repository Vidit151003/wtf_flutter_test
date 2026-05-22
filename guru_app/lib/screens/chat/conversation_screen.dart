import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class ConversationScreen extends StatefulWidget {
  final String chatId;

  const ConversationScreen({super.key, required this.chatId});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  static const List<String> _quickReplies = [
    'Got it 👍',
    'Can we talk at 6?',
    'Share plan?',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().setActiveChat(widget.chatId);
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _textController.clear();
    setState(() => _isSending = true);

    final chatProvider = context.read<ChatProvider>();
    await chatProvider.sendMessage(trimmed);

    if (mounted) {
      setState(() => _isSending = false);
      if (chatProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(chatProvider.errorMessage!)),
        );
        chatProvider.clearError();
      }
      _scrollToBottom();
    }
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      context.read<ChatProvider>().setActiveChat(widget.chatId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final authProvider = context.watch<AuthProvider>();
    final messages = chatProvider.messages;
    final currentUser = authProvider.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    // Scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppAvatar(name: 'Aarav', size: 32),
            const SizedBox(width: kSpacing8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Aarav',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: kColorSuccess,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 11,
                        color: kGuruNeutral500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(
                    vertical: kSpacing8),
                itemCount: messages.length + (chatProvider.isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (chatProvider.isTyping && index == 0) {
                    return const _TypingIndicator();
                  }
                  final msgIndex = chatProvider.isTyping ? index - 1 : index;
                  final msg = messages[messages.length - 1 - msgIndex];
                  final isMe = msg.senderId == currentUser?.id;
                  return ChatBubble(
                    message: msg,
                    isMe: isMe,
                    roleColor: isMe ? kGuruPrimary : null,
                  );
                },
              ),
            ),
          ),

          // Quick replies
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: kSpacing12),
              itemCount: _quickReplies.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: kSpacing8),
              itemBuilder: (_, i) => ActionChip(
                label: Text(_quickReplies[i]),
                onPressed: () => _send(_quickReplies[i]),
                backgroundColor: kGuruSurface,
                labelStyle: const TextStyle(
                    fontSize: 13, color: kGuruPrimary),
                side: const BorderSide(color: kGuruPrimary),
              ),
            ),
          ),
          const SizedBox(height: kSpacing8),

          // Input bar
          Container(
            padding: EdgeInsets.only(
              left: kSpacing12,
              right: kSpacing8,
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom +
                  kSpacing8,
              top: kSpacing8,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                  top: BorderSide(
                      color: kGuruNeutral300.withValues(alpha: 0.5))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLines: 4,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: kGuruNeutral100,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: _send,
                  ),
                ),
                const SizedBox(width: kSpacing8),
                _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: kGuruPrimary,
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: () => _send(_textController.text),
                        icon: const Icon(Icons.send_rounded),
                        color: kGuruPrimary,
                        style: IconButton.styleFrom(
                          backgroundColor: kGuruPrimary,
                          foregroundColor: Colors.white,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppAvatar(name: 'Aarav', size: 24),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: kGuruNeutral100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) {
                      final delay = i * 0.2;
                      final t = ((_controller.value - delay) % 1.0)
                          .clamp(0.0, 1.0);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: kGuruNeutral500
                              .withValues(alpha: 0.3 + t * 0.7),
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
