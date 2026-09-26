import 'package:euroside_admin/modules/client/client_screen.dart';
import 'package:euroside_admin/modules/dashboard/dashboard.dart';
import 'package:euroside_admin/modules/tasks/task_screen.dart';
import 'package:flutter/material.dart';

import '../projects/projects_screen.dart';

import '../../core/services/auth_service.dart';
import '../../core/widgets/custom_drawer.dart';
import '../../core/widgets/custom_appbar.dart';
import 'package:iconly/iconly.dart';

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

  // Built once the account's role is known, since "Clients" (an admin-only
  // area on the web dashboard too, unless an admin grants it) only appears
  // for admin/superuser logins - everyone else gets Dashboard/Projects/Tasks.
  late List<Widget> pages;
  late List<String> titles;
  late List<IconData> icons;
  int? _clientsIndex;
  late int _projectsIndex;
  late int _tasksIndex;

  @override
  void initState() {
    super.initState();
    _loadRoleAndBuildTabs();
  }

  Future<void> _loadRoleAndBuildTabs() async {
    final isAdmin = await AuthService.isAdminUser();

    _clientsIndex = isAdmin ? 1 : null;
    _projectsIndex = isAdmin ? 2 : 1;
    _tasksIndex = isAdmin ? 3 : 2;

    pages = [
      DashboardScreen(
        onProjectsTap: () => setState(() => currentIndex = _projectsIndex),
        onTasksTap: () => setState(() => currentIndex = _tasksIndex),
      ),
      if (isAdmin) ClientsScreen(key: clientsScreenKey),
      ProjectsScreen(key: projectsScreenKey),
      const TasksScreen(),
    ];
    titles = ["Dashboard", if (isAdmin) "Clients", "Projects", "Tasks"];
    icons = [
      IconlyLight.home,
      if (isAdmin) IconlyLight.user_1,
      IconlyLight.folder,
      IconlyLight.document,
    ];

    if (mounted) {
      setState(() => _roleLoaded = true);
    }
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
        actions: currentIndex == _clientsIndex
            ? [
                IconButton(
                  icon: const Icon(IconlyLight.search),
                  onPressed: () {
                    clientsScreenKey.currentState?.toggleSearch();
                  },
                ),
              ]
            : currentIndex == _projectsIndex
                ? [
                    IconButton(
                      icon: const Icon(IconlyLight.search),
                      onPressed: () {
                        projectsScreenKey.currentState?.toggleSearch();
                      },
                    ),
                  ]
                : null,
      ),
      drawer: isDesktop ? null : const CustomDrawer(),
      body: Row(
        children: [
          // Show NavigationRail on large screens for true responsiveness
          if (isDesktop)
            NavigationRail(
              backgroundColor: Colors.white,
              selectedIndex: currentIndex,
              onDestinationSelected: (value) =>
                  setState(() => currentIndex = value),
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: IconThemeData(
                color: Theme.of(context).primaryColor,
              ),
              selectedLabelTextStyle: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
              destinations: [
                for (int i = 0; i < titles.length; i++)
                  NavigationRailDestination(
                    icon: Icon(icons[i], color: Colors.grey.shade400),
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
              onTap: (index) => setState(() => currentIndex = index),
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
