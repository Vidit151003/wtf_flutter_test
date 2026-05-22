import 'package:flutter/material.dart';

import '../utils/extensions.dart';

/// Circular avatar that shows either a network image or generated initials.
///
/// Falls back to an initials badge if the image fails to load.
class AppAvatar extends StatelessWidget {
  /// Optional image URL. Falls back to initials when null or load fails.
  final String? url;

  /// Full name used to generate initials when [url] is null.
  final String name;

  /// Diameter of the avatar circle.
  final double size;

  /// Color drawn as a 2 px border around the avatar.
  final Color? borderColor;

  const AppAvatar({
    super.key,
    required this.name,
    this.url,
    this.size = 40.0,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.toInitials();
    final colorScheme = Theme.of(context).colorScheme;

    Widget avatar;

    if (url != null && url!.isNotEmpty) {
      avatar = _NetworkAvatar(
        url: url!,
        size: size,
        initials: initials,
        colorScheme: colorScheme,
      );
    } else {
      avatar = _InitialsAvatar(
        initials: initials,
        size: size,
        colorScheme: colorScheme,
      );
    }

    if (borderColor != null) {
      return Container(
        width: size + 4,
        height: size + 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor!, width: 2),
        ),
        child: avatar,
      );
    }
    return avatar;
  }
}

// ─── Network Avatar ───────────────────────────────────────────────────────────

class _NetworkAvatar extends StatefulWidget {
  final String url;
  final double size;
  final String initials;
  final ColorScheme colorScheme;

  const _NetworkAvatar({
    required this.url,
    required this.size,
    required this.initials,
    required this.colorScheme,
  });

  @override
  State<_NetworkAvatar> createState() => _NetworkAvatarState();
}

class _NetworkAvatarState extends State<_NetworkAvatar> {
  bool _error = false;

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return _InitialsAvatar(
        initials: widget.initials,
        size: widget.size,
        colorScheme: widget.colorScheme,
      );
    }

    return ClipOval(
      child: Image.network(
        widget.url,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _error = true);
          });
          return _InitialsAvatar(
            initials: widget.initials,
            size: widget.size,
            colorScheme: widget.colorScheme,
          );
        },
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Initials Avatar ─────────────────────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final ColorScheme colorScheme;

  const _InitialsAvatar({
    required this.initials,
    required this.size,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: colorScheme.onPrimaryContainer,
          height: 1.0,
        ),
      ),
    );
  }
}
