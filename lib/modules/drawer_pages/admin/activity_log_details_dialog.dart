import 'package:flutter/material.dart';
import 'admin_activity_logs_controller.dart';
import 'dart:convert';

class ActivityLogDetailsDialog extends StatefulWidget {
  final AdminActivityLogsController controller;
  final int logId;

  const ActivityLogDetailsDialog({super.key, required this.controller, required this.logId});

  @override
  State<ActivityLogDetailsDialog> createState() => _ActivityLogDetailsDialogState();
}

class _ActivityLogDetailsDialogState extends State<ActivityLogDetailsDialog> {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F2C4A))),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SelectableText(
            formatted,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Activity Log Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F2C4A))),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_logDetails == null)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: Text("Failed to load details.")),
              )
            else ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Action", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(_logDetails!['action_type']?.toString() ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Module", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(_logDetails!['module_name']?.toString() ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      _buildJsonBlock("Previous State", _logDetails!['change_summary'] != null ? _logDetails!['change_summary']['previous'] : null),
                      _buildJsonBlock("New State / Activity", _logDetails!['change_summary'] != null ? _logDetails!['change_summary']['new'] : null),
                      
                      if (_logDetails!['ip_address'] != null)
                        _buildJsonBlock("IP Address", _logDetails!['ip_address']),
                      if (_logDetails!['browser_information'] != null)
                        _buildJsonBlock("Browser Info", _logDetails!['browser_information']),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
