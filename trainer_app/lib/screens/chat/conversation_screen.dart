import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import '../../providers/chat_provider.dart';

class ConversationScreen extends StatefulWidget {
  final String chatId;

  const ConversationScreen({super.key, required this.chatId});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late TrainerChatProvider _chatProvider;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _typingTimer;

  static const String _trainerId = 'trainer_001';
  static const String _memberId = 'member_001';

  static const _quickReplies = [
    'On it! 💪',
    "Let's schedule for tomorrow",
    'Check your plan 📋',
  ];

  @override
  void initState() {
    super.initState();
    _chatProvider = TrainerChatProvider(
      chatService: context.read<ChatService>(),
      chatId: widget.chatId,
      trainerId: _trainerId,
      memberId: _memberId,
    );
    _msgCtrl.addListener(_onTyping);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _msgCtrl.removeListener(_onTyping);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _chatProvider.dispose();
    super.dispose();
  }

  void _onTyping() {
    _chatProvider.setTyping(_msgCtrl.text.isNotEmpty);
    _typingTimer?.cancel();
    if (_msgCtrl.text.isNotEmpty) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _chatProvider.setTyping(false);
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _msgCtrl.clear();
    await _chatProvider.sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _chatProvider,
      child: Builder(
        builder: (context) {
          final chatProvider = context.watch<TrainerChatProvider>();
          final messages = chatProvider.messages;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (messages.isNotEmpty) _scrollToBottom();
          });

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => context.pop(),
              ),
              title: Row(
                children: [
                  AppAvatar(name: 'DK', size: 32),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DK',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      if (chatProvider.memberTyping)
                        Text(
                          'typing...',
                          style: TextStyle(
                            fontSize: 11,
                            color: kTrainerPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: chatProvider.refresh,
                ),
              ],
            ),
            body: Column(
              children: [
                // Messages list
                Expanded(
                  child: chatProvider.isLoading && messages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : messages.isEmpty
                          ? const Center(
                              child: Text(
                                'No messages yet. Start the conversation!',
                                style:
                                    TextStyle(color: kTrainerNeutral500),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: chatProvider.refresh,
                              child: ListView.builder(
                                controller: _scrollCtrl,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                itemCount: messages.length,
                                itemBuilder: (ctx, i) {
                                  final msg = messages[i];
                                  final isMe =
                                      msg.senderId == _trainerId;
                                  return ChatBubble(
                                    message: msg,
                                    isMe: isMe,
                                  );
                                },
                              ),
                            ),
                ),
                // Member typing indicator
                if (chatProvider.memberTyping)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: kTrainerNeutral100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _TypingDot(delay: 0),
                            _TypingDot(delay: 200),
                            _TypingDot(delay: 400),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Quick replies
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  child: Row(
                    children: _quickReplies
                        .map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(r),
                              onPressed: () => _sendMessage(r),
                              backgroundColor:
                                  kTrainerPrimary.withOpacity(0.08),
                              labelStyle: const TextStyle(
                                color: kTrainerPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              side: BorderSide(
                                  color:
                                      kTrainerPrimary.withOpacity(0.3)),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                // Input bar
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          minLines: 1,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                                color: kTrainerNeutral300),
                            fillColor: kTrainerNeutral100,
                            filled: true,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: _sendMessage,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _sendMessage(_msgCtrl.text),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: kTrainerPrimary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    kTrainerPrimary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TypingDot extends StatelessWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: kTrainerNeutral500,
        shape: BoxShape.circle,
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .scaleXY(
          begin: 0.6,
          end: 1.0,
          delay: Duration(milliseconds: delay),
          duration: 400.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .scaleXY(
          begin: 1.0,
          end: 0.6,
          duration: 400.ms,
          curve: Curves.easeInOut,
        );
  }
}
