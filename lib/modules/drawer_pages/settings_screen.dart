import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../models/admin_team_model.dart';
import 'admin_team_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0; // 0: Teams, 1: Materials
  final AdminTeamController _teamController = AdminTeamController();

  @override
  void initState() {
    super.initState();
    _teamController.fetchTeams();
    _teamController.addListener(_onTeamControllerChanged);
  }

  void _onTeamControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _teamController.removeListener(_onTeamControllerChanged);
    _teamController.dispose();
    super.dispose();
  }

  Future<void> _showAddTeamDialog() async {
    final nameController = TextEditingController();
    TimeOfDay? shiftStart;
    TimeOfDay? shiftEnd;

    String? formatTime(TimeOfDay? t) {
      if (t == null) return null;
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Team'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Team name'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(shiftStart == null ? 'Shift start (optional)' : 'Start: ${formatTime(shiftStart)}'),
                  trailing: const Icon(IconlyLight.time_circle),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: shiftStart ?? const TimeOfDay(hour: 8, minute: 0),
                    );
                    if (picked != null) setDialogState(() => shiftStart = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(shiftEnd == null ? 'Shift end (optional)' : 'End: ${formatTime(shiftEnd)}'),
                  trailing: const Icon(IconlyLight.time_circle),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: shiftEnd ?? const TimeOfDay(hour: 15, minute: 0),
                    );
                    if (picked != null) setDialogState(() => shiftEnd = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(dialogContext);
                final result = await _teamController.createTeam(
                  name: name,
                  shiftStartTime: formatTime(shiftStart),
                  shiftEndTime: formatTime(shiftEnd),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] as String),
                    backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmForceClockOut(AdminTeam team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Force Clock Out'),
        content: Text('Clock out every active session for ${team.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clock Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await _teamController.forceClockOut(team.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] as String),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.corporateBlue : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundStripesPainter(isDark: isDark),
            ),
          ),
          Row(
            children: [
          // Left Sidebar (hide on very small screens or make it narrow, but keep as requested)
          if (isDesktop)
            Container(
              width: 250,
              color: const Color(0xFF0F2C4A),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Icon(IconlyLight.arrow_left, color: Colors.white, size: 20),
                          SizedBox(width: 12),
                          Text("Back", style: TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text("SETTINGS", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                  const SizedBox(height: 12),
                  _buildNavItem(0, IconlyLight.category, "Teams"),
                  _buildNavItem(1, IconlyLight.category, "Materials"),
                ],
              ),
            ),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                // If not desktop, show a simple app bar to allow navigating back
                if (!isDesktop)
                  AppBar(
                    backgroundColor: isDark ? AppTheme.corporateBlue : Colors.white,
                    elevation: 0,
                    iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
                    leading: IconButton(
                      icon: const Icon(IconlyLight.arrow_left),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: Text(
                      _selectedIndex == 0 ? "Teams" : "Materials",
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                Expanded(
                  child: _selectedIndex == 0
                      ? _buildTeamsContent(isDesktop, cardColor: cardColor, textColor: textColor, subtitleColor: subtitleColor, borderColor: borderColor, isDark: isDark)
                      : Center(child: Text("Materials Content", style: TextStyle(color: textColor))),
                ),
              ],
            ),
          ),
            ],
          ),
        ],
      ),
      // Bottom navigation for mobile to switch tabs
      bottomNavigationBar: !isDesktop ? BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (idx) => setState(() => _selectedIndex = idx),
        items: const [
          BottomNavigationBarItem(icon: Icon(IconlyLight.category), label: "Teams"),
          BottomNavigationBarItem(icon: Icon(IconlyLight.category), label: "Materials"),
        ],
      ) : null,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D6EFD) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsContent(
    bool isDesktop, {
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDesktop)
          Container(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Teams",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Create and manage your teams",
                  style: TextStyle(fontSize: 16, color: subtitleColor),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                    child: Row(
                      children: [
                        Icon(IconlyLight.category, color: subtitleColor, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          "Teams",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: borderColor),
                  Padding(
                    padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _teamController.isLoading
                              ? "Loading teams..."
                              : _teamController.errorMessage != null
                                  ? _teamController.errorMessage!
                                  : "You have ${_teamController.teams.length} team${_teamController.teams.length == 1 ? '' : 's'} in your organisation.",
                          style: TextStyle(fontSize: 15, color: textColor),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddTeamDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6EFD),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(IconlyLight.plus, color: Colors.white, size: 18),
                          label: const Text(
                            "Add Team",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_teamController.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    for (final team in _teamController.teams)
                      _buildTeamItem(
                        team: team,
                        isDesktop: isDesktop,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        borderColor: borderColor,
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamItem({
    required AdminTeam team,
    required bool isDesktop,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
  }) {
    final name = team.displayName;
    final createdAt = team.createdAt != null
        ? '${team.createdAt!.day.toString().padLeft(2, '0')}/${team.createdAt!.month.toString().padLeft(2, '0')}/${team.createdAt!.year}'
        : 'Unknown date';
    final lead = team.leadName ?? 'No team lead assigned';
    final shift = (team.shiftStartTime != null && team.shiftEndTime != null)
        ? '${team.shiftStartTime} - ${team.shiftEndTime}'
        : 'Not set';
    final members = '${team.memberCount} Member${team.memberCount == 1 ? '' : 's'}';

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          SizedBox(
            width: isDesktop ? 300 : double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    Text(
                      "Created $createdAt",
                      style: TextStyle(color: subtitleColor, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  lead == "No team lead assigned" ? lead : "Lead: $lead",
                  style: TextStyle(color: subtitleColor, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "Shift: $shift",
                  style: TextStyle(color: subtitleColor, fontSize: 14),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  members,
                  style: TextStyle(
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _confirmForceClockOut(team),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade200),
                  backgroundColor: Colors.red.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(IconlyLight.logout, color: Colors.red.shade700, size: 18),
                label: Text(
                  "Force Clock Out",
                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                ),
              ),
              Icon(IconlyLight.category, color: subtitleColor, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}