import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../models/manager_diary_model.dart';
import 'job_sheet_webview_screen.dart';
import 'manager_diary_controller.dart';
import 'manager_diary_select_screen.dart';

/// Mirrors the web's Manager Diary list: sheets filled directly by
/// managers/admins themselves, outside of any job, saved here for admin
/// review. A plain Manager only sees their own entries (enforced server
/// side); Admin/Superuser see everyone's.
class ManagerDiaryListScreen extends StatefulWidget {
  const ManagerDiaryListScreen({super.key});

  @override
  State<ManagerDiaryListScreen> createState() => _ManagerDiaryListScreenState();
}

class _ManagerDiaryListScreenState extends State<ManagerDiaryListScreen> {
  final ManagerDiaryController _controller = ManagerDiaryController();

  @override
  void initState() {
    super.initState();
    _controller.fetchEntries();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openNewEntry() async {
    final refreshed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManagerDiarySelectScreen()),
    );
    if (refreshed == true) _controller.fetchEntries();
  }

  void _openEntry(ManagerDiaryEntry entry) {
    if (entry.formId == null) return;
    final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.userFormHtml(entry.formId!)}?manager_diary=1&submission_id=${entry.id}';
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JobSheetWebviewScreen(url: url, title: entry.formName)),
    ).then((_) => _controller.fetchEntries());
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.corporateBlue : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        backgroundColor: isDark ? AppTheme.corporateBlue : Colors.white,
        title: Text(
          "Manager Diary",
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F2C4A),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(IconlyLight.swap, color: isDark ? Colors.white : Colors.black87),
            onPressed: _controller.fetchEntries,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewEntry,
        backgroundColor: const Color(0xFF0D6EFD),
        icon: const Icon(IconlyLight.plus, color: Colors.white),
        label: const Text("New Entry", style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: BackgroundStripesPainter(isDark: isDark))),
          SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.isLoading && _controller.entries.isEmpty) {
                  return const ShimmerLoadingList();
                }
                if (_controller.errorMessage != null && _controller.entries.isEmpty) {
                  return Center(child: Text(_controller.errorMessage!, style: const TextStyle(color: Colors.red)));
                }
                if (_controller.entries.isEmpty) {
                  return const Center(child: Text("No Manager Diary entries yet.", style: TextStyle(color: Colors.grey)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
                  itemCount: _controller.entries.length,
                  itemBuilder: (context, index) => _buildEntryCard(_controller.entries[index], isDark),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(ManagerDiaryEntry entry, bool isDark) {
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final statusColor = _statusColor(entry.status);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openEntry(entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(entry.formName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    entry.status.isNotEmpty ? entry.status[0].toUpperCase() + entry.status.substring(1) : '-',
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Filled by ${entry.operativeName}', style: TextStyle(fontSize: 13, color: textSecondary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(IconlyLight.document, size: 14, color: textSecondary),
                const SizedBox(width: 4),
                Text('${entry.completedFields}/${entry.fieldCount} fields', style: TextStyle(fontSize: 12, color: textSecondary)),
                const SizedBox(width: 16),
                Icon(IconlyLight.paper_upload, size: 14, color: textSecondary),
                const SizedBox(width: 4),
                Text('${entry.fileCount} files', style: TextStyle(fontSize: 12, color: textSecondary)),
                const Spacer(),
                if (entry.submittedAt != null)
                  Text(entry.submittedAt!.split('T').first, style: TextStyle(fontSize: 12, color: textSecondary)),
              ],
            ),
            if (entry.canEditAndResubmit) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Tap to edit & resubmit",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0D6EFD)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
