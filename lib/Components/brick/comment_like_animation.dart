import 'package:flutter/material.dart';

class CommentLikeAnimation extends StatefulWidget {
  final bool isLiked; // Whether the comment is currently liked
  final VoidCallback onTap; // Action when like is toggled
  final double size; // Icon size (default 20)

  const CommentLikeAnimation({
    super.key,
    required this.isLiked,
    required this.onTap,
    this.size = 20,
  });

  @override
  State<CommentLikeAnimation> createState() => _CommentLikeAnimationState();
}

class _CommentLikeAnimationState extends State<CommentLikeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // Scale bounce
    _scale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 70,
      ),
    ]).animate(_controller);

    // Shake rotation (slight left/right tilt)
    _rotation = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.05), // rotate right
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.05, end: -0.05), // rotate left
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -0.05, end: 0.0), // back to center
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(CommentLikeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Play forward on like, reverse on dislike
    if (oldWidget.isLiked != widget.isLiked) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Transform.rotate(
              angle: _rotation.value,
              child: Icon(
                widget.isLiked ? Icons.favorite : Icons.favorite_border,
                size: widget.size,
                color: widget.isLiked
                    ? Colors.red
                    : color.onSurfaceVariant,
              ),
            ),
          );
        },
      ),
    );
  }
}
