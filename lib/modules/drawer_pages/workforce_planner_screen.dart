import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_helper.dart';
import '../../core/widgets/background_stripes_painter.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF123B64) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.corporateBlue
          : const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Workforce Planner',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundStripesPainter(isDark: isDark),
            ),
          ),
          RefreshIndicator(
            onRefresh: _load,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (_error != null)
                        _messageCard(
                          _error!,
                          cardColor,
                          textColor,
                          Icons.error_outline,
                        )
                      else ...[
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white24
                                  : const Color(0xFFDCE6F1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0D6EFD,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  IconlyLight.calendar,
                                  color: Color(0xFF0D6EFD),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _data['project']?['name']?.toString() ??
                                          'No assigned project',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '${DateHelper.formatDate(_data['week_start']?.toString())} — ${DateHelper.formatDate(_data['week_end']?.toString())}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (rows.isEmpty)
                          _messageCard(
                            'No workforce allocations for this week.',
                            cardColor,
                            textColor,
                            IconlyLight.calendar,
                          )
                        else
                          for (final raw in rows)
                            _workerCard(raw, cardColor, textColor, isDark),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _messageCard(
    String message,
    Color color,
    Color textColor,
    IconData icon,
  ) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Icon(icon, color: const Color(0xFF0D6EFD), size: 30),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor),
        ),
      ],
    ),
  );

  Widget _workerCard(
    dynamic raw,
    Color cardColor,
    Color textColor,
    bool isDark,
  ) {
    final cells = raw['cells'] as List? ?? [];
    final planned = cells.where((cell) => cell['planned'] == true).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white24 : const Color(0xFFDCE6F1),
        ),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F2FF),
          child: Icon(IconlyLight.user, color: Color(0xFF0D6EFD), size: 18),
        ),
        title: Text(
          raw['worker_name']?.toString() ?? '-',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${planned.length} day(s) planned',
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        children: planned.isEmpty
            ? [const ListTile(title: Text('No allocation for this worker.'))]
            : planned
                  .map<Widget>(
                    (cell) => ListTile(
                      leading: const Icon(
                        IconlyLight.tick_square,
                        color: Colors.green,
                        size: 20,
                      ),
                      title: Text(
                        cell['date']?.toString() ?? '',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        [
                              cell['site_block'],
                              cell['work_type'],
                              cell['shift'],
                              cell['notes'],
                            ]
                            .where(
                              (value) =>
                                  value != null && value.toString().isNotEmpty,
                            )
                            .join(' • '),
                      ),
                    ),
                  )
                  .toList(),
      ),
    );
  }
}
