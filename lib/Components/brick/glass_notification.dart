import 'dart:ui';
import 'package:flutter/material.dart';

/// GlassNotificationToast
/// A reusable glassmorphic notification widget
class GlassNotificationToast extends StatelessWidget {
  final String message; // Message text
  final IconData? icon; // Optional icon
  final Color? iconColor;

  const GlassNotificationToast({
    super.key,
    required this.message,
    this.icon,
    this.iconColor, required bool isDark, required void Function() onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: color.surface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: iconColor ?? color.primary),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
