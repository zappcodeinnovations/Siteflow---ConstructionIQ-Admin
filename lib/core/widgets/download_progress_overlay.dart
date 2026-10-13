import 'package:flutter/material.dart';

import '../services/download_manager.dart';

class DownloadProgressOverlay extends StatelessWidget {
  final VoidCallback onViewDownloads;

  const DownloadProgressOverlay({super.key, required this.onViewDownloads});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: DownloadManager.instance,
    builder: (context, _) {
      final entry = DownloadManager.instance.latestVisible;
      if (entry == null) return const SizedBox.shrink();
      final done = entry.state == DownloadState.completed;
      final failed = entry.state == DownloadState.failed;
      final colors = Theme.of(context).colorScheme;

      return Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(12),
            color: colors.surface,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        failed
                            ? Icons.error_outline
                            : done
                            ? Icons.download_done
                            : Icons.downloading,
                        color: failed
                            ? colors.error
                            : done
                            ? Colors.green
                            : colors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              failed
                                  ? 'Download failed'
                                  : done
                                  ? 'Download complete'
                                  : 'Downloading...',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              entry.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (done)
                              Text(
                                'Saved to ${entry.displayLocation}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      if (done)
                        TextButton(
                          onPressed: onViewDownloads,
                          child: const Text('View'),
                        ),
                    ],
                  ),
                  if (!done && !failed) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: entry.progress),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
