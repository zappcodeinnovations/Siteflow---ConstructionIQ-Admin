import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helper.dart';
import '../../../../models/admin_guest_model.dart';
import 'admin_guests_controller.dart';
import 'invite_guest_dialog.dart';
import 'guest_details_dialog.dart';

class AdminGuestsView extends StatefulWidget {
  const AdminGuestsView({super.key});

  @override
  State<AdminGuestsView> createState() => _AdminGuestsViewState();
}

class _AdminGuestsViewState extends State<AdminGuestsView> {
  final AdminGuestsController _controller = AdminGuestsController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _controller.fetchGuests();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    _controller.setStatusFilter('active');
  }

  Future<void> _exportGuests() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Exporting guests..."),
          duration: Duration(seconds: 2),
        ),
      );
      final queryParams = <String>[
        'status=${Uri.encodeQueryComponent(_controller.statusFilter)}',
      ];
      if (_searchQuery.isNotEmpty) {
        queryParams.add('search=${Uri.encodeQueryComponent(_searchQuery)}');
      }
      final url =
          '${ApiEndpoints.baseUrl}/admin/guests/export/?${queryParams.join('&')}';
      final response = await ApiClient.get(url);
      if (!mounted) return;
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final directory = await getTemporaryDirectory();
        final file = File(
          '${directory.path}/guests_export_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        );
        await file.writeAsBytes(response.bodyBytes);
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: 'Guests Export'),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to export (${response.statusCode}).")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error exporting guests: $e")));
      }
    }
  }

  Future<void> _showImportGuestsDialog() async {
    PlatformFile? pickedFile;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Import Guests from Excel"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () => _controller.downloadImportTemplate(),
                  icon: const Icon(IconlyLight.download, size: 16),
                  label: const Text("Download Template"),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['xlsx'],
                          );
                          if (result != null && result.files.isNotEmpty) {
                            setDialogState(
                              () => pickedFile = result.files.first,
                            );
                          }
                        },
                  icon: const Icon(Icons.attach_file, size: 16),
                  label: const Text("Choose .xlsx File"),
                ),
                const SizedBox(height: 6),
                Text(
                  pickedFile?.name ?? "No file chosen",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: (isSubmitting || pickedFile?.path == null)
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        final result = await _controller.importGuestsExcel(
                          pickedFile!.path!,
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (!mounted) return;
                        final data = result['data'] as Map<String, dynamic>?;
                        final errors = (data?['errors'] as List?) ?? [];
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              errors.isNotEmpty
                                  ? "${result['message']} ${errors.length} row(s) skipped."
                                  : result['message'] ?? '',
                            ),
                            backgroundColor: result['success'] == true
                                ? Colors.green
                                : Colors.red,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Import"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmConvertToMember(AdminGuest guest) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogSurface = isDark ? AppTheme.darkSurfaceRaised : Colors.white;
    final dialogText = isDark ? AppTheme.darkText : const Color(0xFF0F2C4A);
    final mutedText = isDark ? AppTheme.darkMuted : Colors.grey.shade600;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogSurface,
        title: Row(
          children: [
            const Icon(IconlyLight.swap, color: Color(0xFF0D6EFD)),
            const SizedBox(width: 10),
            Text('Convert to Member', style: TextStyle(color: dialogText)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign product access',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: dialogText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${guest.displayName} (${guest.email})',
                style: TextStyle(color: mutedText, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkSurface
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.darkBorder
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D6EFD).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        IconlyLight.category,
                        color: Color(0xFF0D6EFD),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Euroside',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: dialogText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Project operations access',
                            style: TextStyle(fontSize: 12, color: mutedText),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(
                          alpha: isDark ? 0.18 : 0.10,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Available',
                        style: TextStyle(
                          color: isDark
                              ? Colors.green.shade300
                              : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'This will convert the guest to an Operative and assign Euroside member access.',
                style: TextStyle(fontSize: 12, color: mutedText, height: 1.35),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D6EFD),
              foregroundColor: Colors.white,
            ),
            child: const Text('Convert to Member'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await _controller.convertToMember(guest.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? ''),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => InviteGuestDialog(controller: _controller),
    );
  }

  void _deleteGuest(AdminGuest guest) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Guest"),
        content: Text("Are you sure you want to remove ${guest.email}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final result = await _controller.deleteGuest(guest.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message']),
                  backgroundColor: result['success'] == true
                      ? Colors.green
                      : Colors.red,
                ),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showGuestDetails(AdminGuest guest) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) =>
          GuestDetailsDialog(guestId: guest.id, controller: _controller),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: FadeTransition(opacity: animation, child: child),
          ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF0F2C4A),
      const Color(0xFF0D6EFD),
      const Color(0xFF6C757D),
      Colors.teal,
      Colors.indigo,
    ];
    int hash = name.codeUnits.fold(0, (prev, curr) => prev + curr);
    return colors[hash % colors.length];
  }

  Widget _buildGuestCard(
    AdminGuest guest, {
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final initials = guest.displayName.isNotEmpty
        ? guest.displayName.substring(0, 2).toUpperCase()
        : "G";
    final avatarColor = _getAvatarColor(guest.displayName);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showGuestDetails(guest),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: avatarColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        if (guest.isActive)
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guest.displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            guest.email,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "GUEST",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        IconlyLight.more_circle,
                        color: Colors.grey,
                      ),
                      onSelected: (val) {
                        if (val == 'view') _showGuestDetails(guest);
                        if (val == 'convert') _confirmConvertToMember(guest);
                        if (val == 'delete') _deleteGuest(guest);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(
                                IconlyLight.profile,
                                size: 16,
                                color: Color(0xFF0D6EFD),
                              ),
                              SizedBox(width: 8),
                              Text('View Profile'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'convert',
                          child: Row(
                            children: [
                              Icon(IconlyLight.swap, size: 16),
                              SizedBox(width: 8),
                              Text('Convert to Member'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                IconlyLight.delete,
                                size: 16,
                                color: Colors.red,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Remove Guest',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 32,
                  runSpacing: 16,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "USERNAME",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          guest.username.isNotEmpty ? guest.username : "N/A",
                          style: TextStyle(fontSize: 14, color: textColor),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "PHONE",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          guest.phone.isNotEmpty ? guest.phone : "N/A",
                          style: TextStyle(fontSize: 14, color: textColor),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PROJECTS',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${guest.projectCount} ${guest.projectCount == 1 ? 'Project' : 'Projects'}',
                          style: TextStyle(fontSize: 14, color: textColor),
                        ),
                        if (guest.projects.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              guest.projectSummary,
                              style: TextStyle(
                                fontSize: 11,
                                color: subtitleColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSegmentedControl(bool isDark) {
    final selectedStatus = _controller.statusFilter;
    final inactiveText = isDark ? AppTheme.darkMuted : const Color(0xFF64748B);

    Widget buildTab({
      required String status,
      required String label,
      required int count,
      required IconData icon,
    }) {
      final isSelected = selectedStatus == status;
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _controller.setStatusFilter(status),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0D6EFD)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: isSelected ? Colors.white : inactiveText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : inactiveText,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.22)
                          : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: isSelected ? Colors.white : inactiveText,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceRaised : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          buildTab(
            status: 'active',
            label: 'Active',
            count: _controller.activeCount,
            icon: IconlyLight.user_1,
          ),
          const SizedBox(width: 4),
          buildTab(
            status: 'pending',
            label: 'Pending',
            count: _controller.invitedCount,
            icon: IconlyLight.send,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingGuestCard(
    AdminGuest guest, {
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final statusLabel = guest.inviteStatus.isEmpty
        ? 'Pending'
        : '${guest.inviteStatus[0].toUpperCase()}${guest.inviteStatus.substring(1)}';
    final sentAt = guest.sentAt.isNotEmpty ? guest.sentAt : guest.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D6EFD).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    IconlyLight.message,
                    color: Color(0xFF0D6EFD),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guest.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        guest.email,
                        style: TextStyle(fontSize: 12, color: subtitleColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(
                            alpha: isDark ? 0.20 : 0.13,
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.amber.shade200
                                : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 24,
              runSpacing: 10,
              children: [
                _buildPendingDetail(
                  label: 'PROJECTS',
                  value:
                      '${guest.projectCount} ${guest.projectCount == 1 ? 'Project' : 'Projects'}',
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                ),
                _buildPendingDetail(
                  label: 'SENT',
                  value: sentAt.isEmpty
                      ? '-'
                      : DateHelper.formatToLocal(sentAt),
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                ),
              ],
            ),
            if (guest.projects.isNotEmpty) ...[
              const SizedBox(height: 9),
              Text(
                guest.projects.map((project) => project.label).join(', '),
                style: TextStyle(color: subtitleColor, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPendingDetail({
    required String label,
    required String value,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: subtitleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final headerBg = isDark ? AppTheme.darkSurfaceRaised : Colors.grey.shade50;
    final headerTitle = isDark ? AppTheme.darkText : const Color(0xFF0F2C4A);
    final textColor = isDark ? AppTheme.darkText : Colors.black87;
    final subtitleColor = isDark ? AppTheme.darkMuted : Colors.grey.shade600;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade300;
    final searchFillColor = isDark ? AppTheme.darkSurface : Colors.white;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : const Color(0xFFF8FAFC),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final isPendingTab = _controller.statusFilter == 'pending';
          final filteredGuests = _controller.guests.where((guest) {
            if (_searchQuery.isEmpty) return true;
            return guest.displayName.toLowerCase().contains(_searchQuery) ||
                guest.email.toLowerCase().contains(_searchQuery) ||
                guest.projectSummary.toLowerCase().contains(_searchQuery) ||
                guest.projects.any(
                  (project) =>
                      project.label.toLowerCase().contains(_searchQuery),
                );
          }).toList();
          final summaryTotal =
              _controller.activeCount + _controller.invitedCount;
          final totalGuests = summaryTotal > 0
              ? summaryTotal
              : _controller.guests.length;

          return Column(
            children: [
              Container(
                color: headerBg,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Guests\nDirectory',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: headerTitle,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$totalGuests Guests Total',
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6EFD),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _showInviteDialog,
                          icon: const Icon(IconlyLight.add_user, size: 18),
                          label: const Text(
                            'Invite Guest',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: isPendingTab
                            ? 'Search pending guests...'
                            : 'Search guests, projects...',
                        hintStyle: TextStyle(color: subtitleColor),
                        prefixIcon: Icon(
                          IconlyLight.search,
                          color: subtitleColor,
                        ),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  size: 18,
                                  color: subtitleColor,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                        filled: true,
                        fillColor: searchFillColor,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF0D6EFD),
                          ),
                        ),
                      ),
                      onChanged: (value) => setState(
                        () => _searchQuery = value.toLowerCase().trim(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _exportGuests,
                            icon: const Icon(IconlyLight.download, size: 16),
                            label: Text(
                              isPendingTab ? 'Export Pending' : 'Export Excel',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Import guests from Excel',
                          onPressed: _showImportGuestsDialog,
                          icon: Icon(IconlyLight.upload, color: subtitleColor),
                        ),
                        IconButton(
                          tooltip: 'Reset filters',
                          onPressed: _resetFilters,
                          icon: Icon(Icons.refresh, color: subtitleColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusSegmentedControl(isDark),
              Expanded(
                child: _controller.isLoading && _controller.guests.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _controller.errorMessage != null &&
                          _controller.guests.isEmpty
                    ? Center(
                        child: Text(
                          _controller.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : filteredGuests.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPendingTab
                                    ? IconlyLight.send
                                    : IconlyLight.user_1,
                                size: 48,
                                color: subtitleColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isPendingTab
                                    ? 'No pending guest invitations found.'
                                    : 'No active guests found.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: subtitleColor),
                              ),
                              if (isPendingTab) ...[
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  onPressed: _showInviteDialog,
                                  icon: const Icon(
                                    IconlyLight.add_user,
                                    size: 16,
                                  ),
                                  label: const Text('Invite Guest'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: filteredGuests.length,
                        itemBuilder: (context, index) => isPendingTab
                            ? _buildPendingGuestCard(
                                filteredGuests[index],
                                isDark: isDark,
                                cardColor: cardColor,
                                borderColor: borderColor,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              )
                            : _buildGuestCard(
                                filteredGuests[index],
                                isDark: isDark,
                                cardColor: cardColor,
                                borderColor: borderColor,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                              ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
