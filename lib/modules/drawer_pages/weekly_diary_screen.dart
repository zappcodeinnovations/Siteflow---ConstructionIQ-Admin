import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../models/job_sheet_model.dart';
import '../../models/weekly_diary_model.dart';
import 'job_sheet_details_screen.dart';
import 'weekly_diary_controller.dart';

class WeeklyDiaryScreen extends StatefulWidget {
  const WeeklyDiaryScreen({super.key});

  @override
  State<WeeklyDiaryScreen> createState() => _WeeklyDiaryScreenState();
}

class _WeeklyDiaryScreenState extends State<WeeklyDiaryScreen> {
  final WeeklyDiaryController _controller = WeeklyDiaryController();
  bool _openingDetail = false;

  @override
  void initState() {
    super.initState();
    _controller.fetchWeek();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openDay(WeeklyDiaryDay day) async {
    if (day.submissionId == null || _openingDetail) return;
    setState(() => _openingDetail = true);
    try {
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.jobSheets}user_form/${day.submissionId}/';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true && mounted) {
        final sheet = JobSheet.fromJson(decoded['data']);
        Navigator.push(context, MaterialPageRoute(builder: (_) => JobSheetDetailsScreen(jobSheet: sheet)));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded['message'] ?? 'Could not open this entry.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _openingDetail = false);
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
          "Weekly Diary",
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F2C4A),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: BackgroundStripesPainter(isDark: isDark))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final data = _controller.data;
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.corporateBlue : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(IconlyLight.arrow_left_2, color: isDark ? Colors.white : Colors.black87),
                              onPressed: _controller.isLoading ? null : _controller.goToPreviousWeek,
                            ),
                            Text(
                              data == null ? '' : '${data.weekStart}  →  ${data.weekEnd}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            IconButton(
                              icon: Icon(IconlyLight.arrow_right_2, color: isDark ? Colors.white : Colors.black87),
                              onPressed: _controller.isLoading ? null : _controller.goToNextWeek,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        if (_controller.isLoading && _controller.data == null) {
                          return const ShimmerLoadingList();
                        }
                        if (_controller.errorMessage != null && _controller.data == null) {
                          return Center(child: Text(_controller.errorMessage!, style: const TextStyle(color: Colors.red)));
                        }
                        final rows = _controller.data?.rows ?? [];
                        if (rows.isEmpty) {
                          return const Center(child: Text("No Daily Diary entries this week.", style: TextStyle(color: Colors.grey)));
                        }
                        return ListView.builder(
                          itemCount: rows.length,
                          itemBuilder: (context, index) => _buildRowCard(context, rows[index], isDark),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowCard(BuildContext context, WeeklyDiaryRow row, bool isDark) {
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final isComplete = row.status == 'complete';

    return Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.operative, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 2),
                    Text('${row.project} · ${row.client}', style: TextStyle(fontSize: 13, color: textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isComplete ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  row.statusLabel,
                  style: TextStyle(color: isComplete ? Colors.green : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: row.days.map((day) => Expanded(child: _buildDayPill(day, isDark))).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            '${row.submittedCount}/5 submitted · ${row.approvedCount} approved',
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDayPill(WeeklyDiaryDay day, bool isDark) {
    final filled = day.isFilled;
    final approved = day.status == 'approved';
    final bg = !filled
        ? (isDark ? Colors.white10 : Colors.grey.shade100)
        : approved
            ? Colors.green.shade50
            : Colors.amber.shade50;
    final fg = !filled
        ? (isDark ? Colors.white38 : Colors.grey.shade400)
        : approved
            ? Colors.green.shade700
            : Colors.amber.shade800;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: filled ? () => _openDay(day) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: [
              Text(day.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
              const SizedBox(height: 4),
              Icon(
                filled ? (approved ? Icons.check_circle : Icons.access_time_filled) : Icons.remove_circle_outline,
                size: 16,
                color: fg,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
