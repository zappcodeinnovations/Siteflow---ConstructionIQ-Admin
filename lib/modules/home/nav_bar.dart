import 'package:euroside_admin/modules/client/client_screen.dart';
import 'package:euroside_admin/modules/dashboard/dashboard.dart';
import 'package:euroside_admin/modules/tasks/task_screen.dart';
import 'package:flutter/material.dart';

import '../projects/projects_screen.dart';

import '../../core/widgets/custom_drawer.dart';
import '../../core/widgets/custom_appbar.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int currentIndex = 0;
  final GlobalKey<ClientsScreenState> clientsScreenKey = GlobalKey<ClientsScreenState>();

  late final List<Widget> pages = [
    const DashboardScreen(),
    ClientsScreen(key: clientsScreenKey),
    const ProjectsScreen(),
    const TasksScreen(),
  ];

  final List<String> titles = [
    "Dashboard",
    "Clients",
    "Projects",
    "Tasks",
  ];

  final List<IconData> icons = [
    Icons.dashboard_rounded,
    Icons.people_rounded,
    Icons.work_rounded,
    Icons.task_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: titles[currentIndex],
        actions: currentIndex == 1 
            ? [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    clientsScreenKey.currentState?.toggleSearch();
                  },
                )
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
              onDestinationSelected: (value) => setState(() => currentIndex = value),
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: IconThemeData(color: Theme.of(context).primaryColor),
              selectedLabelTextStyle: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
              destinations: [
                for (int i = 0; i < titles.length; i++)
                  NavigationRailDestination(
                    icon: Icon(icons[i], color: Colors.grey.shade400),
                    selectedIcon: Icon(icons[i]),
                    label: Text(titles[i]),
                  )
              ],
            ),
          if (isDesktop) const VerticalDivider(thickness: 1, width: 1),
          // Main Content
          Expanded(child: pages[currentIndex]),
        ],
      ),
      
      // Show premium floating bottom bar on mobile screens
      bottomNavigationBar: isDesktop 
          ? null 
          : SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(titles.length, (index) {
                    final isSelected = currentIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => currentIndex = index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icons[index],
                              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade400,
                              size: 24,
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Text(
                                titles[index],
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
    );
  }
}