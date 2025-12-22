import 'package:flutter/material.dart';

/// Utilities for UI feedback and interactions.

/// Shows a custom, professional toast notification rooted in the application Overlay.
/// 
/// This toast appears at the bottom of the screen with a smooth fade/scale animation,
/// resembling modern system notifications (like screenshot alerts).
/// 
/// [message]: The text to display.
void showToast(BuildContext context, String message) {
  late OverlayEntry overlayEntry;
  
  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: 100, // Positioned at the bottom for better reachability and visibility
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 200),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[800], // Dark grey for a neutral, premium look
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 14, 
                  fontWeight: FontWeight.w500
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  // Insert above current view
  Overlay.of(context).insert(overlayEntry);
  
  // Auto-remove after 2 seconds
  Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());
}
