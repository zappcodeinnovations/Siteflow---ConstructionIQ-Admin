import 'package:flutter/material.dart';
import '../../models/project_model.dart';
import '../../models/project_all_in_one_model.dart';
import 'project_controller.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final ProjectController _controller = ProjectController();
  ProjectAllInOneModel? _allInOneData;
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _tabs = [
    "Tasks",
    "Job Sheets",
    "Approvals",
    "HS&E",
    "Drawings",
    "Locations",
    "Specifications",
    "Docs & Files",
    "Project Setup",
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final data = await _controller.fetchAllInOneProjectDetails(widget.project.id);
    if (mounted) {
      setState(() {
        _allInOneData = data;
        _isLoading = false;
        _errorMessage = _controller.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectNameDisplay = widget.project.code.isNotEmpty 
        ? '${widget.project.code} - ${widget.project.name}' 
        : widget.project.name;
    final clientName = widget.project.client?.name ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: projectNameDisplay,
                style: const TextStyle(
                  color: Color(0xFF0F2C4A),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (clientName.isNotEmpty)
                TextSpan(
                  text: '   $clientName',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          Center(
            child: Text(
              "Site Manager",
              style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {},
              label: const Text("Create Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D6EFD)))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : _allInOneData == null
                  ? const Center(child: Text("No data found"))
                  : DefaultTabController(
        length: _tabs.length,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tab Bar Area
            Container(
              color: Colors.white,
              child: TabBar(
                isScrollable: true,
                indicatorColor: const Color(0xFF0D6EFD),
                indicatorWeight: 3,
                labelColor: const Color(0xFF0D6EFD),
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
              ),
            ),
            const Divider(height: 1, color: Colors.grey),
            
            // Content Area
            Expanded(
              child: TabBarView(
                children: [
                  _buildTasksTab(),
                  _buildPlaceholderTab("Job Sheets"),
                  _buildPlaceholderTab("Approvals"),
                  _buildPlaceholderTab("HS&E"),
                  _buildPlaceholderTab("Drawings"),
                  _buildPlaceholderTab("Locations"),
                  _buildPlaceholderTab("Specifications"),
                  _buildPlaceholderTab("Docs & Files"),
                  _buildPlaceholderTab("Project Setup"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Text(
        "$title content coming soon.",
        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
      ),
    );
  }

  Widget _buildTasksTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: 'Status: All',
                      items: ['Status: All']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: (val) {},
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () {},
                    child: const Text("Add Filter", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const Spacer(),
                Text("1 - 1 of 1", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Custom Tasks Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F2C4A),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                      border: Border(top: BorderSide(color: Color(0xFFF2C94C), width: 3)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.circle_outlined, color: Colors.white70, size: 20),
                        const SizedBox(width: 24),
                        const Expanded(flex: 2, child: Text("TASK NO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                        const Expanded(flex: 3, child: Text("REFERENCE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                        const Expanded(flex: 2, child: Text("STATUS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                        const Expanded(flex: 2, child: Text("OPERATIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                        const Expanded(flex: 2, child: Text("FORM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                        const Expanded(flex: 1, child: Text("SHEETS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                        const Expanded(flex: 1, child: Text("DATE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                        SizedBox(width: 80, child: Text("ACTION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                  
                  // Body (Dynamic rows)
                  Expanded(
                    child: _allInOneData!.tasks.isEmpty
                        ? Center(child: Text("No tasks found", style: TextStyle(color: Colors.grey.shade600)))
                        : ListView.builder(
                            itemCount: _allInOneData!.tasks.length,
                            itemBuilder: (context, index) {
                              final task = _allInOneData!.tasks[index];
                              return _buildTaskRow(
                                taskNo: task['task_no']?.toString() ?? "N/A",
                                reference: task['reference']?.toString() ?? "N/A",
                                status: task['status']?.toString() ?? "N/A",
                                operativeName: task['operative_name']?.toString() ?? "N/A",
                                form: task['form']?.toString() ?? "N/A",
                                sheets: task['sheets']?.toString() ?? "N/A",
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow({
    required String taskNo,
    required String reference,
    required String status,
    required String operativeName,
    required String form,
    required String sheets,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.circle_outlined, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 24),
          Expanded(flex: 2, child: Text(taskNo, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
          Expanded(flex: 3, child: Text(reference, style: const TextStyle(fontSize: 14))),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 14),
                    const SizedBox(width: 4),
                    Text(status, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.blue.shade100,
                  child: const Text("AM", style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(operativeName, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(form, style: const TextStyle(fontSize: 14))),
          Expanded(flex: 1, child: Text(sheets, style: const TextStyle(fontSize: 14))),
          const Expanded(flex: 1, child: Text("", style: TextStyle(fontSize: 14))),
          SizedBox(
            width: 80,
            child: InkWell(
              onTap: () {},
              child: const Text(
                "Delete",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
