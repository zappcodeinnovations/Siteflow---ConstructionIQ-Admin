import 'package:euroside_admin/core/widgets/app_back_button.dart';
import 'package:euroside_admin/modules/auth/login_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Logical iPhone sizes (points) and typical keyboard heights.
const _iphones = <String, (Size, double keyboard, EdgeInsets safeArea)>{
  'iPhone SE': (Size(375, 667), 260, EdgeInsets.only(top: 20)),
  'iPhone 13 mini': (Size(375, 812), 336, EdgeInsets.only(top: 50, bottom: 34)),
  'iPhone 15 Pro Max': (Size(430, 932), 346, EdgeInsets.only(top: 59, bottom: 34)),
};

void _useIphone(WidgetTester tester, Size size, EdgeInsets safeArea) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = size * 3;
  tester.view.padding = FakeViewPadding(
    top: safeArea.top * 3,
    bottom: safeArea.bottom * 3,
  );
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Login screen keeps fields above the keyboard', () {
    for (final entry in _iphones.entries) {
      testWidgets(entry.key, (tester) async {
        final (size, keyboard, safeArea) = entry.value;
        _useIphone(tester, size, safeArea);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: TargetPlatform.iOS),
            home: const LoginScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Open the keyboard, then focus the password field.
        tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 3);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(TextFormField).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'no overflow');

        final visibleBottom = size.height - keyboard;
        final password = tester.getRect(find.byType(TextFormField).last);
        expect(password.top, greaterThanOrEqualTo(0));
        expect(
          password.bottom,
          lessThanOrEqualTo(visibleBottom),
          reason: 'password field must not sit under the keyboard',
        );
      });
    }
  });

  group('Back navigation on iOS', () {
    Widget app(Widget secondary) => MaterialApp(
      theme: ThemeData(
        platform: TargetPlatform.iOS,
        actionIconTheme: AppNavigation.actionIconTheme,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Root')),
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => secondary),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    testWidgets('root screen has no back button', (tester) async {
      await tester.pumpWidget(app(const SizedBox()));
      expect(find.byIcon(AppNavigation.backIcon), findsNothing);
    });

    testWidgets('automatic AppBar back uses the chevron and pops', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          Scaffold(
            appBar: AppBar(title: const Text('Detail')),
            body: const TextField(),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(AppNavigation.backIcon), findsOneWidget);
      final button = tester.getSize(find.byType(BackButton));
      expect(button.width, greaterThanOrEqualTo(44));
      expect(button.height, greaterThanOrEqualTo(44));

      await tester.tap(find.byIcon(AppNavigation.backIcon));
      await tester.pumpAndSettle();
      expect(find.text('Root'), findsOneWidget);
      expect(find.text('Detail'), findsNothing);
    });

    testWidgets('swipe from the left edge goes back', (tester) async {
      await tester.pumpWidget(
        app(Scaffold(appBar: AppBar(title: const Text('Detail')))),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(const Offset(5, 300));
      await gesture.moveBy(const Offset(400, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Detail'), findsNothing);
    });

    testWidgets('drawer screens show back + menu without duplicates', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          Scaffold(
            drawer: const Drawer(child: Text('drawer body')),
            appBar: AppBar(
              leading: const AppNavLeading(),
              leadingWidth: AppNavigation.backAndMenuLeadingWidth,
              title: const Text('Drawer page'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(AppNavigation.backIcon), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.text('drawer body'), findsOneWidget);
      Navigator.of(tester.element(find.text('drawer body'))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AppNavigation.backIcon));
      await tester.pumpAndSettle();
      expect(find.text('Root'), findsOneWidget);
    });

    testWidgets('back keeps the previous screen state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Form')),
              body: Column(
                children: [
                  const TextField(key: Key('field')),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => Scaffold(appBar: AppBar()),
                      ),
                    ),
                    child: const Text('next'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byKey(const Key('field')), 'draft');
      await tester.tap(find.text('next'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('draft'), findsOneWidget);
    });
  });
}
