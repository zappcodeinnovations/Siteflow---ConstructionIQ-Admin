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

  Widget _buildJsonBlock(String title, dynamic data) {
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
      content: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: SelectableText(
          formatted,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required Widget content}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF0F2C4A)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F2C4A))),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: SelectableText(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Activity Log Details", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),

        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logDetails == null
              ? const Center(child: Text("Failed to load details."))
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
                            content: Column(
                              children: [
                                _buildDetailRow("User Name", _logDetails!['user_name']?.toString() ?? 'N/A'),
                                const SizedBox(height: 12),
                                _buildDetailRow("User Role", _logDetails!['user_role']?.toString() ?? 'N/A'),
                              ],
                            )
                          ),
                          const SizedBox(height: 8),

                          // Activity Info Card
                          _buildInfoCard(
                            title: "Activity Details",
                            icon: IconlyLight.activity,
                            content: Column(
                              children: [
                                _buildDetailRow("Action", _logDetails!['action_type']?.toString() ?? 'N/A'),
                                const SizedBox(height: 12),
                                _buildDetailRow("Module", _logDetails!['module_name']?.toString() ?? 'N/A'),
                                if (_logDetails!['record_id'] != null && _logDetails!['record_id'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _buildDetailRow("Record ID", _logDetails!['record_id'].toString()),
                                ],
                                const SizedBox(height: 12),
                                _buildDetailRow("Timestamp", _logDetails!['timestamp']?.toString() ?? 'N/A'),
                              ],
                            )
                          ),
                          const SizedBox(height: 8),
                          
                          _buildJsonBlock("Previous State", _logDetails!['change_summary'] != null ? _logDetails!['change_summary']['previous'] : null),
                          _buildJsonBlock("New State / Activity", _logDetails!['change_summary'] != null ? _logDetails!['change_summary']['new'] : null),
                          
                          if (_logDetails!['ip_address'] != null || _logDetails!['browser_information'] != null) ...[
                            const SizedBox(height: 8),
                            _buildInfoCard(
                              title: "System Information",
                              icon: IconlyLight.info_square,
                              content: Column(
                                children: [
                                  if (_logDetails!['ip_address'] != null)
                                    _buildDetailRow("IP Address", _logDetails!['ip_address']),
                                  if (_logDetails!['browser_information'] != null) ...[
                                    const SizedBox(height: 12),
                                    _buildDetailRow("Browser Info", _logDetails!['browser_information']),
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