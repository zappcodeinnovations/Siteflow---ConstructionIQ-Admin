import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';
import 'admin_team_controller.dart';

class TeamDetailScreen extends StatefulWidget {
  final int teamId;
  final AdminTeamController controller;

  const TeamDetailScreen(
      {super.key, required this.teamId, required this.controller});

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
  final _memberSearchController = TextEditingController();

  TimeOfDay? _shiftStart;
  TimeOfDay? _shiftEnd;
  int? _selectedLeadId;
  Set<int> _selectedProjectIds = {};

  // Inline member add state
  Set<int> _pendingMemberIds = {};
  String _memberSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
    _memberSearchController.addListener(() {
      setState(() => _memberSearchQuery = _memberSearchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _timezoneController.dispose();
    _memberSearchController.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0);
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return '--:--';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String? _formatTime24(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  // ─── Data ───────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await widget.controller.fetchTeamDetail(widget.teamId);
    if (!mounted) return;
    setState(() {
      _data = data;
      _isLoading = false;
      _pendingMemberIds = {};
      _memberSearchController.clear();
      if (data != null) {
        _nameController.text = data['name']?.toString() ?? '';
        _nicknameController.text = data['nickname']?.toString() ?? '';
        _timezoneController.text = data['shift_timezone']?.toString() ?? '';
        _shiftStart = _parseTime(data['shift_start_time']?.toString());
        _shiftEnd = _parseTime(data['shift_end_time']?.toString());
        // Validate lead_id exists in choices to avoid DropdownButtonFormField crash
        final rawLeadId = data['lead_id'];
        final leadChoices = ((data['team_lead_choices'] as List?) ?? [])
            .cast<Map>();
        final validLeadIds =
            leadChoices.map((l) => l['id']).whereType<int>().toSet();
        _selectedLeadId = (rawLeadId is int && validLeadIds.contains(rawLeadId))
            ? rawLeadId
            : null;

        _selectedProjectIds =
            ((data['selected_project_ids'] as List?) ?? [])
                .map((e) =>
                    e is int ? e : int.tryParse(e.toString()) ?? -1)
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
      "shift_start_time": _formatTime24(_shiftStart) ?? '',
      "shift_end_time": _formatTime24(_shiftEnd) ?? '',
      "shift_timezone": _timezoneController.text.trim(),
      "lead_id": _selectedLeadId?.toString() ?? '',
      "project_ids": _selectedProjectIds.toList(),
    };
    final result =
        await widget.controller.updateTeam(widget.teamId, payload);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? ''),
        backgroundColor:
            result['success'] == true ? Colors.green : Colors.red,
      ),
    );
    if (result['success'] == true) await _load();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Team"),
        content: Text(
            'Delete "${_data?['display_name'] ?? _data?['name'] ?? 'this team'}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Delete",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result =
        await widget.controller.deleteTeam(widget.teamId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? ''),
        backgroundColor:
            result['success'] == true ? Colors.green : Colors.red,
      ),
    );
    if (result['success'] == true) Navigator.pop(context);
  }

