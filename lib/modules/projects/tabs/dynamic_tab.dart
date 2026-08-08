import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';

class DynamicTab extends StatelessWidget {
  final String title;
  final List<dynamic> data;

  const DynamicTab({
    Key? key,
    required this.title,
    required this.data,
  }) : super(key: key);

  String _getTitle(dynamic item) {
    if (item is Map) {
      final possibleKeys = [
        'name',
        'title',
        'display_name',
        'label',
        'file_name',
        'location_name',
        'value',
        'text'
      ];
      for (final key in possibleKeys) {
        if (item.containsKey(key) && item[key] != null && item[key].toString().isNotEmpty) {
          return item[key].toString();
        }
      }
      // Fallback: show first string value
      final stringValues = item.values.whereType<String>().toList();
      if (stringValues.isNotEmpty) {
        return stringValues.first;
      }
    }
    return item.toString();
  }

  String? _getSubtitle(dynamic item) {
    if (item is Map) {
      final possibleKeys = [
        'description',
        'file_path',
        'path',
        'code',
        'category',
        'type'
      ];
      for (final key in possibleKeys) {
        if (item.containsKey(key) && item[key] != null && item[key].toString().isNotEmpty) {
          return item[key].toString();
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;

    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconlyLight.folder, size: 64, color: isDark ? Colors.white24 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "No $title available",
              style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = data[index];
        final titleText = _getTitle(item);
        final subtitleText = _getSubtitle(item);
        final isLink = subtitleText != null && (subtitleText.startsWith('http://') || subtitleText.startsWith('https://'));

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (subtitleText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitleText,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (isLink)
                IconButton(
                  icon: Icon(IconlyLight.show, color: isDark ? Colors.white : const Color(0xFF0D6EFD)),
                  onPressed: () {
                    try {
                      launchUrl(Uri.parse(subtitleText), mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
