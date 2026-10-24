import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../core/widgets/custom_drawer.dart';
import '../../core/widgets/app_back_button.dart';
import '../../models/project_model.dart';

class ComplianceDashboardScreen extends StatefulWidget {
  const ComplianceDashboardScreen({super.key});

  @override
  State<ComplianceDashboardScreen> createState() =>
      _ComplianceDashboardScreenState();
}

class _ComplianceDashboardScreenState
    extends State<ComplianceDashboardScreen> {
  bool _loading = true;
  bool _loadingProjects = false;
  String? _error;
  Map<String, dynamic> _data = {};

  List<Project> _projects = [];
  int? _selectedProjectId;

  String _formatDate(dynamic raw) {
    if (raw == null) return '-';
    final str = raw.toString().trim();
    if (str.isEmpty || str == 'null') return '-';
    try {
      final parsed = DateTime.tryParse(str);
      if (parsed != null) {
        return DateFormat('dd MMM yyyy').format(parsed);
      }
    } catch (_) {}
    return str;
  }

  @override
  void initState() {
    super.initState();
    _fetchProjectsAndLoad();
  }

  Future<void> _fetchProjectsAndLoad() async {
    await Future.wait([_fetchProjects(), _load()]);
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
      debugPrint("Error fetching projects for compliance dashboard: $e");
    } finally {
      if (mounted) setState(() => _loadingProjects = false);
    }
  }

  Future<void> _load({int? projectId}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final pId = projectId ?? _selectedProjectId;

    try {
      final query = pId != null ? '?project_id=$pId' : '';
      final response = await ApiClient.get(
        '${ApiEndpoints.baseUrl}/compliance-dashboard/$query',
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['status'] == true) {
        _data = Map<String, dynamic>.from(body['data'] ?? {});
        _error = null;
      } else {
        _error = body['message']?.toString() ?? 'Unable to load compliance data.';
      }
    } catch (error) {
      _error = 'Unable to load compliance data: $error';
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
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedProjectId == null
                            ? const Color(0xFF0D6EFD).withValues(alpha: 0.15)
                            : (isDark ? Colors.white10 : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        IconlyLight.category,
                        color: _selectedProjectId == null
                            ? const Color(0xFF0D6EFD)
                            : (isDark ? Colors.white70 : Colors.grey),
                        size: 18,
                      ),
                    ),
                    title: Text(
                      "All Projects",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _selectedProjectId == null
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: _selectedProjectId == null
                            ? const Color(0xFF0D6EFD)
                            : textColor,
                      ),
                    ),
                    trailing: _selectedProjectId == null
                        ? const Icon(IconlyBold.tick_square,
                            color: Color(0xFF0D6EFD), size: 20)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _selectedProjectId = null);
                      _load();
                    },
                  ),
                  Divider(
                      height: 1,
                      color: isDark ? Colors.white12 : Colors.grey.shade100),
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
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey.shade600),
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
                          color:
                              isDark ? Colors.white12 : Colors.grey.shade100,
                        ),
                        itemBuilder: (context, index) {
                          final project = filtered[index];
                          final isSelected = project.id == _selectedProjectId;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0D6EFD)
                                        .withValues(alpha: 0.15)
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
                                ? const Icon(IconlyBold.tick_square,
                                    color: Color(0xFF0D6EFD), size: 20)
                                : null,
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() => _selectedProjectId = project.id);
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

  Color _scoreColor(num score) {
    if (score >= 90) return const Color(0xFF16A34A);
    if (score >= 70) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurfaceRaised : Colors.white;
    final textColor = isDark ? AppTheme.darkText : const Color(0xFF0F2C4A);
    final mutedColor = isDark ? AppTheme.darkMuted : Colors.grey.shade600;
    final borderColor = isDark ? AppTheme.darkBorder : const Color(0xFFDCE6F1);

    String selectedProjectLabel = "All Projects";
    if (_selectedProjectId != null) {
      final match =
          _projects.where((p) => p.id == _selectedProjectId).toList();
      if (match.isNotEmpty) {
        selectedProjectLabel = "${match.first.code} - ${match.first.name}";
      }
    }

    final score = (_data['score'] as num?) ?? 0;
    final expiredDocuments = _data['expired_documents'] as List? ?? [];
    final expiringSoonDocuments = _data['expiring_soon_documents'] as List? ?? [];
    final expiredQualifications = _data['expired_qualifications'] as List? ?? [];
    final expiringSoonQualifications =
        _data['expiring_soon_qualifications'] as List? ?? [];
    final expiringSoonDays = _data['expiring_soon_days']?.toString() ?? '30';

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackground : const Color(0xFFF4F7FB),
      appBar: AppBar(
        leading: const AppNavLeading(),
        leadingWidth: AppNavigation.backAndMenuLeadingWidth,
        title: const Text(
          'Compliance Dashboard',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: BackgroundStripesPainter(isDark: isDark)),
          ),
          RefreshIndicator(
            onRefresh: () => _load(projectId: _selectedProjectId),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                InkWell(
                  onTap: _showProjectPickerModal,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          child: const Icon(IconlyLight.filter,
                              color: Color(0xFF0D6EFD), size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "SCOPE",
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
                                    color: textColor),
                              ),
                            ],
                          ),
                        ),
                        Icon(IconlyLight.arrow_down_2,
                            color: isDark ? Colors.white70 : Colors.grey.shade600,
                            size: 18),
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
                  _messageCard(_error!, cardColor, textColor, Icons.error_outline)
                else ...[
                  // Safety Compliance Score card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "${score.toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: _scoreColor(score),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Safety Compliance Score",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: mutedColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _scoreBreakdown(
                              "Document Validity",
                              _data['document_validity_pct'],
                              textColor,
                              mutedColor,
                            ),
                            _scoreBreakdown(
                              "Acknowledgment",
                              _data['acknowledgment_completion_pct'],
                              textColor,
                              mutedColor,
                            ),
                            _scoreBreakdown(
                              "Certification",
                              _data['certification_validity_pct'],
                              textColor,
                              mutedColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stat row
                  Row(
                    children: [
                      _statCard(
                        "Expired Docs",
                        expiredDocuments.length.toString(),
                        cardColor,
                        textColor,
                        mutedColor,
                        borderColor,
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        "Expiring in ${expiringSoonDays}d",
                        expiringSoonDocuments.length.toString(),
                        cardColor,
                        textColor,
                        mutedColor,
                        borderColor,
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        "RAMS Pending",
                        (_data['rams_pending_acknowledgments'] ?? 0).toString(),
                        cardColor,
                        textColor,
                        mutedColor,
                        borderColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Text("RAMS Status Overview",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      "${_data['rams_total_count'] ?? 0} RAMS document(s) on record, "
                      "${_data['rams_required_count'] ?? 0} requiring sign-off, "
                      "${_data['rams_pending_acknowledgments'] ?? 0} worker "
                      "acknowledgment(s) still outstanding.",
                      style: TextStyle(fontSize: 13, color: mutedColor, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Text("Expired Documents",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor)),
                  const SizedBox(height: 8),
                  if (expiredDocuments.isEmpty)
                    _messageCard("No expired documents.", cardColor, mutedColor,
                        IconlyLight.shield_done)
                  else
                    for (final raw in expiredDocuments)
                      _documentRow(raw, cardColor, textColor, mutedColor,
                          borderColor, isExpired: true),
                  const SizedBox(height: 18),

                  Text("Expiring Soon (next $expiringSoonDays days)",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor)),
                  const SizedBox(height: 8),
                  if (expiringSoonDocuments.isEmpty)
                    _messageCard("Nothing expiring soon.", cardColor, mutedColor,
                        IconlyLight.time_circle)
                  else
                    for (final raw in expiringSoonDocuments)
                      _documentRow(raw, cardColor, textColor, mutedColor,
                          borderColor, isExpired: false),
                  const SizedBox(height: 18),

                  Text("Employee Certifications",
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor)),
                  const SizedBox(height: 8),
                  if (expiredQualifications.isEmpty &&
                      expiringSoonQualifications.isEmpty)
                    _messageCard("All employee certifications are valid.",
                        cardColor, mutedColor, IconlyLight.shield_done)
                  else ...[
                    for (final raw in expiredQualifications)
                      _qualificationRow(raw, cardColor, textColor, mutedColor,
                          borderColor, isExpired: true),
                    for (final raw in expiringSoonQualifications)
                      _qualificationRow(raw, cardColor, textColor, mutedColor,
                          borderColor, isExpired: false),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBreakdown(
    String label,
    dynamic value,
    Color textColor,
    Color mutedColor,
  ) {
    final pct = (value as num?) ?? 0;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${pct.toStringAsFixed(1)}%",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, color: mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    Color cardColor,
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 10.5, color: mutedColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
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
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF0D6EFD), size: 26),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: textColor)),
          ],
        ),
      );

  Widget _documentRow(
    dynamic raw,
    Color cardColor,
    Color textColor,
    Color mutedColor,
    Color borderColor, {
    required bool isExpired,
  }) {
    final badgeColor =
        isExpired ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final badgeBg =
        isExpired ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(raw['title']?.toString() ?? '-',
                    style: TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 3),
                Text(
                  "${raw['project_name'] ?? '-'} • ${raw['category_label'] ?? '-'}",
                  style: TextStyle(fontSize: 11.5, color: mutedColor),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _formatDate(raw['expiry_date']),
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: badgeColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qualificationRow(
    dynamic raw,
    Color cardColor,
    Color textColor,
    Color mutedColor,
    Color borderColor, {
    required bool isExpired,
  }) {
    final badgeColor =
        isExpired ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final badgeBg =
        isExpired ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(raw['title']?.toString() ?? '-',
                    style: TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 3),
                Text(
                  raw['user_name']?.toString() ?? '-',
                  style: TextStyle(fontSize: 11.5, color: mutedColor),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _formatDate(raw['expiry_date']),
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: badgeColor),
            ),
          ),
        ],
      ),
    );
  }
}