  Future<void> _removeMember(int memberId) async {
    final result =
        await widget.controller.removeMember(widget.teamId, memberId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? ''),
        backgroundColor:
            result['success'] == true ? Colors.green : Colors.red,
      ),
    );
    if (result['success'] == true) await _load();
  }

  Future<void> _addSelectedMembers() async {
    if (_pendingMemberIds.isEmpty) return;
    final result = await widget.controller
        .assignMembers(widget.teamId, _pendingMemberIds.toList());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? ''),
        backgroundColor:
            result['success'] == true ? Colors.green : Colors.red,
      ),
    );
    if (result['success'] == true) await _load();
  }

  // ─── Time picker widget ─────────────────────────────────────────────────────

  Widget _timePicker({
    required String label,
    required TimeOfDay? value,
    required void Function(TimeOfDay) onPicked,
    required bool isDark,
  }) {
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade400;
    final labelColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);

    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value ??
              (label.contains('Start')
                  ? const TimeOfDay(hour: 8, minute: 0)
                  : const TimeOfDay(hour: 17, minute: 0)),
        );
        if (picked != null) setState(() => onPicked(picked));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color: labelColor,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(value),
                    style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(IconlyLight.time_circle,
                size: 20,
                color: isDark ? Colors.white54 : Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor =
        isDark ? Colors.white : const Color(0xFF0F2C4A);
    final subtitleColor =
        isDark ? Colors.white70 : Colors.grey.shade600;
    final dividerColor =
        isDark ? Colors.white12 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : const Color(0xFFF8FAFC),
      // No delete icon in AppBar — moved to bottom
      appBar: AppBar(
        title: Text(
            _data?['display_name']?.toString() ?? 'Team Details'),
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
                      // ── Team Details card ──────────────────────────────
                      _sectionHeader("Team Details", textColor),
                      const SizedBox(height: 16),

                      // Team Name
                      TextField(
                        controller: _nameController,
                        decoration: _inputDeco("Team Name *"),
                      ),
                      const SizedBox(height: 12),

                      // Nickname
                      TextField(
                        controller: _nicknameController,
                        decoration: _inputDeco("Nickname"),
                      ),
                      const SizedBox(height: 12),

                      // Team Lead
                      if (_data!.containsKey('team_lead_choices'))
                        DropdownButtonFormField<int?>(
                          initialValue: _selectedLeadId,
                          decoration: _inputDeco("Team Lead"),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<int?>(
                                value: null, child: Text("No lead")),
                            ...((_data!['team_lead_choices'] as List?) ??
                                    [])
                                .cast<Map>()
                                .map((l) => DropdownMenuItem<int?>(
                                      value: l['id'] as int,
                                      child: Text(
                                          l['name']?.toString() ?? ''),
                                    )),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedLeadId = val),
                        ),
                      const SizedBox(height: 12),

                      // ── Associated Projects ────────────────────────────
                      if (_data!.containsKey('all_projects') &&
                          (_data!['all_projects'] as List?)?.isNotEmpty ==
                              true) ...[
                        Text("Associated Project(s)",
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: subtitleColor)),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                            color: cardColor,
                          ),
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: ListView(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            children: ((_data!['all_projects'] as List)
                                    .cast<Map>())
                                .map((p) {
                              final id = p['id'] as int;
                              final name = p['name']?.toString() ?? '';
                              return CheckboxListTile(
                                dense: true,
                                value:
                                    _selectedProjectIds.contains(id),
                                title: Text(name,
                                    style:
                                        TextStyle(color: textColor)),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedProjectIds.add(id);
                                    } else {
                                      _selectedProjectIds.remove(id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── Shift Times ────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _timePicker(
                              label: "Shift Start Time",
                              value: _shiftStart,
                              onPicked: (t) => _shiftStart = t,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _timePicker(
                              label: "Shift End Time",
                              value: _shiftEnd,
                              onPicked: (t) => _shiftEnd = t,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Shift Timezone ────────────────────────────────
                      TextField(
                        controller: _timezoneController,
                        decoration: _inputDeco(
                          "Shift Timezone",
                          hint: "e.g. Europe/Berlin",
                          helperText:
                              "IANA timezone the site's shift times are in. Leave blank to use each operative's own clock-in timezone.",
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Save Changes ───────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6EFD),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2))
                              : const Text("Save Changes",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Members section ────────────────────────────────
                      _sectionHeader("Members", textColor),
                      const SizedBox(height: 4),

                      // Assigned count hint
                      Builder(builder: (_) {
                        final assigned =
                            ((_data!['assigned_members'] as List?) ??
                                    [])
                                .cast<Map>();
                        return Text(
                          assigned.isEmpty
                              ? "You have 0 members in this team.\nAdd your first operative to this team."
                              : "You have ${assigned.length} member${assigned.length == 1 ? '' : 's'} in this team.",
                          style: TextStyle(
                              color: subtitleColor, fontSize: 13),
                        );
                      }),
                      const SizedBox(height: 12),

                      // ── Assigned members list ──────────────────────────
                      Builder(builder: (_) {
                        final assigned =
                            ((_data!['assigned_members'] as List?) ??
                                    [])
                                .cast<Map>();
                        if (assigned.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: dividerColor),
                          ),
                          child: Column(
                            children: assigned.map((m) {
                              return ListTile(
                                title: Text(
                                    m['name']?.toString() ?? 'Unknown',
                                    style:
                                        TextStyle(color: textColor)),
                                subtitle: Text(
                                    m['employee_id']?.toString() ?? '',
                                    style: TextStyle(
                                        color: subtitleColor,
                                        fontSize: 12)),
                                trailing: IconButton(
                                  icon: const Icon(IconlyLight.delete,
                                      color: Colors.red, size: 18),
                                  onPressed: () =>
                                      _removeMember(m['id'] as int),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }),

                      // ── Add Members (inline search + checklist) ────────
                      if (_data!.containsKey('available_members')) ...[
                        Builder(builder: (_) {
                          final available =
                              ((_data!['available_members'] as List?) ??
                                      [])
                                  .cast<Map>();
                          final filtered = available
                              .where((m) =>
                                  _memberSearchQuery.isEmpty ||
                                  (m['name']?.toString() ?? '')
                                      .toLowerCase()
                                      .contains(_memberSearchQuery) ||
                                  (m['employee_id']?.toString() ?? '')
                                      .toLowerCase()
                                      .contains(_memberSearchQuery))
                              .toList();

                          return Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text("Search Members",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: subtitleColor)),
                              const SizedBox(height: 6),
                              // Search box
                              TextField(
                                controller: _memberSearchController,
                                decoration: _inputDeco(
                                  "Search by name or email",
                                ).copyWith(
                                  prefixIcon: const Icon(
                                      IconlyLight.search,
                                      size: 18),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 12),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text("Add Members",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: subtitleColor)),
                              const SizedBox(height: 6),
                              // Operative checklist
                              Container(
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border:
                                      Border.all(color: dividerColor),
                                ),
                                constraints:
                                    const BoxConstraints(maxHeight: 300),
                                child: available.isEmpty
                                    ? Padding(
                                        padding:
                                            const EdgeInsets.all(16),
                                        child: Text(
                                            "No available operatives.",
                                            style: TextStyle(
                                                color: subtitleColor)),
                                      )
                                    : filtered.isEmpty
                                        ? Padding(
                                            padding:
                                                const EdgeInsets.all(
                                                    16),
                                            child: Text(
                                                "No operatives match your search.",
                                                style: TextStyle(
                                                    color:
                                                        subtitleColor)),
                                          )
                                        : ListView(
                                            shrinkWrap: true,
                                            padding: EdgeInsets.zero,
                                            children: filtered
                                                .map((m) {
                                              final id =
                                                  m['id'] as int;
                                              final name =
                                                  m['name']
                                                          ?.toString() ??
                                                      'Unknown';
                                              final email =
                                                  m['employee_id']
                                                          ?.toString() ??
                                                      '';
                                              return CheckboxListTile(
                                                dense: true,
                                                value: _pendingMemberIds
                                                    .contains(id),
                                                title: Text(name,
                                                    style: TextStyle(
                                                        color:
                                                            textColor)),
                                                subtitle: Text(email,
                                                    style: TextStyle(
                                                        color:
                                                            subtitleColor,
                                                        fontSize: 11)),
                                                onChanged: (val) {
                                                  setState(() {
                                                    if (val == true) {
                                                      _pendingMemberIds
                                                          .add(id);
                                                    } else {
                                                      _pendingMemberIds
                                                          .remove(id);
                                                    }
                                                  });
                                                },
                                              );
                                            }).toList(),
                                          ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Select one or more operatives to add to the team. Checked members will remain selected even when you search/filter.",
                                style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 11),
                              ),
                              const SizedBox(height: 12),
                              // Add Selected Members button
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF0D6EFD),
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                  ),
                                  onPressed: _pendingMemberIds.isEmpty
                                      ? null
                                      : _addSelectedMembers,
                                  child: const Text(
                                    "Add Selected Members",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],

                      const SizedBox(height: 40),

                      // ── Delete Team (danger zone at bottom) ────────────
                      Center(
                        child: TextButton(
                          onPressed: _confirmDelete,
                          child: const Text(
                            "Delete Team",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  // ─── Shared helpers ──────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: color),
    );
  }

  InputDecoration _inputDeco(String label,
      {String? hint, String? helperText}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      helperMaxLines: 3,
      border: const OutlineInputBorder(),
    );
  }
}
