import 'package:flutter/material.dart';

/// A shimmer-style skeleton loader showing [count] placeholder tiles.
///
/// Uses an opacity animation (0.3 → 0.8 → 0.3) repeating every 1 second
/// to simulate the shimmer effect without external packages.
class SkeletonLoader extends StatefulWidget {
  /// Number of skeleton tiles to render.
  final int count;

  const SkeletonLoader({super.key, this.count = 5});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) {
        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: widget.count,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) =>
              Opacity(opacity: _opacity.value, child: const _SkeletonTile()),
        );
      },
    );
  }
}

// ─── Single tile ─────────────────────────────────────────────────────────────

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    final baseColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar placeholder
        _SkeletonBox(width: 48, height: 48, radius: 24, color: baseColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(
                  width: double.infinity,
                  height: 14,
                  radius: 4,
                  color: baseColor),
              const SizedBox(height: 8),
              _SkeletonBox(width: 140, height: 12, radius: 4, color: baseColor),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _SkeletonBox(width: 40, height: 12, radius: 4, color: baseColor),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Color color;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
