import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:euroside_admin/core/widgets/global_keyboard_dismiss.dart';

void main() {
  testWidgets('Tapping outside an active input dismisses focus', (tester) async {
    final focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlobalKeyboardDismiss(
            child: Column(
              children: [
                TextField(
                  key: const ValueKey('input1'),
                  focusNode: focusNode,
                ),
                const SizedBox(height: 100),
                const Text('Outside Area', key: ValueKey('outside')),
              ],
            ),
          ),
        ),
      ),
    );

    // Tap to focus TextField
    await tester.tap(find.byKey(const ValueKey('input1')));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    // Tap outside the TextField
    await tester.tap(find.byKey(const ValueKey('outside')));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('Tapping inside the active input preserves focus', (tester) async {
    final focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlobalKeyboardDismiss(
            child: Center(
              child: SizedBox(
                width: 300,
                child: TextField(
                  key: const ValueKey('input1'),
                  focusNode: focusNode,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('input1')));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    // Tap inside the TextField again (e.g. cursor positioning)
    await tester.tap(find.byKey(const ValueKey('input1')));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('Scrolling dismisses focus', (tester) async {
    final focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlobalKeyboardDismiss(
            child: ListView(
              children: [
                TextField(
                  key: const ValueKey('input1'),
                  focusNode: focusNode,
                ),
                for (int i = 0; i < 30; i++)
                  ListTile(title: Text('Item $i')),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('input1')));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    // Drag / scroll the list
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('iOS keyboard toolbar displays Done button when keyboard is visible on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final focusNode = FocusNode();

    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              viewInsets: EdgeInsets.only(bottom: 300), // Simulating open keyboard
            ),
            child: GlobalKeyboardDismiss(
              child: Scaffold(
                body: TextField(
                  key: const ValueKey('input1'),
                  focusNode: focusNode,
                ),
              ),
            ),
          ),
        ),
      );

      // Focus the field
      await tester.tap(find.byKey(const ValueKey('input1')));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      // On iOS with keyboard visible, 'Done' button must be rendered
      expect(find.text('Done'), findsOneWidget);

      // Tap 'Done'
      await tester.tap(find.text('Done'));
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Android does NOT render iOS toolbar even when keyboard is open', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final focusNode = FocusNode();

    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              viewInsets: EdgeInsets.only(bottom: 300),
            ),
            child: GlobalKeyboardDismiss(
              child: Scaffold(
                body: TextField(
                  key: const ValueKey('input1'),
                  focusNode: focusNode,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('input1')));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      // Should NOT find iOS Done button on Android
      expect(find.text('Done'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
