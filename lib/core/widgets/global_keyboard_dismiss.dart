import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// A centralized, production-grade keyboard dismissal wrapper that provides:
/// 1. Tap-outside to dismiss keyboard (without disturbing active field interactions, cursor positioning, or text selection).
/// 2. Scroll-to-dismiss keyboard on scrollable screens (while preserving internal scrolling inside multiline text areas).
/// 3. Native iOS keyboard accessory toolbar with a "Done" / hide action docked directly above the keyboard.
/// 4. Zero impact on Android behavior, text selection, copy/paste, form validation, or button clicks.
class GlobalKeyboardDismiss extends StatefulWidget {
  final Widget child;

  const GlobalKeyboardDismiss({
    super.key,
    required this.child,
  });

  @override
  State<GlobalKeyboardDismiss> createState() => _GlobalKeyboardDismissState();
}

class _GlobalKeyboardDismissState extends State<GlobalKeyboardDismiss> {
  static const double _kIosToolbarHeight = 42.0;

  Offset? _pointerDownPos;
  DateTime? _pointerDownTime;
  bool _pointerDownInsideFocused = false;

  /// Checks whether a global touch coordinate lies inside the currently focused
  /// input field (including its decoration, prefix/suffix icons, and borders).
  bool _isTouchInsideFocused(Offset globalPosition) {
    final currentFocus = FocusManager.instance.primaryFocus;
    if (currentFocus == null || !currentFocus.hasFocus) {
      return false;
    }

    final focusContext = currentFocus.context;
    if (focusContext == null || !focusContext.mounted) {
      return false;
    }

    final renderObject = focusContext.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize && renderObject.attached) {
      try {
        final local = renderObject.globalToLocal(globalPosition);
        final size = renderObject.size;
        final rect = Rect.fromLTWH(0, 0, size.width, size.height).inflate(4.0);
        if (rect.contains(local)) {
          return true;
        }
      } catch (_) {}

      // Check immediate ancestor RenderBoxes (e.g. InputDecoration container, prefix/suffix icons)
      RenderObject? parentBox = renderObject.parent;
      int depth = 0;
      while (parentBox != null && depth < 4) {
        if (parentBox is RenderBox && parentBox.hasSize && parentBox.attached) {
          try {
            final local = parentBox.globalToLocal(globalPosition);
            final rect = Rect.fromLTWH(0, 0, parentBox.size.width, parentBox.size.height).inflate(4.0);
            if (rect.contains(local)) {
              return true;
            }
          } catch (_) {}
        }
        parentBox = parentBox.parent;
        depth++;
      }
    }

    return false;
  }

  /// Checks whether a scroll notification originated from within the focused
  /// multiline text field itself so we don't dismiss the keyboard while the user
  /// is scrolling through their own typed comment/description.
  bool _isScrollInsideFocusedField(ScrollNotification notification) {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    final scrollContext = notification.context;
    if (focusContext == null || scrollContext == null) {
      return false;
    }

    try {
      final focusedRenderObject = focusContext.findRenderObject();
      final scrollRenderObject = scrollContext.findRenderObject();
      if (focusedRenderObject != null && scrollRenderObject != null) {
        RenderObject? current = scrollRenderObject;
        while (current != null) {
          if (current == focusedRenderObject) {
            return true;
          }
          current = current.parent;
        }
      }
    } catch (_) {}

    return false;
  }

  void _unfocus() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus != null && focus.hasFocus) {
      focus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final originalInsets = MediaQuery.viewInsetsOf(context);
    final keyboardHeight = originalInsets.bottom;
    final isIos = Theme.of(context).platform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final showIosToolbar = isIos && keyboardHeight > 0;
    final toolbarHeight = showIosToolbar ? _kIosToolbarHeight : 0.0;

    // Adjust bottom inset passed to child so scrollables and Scaffolds
    // automatically position themselves above the accessory toolbar.
    final adjustedMediaQuery = showIosToolbar
        ? MediaQuery.of(context).copyWith(
            viewInsets: originalInsets.copyWith(
              bottom: keyboardHeight + toolbarHeight,
            ),
          )
        : null;

    final childWithMediaQuery = adjustedMediaQuery != null
        ? MediaQuery(data: adjustedMediaQuery, child: widget.child)
        : widget.child;

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        // Dismiss keyboard on user-initiated scroll, UNLESS scrolling inside focused multiline field
        if ((notification is UserScrollNotification && notification.direction != ScrollDirection.idle) ||
            (notification is ScrollUpdateNotification && notification.dragDetails != null)) {
          if (!_isScrollInsideFocusedField(notification)) {
            _unfocus();
          }
        }
        return false; // Allow notification to continue bubbling
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (PointerDownEvent event) {
          _pointerDownPos = event.position;
          _pointerDownTime = DateTime.now();
          _pointerDownInsideFocused = _isTouchInsideFocused(event.position);
        },
        onPointerUp: (PointerUpEvent event) {
          final downPos = _pointerDownPos;
          final downTime = _pointerDownTime;
          _pointerDownPos = null;
          _pointerDownTime = null;

          if (downPos == null || downTime == null) return;

          // If the tap started inside the active input, do not dismiss
          if (_pointerDownInsideFocused) return;

          final distance = (event.position - downPos).distance;
          final duration = DateTime.now().difference(downTime);

          // Only treat as a tap if pointer didn't move significantly and wasn't a long-press
          if (distance < 12.0 && duration < const Duration(milliseconds: 600)) {
            // If iOS toolbar is visible, check if tap was inside the toolbar bounds
            if (showIosToolbar) {
              final screenSize = MediaQuery.sizeOf(context);
              final toolbarRect = Rect.fromLTWH(
                0,
                screenSize.height - keyboardHeight - _kIosToolbarHeight,
                screenSize.width,
                _kIosToolbarHeight,
              );
              if (toolbarRect.contains(event.position)) {
                return; // Let the toolbar buttons handle it
              }
            }

            _unfocus();
          }
        },
        child: Stack(
          children: [
            childWithMediaQuery,
            if (showIosToolbar)
              Positioned(
                left: 0,
                right: 0,
                bottom: keyboardHeight,
                height: _kIosToolbarHeight,
                child: _IosKeyboardToolbar(
                  onDone: _unfocus,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IosKeyboardToolbar extends StatelessWidget {
  final VoidCallback onDone;

  const _IosKeyboardToolbar({
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF6F6F6);
    final borderColor = isDark ? const Color(0xFF38383A) : const Color(0xFFD1D5DB);
    final actionColor = isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    final iconColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280);

    return Material(
      color: backgroundColor,
      child: Container(
        height: 42.0,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: borderColor, width: 0.5),
            bottom: BorderSide(color: borderColor, width: 0.5),
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left dismiss/hide keyboard icon
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onDone();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  child: Icon(
                    Icons.keyboard_hide_rounded,
                    size: 20,
                    color: iconColor,
                  ),
                ),
              ),
              // Right "Done" button (native iOS style)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onDone();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: actionColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
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
