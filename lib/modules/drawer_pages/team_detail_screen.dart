import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';
import 'admin_team_controller.dart';

class TeamDetailScreen extends StatefulWidget {
  final int teamId;
  final AdminTeamController controller;

  const TeamDetailScreen({super.key, required this.teamId, required this.controller});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _timezoneController = TextEditingController();
  TimeOfDay? _shiftStart;
  TimeOfDay? _shiftEnd;
  int? _selectedLeadId;
  Set<int> _selectedProjectIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
  }

  String? _formatTime(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await widget.controller.fetchTeamDetail(widget.teamId);
    if (!mounted) return;
    setState(() {
      _data = data;
      _isLoading = false;
      if (data != null) {
        _nameController.text = data['name']?.toString() ?? '';
        _nicknameController.text = data['nickname']?.toString() ?? '';
        _timezoneController.text = data['shift_timezone']?.toString() ?? '';
        _shiftStart = _parseTime(data['shift_start_time']?.toString());
        _shiftEnd = _parseTime(data['shift_end_time']?.toString());
        _selectedLeadId = data['lead_id'];
        _selectedProjectIds = ((data['selected_project_ids'] as List?) ?? [])
            .map((e) => e is int ? e : int.tryParse(e.toString()) ?? -1)
            .where((e) => e != -1)
            .toSet();
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final payload = <String, dynamic>{
      "name": _nameController.text.trim(),
      "nickname": _nicknameController.text.trim(),
      "shift_start_time": _formatTime(_shiftStart) ?? '',
      "shift_end_time": _formatTime(_shiftEnd) ?? '',
      "shift_timezone": _timezoneController.text.trim(),
      "lead_id": _selectedLeadId?.toString() ?? '',
      "project_ids": _selectedProjectIds.toList(),
    };
    final result = await widget.controller.updateTeam(widget.teamId, payload);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
    );
    if (result['success'] == true) {
      await _load();
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Team"),
        content: Text('Delete "${_data?['display_name'] ?? _data?['name'] ?? 'this team'}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await widget.controller.deleteTeam(widget.teamId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
    );
    if (result['success'] == true) {
      Navigator.pop(context);
    }
  }

  Future<void> _removeMember(int memberId, String name) async {
    final result = await widget.controller.removeMember(widget.teamId, memberId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
    );
    if (result['success'] == true) await _load();
  }

  Future<void> _showAddMembersDialog() async {
    final available = ((_data?['available_members'] as List?) ?? []).cast<Map>();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No available operatives to add.")),
      );
      return;
    }
    final selected = <int>{};
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Members"),
          content: SizedBox(
            width: 360,
            height: 400,
            child: ListView(
              children: available.map((m) {
                final id = m['id'] as int;
                final name = m['name']?.toString() ?? 'Unknown';
                return CheckboxListTile(
                  value: selected.contains(id),
                  title: Text(name),
                  subtitle: Text(m['employee_id']?.toString() ?? ''),
                  onChanged: (val) {
                    setDialogState(() {
                      if (val == true) {
                        selected.add(id);
                      } else {
                        selected.remove(id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: selected.isEmpty
                  ? null
                  : () async {
                      Navigator.pop(dialogContext);
                      final result = await widget.controller.assignMembers(widget.teamId, selected.toList());
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                      );
                      if (result['success'] == true) await _load();
                    },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_data?['display_name']?.toString() ?? 'Team Details'),
        actions: [
          IconButton(
            icon: const Icon(IconlyLight.delete, color: Colors.red),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text("Team not found."))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Team Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: "Team Name", border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(labelText: "Nickname", border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      if (_data!.containsKey('team_lead_choices'))
                        DropdownButtonFormField<int?>(
                          initialValue: _selectedLeadId,
                          decoration: const InputDecoration(labelText: "Team Lead", border: OutlineInputBorder()),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text("No lead")),
                            ...((_data!['team_lead_choices'] as List?) ?? []).cast<Map>().map(
                                  (l) => DropdownMenuItem<int?>(value: l['id'] as int, child: Text(l['name']?.toString() ?? '')),
                                ),
                          ],
                          onChanged: (val) => setState(() => _selectedLeadId = val),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(_shiftStart == null ? 'Shift start' : 'Start: ${_formatTime(_shiftStart)}'),
                              trailing: const Icon(IconlyLight.time_circle),
                              onTap: () async {
                                final picked = await showTimePicker(context: context, initialTime: _shiftStart ?? const TimeOfDay(hour: 8, minute: 0));
                                if (picked != null) setState(() => _shiftStart = picked);
                              },
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(_shiftEnd == null ? 'Shift end' : 'End: ${_formatTime(_shiftEnd)}'),
                              trailing: const Icon(IconlyLight.time_circle),
                              onTap: () async {
                                final picked = await showTimePicker(context: context, initialTime: _shiftEnd ?? const TimeOfDay(hour: 17, minute: 0));
                                if (picked != null) setState(() => _shiftEnd = picked);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _timezoneController,
                        decoration: const InputDecoration(
                          labelText: "Shift Timezone (IANA, e.g. Europe/Berlin)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD)),
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Save Changes", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Members", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                          if (_data!.containsKey('available_members'))
                            TextButton.icon(
                              onPressed: _showAddMembersDialog,
                              icon: const Icon(IconlyLight.plus, size: 16),
                              label: const Text("Add"),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                        ),
                        child: Column(
                          children: ((_data!['assigned_members'] as List?) ?? []).cast<Map>().isEmpty
                              ? [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text("No members assigned.", style: TextStyle(color: subtitleColor)),
                                  ),
                                ]
                              : ((_data!['assigned_members'] as List).cast<Map>()).map((m) {
                                  return ListTile(
                                    title: Text(m['name']?.toString() ?? 'Unknown'),
                                    subtitle: Text(m['employee_id']?.toString() ?? ''),
                                    trailing: IconButton(
                                      icon: const Icon(IconlyLight.delete, color: Colors.red, size: 18),
                                      onPressed: () => _removeMember(m['id'] as int, m['name']?.toString() ?? ''),
                                    ),
                                  );
                                }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
