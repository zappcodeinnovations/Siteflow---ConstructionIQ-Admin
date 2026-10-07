import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/theme/app_theme.dart';

/// Drill-down behind a productivity member or project row - backed by the
/// new ProductivityMemberDetailAPIView/ProductivityProjectDetailAPIView.
/// Neither existed before; tapping a row did nothing.
class ProductivityDetailScreen extends StatefulWidget {
  final int id;
  final String title;
  final bool isMember;

  const ProductivityDetailScreen({super.key, required this.id, required this.title, required this.isMember});

  @override
  State<ProductivityDetailScreen> createState() => _ProductivityDetailScreenState();
}

class _ProductivityDetailScreenState extends State<ProductivityDetailScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final path = widget.isMember ? 'members' : 'projects';
      final url = '${ApiEndpoints.baseUrl}/productivity/$path/${widget.id}/';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        _data = (decoded['data'] as Map).cast<String, dynamic>();
      } else {
        _error = decoded['message']?.toString() ?? 'Failed to load productivity detail.';
      }
    } catch (e) {
      _error = 'An error occurred: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildBody(isDark, textColor, textSecondary, cardColor, borderColor),
    );
  }

  Widget _buildBody(bool isDark, Color textColor, Color textSecondary, Color cardColor, Color borderColor) {
    final summary = (_data?['summary'] as Map?)?.cast<String, dynamic>() ?? {};
    final jobs = (_data?['jobs'] as List? ?? []).whereType<Map>().toList();
    final submissions = (_data?['submissions'] as List? ?? []).whereType<Map>().toList();
    final members = (_data?['members'] as List? ?? []).whereType<Map>().toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
          child: Wrap(
            spacing: 24,
            runSpacing: 12,
            children: summary.entries.map((e) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.key.replaceAll('_', ' ').toUpperCase(), style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${e.value}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                ],
              );
            }).toList(),
          ),
        ),
        if (members.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text("Members", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          ...members.map((m) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(m['name']?.toString() ?? ''),
                  subtitle: Text(m['team']?.toString() ?? ''),
                  trailing: Text('${m['job_sheets'] ?? 0} sheets'),
                ),
              )),
        ],
        const SizedBox(height: 24),
        Text("Jobs (${jobs.length})", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        if (jobs.isEmpty) Text("No jobs found.", style: TextStyle(color: textSecondary)),
        ...jobs.map((j) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(j['reference']?.toString() ?? j['task_no']?.toString() ?? 'Job'),
                subtitle: Text(j['operative_name']?.toString() ?? ''),
                trailing: Text(j['status']?.toString() ?? ''),
              ),
            )),
        const SizedBox(height: 24),
        Text("Job Sheets (${submissions.length})", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 8),
        if (submissions.isEmpty) Text("No job sheets found.", style: TextStyle(color: textSecondary)),
        ...submissions.map((s) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(s['name']?.toString() ?? 'Submission'),
                subtitle: Text(s['submitted_at']?.toString() ?? ''),
                trailing: Text(s['status_label']?.toString() ?? ''),
              ),
            )),
      ],
    );
  }
}
