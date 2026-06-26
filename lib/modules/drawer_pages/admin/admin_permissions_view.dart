import 'package:flutter/material.dart';
import '../../../../models/admin_permission_model.dart';
import 'admin_permissions_controller.dart';
import 'create_role_dialog.dart';
import '../../../../core/widgets/shimmer_loading.dart';

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

  String _formatMenuTitle(String key) {
    return key.split('_').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ');
  }

  IconData _getMenuIcon(String key) {
    switch (key) {
      case 'dashboard': return Icons.dashboard_outlined;
      case 'clients': return Icons.people_outline;
      case 'projects': return Icons.folder_open;
      case 'tasks': return Icons.task_outlined;
      case 'job_sheets': return Icons.assignment_outlined;
      case 'productivity': return Icons.bar_chart;
      case 'timesheets': return Icons.access_time;
      case 'authority_attendance': return Icons.admin_panel_settings_outlined;
      case 'library': return Icons.library_books_outlined;
      default: return Icons.widgets_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Permission Management", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F2C4A))),
                const SizedBox(height: 4),
                Text("Create roles and configure permissions for custom roles and system roles.", style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F2C4A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
              onPressed: _showCreateRoleDialog,
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text("Create Role", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Role Selector Bar
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Select Role", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<AdminRole>(
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16)),
                          value: _controller.selectedRole,
                          hint: const Text("Select a role"),
                          items: _controller.roles.map((r) {
                            return DropdownMenuItem<AdminRole>(
                              value: r,
                              child: Text(r.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              _controller.selectRole(val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D6EFD),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _controller.selectedRole == null || _controller.isSaving 
                            ? null 
                            : () async {
                                final result = await _controller.savePermissions();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(result['message']), backgroundColor: result['success'] ? Colors.green : Colors.red),
                                  );
                                }
                              },
                        icon: _controller.isSaving 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
                        label: const Text("Save Permissions", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              );
            }
          ),
        ),
        const SizedBox(height: 24),

        // Permissions Table
        Expanded(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_controller.selectedRole == null) {
                return Center(
                  child: Text("Please select a role above to configure permissions.", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                      child: Row(
                        children: [
                          Icon(Icons.shield_outlined, color: Colors.grey.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text("Configuring permissions for role: ${_controller.selectedRole!.name}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    
                    // Table Header
                    Container(
                      color: const Color(0xFF0F2C4A),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          const Expanded(flex: 4, child: Text("SIDEBAR MENU", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                          Expanded(flex: 1, child: Center(child: Text("VIEW", style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 11)))),
                          Expanded(flex: 1, child: Center(child: Text("CREATE", style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 11)))),
                          Expanded(flex: 1, child: Center(child: Text("EDIT", style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 11)))),
                          Expanded(flex: 1, child: Center(child: Text("DELETE", style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold, fontSize: 11)))),
                        ],
                      ),
                    ),

                    // Table Body
                    Expanded(
                      child: _controller.isLoading
                          ? const ShimmerLoadingList()
                          : _controller.errorMessage != null
                              ? Center(child: Text(_controller.errorMessage!, style: const TextStyle(color: Colors.red)))
                              : ListView.separated(
                                  itemCount: _controller.permissions.length,
                                  separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                                  itemBuilder: (context, index) {
                                    final p = _controller.permissions[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 4, 
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                                  child: Icon(_getMenuIcon(p.menuKey), size: 16, color: Colors.blue.shade700),
                                                ),
                                                const SizedBox(width: 16),
                                                Text(_formatMenuTitle(p.menuKey), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                              ],
                                            )
                                          ),
                                          Expanded(
                                            flex: 1, 
                                            child: Center(
                                              child: Checkbox(value: p.canView, onChanged: (v) => _controller.updatePermission(index, 'view', v ?? false)),
                                            )
                                          ),
                                          Expanded(
                                            flex: 1, 
                                            child: Center(
                                              child: Checkbox(value: p.canCreate, onChanged: (v) => _controller.updatePermission(index, 'create', v ?? false)),
                                            )
                                          ),
                                          Expanded(
                                            flex: 1, 
                                            child: Center(
                                              child: Checkbox(value: p.canEdit, onChanged: (v) => _controller.updatePermission(index, 'edit', v ?? false)),
                                            )
                                          ),
                                          Expanded(
                                            flex: 1, 
                                            child: Center(
                                              child: Checkbox(value: p.canDelete, onChanged: (v) => _controller.updatePermission(index, 'delete', v ?? false)),
                                            )
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
