import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'tabs/dynamic_tab.dart';
import 'tabs/project_setup_tab.dart';
import 'tabs/tasks_tab.dart';
import 'tabs/job_sheets_tab.dart';
import 'tabs/drawings_tab.dart';
import 'tabs/approvals_tab.dart';
import 'tabs/hse_tab.dart';
import 'tabs/incidents_tab.dart';
import 'tabs/snags_tab.dart';
import 'tabs/inspections_tab.dart';
import 'tabs/site_manager_tab.dart';
import 'tabs/project_template_tab.dart';
import '../../models/project_model.dart';
import '../../models/project_all_in_one_model.dart';
import 'project_controller.dart';
import 'tabs/docs_files_tab.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/auth_service.dart';

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

  bool _canViewTasks = false;
  bool _canCreateTasks = false;
  bool _canViewJobSheets = false;
  bool _canViewApprovals = false;
  bool _canEditProject = false;

  @override
  void initState() {
    super.initState();
    _loadAccessAndData();
  }

  Future<void> _loadAccessAndData() async {
    final access = await Future.wait([
      AuthService.can('tasks'),
      AuthService.can('tasks', action: 'create'),
      AuthService.can('job_sheets'),
      AuthService.can('approvals'),
      AuthService.can('projects', action: 'edit'),
    ]);
    if (!mounted) return;
    setState(() {
      _canViewTasks = access[0];
      _canCreateTasks = access[1];
      _canViewJobSheets = access[2];
      _canViewApprovals = access[3];
      _canEditProject = access[4];
    });
    await _fetchData();
  }

  Future<void> _fetchData() async {
    final data = await _controller.fetchAllInOneProjectDetails(
      widget.project.id,
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Custom Palette based on theme mode
    final bgColor = isDark ? AppTheme.corporateBlue : const Color(0xFFF8FAFC);
    final appBarBg = isDark ? AppTheme.corporateBlue : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final projectNameDisplay = widget.project.code.isNotEmpty
        ? '${widget.project.code} - ${widget.project.name}'
        : widget.project.name;
    final clientName = widget.project.client?.name ?? '';
    final tabs = <String>[
      if (_canViewTasks) 'Tasks',
      if (_canViewJobSheets) 'Job Sheets',
      if (_canViewApprovals) 'Approvals',
      'HS&E',
      'Incidents',
      'Snags',
      'Inspections',
      'Drawings',
      'Site Manager',
      'Locations',
      'Specifications',
      'Project Template',
      'Docs & Files',
      'Project Setup',
    ];
    final tabViews = <Widget>[
      if (_canViewTasks) TasksTab(tasks: _allInOneData?.tasks ?? []),
      if (_canViewJobSheets)
        JobSheetsTab(
          jobSheets: _allInOneData?.jobSheets ?? [],
          filterOptions: _allInOneData?.jobSheetsFilterOptions ?? {},
        ),
      if (_canViewApprovals) const ApprovalsTab(),
      const HseTab(),
      IncidentsTab(projectId: widget.project.id),
      SnagsTab(projectId: widget.project.id),
      InspectionsTab(projectId: widget.project.id),
      DrawingsTab(
        rawBlocks:
            _allInOneData
                    ?.projectSetup?['dropdown_options']?['available_blocks']
                as List?,
        drawings: _allInOneData?.drawings,
      ),
      SiteManagerTab(
        rawBlocks:
            _allInOneData
                    ?.projectSetup?['dropdown_options']?['available_blocks']
                as List?,
      ),
      DynamicTab(title: "Locations", data: _allInOneData?.locations ?? []),
      DynamicTab(
        title: "Specifications",
        data: _allInOneData?.specifications ?? [],
      ),
      ProjectTemplateTab(projectId: widget.project.id),
      DocsFilesTab(
        folders: _allInOneData?.docsFolders ?? [],
        files: _allInOneData?.docsFiles ?? [],
      ),
      ProjectSetupTab(
        projectId: widget.project.id,
        projectSetup: _allInOneData?.projectSetup,
        canEdit: _canEditProject,
      ),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: projectNameDisplay,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              if (clientName.isNotEmpty)
                TextSpan(
                  text: '   $clientName',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
            ],
          ),
        ),
        actions: _canCreateTasks
            ? [
                if (MediaQuery.of(context).size.width > 600) ...[
                  Center(
                    child: Text(
                      "Site Manager",
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {},
                      label: const Text(
                        "Create Task",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: const Icon(
                        IconlyLight.arrow_down_2,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ] else ...[
                  IconButton(
                    icon: const Icon(IconlyLight.plus),
                    onPressed: () {},
                    color: const Color(0xFF0D6EFD),
                  ),
                ],
              ]
            : null,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundStripesPainter(isDark: isDark),
            ),
          ),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0D6EFD)),
                )
              : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : _allInOneData == null
              ? const Center(child: Text("No data found"))
              : DefaultTabController(
                  length: tabs.length,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tab Bar Area
                      Container(
                        color: isDark ? AppTheme.corporateBlue : Colors.white,
                        child: TabBar(
                          isScrollable: true,
                          indicatorColor: isDark
                              ? Colors.white
                              : const Color(0xFF0D6EFD),
                          indicatorWeight: 3,
                          labelColor: isDark
                              ? Colors.white
                              : const Color(0xFF0D6EFD),
                          unselectedLabelColor: isDark
                              ? Colors.white70
                              : Colors.grey.shade600,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          tabs: tabs.map((tab) => Tab(text: tab)).toList(),
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                      ),

                      // Content Area
                      Expanded(child: TabBarView(children: tabViews)),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
