import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job_sheet_model.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import 'package:iconly/iconly.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';
import 'job_sheet_webview_screen.dart';

class JobSheetDetailsScreen extends StatefulWidget {
  final JobSheet jobSheet;

  const JobSheetDetailsScreen({super.key, required this.jobSheet});

  @override
  State<JobSheetDetailsScreen> createState() => _JobSheetDetailsScreenState();
}

class _JobSheetDetailsScreenState extends State<JobSheetDetailsScreen> {
  late JobSheet jobSheet;
  bool _submittingDecision = false;

  @override
  void initState() {
    super.initState();
    jobSheet = widget.jobSheet;
  }

  void _openFormBrowser(BuildContext context) {
    String path = jobSheet.viewFormInBrowserUrl.isNotEmpty
        ? jobSheet.viewFormInBrowserUrl
        : jobSheet.globalDetailApiUrl;

    String base = ApiEndpoints.baseUrl;
    if (path.startsWith('/api/') && base.endsWith('/api')) {
      base = base.substring(0, base.length - 4);
    }

    final urlStr = base + path;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobSheetWebviewScreen(
          url: urlStr,
          title: "Form: ${jobSheet.sheetNo}",
        ),
      ),
    );
  }

  Future<void> _submitDecision(String decision) async {
    String rejectionReason = '';
    if (decision == 'reject' || decision == 'request_rectification') {
      final reason = await _promptForReason(decision);
      if (reason == null) return; // cancelled
      rejectionReason = reason;
    }

    setState(() => _submittingDecision = true);
    try {
      final response = await ApiClient.patch(
        '${ApiEndpoints.baseUrl}/my-approvals/${jobSheet.id}/',
        body: {
          'decision': decision,
          if (rejectionReason.isNotEmpty) 'rejection_reason': rejectionReason,
        },
      );
      final body = jsonDecode(response.body);
      if (!mounted) return;
      if (response.statusCode == 200 && body['status'] == true) {
        final data = body['data'] ?? {};
        setState(() {
          jobSheet = JobSheet(
            id: jobSheet.id,
            source: jobSheet.source,
            sheetNo: jobSheet.sheetNo,
            status: data['status']?.toString() ?? jobSheet.status,
            statusLabel: data['status']?.toString() ?? jobSheet.statusLabel,
            jobNo: jobSheet.jobNo,
            jobReference: jobSheet.jobReference,
            projectName: jobSheet.projectName,
            clientName: jobSheet.clientName,
            operative: jobSheet.operative,
            operativeCode: jobSheet.operativeCode,
            form: jobSheet.form,
            location: jobSheet.location,
            comments: jobSheet.comments,
            materialCost: jobSheet.materialCost,
            charge: jobSheet.charge,
            globalDetailApiUrl: jobSheet.globalDetailApiUrl,
            created: jobSheet.created,
            submitted: jobSheet.submitted,
            lastUpdated: jobSheet.lastUpdated,
            formHtmlUrl: jobSheet.formHtmlUrl,
            viewFormInBrowserUrl: jobSheet.viewFormInBrowserUrl,
            rejectionReason: rejectionReason.isNotEmpty ? rejectionReason : jobSheet.rejectionReason,
            reviewedBy: jobSheet.reviewedBy,
            reviewed: jobSheet.reviewed,
            resubmissionCount: jobSheet.resubmissionCount,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(body['message']?.toString() ?? 'Submission updated.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(body['message']?.toString() ?? 'Failed to update submission.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingDecision = false);
    }
  }

  Future<String?> _promptForReason(String decision) async {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        title: Text(
          decision == 'reject' ? 'Reject Submission' : 'Request Rectification',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: const InputDecoration(
            hintText: 'Reason (required)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(context, reason);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F2C4A),
            ),
          ),
          Divider(
            height: 32,
            color: isDark ? Colors.white24 : Colors.grey.shade200,
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReviewSection(bool isDark) {
    final hasReviewInfo = jobSheet.rejectionReason.isNotEmpty ||
        jobSheet.reviewedBy.isNotEmpty ||
        jobSheet.reviewed.isNotEmpty ||
        jobSheet.resubmissionCount > 0;
    if (!hasReviewInfo && !jobSheet.isReviewable) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        const SizedBox(height: 24),
        _buildSectionCard(
          title: "Review & QA Status",
          isDark: isDark,
          children: [
            if (jobSheet.reviewedBy.isNotEmpty)
              _buildDetailRow("Reviewed By", jobSheet.reviewedBy, isDark),
            if (jobSheet.reviewed.isNotEmpty)
              _buildDetailRow("Reviewed At", jobSheet.reviewed, isDark),
            if (jobSheet.rejectionReason.isNotEmpty)
              _buildDetailRow("Rejection Reason", jobSheet.rejectionReason, isDark),
            if (jobSheet.resubmissionCount > 0)
              _buildDetailRow("Resubmissions", jobSheet.resubmissionCount.toString(), isDark),
            if (jobSheet.isReviewable) ...[
              const SizedBox(height: 8),
              Text(
                "This submission is awaiting review.",
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _submittingDecision ? null : () => _submitDecision('approve'),
                    icon: const Icon(IconlyLight.tick_square, color: Colors.white, size: 18),
                    label: const Text("Approve", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD97706),
                      side: const BorderSide(color: Color(0xFFD97706)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _submittingDecision ? null : () => _submitDecision('request_rectification'),
                    icon: const Icon(IconlyLight.edit, size: 18),
                    label: const Text("Request Rectification", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _submittingDecision ? null : () => _submitDecision('reject'),
                    icon: const Icon(IconlyLight.close_square, size: 18),
                    label: const Text("Reject", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Text(
          "Job Sheet: ${jobSheet.sheetNo}",
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F2C4A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundStripesPainter(isDark: isDark),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status and Actions Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              IconlyLight.tick_square,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              jobSheet.statusLabel.isNotEmpty
                                  ? jobSheet.statusLabel
                                  : jobSheet.status,
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (jobSheet.viewFormInBrowserUrl.isNotEmpty ||
                          jobSheet.globalDetailApiUrl.isNotEmpty)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6EFD),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _openFormBrowser(context),
                          icon: const Icon(
                            IconlyLight.document,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            "View Form",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Main Details Row / Column depending on screen size
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildSectionCard(
                              title: "Core Information",
                              isDark: isDark,
                              children: [
                                _buildDetailRow(
                                  "Project",
                                  jobSheet.projectName,
                                  isDark,
                                ),
                                _buildDetailRow(
                                  "Client",
                                  jobSheet.clientName,
                                  isDark,
                                ),
                                _buildDetailRow("Job No.", jobSheet.jobNo, isDark),
                                _buildDetailRow(
                                  "Job Reference",
                                  jobSheet.jobReference,
                                  isDark,
                                ),
                                _buildDetailRow(
                                  "Operative",
                                  "${jobSheet.operative} (${jobSheet.operativeCode})",
                                  isDark,
                                ),
                                _buildDetailRow("Form Type", jobSheet.form, isDark),
                                _buildDetailRow(
                                  "Location",
                                  jobSheet.location,
                                  isDark,
                                ),
                              ],
                            ),
                            _buildReviewSection(isDark),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [
                            _buildSectionCard(
                              title: "Financials & Notes",
                              isDark: isDark,
                              children: [
                                _buildDetailRow(
                                  "Material Cost",
                                  jobSheet.materialCost.isNotEmpty
                                      ? "£${jobSheet.materialCost}"
                                      : "-",
                                  isDark,
                                ),
                                _buildDetailRow(
                                  "Charge",
                                  jobSheet.charge.isNotEmpty
                                      ? "£${jobSheet.charge}"
                                      : "-",
                                  isDark,
                                ),
                                _buildDetailRow(
                                  "Comments",
                                  jobSheet.comments,
                                  isDark,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildSectionCard(
                              title: "Timestamps",
                              isDark: isDark,
                              children: [
                                // jobSheet.created/submitted/lastUpdated are
                                // already localized to the device timezone
                                // server-side (tz=<device tz> is sent with the
                                // request) - re-running them through
                                // DateHelper here would treat an already-local
                                // string as UTC and shift it a second time.
                                _buildDetailRow(
                                  "Created",
                                  jobSheet.created,
                                  isDark,
                                ),
                                _buildDetailRow(
                                  "Submitted",
                                  jobSheet.submitted,
                                  isDark,
                                ),
                                _buildDetailRow(
                                  "Last Updated",
                                  jobSheet.lastUpdated,
                                  isDark,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildSectionCard(
                        title: "Core Information",
                        isDark: isDark,
                        children: [
                          _buildDetailRow(
                            "Project",
                            jobSheet.projectName,
                            isDark,
                          ),
                          _buildDetailRow(
                            "Client",
                            jobSheet.clientName,
                            isDark,
                          ),
                          _buildDetailRow("Job No.", jobSheet.jobNo, isDark),
                          _buildDetailRow(
                            "Job Reference",
                            jobSheet.jobReference,
                            isDark,
                          ),
                          _buildDetailRow(
                            "Operative",
                            "${jobSheet.operative} (${jobSheet.operativeCode})",
                            isDark,
                          ),
                          _buildDetailRow("Form Type", jobSheet.form, isDark),
                          _buildDetailRow(
                            "Location",
                            jobSheet.location,
                            isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        title: "Financials & Notes",
                        isDark: isDark,
                        children: [
                          _buildDetailRow(
                            "Material Cost",
                            jobSheet.materialCost.isNotEmpty
                                ? "£${jobSheet.materialCost}"
                                : "-",
                            isDark,
                          ),
                          _buildDetailRow(
                            "Charge",
                            jobSheet.charge.isNotEmpty
                                ? "£${jobSheet.charge}"
                                : "-",
                            isDark,
                          ),
                          _buildDetailRow(
                            "Comments",
                            jobSheet.comments,
                            isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        title: "Timestamps",
                        isDark: isDark,
                        children: [
                          _buildDetailRow(
                            "Created",
                            jobSheet.created,
                            isDark,
                          ),
                          _buildDetailRow(
                            "Submitted",
                            jobSheet.submitted,
                            isDark,
                          ),
                          _buildDetailRow(
                            "Last Updated",
                            jobSheet.lastUpdated,
                            isDark,
                          ),
                        ],
                      ),
                      _buildReviewSection(isDark),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
