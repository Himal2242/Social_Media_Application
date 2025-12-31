import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassNotificationTile {
  static OverlayEntry? _notificationOverlay;
  static Timer? _timer;

  /// Call this anywhere with:
  /// `GlassNotificationTile.show(context, "Comment posted!")`
  static void show(BuildContext context, String message) {
    _remove();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use a StatefulBuilder inside OverlayEntry to handle opacity animation
    _notificationOverlay = OverlayEntry(
      builder: (context) => _GlassNotificationWidget(
        message: message,
        isDark: isDark,
        onDismissed: _remove,
      ),
    );

    Overlay.of(context)?.insert(_notificationOverlay!);
  }

  static void _remove() {
    _timer?.cancel();
    _timer = null;
    _notificationOverlay?.remove();
    _notificationOverlay = null;
  }
}

class _GlassNotificationWidget extends StatefulWidget {
  final String message;
  final bool isDark;
  final VoidCallback onDismissed;

  const _GlassNotificationWidget({
    Key? key,
    required this.message,
    required this.isDark,
    required this.onDismissed,
  }) : super(key: key);

  @override
  State<_GlassNotificationWidget> createState() => _GlassNotificationWidgetState();
}

class _GlassNotificationWidgetState extends State<_GlassNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    // Auto fade out after 2 seconds
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismissed();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + 100;

    return Positioned(
      bottom: bottomPadding,
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _opacityAnim,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: widget.isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
