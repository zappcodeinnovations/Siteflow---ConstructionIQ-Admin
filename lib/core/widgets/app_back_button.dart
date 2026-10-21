import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// App-wide back navigation.
///
/// iPhones have no system back button, so every secondary screen needs a
/// visible chevron in the top-left. Automatic AppBar back buttons pick up
/// [AppNavigation.actionIconTheme] (set on both app themes); screens with a
/// custom header or a drawer use [AppBackButton] / [AppNavLeading] instead.
class AppNavigation {
  AppNavigation._();

  /// iOS-style chevron used for every back button in the app.
  static const IconData backIcon = CupertinoIcons.chevron_left;

  /// Width of an AppBar `leading` holding a back button and a menu button.
  static const double backAndMenuLeadingWidth = 96;

  static final ActionIconThemeData actionIconTheme = ActionIconThemeData(
    backButtonIconBuilder: (context) =>
        const Icon(backIcon, semanticLabel: 'Back'),
  );

  /// Pops to the previous screen. Screens reached from the drawer replace
  /// everything above Home, so when there is nothing to pop (e.g. after a
  /// deep link) fall back to Home instead of leaving the user stuck.
  static void goBack(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }
}

/// Chevron back button with a 44pt tap target (Apple HIG minimum).
class AppBackButton extends StatelessWidget {
  final Color? color;
  final VoidCallback? onPressed;

  const AppBackButton({super.key, this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(AppNavigation.backIcon, color: color),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      onPressed: onPressed ?? () => AppNavigation.goBack(context),
    );
  }
}

/// AppBar `leading` for screens that also own a drawer: back chevron first,
/// then the menu button, so neither navigation path is lost. Use with
/// `leadingWidth: AppNavigation.backAndMenuLeadingWidth`.
class AppNavLeading extends StatelessWidget {
  final Color? color;

  const AppNavLeading({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBackButton(color: color),
        Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: color),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ],
    );
  }
}
