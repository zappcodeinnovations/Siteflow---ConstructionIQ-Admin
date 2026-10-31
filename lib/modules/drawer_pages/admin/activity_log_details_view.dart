import 'package:flutter/material.dart';
import 'admin_activity_logs_controller.dart';
import 'dart:convert';
import 'package:iconly/iconly.dart';

class ActivityLogDetailsView extends StatefulWidget {
  final AdminActivityLogsController controller;
  final int logId;

  const ActivityLogDetailsView({super.key, required this.controller, required this.logId});

  @override
  State<ActivityLogDetailsView> createState() => _ActivityLogDetailsViewState();
}

class _ActivityLogDetailsViewState extends State<ActivityLogDetailsView> {
  bool _isLoading = true;
  Map<String, dynamic>? _logDetails;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final details = await widget.controller.fetchLogDetails(widget.logId);
    if (mounted) {
      setState(() {
        _logDetails = details;
        _isLoading = false;
      });
    }
  }

  String _prettifyLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  dynamic _tryParsePythonLiteral(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {}
    try {
      final converted = text
          .replaceAll('None', 'null')
          .replaceAll('True', 'true')
          .replaceAll('False', 'false')
          .replaceAllMapped(RegExp(r"'([^']*)'"), (m) => '"${m[1]}"');
      return jsonDecode(converted);
    } catch (_) {
      return null;
    }
  }

  String _formatTimestamp(dynamic raw) {
    if (raw == null || raw.toString().isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      final second = dt.second.toString().padLeft(2, '0');
      return '$day/$month/${dt.year}, ${hour12.toString().padLeft(2, '0')}:$minute:$second $period';
    } catch (_) {
      return raw.toString();
    }
  }

  Widget _buildValueDisplay(dynamic value, {bool isDark = false, int depth = 0}) {
    final mutedStyle = TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.grey);
    final valueStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87);

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        final parsed = _tryParsePythonLiteral(trimmed);
        if (parsed != null) return _buildValueDisplay(parsed, isDark: isDark, depth: depth);
      }
      return SelectableText(value.isEmpty ? '-' : value, style: valueStyle);
    }
    if (value == null) return Text('-', style: mutedStyle);
    if (value is bool) return Text(value ? 'Yes' : 'No', style: valueStyle);
    if (value is num) return SelectableText(value.toString(), style: valueStyle);

    if (value is Map) {
      final entries = value.entries
          .where((e) => e.value != null && e.value.toString().isNotEmpty && e.value.toString() != '[]' && e.value.toString() != '{}')
          .toList();
      if (entries.isEmpty) return Text('-', style: mutedStyle);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(_prettifyLabel(entry.key.toString()), style: mutedStyle.copyWith(fontWeight: FontWeight.w500)),
                  ),
                  Expanded(child: _buildValueDisplay(entry.value, isDark: isDark, depth: depth + 1)),
                ],
              ),
            ),
        ],
      );
    }

    if (value is List) {
      if (value.isEmpty) return Text('-', style: mutedStyle);
      if (value.every((e) => e is Map)) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in value)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF162A42) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                ),
                child: _buildValueDisplay(item, isDark: isDark, depth: depth + 1),
              ),
          ],
        );
      }
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: value
            .map(
              (item) => Chip(
                label: Text(item.toString(), style: const TextStyle(fontSize: 12)),
                backgroundColor: isDark ? const Color(0xFF162A42) : Colors.grey.shade100,
                side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
              ),
            )
            .toList(),
      );
    }

    return SelectableText(value.toString(), style: valueStyle);
  }

  Widget _buildStateCard(String title, dynamic rawValue, {bool isDark = false}) {
    dynamic normalized = rawValue;
    if (normalized is String) {
      final trimmed = normalized.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        normalized = _tryParsePythonLiteral(trimmed) ?? normalized;
      }
    }
    final isEmptyMap = normalized is Map && normalized.isEmpty;
    final isEmptyList = normalized is List && normalized.isEmpty;
    final isEmptyString = normalized is String && normalized.isEmpty;
    if (normalized == null || isEmptyMap || isEmptyList || isEmptyString) {
      return const SizedBox.shrink();
    }

    return _buildInfoCard(
      title: title,
      icon: IconlyLight.document,
      isDark: isDark,
      content: _buildValueDisplay(normalized, isDark: isDark),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required Widget content, bool isDark = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F2C4A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: isDark ? Colors.white : const Color(0xFF0F2C4A)),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF0F2C4A))),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: isDark ? Colors.white12 : null),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isDark = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.grey, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: SelectableText(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A1929) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Activity Log Details", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF0F2C4A) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logDetails == null
              ? Center(child: Text("Failed to load details.", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Info Card
                          _buildInfoCard(
                            title: "User Information",
                            icon: IconlyLight.profile,
                            isDark: isDark,
                            content: Column(
                              children: [
                                _buildDetailRow("User Name", _logDetails!['user_name']?.toString() ?? 'N/A', isDark: isDark),
                                const SizedBox(height: 12),
                                _buildDetailRow("User Role", _logDetails!['user_role']?.toString() ?? 'N/A', isDark: isDark),
                              ],
                            )
                          ),
                          const SizedBox(height: 8),

                          // Activity Info Card
                          _buildInfoCard(
                            title: "Activity Details",
                            icon: IconlyLight.activity,
                            isDark: isDark,
                            content: Column(
                              children: [
                                _buildDetailRow("Action", _logDetails!['action_type']?.toString() ?? 'N/A', isDark: isDark),
                                const SizedBox(height: 12),
                                _buildDetailRow("Module", _logDetails!['module_name']?.toString() ?? 'N/A', isDark: isDark),
                                if (_logDetails!['record_id'] != null && _logDetails!['record_id'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _buildDetailRow("Record ID", _logDetails!['record_id'].toString(), isDark: isDark),
                                ],
                                const SizedBox(height: 12),
                                _buildDetailRow("Timestamp", _formatTimestamp(_logDetails!['timestamp']), isDark: isDark),
                              ],
                            )
                          ),
                          const SizedBox(height: 8),
                          
                          _buildStateCard("Previous State", _logDetails!['previous_value'], isDark: isDark),
                          _buildStateCard("New State / Activity", _logDetails!['new_value'], isDark: isDark),
                          
                          if (_logDetails!['ip_address'] != null || _logDetails!['browser_information'] != null) ...[
                            const SizedBox(height: 8),
                            _buildInfoCard(
                              title: "System Information",
                              icon: IconlyLight.info_square,
                              isDark: isDark,
                              content: Column(
                                children: [
                                  if (_logDetails!['ip_address'] != null)
                                    _buildDetailRow("IP Address", _logDetails!['ip_address'], isDark: isDark),
                                  if (_logDetails!['browser_information'] != null) ...[
                                    const SizedBox(height: 12),
                                    _buildDetailRow("Browser Info", _logDetails!['browser_information'], isDark: isDark),
                                  ],
                                ],
                              )
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}