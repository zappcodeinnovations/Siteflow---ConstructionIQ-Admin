import 'dart:convert';

import 'package:flutter/material.dart';
import '../../models/job_sheet_model.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import 'package:iconly/iconly.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_helper.dart';
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
  Map<int, String> _materialNamesById = const {};

  @override
  void initState() {
    super.initState();
    jobSheet = widget.jobSheet;
    _loadDetailedJobSheet();
  }

  Future<void> _loadDetailedJobSheet() async {
    if (jobSheet.globalDetailApiUrl.isEmpty) return;
    var base = ApiEndpoints.baseUrl;
    if (jobSheet.globalDetailApiUrl.startsWith('/api/') &&
        base.endsWith('/api')) {
      base = base.substring(0, base.length - 4);
    }
    try {
      final response = await ApiClient.get(
        '$base${jobSheet.globalDetailApiUrl}',
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted ||
          response.statusCode != 200 ||
          body['status'] != true ||
          body['data'] is! Map) {
        return;
      }
      final detailed = JobSheet.fromJson(
        (body['data'] as Map).cast<String, dynamic>(),
      );
      final entries = _materialEntries(detailed);
      final unresolvedIds = entries
          .where(
            (entry) =>
                (entry['material_name']?.toString().trim().isEmpty ?? true) &&
                (entry['name']?.toString().trim().isEmpty ?? true),
          )
          .map((entry) => int.tryParse(entry['material_id']?.toString() ?? ''))
          .whereType<int>()
          .toSet();
      var resolvedNames = <int, String>{};
      if (unresolvedIds.isNotEmpty) {
        resolvedNames = await _loadMaterialNames(unresolvedIds);
      }
      if (!mounted) return;
      setState(() {
        jobSheet = detailed;
        _materialNamesById = resolvedNames;
      });
    } catch (_) {
      // The list data remains usable if a detailed payload is temporarily unavailable.
    }
  }

  List<Map<String, dynamic>> _parseMaterialEntries(dynamic value) {
    dynamic parsed = value;
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return const [];
      try {
        parsed = jsonDecode(text);
      } catch (_) {
        return const [];
      }
    }
    if (parsed is! List) return const [];
    return parsed
        .whereType<Map>()
        .map((entry) => entry.cast<String, dynamic>())
        .toList();
  }

  List<Map<String, dynamic>> _materialEntries([JobSheet? sheet]) {
    final target = sheet ?? jobSheet;
    if (target.materialsUsed.isNotEmpty) return target.materialsUsed;
    return _parseMaterialEntries(
      target.rawFields['materials_used'] ?? target.rawFields['materials'],
    );
  }

  Future<Map<int, String>> _loadMaterialNames(Set<int> ids) async {
    try {
      final response = await ApiClient.get(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.libraryMaterials}',
      );
      if (response.statusCode != 200) return const {};
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final rows = decoded['data'] as List? ?? const [];
      return {
        for (final row in rows.whereType<Map>())
          if (ids.contains(int.tryParse(row['id']?.toString() ?? '')))
            int.parse(row['id'].toString()): row['name']?.toString() ?? '',
      };
    } catch (_) {
      return const {};
    }
  }

  String _cleanQuantity(dynamic value) {
    final number = num.tryParse(value?.toString() ?? '');
    if (number == null) return value?.toString() ?? '';
    return number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toString();
  }

  String _materialsDisplay() {
    final entries = _materialEntries();
    if (entries.isEmpty) {
      return jobSheet.material.isNotEmpty ? jobSheet.material : '-';
    }
    return entries
        .map((entry) {
          final materialId = int.tryParse(
            entry['material_id']?.toString() ?? '',
          );
          final name =
              entry['material_name']?.toString().trim().isNotEmpty == true
              ? entry['material_name'].toString().trim()
              : entry['name']?.toString().trim().isNotEmpty == true
              ? entry['name'].toString().trim()
              : _materialNamesById[materialId] ??
                    (materialId == null ? 'Material' : 'Material #$materialId');
          final quantity = _cleanQuantity(entry['quantity']);
          final unit = entry['unit_label']?.toString().trim() ?? '';
          final batch = entry['batch_reference']?.toString().trim() ?? '';
          final expiry = entry['expiry_date']?.toString().trim() ?? '';
          final parts = <String>[name];
          if (quantity.isNotEmpty) {
            parts.add('$quantity ${unit.isEmpty ? 'qty' : unit}');
          }
          if (batch.isNotEmpty) parts.add('Batch: $batch');
          if (expiry.isNotEmpty) parts.add('Expiry: $expiry');
          return parts.join(' • ');
        })
        .join('\n');
  }

  String _traceabilityValue(String key, dynamic value) {
    final normalized = key.toLowerCase().replaceAll(' ', '_');
    if (normalized == 'materials_used' || normalized == 'materials') {
      return _materialsDisplay();
    }
    if (normalized == 'labour_hours') {
      final decimalHours = num.tryParse(value?.toString() ?? '');
      if (decimalHours != null) {
        final totalMinutes = (decimalHours * 60).round();
        return '${totalMinutes ~/ 60}h ${totalMinutes % 60}m '
            '(${decimalHours.toStringAsFixed(2)} h)';
      }
    }
    if (value is String &&
        (normalized.contains('started_at') ||
            normalized.contains('finished_at'))) {
      return DateHelper.formatDisplayTimestamp(value);
    }
    if (value is List) {
      return value
          .map(
            (item) => item is Map
                ? item.values
                      .where((v) => v != null && '$v'.isNotEmpty)
                      .join(' • ')
                : item.toString(),
          )
          .join(', ');
    }
    if (value is Map) {
      return value.values
          .where((v) => v != null && '$v'.isNotEmpty)
          .join(' • ');
    }
    return value?.toString().trim().isNotEmpty == true ? value.toString() : '-';
  }

  String _traceabilityLabel(String key) => key
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');

  Widget _buildTraceabilitySection(bool isDark) {
    const keys = [
      'specification',
      'work_type',
      'work_started_at',
      'work_finished_at',
      'labour_hours',
      'break_time',
      'materials_used',
    ];
    final values = <String, dynamic>{...jobSheet.rawFields};
    final materialEntries = _materialEntries();
    if (materialEntries.isNotEmpty) {
      values['materials_used'] = materialEntries;
    } else if (jobSheet.material.isNotEmpty) {
      values['materials_used'] = jobSheet.material;
    }
    final rows = keys
        .where(
          (key) => values[key] != null && values[key].toString().isNotEmpty,
        )
        .toList();
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: 24),
        _buildSectionCard(
          title: 'Traceability',
          isDark: isDark,
          children: rows
              .map(
                (key) => key == 'materials_used'
                    ? _buildMaterialsDetail(isDark)
                    : _buildDetailRow(
                        _traceabilityLabel(key),
                        _traceabilityValue(key, values[key]),
                        isDark,
                      ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildMaterialsDetail(bool isDark) {
    final lines = _materialsDisplay().split('\n');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Materials Used',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: .06)
                    : const Color(0xFFF3F7FC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                line,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
            rejectionReason: rejectionReason.isNotEmpty
                ? rejectionReason
                : jobSheet.rejectionReason,
            reviewedBy: jobSheet.reviewedBy,
            reviewed: jobSheet.reviewed,
            resubmissionCount: jobSheet.resubmissionCount,
            qaStatus: jobSheet.qaStatus,
            qaStatusLabel: jobSheet.qaStatusLabel,
            qaNotes: jobSheet.qaNotes,
            qaCheckedBy: jobSheet.qaCheckedBy,
            qaChecked: jobSheet.qaChecked,
            rawFields: jobSheet.rawFields,
            payload: jobSheet.payload,
            material: jobSheet.material,
            materialsUsed: jobSheet.materialsUsed,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message']?.toString() ?? 'Submission updated.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              body['message']?.toString() ?? 'Failed to update submission.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _submittingDecision = false);
    }
  }

  Future<void> _submitQaStatus(String qaStatus) async {
    final notes = await _promptForQaNotes(qaStatus);
    if (notes == null) return;

    setState(() => _submittingDecision = true);
    try {
      final response = await ApiClient.patch(
        '${ApiEndpoints.baseUrl}/job-sheets/${jobSheet.source}/${jobSheet.id}/qa/',
        body: {'qa_status': qaStatus, 'qa_notes': notes},
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (response.statusCode == 200 && body['status'] == true) {
        final data =
            (body['data'] as Map?)?.cast<String, dynamic>() ?? const {};
        setState(() {
          jobSheet = JobSheet(
            id: jobSheet.id,
            source: jobSheet.source,
            sheetNo: jobSheet.sheetNo,
            status: jobSheet.status,
            statusLabel: jobSheet.statusLabel,
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
            rejectionReason: jobSheet.rejectionReason,
            reviewedBy: jobSheet.reviewedBy,
            reviewed: jobSheet.reviewed,
            resubmissionCount: jobSheet.resubmissionCount,
            qaStatus: data['qa_status']?.toString() ?? jobSheet.qaStatus,
            qaStatusLabel:
                data['qa_status_label']?.toString() ?? jobSheet.qaStatusLabel,
            qaNotes: data['qa_notes']?.toString() ?? jobSheet.qaNotes,
            qaCheckedBy:
                data['qa_checked_by']?.toString() ?? jobSheet.qaCheckedBy,
            qaChecked: data['qa_checked']?.toString() ?? jobSheet.qaChecked,
            rawFields: jobSheet.rawFields,
            payload: jobSheet.payload,
            material: jobSheet.material,
            materialsUsed: jobSheet.materialsUsed,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message']?.toString() ?? 'QA status updated.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              body['message']?.toString() ?? 'Failed to update QA status.',
            ),
          ),
        );
      }
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The server returned an invalid response. Please try again.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update QA status. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingDecision = false);
    }
  }

  Future<String?> _promptForQaNotes(String qaStatus) async {
    final controller = TextEditingController(text: jobSheet.qaNotes);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(qaStatus == 'passed' ? 'QA Pass' : 'QA Fail'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'QA notes (optional)',
            hintText: 'Add inspection or checklist notes',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(qaStatus == 'passed' ? 'Mark Pass' : 'Mark Fail'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
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
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
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
              _buildDetailRow(
                "Rejection Reason",
                jobSheet.rejectionReason,
                isDark,
              ),
            if (jobSheet.resubmissionCount > 0)
              _buildDetailRow(
                "Resubmissions",
                jobSheet.resubmissionCount.toString(),
                isDark,
              ),
            _buildDetailRow("QA Status", jobSheet.qaStatusLabel, isDark),
            if (jobSheet.qaCheckedBy.isNotEmpty)
              _buildDetailRow("QA Checked By", jobSheet.qaCheckedBy, isDark),
            if (jobSheet.qaChecked.isNotEmpty)
              _buildDetailRow("QA Checked At", jobSheet.qaChecked, isDark),
            if (jobSheet.qaNotes.isNotEmpty)
              _buildDetailRow("QA Notes", jobSheet.qaNotes, isDark),
            const SizedBox(height: 12),
            Text(
              "QA Evaluation",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F2C4A),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _submittingDecision
                      ? null
                      : () => _submitQaStatus('passed'),
                  icon: const Icon(
                    IconlyLight.tick_square,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    "QA Pass",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _submittingDecision
                      ? null
                      : () => _submitQaStatus('failed'),
                  icon: const Icon(IconlyLight.close_square, size: 18),
                  label: const Text(
                    "QA Fail",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _submittingDecision
                        ? null
                        : () => _submitDecision('approve'),
                    icon: const Icon(
                      IconlyLight.tick_square,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      "Approve",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD97706),
                      side: const BorderSide(color: Color(0xFFD97706)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _submittingDecision
                        ? null
                        : () => _submitDecision('request_rectification'),
                    icon: const Icon(IconlyLight.edit, size: 18),
                    label: const Text(
                      "Request Rectification",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _submittingDecision
                        ? null
                        : () => _submitDecision('reject'),
                    icon: const Icon(IconlyLight.close_square, size: 18),
                    label: const Text(
                      "Reject",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
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
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.05,
                        ),
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
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
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
                                _buildDetailRow(
                                  "Job No.",
                                  jobSheet.jobNo,
                                  isDark,
                                ),
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
                                _buildDetailRow(
                                  "Form Type",
                                  jobSheet.form,
                                  isDark,
                                ),
                                _buildDetailRow(
                                  "Location",
                                  jobSheet.location,
                                  isDark,
                                ),
                              ],
                            ),
                            _buildReviewSection(isDark),
                            _buildTraceabilitySection(isDark),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [
                            _buildSectionCard(
                              title:
                                  jobSheet.form.toLowerCase().contains("daily")
                                  ? "Notes"
                                  : "Financials & Notes",
                              isDark: isDark,
                              children: [
                                if (!jobSheet.form.toLowerCase().contains(
                                  "daily",
                                )) ...[
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
                                ],
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
                        title: jobSheet.form.toLowerCase().contains("daily")
                            ? "Notes"
                            : "Financials & Notes",
                        isDark: isDark,
                        children: [
                          if (!jobSheet.form.toLowerCase().contains(
                            "daily",
                          )) ...[
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
                          ],
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
                          _buildDetailRow("Created", jobSheet.created, isDark),
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
                      _buildTraceabilitySection(isDark),
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
