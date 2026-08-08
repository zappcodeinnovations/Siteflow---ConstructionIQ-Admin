import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../core/theme/app_theme.dart';

class ProjectSetupTab extends StatefulWidget {
  final Map<String, dynamic>? projectSetup;

  const ProjectSetupTab({Key? key, this.projectSetup}) : super(key: key);

  @override
  State<ProjectSetupTab> createState() => _ProjectSetupTabState();
}

class _ProjectSetupTabState extends State<ProjectSetupTab> {
  String? _selectedTeamId;
  Set<String> _selectedWorkerIds = {};

  Widget _buildResponsiveRow(BuildContext context, List<Widget> children) {
    final double width = MediaQuery.of(context).size.width;
    if (width > 600) {
      // Side-by-side with padding
      final List<Widget> RowChildren = [];
      for (int i = 0; i < children.length; i++) {
        RowChildren.add(Expanded(child: children[i]));
        if (i < children.length - 1) {
          RowChildren.add(const SizedBox(width: 16));
        }
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: RowChildren,
      );
    } else {
      // Stacked vertically
      final List<Widget> ColumnChildren = [];
      for (int i = 0; i < children.length; i++) {
        ColumnChildren.add(children[i]);
        if (i < children.length - 1) {
          ColumnChildren.add(const SizedBox(height: 16));
        }
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: ColumnChildren,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.projectSetup == null) {
      return const Center(child: Text("Project Setup data not available"));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);

    final setup = widget.projectSetup!;
    final metadata = setup['basic_metadata'] ?? {};
    final dropdowns = setup['dropdown_options'] ?? {};
    final availableTeams = dropdowns['available_teams'] as List? ?? [];
    final availableWorkers = dropdowns['available_workers'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar (Responsive Wrap instead of Row)
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                "Project Setup",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white10 : const Color(0xFF0D6EFD),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: isDark ? Colors.white24 : Colors.transparent),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Setup saved successfully")),
                  );
                },
                icon: const Icon(IconlyLight.download, color: Colors.white, size: 18),
                label: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              // Left Column (Basic Info & Location)
              SizedBox(
                width: MediaQuery.of(context).size.width > 1000
                    ? 500
                    : double.infinity,
                child: Column(
                  children: [
                    _buildSetupCard(
                      context,
                      title: "Basic Information",
                      icon: IconlyLight.info_square,
                      children: [
                        _buildTextField(context, "Project Code", metadata['code']?.toString() ?? ''),
                        const SizedBox(height: 16),
                        _buildTextField(context, "Project Name", metadata['name']?.toString() ?? ''),
                        const SizedBox(height: 16),
                        _buildResponsiveRow(context, [
                          _buildDropdownField(
                            context,
                            "Status",
                            metadata['status']?.toString() ?? '',
                            dropdowns['available_statuses'] ?? [],
                          ),
                          _buildDropdownField(
                            context,
                            "Priority",
                            metadata['priority']?.toString() ?? '',
                            dropdowns['available_priorities'] ?? [],
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _buildResponsiveRow(context, [
                          _buildTextField(context, "Progress (%)", metadata['progress']?.toString() ?? '0'),
                          _buildTextField(context, "Budget", metadata['budget']?.toString() ?? ''),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSetupCard(
                      context,
                      title: "Location Details",
                      icon: IconlyLight.location,
                      children: [
                        _buildTextField(context, "Site Address", metadata['site_address']?.toString() ?? ''),
                        const SizedBox(height: 16),
                        _buildResponsiveRow(context, [
                          _buildTextField(context, "City", metadata['city']?.toString() ?? ''),
                          _buildTextField(context, "State", metadata['state']?.toString() ?? ''),
                        ]),
                        const SizedBox(height: 16),
                        _buildResponsiveRow(context, [
                          _buildTextField(context, "Country", metadata['country']?.toString() ?? ''),
                          _buildTextField(context, "Postal Code", metadata['postal_code']?.toString() ?? ''),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),

              // Right Column (Assignments & Teams)
              SizedBox(
                width: MediaQuery.of(context).size.width > 1000
                    ? 500
                    : double.infinity,
                child: Column(
                  children: [
                    _buildSetupCard(
                      context,
                      title: "Assignments",
                      icon: IconlyLight.profile,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (dropdowns['available_managers'] as List? ?? []).map((m) {
                              return Chip(
                                avatar: CircleAvatar(
                                  backgroundColor: Colors.orange.shade100,
                                  child: Text(
                                    m['display_name']?.toString().substring(0, 1) ?? 'M',
                                    style: TextStyle(color: Colors.orange.shade800, fontSize: 10),
                                  ),
                                ),
                                label: Text(m['display_name']?.toString() ?? 'Manager'),
                                backgroundColor: isDark ? AppTheme.corporateBlue : Colors.white,
                                side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSetupCard(
                      context,
                      title: "Teams & Workers",
                      icon: IconlyLight.user,
                      children: [
                        _buildTeamSelection(context, availableTeams, availableWorkers),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSelection(BuildContext context, List<dynamic> availableTeams, List<dynamic> availableWorkers) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.grey;
    final textStyle = TextStyle(color: isDark ? Colors.white : Colors.black87);

    List<dynamic> teamWorkers = [];
    if (_selectedTeamId != null) {
      final team = availableTeams.firstWhere((t) => t['id'].toString() == _selectedTeamId, orElse: () => null);
      if (team != null) {
        final memberIds = team['member_ids'] as List? ?? [];
        teamWorkers = availableWorkers.where((w) => memberIds.contains(w['id'])).toList();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Available Teams",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: labelColor),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: isDark ? AppTheme.corporateBlue : Colors.white,
              isExpanded: true,
              value: _selectedTeamId,
              hint: Text("Select a team", style: TextStyle(color: labelColor)),
              items: availableTeams.map((e) {
                final val = e['id']?.toString() ?? '';
                final name = e['name']?.toString() ?? '';
                return DropdownMenuItem(
                  value: val,
                  child: Text(
                    name,
                    style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedTeamId = val;
                });
              },
              icon: Icon(IconlyLight.arrow_down_2, color: isDark ? Colors.white70 : Colors.grey),
            ),
          ),
        ),
        if (_selectedTeamId != null && teamWorkers.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            "Team Workers",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: labelColor),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: teamWorkers.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
              itemBuilder: (context, index) {
                final worker = teamWorkers[index];
                final workerId = worker['id'].toString();
                final workerName = worker['display_name']?.toString() ?? 'Worker';
                final isSelected = _selectedWorkerIds.contains(workerId);

                return CheckboxListTile(
                  title: Text(workerName, style: textStyle),
                  value: isSelected,
                  activeColor: const Color(0xFF0D6EFD),
                  checkColor: Colors.white,
                  side: BorderSide(color: isDark ? Colors.white54 : Colors.grey.shade400),
                  onChanged: (bool? checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedWorkerIds.add(workerId);
                      } else {
                        _selectedWorkerIds.remove(workerId);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ] else if (_selectedTeamId != null) ...[
          const SizedBox(height: 16),
          Text("No workers found for this team.", style: TextStyle(color: labelColor, fontStyle: FontStyle.italic)),
        ],
      ],
    );
  }

  Widget _buildSetupCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isDark ? Colors.white : const Color(0xFF0D6EFD), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label, String initialValue) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.grey;
    final textStyle = TextStyle(color: isDark ? Colors.white : Colors.black87);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: labelColor),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          style: textStyle,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? Colors.white : const Color(0xFF0D6EFD), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(BuildContext context, String label, String currentValue, List<dynamic> options) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: labelColor),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: isDark ? AppTheme.corporateBlue : Colors.white,
              isExpanded: true,
              value: options.isNotEmpty
                  ? options.first['value']?.toString() ?? options.first['id']?.toString()
                  : null,
              items: options.map((e) {
                final val = e['value']?.toString() ?? e['id']?.toString() ?? '';
                final name = e['label']?.toString() ?? e['name']?.toString() ?? '';
                return DropdownMenuItem(
                  value: val,
                  child: Text(
                    name,
                    style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: (val) {},
              icon: Icon(IconlyLight.arrow_down_2, color: isDark ? Colors.white70 : Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}

