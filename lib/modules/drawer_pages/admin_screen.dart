import 'package:flutter/material.dart';
import '../../core/widgets/custom_drawer.dart';
import '../profile/profile_screen.dart';
import 'admin/admin_members_view.dart';
import 'admin/admin_announcements_view.dart';
import 'admin/admin_notifications_view.dart';
import 'admin/admin_permissions_view.dart';
import 'admin/admin_activity_logs_view.dart';
// import 'admin/admin_organisation_view.dart';
import 'admin/admin_support_view.dart';
import 'admin/admin_guests_view.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  final ScrollController _mobileScrollController = ScrollController();

  final List<Map<String, dynamic>> _sideMenus = [
    {"title": "Profile", "icon": IconlyLight.profile},
    {"title": "Members", "icon": IconlyLight.user_1},
    {"title": "Guests", "icon": IconlyLight.message},
    {"title": "Announcements", "icon": IconlyLight.category},
    {"title": "Notifications", "icon": IconlyLight.notification},
    {"title": "Permissions", "icon": IconlyLight.category},
    {"title": "Activity Logs", "icon": IconlyLight.category},
    // {"title": "Organisation", "icon": IconlyLight.work},
    {"title": "Support", "icon": IconlyLight.category},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _mobileScrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveTab(int index) {
    if (_mobileScrollController.hasClients) {
      final screenWidth = MediaQuery.of(context).size.width;
      // Approximate tab width is 120, offset to center it.
      final scrollOffset = (index * 120.0) - (screenWidth / 2) + 60.0;
      _mobileScrollController.animateTo(
        scrollOffset.clamp(0.0, _mobileScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onMenuTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _scrollToActiveTab(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildContent(String menu) {
    switch (menu) {
      case "Profile":
        return const ProfileScreen();
      case "Members":
        return const AdminMembersView();
      case "Guests":
        return const AdminGuestsView();
      case "Announcements":
        return const AdminAnnouncementsView();
      case "Notifications":
        return const AdminNotificationsView();
      case "Permissions":
        return const AdminPermissionsView();
      case "Activity Logs":
        return const AdminActivityLogsView();
      // case "Organisation":
      //   return const AdminOrganisationView();
      case "Support":
        return const AdminSupportView();
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(IconlyLight.category, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text("$menu Content", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
              const Text("This module is under construction.", style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.corporateBlue : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text("ADMIN", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        backgroundColor: isDark ? const Color(0xFF101A26) : const Color(0xFF0F2C4A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundStripesPainter(isDark: isDark),
            ),
          ),
          Column(
            children: [
          // Mobile Horizontal Menu
          if (!isDesktop)
            Container(
              height: 56,
              color: const Color(0xFF0F2C4A),
              child: ListView.builder(
                controller: _mobileScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: _sideMenus.length,
                itemBuilder: (context, index) {
                  final item = _sideMenus[index];
                  final isSelected = _currentIndex == index;
                  return InkWell(
                    onTap: () => _onMenuTapped(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected ? const Color(0xFF0D6EFD) : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          Icon(item["icon"], color: isSelected ? Colors.white : Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            item["title"],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
          Expanded(
            child: Row(
              children: [
                // Desktop Left Sidebar Pane
                if (isDesktop)
                  Container(
                    width: 250,
                    color: const Color(0xFF0F2C4A),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: _sideMenus.length,
                      itemBuilder: (context, index) {
                        final item = _sideMenus[index];
                        final isSelected = _currentIndex == index;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: InkWell(
                            onTap: () => _onMenuTapped(index),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF0D6EFD) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(item["icon"], color: Colors.white, size: 20),
                                  const SizedBox(width: 16),
                                  Text(
                                    item["title"],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                
                // Right Content Pane with Swipe PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                      if (!isDesktop) {
                        _scrollToActiveTab(index);
                      }
                    },
                    itemCount: _sideMenus.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildContent(_sideMenus[index]["title"]),
                      );
                    },
                  ),
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
}