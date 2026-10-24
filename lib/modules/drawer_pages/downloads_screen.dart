import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/download_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_drawer.dart';
import '../../core/widgets/app_back_button.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final _manager = DownloadManager.instance;

  @override
  void initState() {
    super.initState();
    _manager.load();
  }

  String _size(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  Future<void> _delete(DownloadEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete download?'),
        content: Text(
          'Delete ${entry.fileName} from the device? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await _manager.delete(entry);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted ? 'Downloaded file deleted.' : 'File could not be deleted.',
        ),
        backgroundColor: deleted ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _open(DownloadEntry entry) async {
    final opened = await _manager.open(entry);
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No compatible app was found to open this file.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? AppTheme.darkBackground : const Color(0xFFF8FAFC),
      drawer: const CustomDrawer(),
      appBar: AppBar(
        leading: const AppNavLeading(),
        leadingWidth: AppNavigation.backAndMenuLeadingWidth,
        title: const Text('View Downloads')),
      body: AnimatedBuilder(
        animation: _manager,
        builder: (context, _) {
          final entries = _manager.entries;
          if (entries.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.download_done_outlined,
                    size: 56,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text('No downloaded files yet.'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final downloading = entry.state == DownloadState.downloading;
              final failed = entry.state == DownloadState.failed;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: failed
                                ? Colors.red.withValues(alpha: .12)
                                : const Color(
                                    0xFF0D6EFD,
                                  ).withValues(alpha: .12),
                            child: Icon(
                              failed
                                  ? Icons.error_outline
                                  : Icons.insert_drive_file_outlined,
                              color: failed
                                  ? Colors.red
                                  : const Color(0xFF0D6EFD),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.fileName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${_size(entry.byteCount)} • ${DateFormat('dd MMM yyyy, hh:mm a').format(entry.createdAt)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (!downloading)
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'open') _open(entry);
                                if (value == 'delete') _delete(entry);
                              },
                              itemBuilder: (_) => [
                                if (!failed)
                                  const PopupMenuItem(
                                    value: 'open',
                                    child: ListTile(
                                      leading: Icon(Icons.open_in_new),
                                      title: Text('Open File'),
                                    ),
                                  ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    title: Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (downloading)
                        LinearProgressIndicator(value: entry.progress)
                      else if (failed) ...[
                        Text(
                          entry.error ?? 'Download failed.',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () => _delete(entry),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          label: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Saved to',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 2),
                        SelectableText(
                          entry.displayLocation,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _open(entry),
                              icon: const Icon(Icons.open_in_new, size: 18),
                              label: const Text('Open File'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _delete(entry),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              label: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
