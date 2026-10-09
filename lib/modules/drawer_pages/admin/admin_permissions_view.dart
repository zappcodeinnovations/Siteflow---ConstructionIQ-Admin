import 'package:flutter/material.dart';
import '../../../../models/admin_permission_model.dart';
import 'admin_permissions_controller.dart';
import 'create_role_dialog.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:iconly/iconly.dart';

class AdminPermissionsView extends StatefulWidget {
  const AdminPermissionsView({super.key});

  @override
  State<AdminPermissionsView> createState() => _AdminPermissionsViewState();
}

class _AdminPermissionsViewState extends State<AdminPermissionsView> {
  final AdminPermissionsController _controller = AdminPermissionsController();

  @override
  void initState() {
    super.initState();
    _controller.initializeData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showCreateRoleDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateRoleDialog(controller: _controller),
    );
  }

  void _showRenameRoleDialog(AdminRole role) {
    final nameController = TextEditingController(text: role.name);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Rename Role"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Role name", border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(dialogContext);
              final result = await _controller.renameRole(role, newName);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? ''),
                  backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRole(AdminRole role) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Role"),
        content: Text('Delete the role "${role.name}"? Users must be reassigned off it first.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final result = await _controller.deleteRole(role);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? ''),
                  backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getMenuIcon(String key) {
    final normalized = key.toLowerCase().replaceAll('/', '_').replaceAll(' ', '_');
    switch (normalized) {
      case 'dashboard':
        return IconlyLight.category;
      case 'clients':
        return IconlyLight.user_1;
      case 'projects':
        return IconlyLight.folder;
      case 'tasks':
        return IconlyLight.tick_square;
      case 'job_sheets':
      case 'daily_reports':
        return IconlyLight.document;
      case 'weekly_diary':
      case 'manager_attendance':
      case 'authority_attendance':
        return IconlyLight.calendar;
      case 'productivity':
        return IconlyLight.chart;
      case 'timesheets':
        return IconlyLight.time_circle;
      case 'library':
        return IconlyLight.bookmark;
      case 'notifications':
        return IconlyLight.notification;
      case 'settings':
      case 'settings_teams':
        return IconlyLight.setting;
      case 'admin':
        return IconlyLight.shield_done;
      default:
        return IconlyLight.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? AppTheme.darkText : const Color(0xFF0F2C4A);
    final subtitleColor = isDark ? AppTheme.darkMuted : Colors.grey.shade600;
    final borderColor = isDark ? AppTheme.darkBorder : Colors.grey.shade200;
    final dropdownFillColor = isDark ? AppTheme.darkSurfaceRaised : Colors.grey.shade50;

    return LayoutBuilder(
      builder: (context, screenConstraints) {
        final isMobile = screenConstraints.maxWidth < 600;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Permission Management",
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Create roles and configure access permissions cleanly.",
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F2C4A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 20,
                        vertical: isMobile ? 10 : 14,
                      ),
                      elevation: 0,
                    ),
                    onPressed: _showCreateRoleDialog,
                    icon: const Icon(
                      IconlyLight.plus,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: isMobile
                        ? const SizedBox.shrink()
                        : const Text(
                            "Create Role",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Role Selector Card
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    Widget roleDropdown = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Active Role",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: subtitleColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<AdminRole>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: dropdownFillColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          value: _controller.selectedRole,
                          hint: const Text("Select a role"),
                          items: _controller.roles.map((r) {
                            return DropdownMenuItem<AdminRole>(
                              value: r,
                              child: Row(
                                children: [
                                  Icon(
                                    r.isSystem
                                        ? IconlyLight.shield_done
                                        : IconlyLight.user,
                                    size: 14,
                                    color: r.isSystem
                                        ? Colors.green
                                        : Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      r.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) _controller.selectRole(val);
                          },
                        ),
                        if (_controller.selectedRole != null && !_controller.selectedRole!.isSystem)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showRenameRoleDialog(_controller.selectedRole!),
                                  icon: const Icon(IconlyLight.edit, size: 16),
                                  label: const Text("Rename"),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _confirmDeleteRole(_controller.selectedRole!),
                                  icon: const Icon(IconlyLight.delete, size: 16, color: Colors.red),
                                  label: const Text("Delete", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );

                    Widget actionButton = _controller.selectedRole != null
                        ? ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D6EFD),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _controller.isSaving
                                ? null
                                : () async {
                                    final result = await _controller
                                        .savePermissions();
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            result['message'] ?? 'Permissions saved.',
                                          ),
                                          backgroundColor:
                                              result['success'] == true
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            icon: _controller.isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    IconlyLight.tick_square,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                            label: const Text(
                              "Save Permissions",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const SizedBox.shrink();

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          roleDropdown,
                          const SizedBox(height: 16),
                          actionButton,
                        ],
                      );
                    } else {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(flex: 2, child: roleDropdown),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: actionButton,
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Permissions List
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  if (_controller.selectedRole == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            IconlyLight.shield_done,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Fetching roles...",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (_controller.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (_controller.errorMessage != null &&
                      _controller.permissions.isEmpty) {
                    return Center(
                      child: Text(
                        _controller.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _controller.permissions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = _controller.permissions[index];

                      return Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.01),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 20,
                          vertical: 16,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmallScreen = constraints.maxWidth < 600;

                            Widget titleWidget = Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getMenuIcon(p.menuKey),
                                    size: 20,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    p.label.isNotEmpty ? p.label : p.menuKey,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: textColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );

                            Widget checkboxesWidget = SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: isSmallScreen
                                    ? MainAxisAlignment.start
                                    : MainAxisAlignment.end,
                                children: [
                                  _buildCheckboxControl(
                                    label: "View",
                                    value: p.canView,
                                    onChanged: (v) => _controller.updatePermission(
                                      index,
                                      'view',
                                      v ?? false,
                                    ),
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 6),
                                  _buildCheckboxControl(
                                    label: "Create",
                                    value: p.canCreate,
                                    onChanged: (v) => _controller.updatePermission(
                                      index,
                                      'create',
                                      v ?? false,
                                    ),
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 6),
                                  _buildCheckboxControl(
                                    label: "Edit",
                                    value: p.canEdit,
                                    onChanged: (v) => _controller.updatePermission(
                                      index,
                                      'edit',
                                      v ?? false,
                                    ),
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 6),
                                  _buildCheckboxControl(
                                    label: "Delete",
                                    value: p.canDelete,
                                    onChanged: (v) => _controller.updatePermission(
                                      index,
                                      'delete',
                                      v ?? false,
                                    ),
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                            );

                            if (isSmallScreen) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  titleWidget,
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(height: 1),
                                  ),
                                  checkboxesWidget,
                                ],
                              );
                            } else {
                              return Row(
                                children: [
                                  Expanded(flex: 2, child: titleWidget),
                                  Expanded(flex: 3, child: checkboxesWidget),
                                ],
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheckboxControl({
    required String label,
    required bool value,
    required Function(bool?)? onChanged,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: value ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? color.withValues(alpha: 0.3) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: value ? color : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            height: 20,
            width: 20,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: color,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
