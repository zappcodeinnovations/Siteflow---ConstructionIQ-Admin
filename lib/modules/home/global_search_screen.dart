import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../models/project_model.dart';
import '../projects/project_details_screen.dart';
import '../drawer_pages/job_sheet_screen.dart';
import '../drawer_pages/team_detail_screen.dart';
import '../drawer_pages/admin_team_controller.dart';

/// Single search box that resolves to whichever screen actually has the
/// match (project/team/job sheet), mirroring admin_app.views.global_search's
/// "first matching category wins" redirect - this didn't exist in the app
/// at all; each screen only ever searched within itself.
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _queryController = TextEditingController();
  bool _isSearching = false;
  bool _isOpening = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
      _result = null;
    });
    try {
      final url = '${ApiEndpoints.baseUrl}/search/?q=${Uri.encodeQueryComponent(query)}';
      final response = await ApiClient.get(url);
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        setState(() => _result = (decoded['data'] as Map).cast<String, dynamic>());
      } else {
        setState(() => _error = decoded['message']?.toString() ?? 'Search failed.');
      }
    } catch (e) {
      setState(() => _error = 'An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _openResult() async {
    final result = _result;
    if (result == null) return;
    setState(() => _isOpening = true);

    try {
      switch (result['target']) {
        case 'projects':
          final projectId = result['project_id'];
          if (projectId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("No project matched \"${result['query']}\". Try the Projects tab's own search.")),
            );
            return;
          }
          final response = await ApiClient.get(ApiEndpoints.baseUrl + ApiEndpoints.projects);
          final decoded = jsonDecode(response.body);
          final list = (decoded['data'] as List? ?? []);
          final match = list.cast<Map>().firstWhere((p) => p['id'] == projectId, orElse: () => {});
          if (match.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Project could not be opened.")));
            }
            return;
          }
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProjectDetailsScreen(project: Project.fromJson(match.cast<String, dynamic>()))),
          );
          break;

        case 'teams':
          final teamId = result['team_id'];
          if (teamId == null || !mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TeamDetailScreen(teamId: teamId as int, controller: AdminTeamController())),
          );
          break;

        case 'job_sheets':
          if (!mounted) return;
          Navigator.push(context, MaterialPageRoute(builder: (_) => const JobSheetScreen()));
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to open result: $e")));
      }
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  String _targetLabel(String? target) {
    switch (target) {
      case 'projects':
        return 'Projects';
      case 'teams':
        return 'Teams';
      case 'job_sheets':
        return 'Job Sheets';
      default:
        return target ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;

    return Scaffold(
      appBar: AppBar(title: const Text("Search")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _queryController,
              autofocus: true,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: "Search projects, teams, job sheets…",
                prefixIcon: const Icon(IconlyLight.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isSearching ? null : _search,
              child: _isSearching
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Search", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_result != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Found in ${_targetLabel(_result!['target'])}", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 4),
                          Text("for \"${_result!['query']}\"", style: TextStyle(color: subtitleColor, fontSize: 13)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isOpening ? null : _openResult,
                      child: _isOpening
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Open"),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
