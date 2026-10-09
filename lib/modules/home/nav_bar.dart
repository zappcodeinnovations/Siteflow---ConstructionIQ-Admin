import 'package:euroside_admin/modules/client/client_screen.dart';
import 'package:euroside_admin/modules/dashboard/dashboard.dart';
import 'package:euroside_admin/modules/tasks/task_screen.dart';
import '../dashboard/dashboard_controller.dart';
import 'package:flutter/material.dart';

import '../projects/projects_screen.dart';

import '../../core/services/auth_service.dart';
import '../../core/widgets/custom_drawer.dart';
import '../../core/widgets/custom_appbar.dart';
import 'package:iconly/iconly.dart';
import 'global_search_screen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int currentIndex = 0;
  bool _roleLoaded = false;
  final GlobalKey<ClientsScreenState> clientsScreenKey =
      GlobalKey<ClientsScreenState>();
  final GlobalKey<ProjectsScreenState> projectsScreenKey =
      GlobalKey<ProjectsScreenState>();

  late List<Widget> pages;
  late List<String> titles;
  late List<IconData> icons;
  int? _clientsIndex;
  int? _projectsIndex;
  int? _tasksIndex;

  @override
  void initState() {
    super.initState();
    _loadRoleAndBuildTabs();
  }

  Future<void> _loadRoleAndBuildTabs() async {
    final allowed = await Future.wait([
      AuthService.can('dashboard'),
      AuthService.can('clients'),
      AuthService.can('projects'),
      AuthService.can('tasks'),
    ]);

    pages = [];
    titles = [];
    icons = [];

    void addTab(String title, IconData icon, Widget page) {
      titles.add(title);
      icons.add(icon);
      pages.add(page);
    }

    if (allowed[0]) {
      addTab(
        'Dashboard',
        IconlyLight.home,
        DashboardScreen(
          onProjectsTap: () {
            if (_projectsIndex != null) {
              setState(() => currentIndex = _projectsIndex!);
            }
          },
          onTasksTap: () {
            if (_tasksIndex != null) {
              setState(() => currentIndex = _tasksIndex!);
            }
          },
        ),
      );
    }
    if (allowed[1]) {
      _clientsIndex = pages.length;
      addTab(
        'Clients',
        IconlyLight.user_1,
        ClientsScreen(key: clientsScreenKey),
      );
    }
    if (allowed[2]) {
      _projectsIndex = pages.length;
      addTab(
        'Projects',
        IconlyLight.folder,
        ProjectsScreen(key: projectsScreenKey),
      );
    }
    if (allowed[3]) {
      _tasksIndex = pages.length;
      addTab('Tasks', IconlyLight.document, const TasksScreen());
    }
    if (pages.isEmpty) {
      addTab(
        'Access denied',
        IconlyLight.shield_done,
        const Center(
          child: Text('No modules have been assigned to this account.'),
        ),
      );
    }

    if (mounted) {
      setState(() => _roleLoaded = true);
    }
  }

  Future<void> _logout() async {
    await AuthService.clearTokens();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_roleLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    return Scaffold(
      appBar: CustomAppBar(
        title: titles[currentIndex],
        actions: [
          IconButton(
            icon: const Icon(IconlyLight.search),
            tooltip: currentIndex == _clientsIndex
                ? "Search & Filter Clients"
                : currentIndex == _projectsIndex
                ? "Search & Filter Projects"
                : "Search everything",
            onPressed: () {
              if (currentIndex == _clientsIndex) {
                clientsScreenKey.currentState?.toggleSearch();
              } else if (currentIndex == _projectsIndex) {
                projectsScreenKey.currentState?.toggleSearch();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GlobalSearchScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      drawer: isDesktop ? null : const CustomDrawer(),
      body: Row(
        children: [
          // Show NavigationRail on large screens for true responsiveness
          if (isDesktop)
            NavigationRail(
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedIndex: currentIndex,
              onDestinationSelected: (value) {
                if (value == 0) {
                  DashboardController.triggerGlobalRefresh();
                }
                setState(() => currentIndex = value);
              },
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: IconThemeData(
                color: Theme.of(context).primaryColor,
              ),
              selectedLabelTextStyle: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: IconButton(
                      tooltip: 'Logout',
                      onPressed: _logout,
                      icon: const Icon(IconlyLight.logout),
                    ),
                  ),
                ),
              ),
              destinations: [
                for (int i = 0; i < titles.length; i++)
                  NavigationRailDestination(
                    icon: Icon(
                      icons[i],
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    selectedIcon: Icon(icons[i]),
                    label: Text(titles[i]),
                  ),
              ],
            ),
          if (isDesktop) const VerticalDivider(thickness: 1, width: 1),
          // Main Content
          Expanded(child: pages[currentIndex]),
        ],
      ),

      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
                if (index == 0) {
                  DashboardController.triggerGlobalRefresh();
                }
                setState(() => currentIndex = index);
              },
              type: BottomNavigationBarType.fixed,
              items: List.generate(titles.length, (index) {
                return BottomNavigationBarItem(
                  icon: Icon(icons[index]),
                  label: titles[index],
                );
              }),
            ),
    );
  }
}
