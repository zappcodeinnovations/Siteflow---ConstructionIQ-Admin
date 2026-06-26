import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {

  bool notification = true;
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Settings"),
      ),

      body: ListView(
        children: [

          SwitchListTile(

            value: notification,

            onChanged: (value) {
              setState(() {
                notification = value;
              });
            },

            title: const Text("Notifications"),

            secondary: const Icon(Icons.notifications),
          ),

          SwitchListTile(

            value: darkMode,

            onChanged: (value) {
              setState(() {
                darkMode = value;
              });
            },

            title: const Text("Dark Mode"),

            secondary: const Icon(Icons.dark_mode),
          ),

          ListTile(

            leading: const Icon(Icons.lock),

            title: const Text("Change Password"),

            trailing: const Icon(Icons.arrow_forward_ios),
          ),

          ListTile(

            leading: const Icon(Icons.logout),

            title: const Text("Logout"),

            trailing: const Icon(Icons.arrow_forward_ios),

            onTap: () async {
              await AuthService.clearTokens();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}