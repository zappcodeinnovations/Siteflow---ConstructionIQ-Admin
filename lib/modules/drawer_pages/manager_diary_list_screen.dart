import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';
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
    final bgColor = isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
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
            icon: Icon(Icons.refresh, color: isDark ? Colors.white : Colors.black87),
            onPressed: _controller.fetchEntries,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewEntry,
        backgroundColor: const Color(0xFF0D6EFD),
        icon: const Icon(IconlyLight.plus, color: Colors.white),
        label: const Text("Fill the Sheet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: BackgroundStripesPainter(isDark: isDark))),
          SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.isLoading && _controller.entries.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (_controller.errorMessage != null && _controller.entries.isEmpty) {
                  return Center(child: Text(_controller.errorMessage!, style: const TextStyle(color: Colors.red)));
                }

                final count = _controller.entries.length;
                final paginationText = count > 0 ? "1 - $count of $count" : "0 of 0";

                return ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
                  children: [
                    _buildHeaderInfo(isDark, paginationText),
                    const SizedBox(height: 16),
                    if (_controller.entries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 48.0),
                        child: Center(
                          child: Text("No Manager Diary entries yet.", style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    else
                      ..._controller.entries.map((entry) => _buildEntryCard(entry, isDark)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(bool isDark, String paginationText) {
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              "Sheets filled directly by managers/admins, outside of any job. Saved here for admin review.",
              style: TextStyle(fontSize: 12, color: textSecondary, height: 1.3),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
            ),
            child: Text(
              paginationText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateUk(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dateOnly = dateStr.split('T').first;
      final parts = dateOnly.split('-');
      if (parts.length == 3 && parts[0].length == 4) {
        return '${parts[2].padLeft(2, '0')}/${parts[1].padLeft(2, '0')}/${parts[0]}';
      }
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        final day = parsed.day.toString().padLeft(2, '0');
        final month = parsed.month.toString().padLeft(2, '0');
        final year = parsed.year.toString();
        return '$day/$month/$year';
      }
    } catch (_) {}
    return dateStr;
  }

  Widget _buildEntryCard(ManagerDiaryEntry entry, bool isDark) {
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 4))],
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
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
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
                if (entry.submittedAt != null && entry.submittedAt!.isNotEmpty)
                  Text(
                    _formatDateUk(entry.submittedAt!),
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
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
