import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../approval_stages_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/approval_request_model.dart';
import '../project_approvals_controller.dart';
import 'site_manager_tab.dart';

class ApprovalsTab extends StatefulWidget {
  final int projectId;
  const ApprovalsTab({Key? key, required this.projectId}) : super(key: key);

  @override
  State<ApprovalsTab> createState() => _ApprovalsTabState();
}

class _ApprovalsTabState extends State<ApprovalsTab> {
  late final ProjectApprovalsController _controller =
      ProjectApprovalsController(widget.projectId);

  String _selectedSite = 'Site: All Blocks, All Levels';

  @override
  void initState() {
    super.initState();
    _controller.fetchAllData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showAddStageDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AddApprovalStageDialog(controller: _controller),
    );
  }

  void _openSiteManagerScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text("Site Manager"),
          ),
          body: const SiteManagerTab(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final stages = _controller.stages;
        final forms = _controller.projectForms;
        final enabledFormsCount =
            forms.where((f) => f['is_enabled'] == true).length;
        final allFormsEnabled =
            forms.isNotEmpty && enabledFormsCount == forms.length;

        return RefreshIndicator(
          onRefresh: _controller.fetchAllData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Toolbar Row: Site Filter & Site Manager Button
                _buildToolbar(isDark, textColor, textSecondary, borderColor),
                const SizedBox(height: 16),

                // 2. Pending Approvals Banner (if any)
                if (_controller.approvals.isNotEmpty) ...[
                  _buildPendingApprovalsSection(
                      cardColor, borderColor, textColor, textSecondary),
                  const SizedBox(height: 16),
                ],

                // 3. Approval Stages Section Card
                _buildApprovalStagesSection(
                  context,
                  stages: stages,
                  isDark: isDark,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 16),

                // 4. Forms Section Card
                _buildFormsSection(
                  context,
                  forms: forms,
                  enabledCount: enabledFormsCount,
                  allEnabled: allFormsEnabled,
                  isDark: isDark,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  textSecondary: textSecondary,
                ),
                const SizedBox(height: 16),

                // 5. Information Cards (How It Works, Audit Ready, Forms Gated)
                _buildInformationCards(
                    context, cardColor, borderColor, textColor, textSecondary),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Toolbar & Controls ---
  Widget _buildToolbar(
      bool isDark, Color textColor, Color textSecondary, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Site Filter Dropdown Pill
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                value: _selectedSite,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                items: [
                  'Site: All Blocks, All Levels',
                  'Site: Block A',
                  'Site: Block B',
                  'Site: Main Building',
                ].map((site) {
                  return DropdownMenuItem(
                    value: site,
                    child: Text(site),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSite = val);
                },
                icon: Icon(
                  IconlyLight.arrow_down_2,
                  size: 16,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ),
          ),

          // Site Manager Button
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: isDark ? Colors.white10 : const Color(0xFF0D6EFD),
              foregroundColor: Colors.white,
              side: BorderSide(
                  color: isDark ? Colors.white24 : const Color(0xFF0D6EFD)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: _openSiteManagerScreen,
            child: const Text(
              "Site Manager",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // --- Approval Stages Section ---
  Widget _buildApprovalStagesSection(
    BuildContext context, {
    required List<Map<String, dynamic>> stages,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color textSecondary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Approval Stages",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    elevation: 0,
                  ),
                  onPressed: _showAddStageDialog,
                  child: const Text(
                    "Add Stage",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),

          // Body: Empty State or Configured Stages List
          if (_controller.isLoadingStages)
            const Padding(
              padding: EdgeInsets.all(36.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (stages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(IconlyLight.tick_square,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                        size: 28),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "No approval stages yet",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Create a QA process that helps maintain compliance and accountability. Review, approve, or reject job sheets in real time, with a clear record of who approved and when.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            ApprovalStagesScreen(controller: _controller),
                      ));
                    },
                    child: const Text(
                      "Setup Approvals",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ...stages.map((stage) {
                    final signerNames = ((stage['signers'] as List?) ?? [])
                        .map((s) => (s as Map)['name']?.toString() ?? '')
                        .join(', ');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(IconlyLight.tick_square,
                                size: 16, color: Color(0xFF0D6EFD)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stage['title']?.toString() ?? '',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: textColor),
                                ),
                                if ((stage['declaration']?.toString() ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    stage['declaration']?.toString() ?? '',
                                    style: TextStyle(
                                        color: textSecondary, fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (signerNames.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "Signers: $signerNames",
                                    style: TextStyle(
                                        color: const Color(0xFF0D6EFD),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(IconlyLight.arrow_right_2, size: 16),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) =>
                                    ApprovalStagesScreen(controller: _controller),
                              ));
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              ApprovalStagesScreen(controller: _controller),
                        ));
                      },
                      icon: const Icon(IconlyLight.setting, size: 16),
                      label: const Text("Manage Approval Stages",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- Forms Section ---
  Widget _buildFormsSection(
    BuildContext context, {
    required List<Map<String, dynamic>> forms,
    required int enabledCount,
    required bool allEnabled,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color textSecondary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row with Title & Enable All Switch
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Forms",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Approvals are enabled on $enabledCount of ${forms.length} forms.",
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Enable All Forms",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: allEnabled,
                        activeColor: const Color(0xFF0D6EFD),
                        onChanged: (val) {
                          _controller.toggleAllFormApprovals(val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),

          // Forms List with Checkboxes
          if (_controller.isLoadingForms)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: forms.length,
              separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: isDark ? Colors.white10 : Colors.grey.shade100),
              itemBuilder: (context, index) {
                final form = forms[index];
                final name = form['name']?.toString() ??
                    form['form_name']?.toString() ??
                    '';
                final formId = form['id'] ?? form['form_id'] ?? name;
                final isEnabled = form['is_enabled'] == true;

                return InkWell(
                  onTap: () {
                    _controller.toggleFormApproval(formId, !isEnabled);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isEnabled ? FontWeight.bold : FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ),
                        Checkbox(
                          value: isEnabled,
                          activeColor: const Color(0xFF0D6EFD),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) {
                            if (val != null) {
                              _controller.toggleFormApproval(formId, val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- Information Cards Section ---
  Widget _buildInformationCards(
    BuildContext context,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color textSecondary,
  ) {
    return Column(
      children: [
        _buildInfoCard(
          context,
          "How It Works",
          "Define approval stages for this project and assign accountable users for each declaration.",
          cardColor,
          borderColor,
          textColor,
          textSecondary,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          context,
          "Audit Ready",
          "All stage declarations, timestamps, and assigned members remain available for verification and reporting.",
          cardColor,
          borderColor,
          textColor,
          textSecondary,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          context,
          "Forms Gated",
          "Only the forms toggled on above require approval sign-off before their job sheets are considered final.",
          cardColor,
          borderColor,
          textColor,
          textSecondary,
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String description,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color textSecondary,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // --- Pending Approvals Section ---
  Widget _buildPendingApprovalsSection(Color cardColor, Color borderColor,
      Color textColor, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0D6EFD).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(IconlyLight.time_circle,
                  color: Color(0xFF0D6EFD), size: 18),
              const SizedBox(width: 8),
              Text(
                "Pending Approvals (${_controller.approvals.length})",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._controller.approvals.map((a) => _buildApprovalRow(
              a, cardColor, borderColor, textColor, textSecondary)),
        ],
      ),
    );
  }

  Widget _buildApprovalRow(ApprovalRequestModel approval, Color cardColor,
      Color borderColor, Color textColor, Color textSecondary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: approval.isRead ? borderColor : const Color(0xFF0D6EFD)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(approval.formName,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: textColor)),
                const SizedBox(height: 2),
                Text(
                  approval.resubmissionCount > 0
                      ? "${approval.operativeName} · Resubmission #${approval.resubmissionCount}"
                      : approval.operativeName,
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
          if (!approval.isRead)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFF0D6EFD).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6)),
              child: const Text("New",
                  style: TextStyle(
                      color: Color(0xFF0D6EFD),
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}
