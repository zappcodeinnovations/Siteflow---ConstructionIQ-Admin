import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../approval_stages_screen.dart';
import '../../../core/theme/app_theme.dart';

class ApprovalsTab extends StatelessWidget {
  const ApprovalsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main center card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Icon(IconlyLight.tick_square, color: isDark ? Colors.white70 : Colors.grey.shade600, size: 28),
                ),
                const SizedBox(height: 24),
                Text(
                  "Approvals",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Configure quality assurance declarations and compliance sign-offs from your project template, then\ntrack approvals in project delivery.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white10 : const Color(0xFF0D6EFD),
                    foregroundColor: Colors.white,
                    side: BorderSide(color: isDark ? Colors.white24 : Colors.transparent),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const ApprovalStagesScreen(),
                    ));
                  },
                  child: const Text("Setup Approvals", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Bottom three cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;
              return Flex(
                direction: isDesktop ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: isDesktop ? 1 : 0, child: _buildInfoCard(
                    context,
                    "How It Works",
                    "Define approval stages in your template and assign accountable users for each declaration."
                  )),
                  SizedBox(width: isDesktop ? 24 : 0, height: isDesktop ? 0 : 16),
                  Expanded(flex: isDesktop ? 1 : 0, child: _buildInfoCard(
                    context,
                    "Audit Ready",
                    "All stage declarations, timestamps, and assigned members remain available for verification and reporting."
                  )),
                  SizedBox(width: isDesktop ? 24 : 0, height: isDesktop ? 0 : 16),
                  Expanded(flex: isDesktop ? 1 : 0, child: _buildInfoCard(
                    context,
                    "Project Safe",
                    "Configuration is managed in the template area, preserving current project data and workflows."
                  )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String description) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

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
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
