import 'package:euroside_admin/modules/client/client_screen.dart';
import 'package:euroside_admin/modules/dashboard/dashboard.dart';
import 'package:euroside_admin/modules/tasks/task_screen.dart';
import 'package:flutter/material.dart';

import '../projects/projects_screen.dart';

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
  final GlobalKey<ClientsScreenState> clientsScreenKey =
      GlobalKey<ClientsScreenState>();
  final GlobalKey<ProjectsScreenState> projectsScreenKey =
      GlobalKey<ProjectsScreenState>();

  late final List<Widget> pages = [
    DashboardScreen(
      onProjectsTap: () => setState(() => currentIndex = 2),
      onTasksTap: () => setState(() => currentIndex = 3),
    ),
    ClientsScreen(key: clientsScreenKey),
    ProjectsScreen(key: projectsScreenKey),
    const TasksScreen(),
  ];

  final List<String> titles = ["Dashboard", "Clients", "Projects", "Tasks"];

  final List<IconData> icons = [
    IconlyLight.home,
    IconlyLight.user_1,
    IconlyLight.folder,
    IconlyLight.document,
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    return Scaffold(
      appBar: CustomAppBar(
        title: titles[currentIndex],
        actions: currentIndex == 1
            ? [
                IconButton(
                  icon: const Icon(IconlyLight.search),
                  onPressed: () {
                    clientsScreenKey.currentState?.toggleSearch();
                  },
                ),
              ]
            : currentIndex == 2
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
