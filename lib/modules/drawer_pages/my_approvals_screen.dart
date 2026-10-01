import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/widgets/custom_drawer.dart';

class MyApprovalsScreen extends StatefulWidget {
  const MyApprovalsScreen({super.key});

  @override
  State<MyApprovalsScreen> createState() => _MyApprovalsScreenState();
}

class _MyApprovalsScreenState extends State<MyApprovalsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await ApiClient.get(
        '${ApiEndpoints.baseUrl}/my-approvals/',
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['status'] == true) {
        _items = body['data'] as List? ?? [];
        _error = null;
      } else {
        _error = body['message']?.toString() ?? 'Unable to load approvals.';
      }
    } catch (error) {
      _error = 'Unable to load approvals: $error';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Approvals')),
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
            : _items.isEmpty
            ? ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No pending approvals.'),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _items[index] as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      title: Text(
                        item['form_name']?.toString() ?? 'Form submission',
                      ),
                      subtitle: Text(
                        '${item['project_name'] ?? '-'}\n${item['operative_name'] ?? '-'}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
