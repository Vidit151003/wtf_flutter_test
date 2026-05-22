import 'package:flutter/material.dart';

import '../models/message_model.dart';
import '../utils/extensions.dart';

/// Animated chat bubble with slide-in animation, status ticks, and timestamp.
class ChatBubble extends StatefulWidget {
  /// True when the message belongs to the current user.
  final bool isMe;

  /// The message to render.
  final MessageModel message;

  /// Optional role-based accent color for the bubble border.
  final Color? roleColor;

  const ChatBubble({
    super.key,
    required this.isMe,
    required this.message,
    this.roleColor,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(widget.isMe ? 0.3 : -0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMe = widget.isMe;
    final msg = widget.message;

    final bubbleColor = isMe
        ? (widget.roleColor ?? colorScheme.primary)
        : colorScheme.surfaceContainerHighest;

    final textColor = isMe ? colorScheme.onPrimary : colorScheme.onSurface;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
      bottomRight:
          isMe ? const Radius.circular(4) : const Radius.circular(18),
    );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(
              left: isMe ? 64 : 12,
              right: isMe ? 12 : 64,
              top: 4,
              bottom: 4,
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: borderRadius,
              border: isMe
                  ? null
                  : Border.all(
                      color:
                          (widget.roleColor ?? colorScheme.outline)
                              .withValues(alpha: 0.4),
                    ),
            ),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg.text,
                  style: TextStyle(
                    fontSize: 15,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg.createdAt.toSlotLabel(),
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor.withValues(alpha: 0.65),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      _StatusIcon(
                          status: msg.status, color: textColor),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Status icon ─────────────────────────────────────────────────────────────

class _StatusIcon extends StatefulWidget {
  final MessageStatus status;
  final Color color;

  const _StatusIcon({required this.status, required this.color});

  @override
  State<_StatusIcon> createState() => _StatusIconState();
}

class _StatusIconState extends State<_StatusIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.status == MessageStatus.sending) {
      _spin.repeat();
    }
  }

  @override
  void didUpdateWidget(_StatusIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == MessageStatus.sending) {
      _spin.repeat();
    } else {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color.withValues(alpha: 0.75);
    switch (widget.status) {
      case MessageStatus.sending:
        return RotationTransition(
          turns: _spin,
          child: Icon(Icons.sync, size: 12, color: color),
        );
      case MessageStatus.sent:
        return Icon(Icons.done, size: 12, color: color);
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 12, color: color);
    }
  }
}
