import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../core/widgets/custom_drawer.dart';
import '../../models/project_model.dart';

class WorkforcePlannerScreen extends StatefulWidget {
  const WorkforcePlannerScreen({super.key});

  @override
  State<WorkforcePlannerScreen> createState() => _WorkforcePlannerScreenState();
}

class _WorkforcePlannerScreenState extends State<WorkforcePlannerScreen> {
  bool _loading = true;
  bool _loadingProjects = false;
  String? _error;
  Map<String, dynamic> _data = {};

  List<Project> _projects = [];
  int? _selectedProjectId;
  String? _currentWeekStart;

  @override
  void initState() {
    super.initState();
    _fetchProjectsAndLoad();
  }

  Future<void> _fetchProjectsAndLoad() async {
    await Future.wait([
      _fetchProjects(),
      _load(),
    ]);
  }

  Future<void> _fetchProjects() async {
    _loadingProjects = true;
    try {
      final response = await ApiClient.get(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.projects}?page_size=100',
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['status'] == true) {
        final List<dynamic> list = body['data'] ?? [];
        if (mounted) {
          setState(() {
            _projects = list.map((j) => Project.fromJson(j)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching projects for workforce planner: $e");
    } finally {
      if (mounted) {
        setState(() => _loadingProjects = false);
      }
    }
  }

  Future<void> _load({int? projectId, String? weekStart}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final pId = projectId ?? _selectedProjectId;
    final wStart = weekStart ?? _currentWeekStart;

    try {
      final queryParams = <String>[];
      if (pId != null) queryParams.add('project_id=$pId');
      if (wStart != null && wStart.isNotEmpty) queryParams.add('week_start=$wStart');
      final query = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';

      final response = await ApiClient.get(
        '${ApiEndpoints.baseUrl}/workforce-planner/$query',
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['status'] == true) {
        _data = Map<String, dynamic>.from(body['data'] ?? {});
        _error = null;

        // Sync selected project ID from response if not set
        final projectData = _data['project'];
        if (projectData is Map && projectData['id'] != null) {
          final id = int.tryParse(projectData['id'].toString());
          if (id != null) {
            _selectedProjectId = id;
          }
        }
        if (_data['week_start'] != null) {
          _currentWeekStart = _data['week_start'].toString();
        }
      } else {
        _error = body['message']?.toString() ?? 'Unable to load workforce plan.';
      }
    } catch (error) {
      _error = 'Unable to load workforce plan: $error';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showProjectPickerModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String query = "";
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered = _projects.where((p) {
              final q = query.toLowerCase().trim();
              if (q.isEmpty) return true;
              return p.name.toLowerCase().contains(q) ||
                  p.code.toLowerCase().contains(q);
            }).toList();

            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Select Project",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          IconlyLight.close_square,
                          color: isDark ? Colors.white70 : Colors.grey,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search Bar
                  TextField(
                    onChanged: (val) => setModalState(() => query = val),
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: "Search projects by name or code...",
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        IconlyLight.search,
                        color: isDark ? Colors.white70 : Colors.grey,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppTheme.corporateBlue
                          : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_loadingProjects)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          "No projects match your search.",
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: isDark ? Colors.white12 : Colors.grey.shade100,
                        ),
                        itemBuilder: (context, index) {
                          final project = filtered[index];
                          final isSelected = project.id == _selectedProjectId;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0D6EFD).withValues(alpha: 0.15)
                                    : (isDark
                                        ? Colors.white10
                                        : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                IconlyLight.document,
                                color: isSelected
                                    ? const Color(0xFF0D6EFD)
                                    : (isDark ? Colors.white70 : Colors.grey),
                                size: 18,
                              ),
                            ),
                            title: Text(
                              project.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF0D6EFD)
                                    : textColor,
                              ),
                            ),
                            subtitle: Text(
                              "${project.code} • ${project.statusLabel}",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade600,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    IconlyBold.tick_square,
                                    color: Color(0xFF0D6EFD),
                                    size: 20,
                                  )
                                : null,
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _selectedProjectId = project.id;
                              });
                              _load(projectId: project.id);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _data['rows'] as List? ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurfaceRaised : Colors.white;
    final textColor = isDark ? AppTheme.darkText : const Color(0xFF0F2C4A);
    final borderColor = isDark ? AppTheme.darkBorder : const Color(0xFFDCE6F1);

    // Selected project display label
    String selectedProjectLabel = "Select Project";
    if (_selectedProjectId != null) {
      final match = _projects.where((p) => p.id == _selectedProjectId).toList();
      if (match.isNotEmpty) {
        selectedProjectLabel = "${match.first.code} - ${match.first.name}";
      } else if (_data['project']?['name'] != null) {
        selectedProjectLabel = _data['project']?['name']?.toString() ?? "Selected Project";
      }
    } else if (_data['project']?['name'] != null) {
      selectedProjectLabel = _data['project']?['name']?.toString() ?? "Selected Project";
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
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
            onRefresh: () => _load(projectId: _selectedProjectId),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Project Selector Filter Card
                InkWell(
                  onTap: _showProjectPickerModal,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            IconlyLight.filter,
                            color: Color(0xFF0D6EFD),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "PROJECT",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                selectedProjectLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          IconlyLight.arrow_down_2,
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(64.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_error != null)
                  _messageCard(
                    _error!,
                    cardColor,
                    textColor,
                    Icons.error_outline,
                  )
                else ...[
                  // Current Project & Week Schedule Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D6EFD).withValues(alpha: 0.12),
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
                                    selectedProjectLabel,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${_data['week_start'] ?? ''} — ${_data['week_end'] ?? ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppTheme.darkMuted
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
  ) =>
      Container(
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
          color: isDark ? AppTheme.darkBorder : const Color(0xFFDCE6F1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
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
              color: isDark ? AppTheme.darkMuted : Colors.grey.shade600,
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
      ),
    );
  }
}
