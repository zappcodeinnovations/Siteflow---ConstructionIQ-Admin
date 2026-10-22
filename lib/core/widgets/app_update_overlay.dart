import 'package:flutter/material.dart';

import '../services/app_update_service.dart';

/// Drawn above the Navigator (MaterialApp.builder) so route changes (splash
/// redirect, logout) can never remove a mandatory update popup.
class AppUpdateOverlay extends StatelessWidget {
  const AppUpdateOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppUpdatePrompt?>(
      valueListenable: AppUpdateService.prompt,
      builder: (context, prompt, _) {
        if (prompt == null) return const SizedBox.shrink();
        return Positioned.fill(
          child: AppUpdateDialog(
            mandatory: prompt.mandatory,
            message: prompt.config.updateMessage,
            onUpdate: AppUpdateService.openStore,
            onLater: AppUpdateService.dismissOptional,
          ),
        );
      },
    );
  }
}

class AppUpdateDialog extends StatefulWidget {
  const AppUpdateDialog({
    super.key,
    required this.mandatory,
    required this.message,
    required this.onUpdate,
    required this.onLater,
  });

  final bool mandatory;
  final String message;
  final Future<bool> Function() onUpdate;
  final VoidCallback onLater;

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _opening = false;
  bool _openFailed = false;

  @override
  void initState() {
    super.initState();
    // Keep keystrokes from reaching a text field hidden behind the popup.
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _handleUpdate() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _openFailed = false;
    });
    final opened = await widget.onUpdate();
    if (!mounted) return;
    setState(() {
      _opening = false;
      _openFailed = !opened;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Stack(
      children: [
        ModalBarrier(
          dismissible: !widget.mandatory,
          onDismiss: widget.mandatory ? null : widget.onLater,
          color: Colors.black.withValues(alpha: 0.55),
        ),
        BlockSemantics(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Material(
                    color: scheme.surface,
                    elevation: 8,
                    shadowColor: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    child: Semantics(
                      scopesRoute: true,
                      namesRoute: true,
                      explicitChildNodes: true,
                      label: 'Update available',
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.system_update_rounded,
                                  color: scheme.primary,
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Update Available!',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.message,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.4,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            if (widget.mandatory) ...[
                              const SizedBox(height: 10),
                              Text(
                                'This update is required to continue using the app.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ],
                            if (_openFailed) ...[
                              const SizedBox(height: 12),
                              Text(
                                "Couldn't open the store. Please update the app "
                                'from the Play Store or App Store.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            FilledButton(
                              onPressed: _opening ? null : _handleUpdate,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _opening
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Update Now'),
                            ),
                            if (!widget.mandatory) ...[
                              const SizedBox(height: 6),
                              TextButton(
                                onPressed: widget.onLater,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                ),
                                child: const Text('Later'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
