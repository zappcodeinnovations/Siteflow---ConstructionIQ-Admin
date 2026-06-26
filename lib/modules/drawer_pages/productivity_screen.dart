import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/api_endpoints.dart';
import 'productivity_controller.dart';
import '../../models/productivity_model.dart';
import '../../core/widgets/shimmer_loading.dart';

class ProductivityScreen extends StatefulWidget {
  const ProductivityScreen({super.key});

  @override
  State<ProductivityScreen> createState() => _ProductivityScreenState();
}

class _ProductivityScreenState extends State<ProductivityScreen> {
  final ProductivityController _controller = ProductivityController();

  @override
  void initState() {
    super.initState();
    _controller.fetchProductivity();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final initialDate = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(
        start: initialDate.subtract(const Duration(days: 30)),
        end: initialDate,
      ),
    );
    if (picked != null) {
      final startStr = "${picked.start.day.toString().padLeft(2, '0')}/${picked.start.month.toString().padLeft(2, '0')}/${picked.start.year}";
      final endStr = "${picked.end.day.toString().padLeft(2, '0')}/${picked.end.month.toString().padLeft(2, '0')}/${picked.end.year}";
      _controller.setDateRange(startStr, endStr);
      _controller.fetchProductivity();
    }
  }

  void _showFilterDialog() {
    if (_controller.data == null) return;
    
    final options = _controller.data!.filterOptions;
    final teams = (options['teams'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final members = (options['members'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final projects = (options['projects'] as List?)?.map((e) => e.toString()).toList() ?? [];

    showDialog(
      context: context,
      builder: (context) {
        String? tempTeam = _controller.selectedTeam;
        String? tempMember = _controller.selectedMember;
        String? tempProject = _controller.selectedProject;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Filter Productivity"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Team"),
                      value: tempTeam,
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text("All Teams")),
                        ...teams.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                      ],
                      onChanged: (val) => setState(() => tempTeam = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Member"),
                      value: tempMember,
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text("All Members")),
                        ...members.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                      ],
                      onChanged: (val) => setState(() => tempMember = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Project"),
                      value: tempProject,
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text("All Projects")),
                        ...projects.map((p) => DropdownMenuItem(value: p, child: Text(p))),
                      ],
                      onChanged: (val) => setState(() => tempProject = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _controller.setTeam(tempTeam);
                    _controller.setMember(tempMember);
                    _controller.setProject(tempProject);
                    _controller.fetchProductivity();
                    Navigator.pop(context);
                  },
                  child: const Text("Apply Filters"),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _downloadReport() async {
    final baseUrl = '${ApiEndpoints.baseUrl}/productivity/?export=excel';
    
    List<String> queryParams = [];
    if (_controller.fromDate.isNotEmpty) queryParams.add('from=${_controller.fromDate}');
    if (_controller.toDate.isNotEmpty) queryParams.add('to=${_controller.toDate}');
    if (_controller.selectedTeam != null && _controller.selectedTeam!.isNotEmpty) queryParams.add('team=${_controller.selectedTeam}');
    if (_controller.selectedMember != null && _controller.selectedMember!.isNotEmpty) queryParams.add('member=${_controller.selectedMember}');
    if (_controller.selectedProject != null && _controller.selectedProject!.isNotEmpty) queryParams.add('project=${_controller.selectedProject}');
    
    final finalUrl = queryParams.isEmpty ? baseUrl : '$baseUrl&${queryParams.join('&')}';
    final url = Uri.parse(finalUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not download report")),
        );
      }
    }
  }

  Widget _buildKpiCard(String title, String value, Color bgColor, Color textColor, IconData iconData) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(iconData, size: 18, color: textColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton("By Member", "member"),
          _buildToggleButton("By Team", "team"),
          _buildToggleButton("By Project", "project"),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, String viewKey) {
    final isSelected = _controller.currentView == viewKey;
    return InkWell(
      onTap: () => _controller.setView(viewKey),
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.transparent, // Dark Navy
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildDataList() {
    if (_controller.isLoading && _controller.data == null) {
      return const ShimmerLoadingList();
    }
    if (_controller.errorMessage != null && _controller.data == null) {
      return Center(child: Text(_controller.errorMessage!, style: const TextStyle(color: Colors.red)));
    }
    if (_controller.data == null) {
      return const Center(child: Text("No productivity data."));
    }

    final itemCount = _getListItemCount();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _controller.currentView == 'member' ? "Team Members" : _controller.currentView == 'team' ? "Teams" : "Projects",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                "Showing $itemCount results",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) => _buildListCard(index),
        ),
      ],
    );
  }

  int _getListItemCount() {
    if (_controller.currentView == 'member') return _controller.data!.byMember.length;
    if (_controller.currentView == 'team') return _controller.data!.byTeam.length;
    if (_controller.currentView == 'project') return _controller.data!.byProject.length;
    return 0;
  }

  Widget _buildListCard(int index) {
    String title = "";
    String subtitle = "";
    String initials = "";
    String badgeText = "";
    Color avatarColor = const Color(0xFF0F172A); // Default dark
    
    String sheets = "0";
    String opCost = "0";
    String matCost = "0";
    String totalCharge = "0";

    if (_controller.currentView == 'member') {
      final member = _controller.data!.byMember[index];
      title = member.name;
      subtitle = "Team Member";
      initials = member.initials.isNotEmpty ? member.initials : member.name.substring(0, 1).toUpperCase();
      badgeText = member.team;
      sheets = member.jobSheets.toString();
      opCost = '£${member.operative.toStringAsFixed(0)}';
      matCost = '£${member.materialCost.toStringAsFixed(0)}';
      totalCharge = '£${member.charge.toStringAsFixed(2)}';
      // Use different colors based on index for variety like in design
      avatarColor = index % 2 == 0 ? const Color(0xFF0F172A) : const Color(0xFFD4AF37);
    } else if (_controller.currentView == 'team') {
      final team = _controller.data!.byTeam[index];
      title = team.team;
      subtitle = "${team.members} Members";
      initials = team.team.isNotEmpty ? team.team.substring(0, 1).toUpperCase() : "T";
      sheets = team.jobSheets.toString();
      opCost = '£${team.operative.toStringAsFixed(0)}';
      matCost = '£${team.materialCost.toStringAsFixed(0)}';
      totalCharge = '£${team.charge.toStringAsFixed(2)}';
    } else {
      final project = _controller.data!.byProject[index];
      title = project.name;
      subtitle = project.client;
      initials = project.name.isNotEmpty ? project.name.substring(0, 1).toUpperCase() : "P";
      badgeText = "${project.members} Members";
      sheets = project.jobSheets.toString();
      opCost = '£${project.operative.toStringAsFixed(0)}';
      matCost = '£${project.materialCost.toStringAsFixed(0)}';
      totalCharge = '£${project.charge.toStringAsFixed(2)}';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header Row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: avatarColor,
                  child: Text(initials, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                if (badgeText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4338CA)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("SHEETS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(sheets, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ),
                Container(height: 30, width: 1, color: Colors.grey.shade100),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("OP COST", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(opCost, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ),
                Container(height: 30, width: 1, color: Colors.grey.shade100),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("MAT COST", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Text(matCost, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 16),
            
            // Footer Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Charge", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                Text(
                  totalCharge,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Productivity",
          style: TextStyle(color: Color(0xFF0F2C4A), fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Action Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Row: Date & Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Date Selector
                          InkWell(
                            onTap: () => _selectDateRange(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                                ]
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 14, color: Colors.blue.shade700),
                                  const SizedBox(width: 8),
                                  const Text("This Month", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey.shade600),
                                ],
                              ),
                            ),
                          ),
                          
                          // Quick Actions
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.filter_list, color: Colors.black87),
                                onPressed: _showFilterDialog,
                                tooltip: 'Filters',
                              ),
                              IconButton(
                                icon: const Icon(Icons.download, color: Colors.black87),
                                onPressed: _downloadReport,
                                tooltip: 'Download Report',
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.black87),
                                onPressed: () {
                                  _controller.setTeam(null);
                                  _controller.setMember(null);
                                  _controller.setProject(null);
                                  _controller.fetchProductivity();
                                },
                                tooltip: 'Refresh',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Bottom Row: View Toggles
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: _buildToggleBar(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // KPI Cards Grid
                  if (_controller.data != null)
                    GridView.count(
                      crossAxisCount: 2, // 2 cards per row to match design
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.4, 
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildKpiCard("Active Projects", _controller.data!.summary?.activeProjects.toString() ?? "0", const Color(0xFFEEF2FF), const Color(0xFF4338CA), Icons.bar_chart),
                        _buildKpiCard("Active Members", _controller.data!.summary?.activeMembers.toString() ?? "0", const Color(0xFFFFFBEB), const Color(0xFFB45309), Icons.people_outline),
                        _buildKpiCard("Job Sheets", _controller.data!.summary?.jobSheets.toString() ?? "0", const Color(0xFFF0FDF4), const Color(0xFF15803D), Icons.description_outlined),
                        _buildKpiCard("Operative Cost", '£${_controller.data!.summary?.operativeTotal.toStringAsFixed(0) ?? "0"}', const Color(0xFFFAFAFA), Colors.black87, Icons.currency_pound),
                        _buildKpiCard("Material Cost", '£${_controller.data!.summary?.materialCostTotal.toStringAsFixed(0) ?? "0"}', const Color(0xFFFAFAFA), Colors.black87, Icons.inventory_2_outlined),
                        _buildKpiCard("Total Charge", '£${_controller.data!.summary?.chargeTotal.toStringAsFixed(0) ?? "0"}', const Color(0xFFEEF2FF), const Color(0xFF2563EB), Icons.account_balance_wallet_outlined),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Dynamic Data List
                  _buildDataList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}