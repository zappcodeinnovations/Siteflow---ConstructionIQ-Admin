import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 0; // 0: Teams, 1: Materials

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
                          "You have 2 teams in your organisation.",
                          style: TextStyle(fontSize: 15, color: textColor),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {},
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
                  _buildTeamItem(
                    name: "Team A",
                    createdAt: "23 Jun 2026, 03:15 PM",
                    lead: "No team lead assigned",
                    shift: "Not set",
                    members: "0 Members",
                    isDesktop: isDesktop,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    borderColor: borderColor,
                  ),
                  _buildTeamItem(
                    name: "TEAM LSE",
                    createdAt: "19 Jun 2026, 03:28 PM",
                    lead: "George Barrett",
                    shift: "Not set",
                    members: "27 Members",
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
    required String name,
    required String createdAt,
    required String lead,
    required String shift,
    required String members,
    required bool isDesktop,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
  }) {
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
                onPressed: () {},
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