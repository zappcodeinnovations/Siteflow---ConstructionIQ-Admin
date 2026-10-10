import 'package:flutter/material.dart';
import 'admin_support_controller.dart';
import 'create_ticket_dialog.dart';
import 'ticket_details_view.dart';
import '../admin_screen.dart';
import '../../projects/projects_screen.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/theme/app_theme.dart';
import 'package:iconly/iconly.dart';
import '../../../../models/admin_support_model.dart';

class AdminSupportView extends StatefulWidget {
  const AdminSupportView({super.key});

  @override
  State<AdminSupportView> createState() => _AdminSupportViewState();
}

class _AdminSupportViewState extends State<AdminSupportView> {
  final AdminSupportController _controller = AdminSupportController();

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

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: textColor.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(24), child: child),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(
    IconData icon,
    String title,
    String subtitle, {
    required VoidCallback onTap,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
    bool isDark = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162A42) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F2C4A) : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.blue.shade100,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0D6EFD),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBeforeSendItem(
    IconData icon,
    String title,
    String subtitle, {
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
    bool isDark = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162A42) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F2C4A) : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.blue.shade100,
              ),
            ),
            child: Icon(
              icon,
              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0D6EFD),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(color: subtitleColor, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String statusDisplay, String statusKey) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade700;

    if (statusKey == 'open' || statusKey == 'in_progress') {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade700;
    } else if (statusKey == 'resolved' || statusKey == 'closed') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        statusDisplay,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _buildTicketCard(
    SupportTicket ticket, {
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
    bool isDark = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ticket.ticketNumber,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: subtitleColor,
                  fontSize: 12,
                ),
              ),
              _buildStatusPill(ticket.statusDisplay, ticket.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ticket.subject,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(IconlyLight.category, size: 14, color: subtitleColor),
              const SizedBox(width: 4),
              Text(
                ticket.categoryDisplay,
                style: TextStyle(color: subtitleColor, fontSize: 12),
              ),
              const SizedBox(width: 16),
              Icon(
                IconlyLight.time_circle,
                size: 14,
                color: subtitleColor,
              ),
              const SizedBox(width: 4),
              Text(
                "Updated: ${DateHelper.formatDate(ticket.lastMessageAt)}",
                style: TextStyle(color: subtitleColor, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TicketDetailsView(
                      controller: _controller,
                      ticketId: ticket.id,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF162A42) : Colors.blue.shade50,
                foregroundColor: isDark ? Colors.white : Colors.blue.shade700,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: isDark ? Colors.white24 : Colors.transparent),
                ),
              ),
              child: const Text(
                "View Ticket",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Support",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final refresh = await showDialog(
                      context: context,
                      builder: (context) =>
                          CreateTicketDialog(controller: _controller),
                    );
                    if (refresh == true) {
                      _controller.fetchTickets();
                    }
                  },
                  icon: const Icon(
                    IconlyLight.plus,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    "Create New Ticket",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
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
                ),
              ],
            ),
            const SizedBox(height: 32),

            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  if (_controller.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  Widget contentLeft = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_controller.tickets.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                IconlyLight.document,
                                size: 48,
                                color: subtitleColor.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No support tickets found",
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Create a new ticket to get help from our team.",
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _controller.tickets.length,
                          itemBuilder: (context, index) {
                            return _buildTicketCard(
                              _controller.tickets[index],
                              cardColor: cardColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                              isDark: isDark,
                            );
                          },
                        ),
                    ],
                  );

                  Widget contentRight = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCard(
                        title: "Support Details",
                        icon: IconlyLight.info_square,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  IconlyLight.message,
                                  size: 16,
                                  color: isDark ? Colors.lightBlueAccent : Colors.blue.shade700,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Email: ${_controller.quickActions?.supportEmail ?? 'Loading...'}",
                                  style: TextStyle(fontSize: 13, color: textColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  IconlyLight.category,
                                  size: 16,
                                  color: isDark ? Colors.lightBlueAccent : Colors.blue.shade700,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Call: ${_controller.quickActions?.supportPhone ?? 'Loading...'}",
                                  style: TextStyle(fontSize: 13, color: textColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  IconlyLight.category,
                                  size: 16,
                                  color: isDark ? Colors.lightBlueAccent : Colors.blue.shade700,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Monday to Friday, 09:30 - 17:30",
                                  style: TextStyle(fontSize: 13, color: textColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF162A42) : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isDark ? Colors.white12 : Colors.blue.shade100),
                              ),
                              child: Text(
                                "Include screenshots, exact URLs, and affected job or project numbers. This helps support resolve the request faster.",
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.blue.shade900,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quick Actions Card
                      _buildCard(
                        title: "Quick Actions",
                        icon: Icons.bolt_rounded,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        child: Column(
                          children: [
                            _buildQuickActionItem(
                              IconlyLight.user_1,
                              "Manage Members",
                              "Invite users, reset access, and review pending invitations.",
                              cardColor: cardColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                              isDark: isDark,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AdminScreen(initialMenuKey: 'admin_members'),
                                  ),
                                );
                              },
                            ),
                            _buildQuickActionItem(
                              IconlyLight.work,
                              "Organisation Settings",
                              "Update organisation name, currency, and profile settings.",
                              cardColor: cardColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                              isDark: isDark,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AdminScreen(initialMenuKey: 'admin_organisation'),
                                  ),
                                );
                              },
                            ),
                            _buildQuickActionItem(
                              IconlyLight.folder,
                              "Project Admin",
                              "Check Project Admin, assigned operatives, forms, and locations.",
                              cardColor: cardColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                              isDark: isDark,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProjectsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildCard(
                        title: "Before You Send",
                        icon: IconlyLight.tick_square,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        child: Column(
                          children: [
                            _buildBeforeSendItem(
                              IconlyLight.edit,
                              "Copy the page URL",
                              "Paste the exact page where the issue appears.",
                              cardColor: cardColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                              isDark: isDark,
                            ),
                            _buildBeforeSendItem(
                              IconlyLight.document,
                              "Add record numbers",
                              "Include project, job, form submission, or user email details.",
                              cardColor: cardColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  if (isMobile) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          contentLeft,
                          const SizedBox(height: 24),
                          contentRight,
                        ],
                      ),
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: SingleChildScrollView(child: contentLeft),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(child: contentRight),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
