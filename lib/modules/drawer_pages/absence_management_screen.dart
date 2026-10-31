import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../core/widgets/custom_date_picker_dialog.dart';
import '../../core/widgets/custom_drawer.dart';
import '../../models/absence_management_model.dart';
import 'absence_management_controller.dart';

class AbsenceManagementScreen extends StatefulWidget {
  const AbsenceManagementScreen({super.key});

  @override
  State<AbsenceManagementScreen> createState() =>
      _AbsenceManagementScreenState();
}

class _AbsenceManagementScreenState extends State<AbsenceManagementScreen> {
  final AbsenceManagementController _controller = AbsenceManagementController();
  final TextEditingController _searchCtrl = TextEditingController();
  String _userRoleDisplayName = 'Admin';
  bool _canCreate = true;
  bool _canEdit = true;

  @override
  void initState() {
    super.initState();
    _loadUserPermissions();
    _controller.fetchAbsences();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUserPermissions() async {
    final roleName = await AuthService.getRoleDisplayName();
    final canCreate = await AuthService.can(
      'absence_management',
      action: 'create',
    );
    final canEdit = await AuthService.can('absence_management', action: 'edit');
    if (mounted) {
      setState(() {
        _userRoleDisplayName = roleName;
        _canCreate = canCreate;
        _canEdit = canEdit;
      });
    }
  }

  void _onSearchChanged(String val) {
    _controller.setSearchQuery(val);
  }

  Future<void> _selectDateRange() async {
    final picked = await CustomDatePickerDialog.showCustomDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      final startStr = DateFormat('yyyy-MM-dd').format(picked.start);
      final endStr = DateFormat('yyyy-MM-dd').format(picked.end);
      _controller.setDateRange(startStr, endStr);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF198754);
      case 'rejected':
        return const Color(0xFFDC3545);
      case 'cancelled':
        return const Color(0xFF6C757D);
      case 'pending':
      default:
        return const Color(0xFFFD7E14);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'sick':
        return Icons.medical_services_outlined;
      case 'annual_holiday':
        return Icons.beach_access_outlined;
      case 'approved_leave':
        return Icons.verified_user_outlined;
      case 'emergency_leave':
        return Icons.warning_amber_rounded;
      default:
        return Icons.event_busy_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? AppTheme.darkBackground
        : const Color(0xFFF4F7FB);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        leading: const AppNavLeading(),
        leadingWidth: AppNavigation.backAndMenuLeadingWidth,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Absence Management',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            Text(
              '$_userRoleDisplayName Scope',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _controller.fetchAbsences(),
          ),
          if (_canCreate)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.corporateBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Record',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: _showRecordAbsenceModal,
              ),
            ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundStripesPainter(isDark: isDark),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return RefreshIndicator(
                onRefresh: () => _controller.fetchAbsences(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Top Overview / KPI Cards
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: _buildKpiGrid(isDark),
                      ),
                    ),

                    // Filter Toolbar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: _buildFilterBar(isDark),
                      ),
                    ),

                    // Status Tabs Pills
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: _buildStatusPills(isDark),
                      ),
                    ),

                    // Active filters indicator
                    if (_controller.hasActiveFilters)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Row(
                            children: [
                              Text(
                                'Filtered results (${_controller.absences.length})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.clear_all, size: 16),
                                label: const Text(
                                  'Reset All',
                                  style: TextStyle(fontSize: 12),
                                ),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _controller.resetFilters();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Main Content: List or Loading or Empty
                    if (_controller.isLoading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_controller.errorMessage != null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _controller.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: () => _controller.fetchAbsences(),
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else if (_controller.absences.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(isDark),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final item = _controller.absences[index];
                            return _buildAbsenceCard(item, isDark);
                          }, childCount: _controller.absences.length),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(bool isDark) {
    final sum = _controller.summary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 20) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildKpiCard(
              title: 'Total',
              count: sum.totalRequests,
              icon: IconlyLight.document,
              color: const Color(0xFF0D6EFD),
              isActive: _controller.statusFilter == 'all',
              isDark: isDark,
              width: cardWidth,
              onTap: () => _controller.setStatusFilter('all'),
            ),
            _buildKpiCard(
              title: 'Pending',
              count: sum.pendingRequests,
              icon: IconlyLight.time_circle,
              color: const Color(0xFFFD7E14),
              isActive: _controller.statusFilter == 'pending',
              isDark: isDark,
              width: cardWidth,
              onTap: () => _controller.setStatusFilter('pending'),
            ),
            _buildKpiCard(
              title: 'Approved',
              count: sum.approvedRequests,
              icon: IconlyLight.tick_square,
              color: const Color(0xFF198754),
              isActive: _controller.statusFilter == 'approved',
              isDark: isDark,
              width: cardWidth,
              onTap: () => _controller.setStatusFilter('approved'),
            ),
            _buildKpiCard(
              title: 'Rejected',
              count: sum.rejectedRequests,
              icon: Icons.cancel_outlined,
              color: const Color(0xFFDC3545),
              isActive: _controller.statusFilter == 'rejected',
              isDark: isDark,
              width: cardWidth,
              onTap: () => _controller.setStatusFilter('rejected'),
            ),
            _buildKpiCard(
              title: 'Absent Today',
              count: sum.absentToday,
              icon: Icons.person_off_outlined,
              color: const Color(0xFF6F42C1),
              isActive: false,
              isDark: isDark,
              width: cardWidth,
              onTap: null,
            ),
            _buildKpiCard(
              title: 'Upcoming',
              count: sum.upcomingAbsences,
              icon: IconlyLight.calendar,
              color: const Color(0xFF0DCAF0),
              isActive: false,
              isDark: isDark,
              width: cardWidth,
              onTap: null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required bool isActive,
    required bool isDark,
    required double width,
    VoidCallback? onTap,
  }) {
    final bg = isDark
        ? (isActive
              ? color.withValues(alpha: 0.25)
              : AppTheme.darkSurfaceRaised)
        : (isActive ? color.withValues(alpha: 0.12) : Colors.white);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? color
                : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const Spacer(),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return Row(
      children: [
        // Search bar
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1),
              ),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              onSubmitted: (val) => _controller.fetchAbsences(),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search operative, project, notes...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                prefixIcon: const Icon(IconlyLight.search, size: 18),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          _controller.setSearchQuery('');
                          _controller.fetchAbsences();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Date Range Picker button
        InkWell(
          onTap: _selectDateRange,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _controller.fromDate != null
                  ? AppTheme.corporateBlue.withValues(alpha: 0.15)
                  : (isDark ? AppTheme.darkSurfaceRaised : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _controller.fromDate != null
                    ? AppTheme.corporateBlue
                    : (isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  IconlyLight.calendar,
                  size: 18,
                  color: _controller.fromDate != null
                      ? AppTheme.corporateBlue
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(width: 6),
                Text(
                  _controller.fromDate != null
                      ? DateFormat(
                          'dd/MM',
                        ).format(DateTime.parse(_controller.fromDate!))
                      : 'Dates',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _controller.fromDate != null
                        ? AppTheme.corporateBlue
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Filter Dialog Button
        InkWell(
          onTap: _showAdvancedFilterDialog,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color:
                  (_controller.selectedType != null ||
                      _controller.selectedProjectId != null ||
                      _controller.selectedOperativeId != null)
                  ? AppTheme.corporateBlue.withValues(alpha: 0.15)
                  : (isDark ? AppTheme.darkSurfaceRaised : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    (_controller.selectedType != null ||
                        _controller.selectedProjectId != null ||
                        _controller.selectedOperativeId != null)
                    ? AppTheme.corporateBlue
                    : (isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  IconlyLight.filter,
                  size: 18,
                  color:
                      (_controller.selectedType != null ||
                          _controller.selectedProjectId != null ||
                          _controller.selectedOperativeId != null)
                      ? AppTheme.corporateBlue
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPills(bool isDark) {
    final statuses = [
      {'key': 'all', 'label': 'All'},
      {'key': 'pending', 'label': 'Pending'},
      {'key': 'approved', 'label': 'Approved'},
      {'key': 'rejected', 'label': 'Rejected'},
      {'key': 'cancelled', 'label': 'Cancelled'},
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = statuses[index];
          final isSelected = _controller.statusFilter == item['key'];
          final color = item['key'] == 'all'
              ? AppTheme.corporateBlue
              : _getStatusColor(item['key']!);

          return ChoiceChip(
            label: Text(item['label']!),
            selected: isSelected,
            onSelected: (_) => _controller.setStatusFilter(item['key']!),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            selectedColor: color,
            backgroundColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
            side: BorderSide(
              color: isSelected
                  ? color
                  : (isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1)),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAbsenceCard(AbsenceRecord record, bool isDark) {
    final statusColor = _getStatusColor(record.status);
    final typeIcon = _getTypeIcon(record.absenceType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Operative name, Employee ID, Status Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.corporateBlue.withValues(
                    alpha: 0.12,
                  ),
                  child: Text(
                    record.operativeName.isNotEmpty
                        ? record.operativeName[0].toUpperCase()
                        : 'O',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.corporateBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.operativeName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (record.operativeEmployeeId.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white12
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                record.operativeEmployeeId,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              record.projectName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    record.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Absence Type & Dates Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Type chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF0D6EFD).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              typeIcon,
                              size: 14,
                              color: const Color(0xFF0D6EFD),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              record.absenceTypeLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0D6EFD),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Duration badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? Colors.white12
                                  : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          record.durationLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),

                      if (record.isPartialDay &&
                          !record.durationLabel
                              .toLowerCase()
                              .contains('half'))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Half Day',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Dates
                  Text(
                    _formatDateRange(record.startDate, record.endDate),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rejection reason banner if rejected
          if (record.isRejected && record.rejectionReason != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC3545).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFDC3545).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xFFDC3545),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rejection Reason:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC3545),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            record.rejectionReason!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Reason text snippet if available
          if (record.reason.isNotEmpty && !record.isRejected)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Reason: ${record.reason}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),

          // Action buttons row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(
                      color: isDark
                          ? AppTheme.darkBorder
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  icon: const Icon(IconlyLight.show, size: 14),
                  label: const Text('Details', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showDetailsModal(record),
                ),
                const Spacer(),

                // Action buttons based on status
                if (_canEdit && record.isPending) ...[
                  // Approve button
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF198754),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text(
                      'Approve',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _confirmApprove(record),
                  ),
                  const SizedBox(width: 8),

                  // Reject button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC3545),
                      side: const BorderSide(color: Color(0xFFDC3545)),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.close, size: 14),
                    label: const Text('Reject', style: TextStyle(fontSize: 12)),
                    onPressed: () => _promptRejectReason(record),
                  ),
                ] else if (_canEdit &&
                    (record.isApproved || record.isPending)) ...[
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFDC3545),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 14),
                    label: const Text(
                      'Cancel Request',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _confirmCancel(record),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  String _formatDateRange(String start, String end) {
    if (start.isEmpty && end.isEmpty) return '-';
    if (start.isEmpty) return _formatDate(end);
    if (end.isEmpty) return _formatDate(start);
    final formattedStart = _formatDate(start);
    final formattedEnd = _formatDate(end);
    if (formattedStart == formattedEnd) {
      return formattedStart;
    }
    return '$formattedStart - $formattedEnd';
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.corporateBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                IconlyLight.calendar,
                size: 48,
                color: AppTheme.corporateBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Absence Requests Found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.hasActiveFilters
                  ? 'Try modifying your search or filter criteria.'
                  : 'There are currently no absence or leave requests recorded.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            if (_controller.hasActiveFilters) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.corporateBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear Filters'),
                onPressed: () {
                  _searchCtrl.clear();
                  _controller.resetFilters();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Details Modal
  void _showDetailsModal(AbsenceRecord record) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(record.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurfaceRaised : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                children: [
                  Text(
                    'Absence Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      record.statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildDetailRow('Operative', record.operativeName, isDark),
              if (record.operativeEmployeeId.isNotEmpty)
                _buildDetailRow(
                  'Employee ID',
                  record.operativeEmployeeId,
                  isDark,
                ),
              _buildDetailRow('Project', record.projectName, isDark),
              _buildDetailRow('Absence Type', record.absenceTypeLabel, isDark),
              _buildDetailRow(
                'Dates',
                _formatDateRange(record.startDate, record.endDate),
                isDark,
              ),
              _buildDetailRow('Duration', record.durationLabel, isDark),
              _buildDetailRow(
                'Partial Day',
                record.isPartialDay ? 'Yes (Half Day)' : 'No (Full Day)',
                isDark,
              ),
              if (record.reason.isNotEmpty)
                _buildDetailRow('Reason', record.reason, isDark),
              if (record.recordedByName.isNotEmpty)
                _buildDetailRow('Recorded By', record.recordedByName, isDark),
              if (record.rejectionReason != null)
                _buildDetailRow(
                  'Rejection Reason',
                  record.rejectionReason!,
                  isDark,
                  isHighlight: true,
                ),
              if (record.notes.isNotEmpty && record.rejectionReason == null)
                _buildDetailRow('Notes', record.notes, isDark),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    bool isDark, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight
                    ? const Color(0xFFDC3545)
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Record Absence Modal
  Future<void> _showRecordAbsenceModal() async {
    final operatives = _controller.options.operatives;
    final projects = _controller.options.projects;

    if (operatives.isEmpty && projects.isEmpty) {
      await _controller.fetchAbsences();
    }
    if (!mounted) return;

    int? selectedOpId;
    int? selectedProjId;
    String selectedType = 'sick';
    DateTimeRange range = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now(),
    );
    bool partialDay = false;
    final reasonCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkSurfaceRaised
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Text(
                      'Record Operative Absence',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Operative Dropdown
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Select Operative *',
                        prefixIcon: Icon(IconlyLight.user_1, size: 20),
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedOpId,
                      isExpanded: true,
                      items: operatives.map((item) {
                        return DropdownMenuItem<int>(
                          value: item['id'] as int,
                          child: Text('${item['name']}'),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setSheetState(() => selectedOpId = val),
                    ),
                    const SizedBox(height: 14),

                    // Project Dropdown
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Project (Optional)',
                        prefixIcon: Icon(IconlyLight.work, size: 20),
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedProjId,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<int>(
                          value: 0,
                          child: Text('Project not selected'),
                        ),
                        ...projects.map((item) {
                          return DropdownMenuItem<int>(
                            value: item['id'] as int,
                            child: Text('${item['name']}'),
                          );
                        }),
                      ],
                      onChanged: (val) =>
                          setSheetState(() => selectedProjId = val),
                    ),
                    const SizedBox(height: 14),

                    // Absence Type Dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Absence Type *',
                        prefixIcon: Icon(Icons.category_outlined, size: 20),
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedType,
                      items: const [
                        DropdownMenuItem(
                          value: 'sick',
                          child: Text('Sick Leave'),
                        ),
                        DropdownMenuItem(
                          value: 'annual_holiday',
                          child: Text('Annual Holiday'),
                        ),
                        DropdownMenuItem(
                          value: 'approved_leave',
                          child: Text('Approved Leave'),
                        ),
                        DropdownMenuItem(
                          value: 'emergency_leave',
                          child: Text('Emergency Leave'),
                        ),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (val) => setSheetState(
                        () => selectedType = val ?? selectedType,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Date Period
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      title: const Text(
                        'Absence Period *',
                        style: TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        '${DateFormat('dd MMM yyyy').format(range.start)} - ${DateFormat('dd MMM yyyy').format(range.end)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(IconlyLight.calendar),
                      onTap: () async {
                        final picked =
                            await CustomDatePickerDialog.showCustomDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                        if (picked != null) {
                          setSheetState(() => range = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Partial Day Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Partial Day (Half Day)'),
                      value: partialDay,
                      onChanged: (val) => setSheetState(() => partialDay = val),
                    ),
                    const SizedBox(height: 8),

                    // Reason Field
                    TextField(
                      controller: reasonCtrl,
                      decoration: const InputDecoration(
                        labelText:
                            'Reason for Absence (Required if type is Other)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Notes Field
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.corporateBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (selectedOpId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please select an operative.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (selectedType == 'other' &&
                                    reasonCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please provide a reason for Other absence.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setSheetState(() => isSubmitting = true);

                                final startStr = DateFormat(
                                  'yyyy-MM-dd',
                                ).format(range.start);
                                final endStr = DateFormat(
                                  'yyyy-MM-dd',
                                ).format(range.end);

                                final result = await _controller.recordAbsence(
                                  operativeId: selectedOpId!,
                                  projectId:
                                      (selectedProjId != null &&
                                          selectedProjId! > 0)
                                      ? selectedProjId
                                      : null,
                                  absenceType: selectedType,
                                  startDate: startStr,
                                  endDate: endStr,
                                  isPartialDay: partialDay,
                                  reason: reasonCtrl.text.trim(),
                                  notes: notesCtrl.text.trim(),
                                );

                                if (sheetCtx.mounted &&
                                    result['success'] == true) {
                                  Navigator.pop(sheetCtx);
                                }

                                if (mounted) {
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result['message']?.toString() ?? '',
                                      ),
                                      backgroundColor: result['success'] == true
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  );
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Absence',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    reasonCtrl.dispose();
    notesCtrl.dispose();
  }

  // Approve Confirmation
  Future<void> _confirmApprove(AbsenceRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Approve Absence Request'),
        content: Text(
          'Are you sure you want to approve the absence request for ${record.operativeName} from ${_formatDate(record.startDate)} to ${_formatDate(record.endDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF198754),
            ),
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await _controller.approveAbsence(record.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? ''),
            backgroundColor: res['success'] == true ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  // Reject Dialog with mandatory reason
  Future<void> _promptRejectReason(AbsenceRecord record) async {
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Reject Absence Request'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rejecting absence for ${record.operativeName}. A rejection reason is mandatory.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: reasonCtrl,
                maxLines: 3,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason *',
                  hintText: 'Enter why this request is being rejected...',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a rejection reason.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC3545),
            ),
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(dlgCtx, true);
              }
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await _controller.rejectAbsence(
        record.id,
        reasonCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? ''),
            backgroundColor: res['success'] == true ? Colors.green : Colors.red,
          ),
        );
      }
    }
    reasonCtrl.dispose();
  }

  // Cancel Confirmation
  Future<void> _confirmCancel(AbsenceRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Cancel Absence Request'),
        content: Text(
          'Are you sure you want to cancel the absence for ${record.operativeName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: const Text('No, keep it'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC3545),
            ),
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: const Text('Yes, Cancel Request'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await _controller.cancelAbsence(record.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? ''),
            backgroundColor: res['success'] == true ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  // Advanced Filter Dialog
  Future<void> _showAdvancedFilterDialog() async {
    String? tempType = _controller.selectedType;
    int? tempProj = _controller.selectedProjectId;
    int? tempOp = _controller.selectedOperativeId;
    String tempSort = _controller.sort;

    await showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Filter Absences'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Project dropdown
                DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(labelText: 'Project'),
                  initialValue: tempProj,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Projects'),
                    ),
                    ..._controller.options.projects.map(
                      (p) => DropdownMenuItem<int?>(
                        value: p['id'] as int,
                        child: Text('${p['name']}'),
                      ),
                    ),
                  ],
                  onChanged: (val) => setDlgState(() => tempProj = val),
                ),
                const SizedBox(height: 12),

                // Operative dropdown
                DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(labelText: 'Operative'),
                  initialValue: tempOp,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Operatives'),
                    ),
                    ..._controller.options.operatives.map(
                      (o) => DropdownMenuItem<int?>(
                        value: o['id'] as int,
                        child: Text('${o['name']}'),
                      ),
                    ),
                  ],
                  onChanged: (val) => setDlgState(() => tempOp = val),
                ),
                const SizedBox(height: 12),

                // Type dropdown
                DropdownButtonFormField<String?>(
                  decoration: const InputDecoration(labelText: 'Absence Type'),
                  initialValue: tempType,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Types')),
                    DropdownMenuItem(value: 'sick', child: Text('Sick Leave')),
                    DropdownMenuItem(
                      value: 'annual_holiday',
                      child: Text('Annual Holiday'),
                    ),
                    DropdownMenuItem(
                      value: 'approved_leave',
                      child: Text('Approved Leave'),
                    ),
                    DropdownMenuItem(
                      value: 'emergency_leave',
                      child: Text('Emergency Leave'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (val) => setDlgState(() => tempType = val),
                ),
                const SizedBox(height: 12),

                // Sorting
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Sort By'),
                  initialValue: tempSort,
                  items: const [
                    DropdownMenuItem(
                      value: 'newest',
                      child: Text('Newest First'),
                    ),
                    DropdownMenuItem(
                      value: 'oldest',
                      child: Text('Oldest First'),
                    ),
                    DropdownMenuItem(
                      value: 'name_asc',
                      child: Text('Operative Name (A-Z)'),
                    ),
                    DropdownMenuItem(
                      value: 'duration_desc',
                      child: Text('Duration (Longest First)'),
                    ),
                  ],
                  onChanged: (val) =>
                      setDlgState(() => tempSort = val ?? tempSort),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _controller.resetFilters();
                Navigator.pop(dlgCtx);
              },
              child: const Text('Reset'),
            ),
            FilledButton(
              onPressed: () {
                _controller.setAdvancedFilters(
                  absenceType: tempType,
                  projectId: tempProj,
                  operativeId: tempOp,
                  sort: tempSort,
                );
                Navigator.pop(dlgCtx);
              },
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
