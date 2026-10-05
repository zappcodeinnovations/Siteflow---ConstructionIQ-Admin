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

  Widget _buildJsonBlock(String title, dynamic data, {bool isDark = false}) {
    if (data == null || data.toString().isEmpty || data.toString() == '{}') {
      return const SizedBox.shrink();
    }

    String formatted = "";
    if (data is String) {
      formatted = data;
    } else {
      formatted = const JsonEncoder.withIndent('  ').convert(data);
    }

    return _buildInfoCard(
      title: title,
      icon: IconlyLight.document,
      isDark: isDark,
      content: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF162A42) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
        ),
        child: SelectableText(
          formatted,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.5,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
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
                                _buildDetailRow("Timestamp", _logDetails!['timestamp']?.toString() ?? 'N/A', isDark: isDark),
                              ],
                            )
                          ),
                          const SizedBox(height: 8),
                          
                          _buildJsonBlock("Previous State", _logDetails!['change_summary'] != null ? _logDetails!['change_summary']['previous'] : null, isDark: isDark),
                          _buildJsonBlock("New State / Activity", _logDetails!['change_summary'] != null ? _logDetails!['change_summary']['new'] : null, isDark: isDark),
                          
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