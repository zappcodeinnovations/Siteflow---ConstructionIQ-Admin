import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/widgets/custom_drawer.dart';

class WorkforcePlannerScreen extends StatefulWidget {
  const WorkforcePlannerScreen({super.key});

  @override
  State<WorkforcePlannerScreen> createState() => _WorkforcePlannerScreenState();
}

class _WorkforcePlannerScreenState extends State<WorkforcePlannerScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await ApiClient.get(
        '${ApiEndpoints.baseUrl}/workforce-planner/',
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['status'] == true) {
        _data = Map<String, dynamic>.from(body['data'] ?? {});
        _error = null;
      } else {
        _error =
            body['message']?.toString() ?? 'Unable to load workforce plan.';
      }
    } catch (error) {
      _error = 'Unable to load workforce plan: $error';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final rows = _data['rows'] as List? ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Workforce Planner')),
      drawer: const CustomDrawer(),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    _data['project']?['name']?.toString() ??
                        'No assigned project',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_data['week_start'] ?? ''} — ${_data['week_end'] ?? ''}',
                  ),
                  const SizedBox(height: 16),
                  if (rows.isEmpty)
                    const Text('No workforce allocations for this week.'),
                  for (final raw in rows)
                    Card(
                      child: ExpansionTile(
                        title: Text(raw['worker_name']?.toString() ?? '-'),
                        children: [
                          for (final cell in (raw['cells'] as List? ?? []))
                            if (cell['planned'] == true)
                              ListTile(
                                title: Text(cell['date']?.toString() ?? ''),
                                subtitle: Text(
                                  [
                                        cell['site_block'],
                                        cell['work_type'],
                                        cell['shift'],
                                        cell['notes'],
                                      ]
                                      .where(
                                        (value) =>
                                            value != null &&
                                            value.toString().isNotEmpty,
                                      )
                                      .join(' • '),
                                ),
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
