import 'package:erpnext_stock_mobile/src/core/widgets/navigation/app_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('primary navigation button is tappable and sized like before',
      (tester) async {
    int selectedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: AppNavigationBar(
            height: 60,
            destinations: const [
              AppNavigationDestination(
                label: 'Home',
                icon: Icon(Icons.home_outlined),
              ),
              AppNavigationDestination(
                label: 'Search',
                icon: Icon(Icons.search_outlined),
              ),
              AppNavigationDestination(
                label: 'Create',
                icon: Icon(Icons.add_rounded),
                selectedIcon: Icon(Icons.add_rounded),
                isPrimary: true,
              ),
              AppNavigationDestination(
                label: 'Files',
                icon: Icon(Icons.folder_outlined),
              ),
            ],
            selectedIndex: 0,
            onDestinationSelected: (index) {
              selectedIndex = index;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final buttonFinder =
        find.byKey(const ValueKey('app-primary-navigation-button'));
    final navBarFinder = find.byType(NavigationBar);
    expect(buttonFinder, findsOneWidget);
    expect(navBarFinder, findsOneWidget);
    expect(tester.getSize(buttonFinder), const Size(80, 80));

    final buttonRect = tester.getRect(buttonFinder);
    final navBarRect = tester.getRect(navBarFinder);
    expect(buttonRect.top, lessThan(navBarRect.top));
    expect(buttonRect.bottom, lessThan(navBarRect.top));

    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(selectedIndex, 2);
  });

  testWidgets('navigation bar ignores bottom system padding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            padding: EdgeInsets.only(bottom: 32),
          ),
          child: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: AppNavigationBar(
              destinations: const [
                AppNavigationDestination(
                  label: 'Home',
                  icon: Icon(Icons.home_outlined),
                ),
                AppNavigationDestination(
                  label: 'Search',
                  icon: Icon(Icons.search_outlined),
                ),
              ],
              selectedIndex: 0,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final navBarFinder = find.byType(NavigationBar);
    expect(navBarFinder, findsOneWidget);
    expect(tester.getSize(navBarFinder).height, appNavigationBarHeight);
  });

  testWidgets('navigation bar lifts above system bottom inset', (tester) async {
    addTearDown(() {
      tester.view.viewPadding = FakeViewPadding.zero;
      tester.view.systemGestureInsets = FakeViewPadding.zero;
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewPadding = const FakeViewPadding(bottom: 32);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: AppNavigationBar(
            height: 60,
            destinations: const [
              AppNavigationDestination(
                label: 'Home',
                icon: Icon(Icons.home_outlined),
              ),
              AppNavigationDestination(
                label: 'Search',
                icon: Icon(Icons.search_outlined),
              ),
            ],
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final hostFinder = find.byKey(const ValueKey('app-navigation-bar-host'));
    final shellFinder = find.byKey(const ValueKey('app-navigation-bar-shell'));
    expect(hostFinder, findsOneWidget);
    expect(shellFinder, findsOneWidget);
    expect(tester.getSize(shellFinder).height, closeTo(92.0, 0.01));
    expect(tester.getSize(hostFinder).height, closeTo(92.0, 0.01));
  });

  testWidgets('navigation bar also lifts above gesture inset', (tester) async {
    addTearDown(() {
      tester.view.viewPadding = FakeViewPadding.zero;
      tester.view.systemGestureInsets = FakeViewPadding.zero;
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1.0;
    tester.view.viewPadding = FakeViewPadding.zero;
    tester.view.systemGestureInsets = const FakeViewPadding(bottom: 24);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: AppNavigationBar(
            height: 60,
            destinations: const [
              AppNavigationDestination(
                label: 'Home',
                icon: Icon(Icons.home_outlined),
              ),
              AppNavigationDestination(
                label: 'Search',
                icon: Icon(Icons.search_outlined),
              ),
            ],
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final hostFinder = find.byKey(const ValueKey('app-navigation-bar-host'));
    final shellFinder = find.byKey(const ValueKey('app-navigation-bar-shell'));
    expect(hostFinder, findsOneWidget);
    expect(shellFinder, findsOneWidget);
    expect(tester.getSize(shellFinder).height, closeTo(84.0, 0.01));
    expect(tester.getSize(hostFinder).height, closeTo(84.0, 0.01));
  });

  testWidgets('primary destination can be hidden without breaking taps',
      (tester) async {
    int selectedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: AppNavigationBar(
            primaryVisible: false,
            destinations: const [
              AppNavigationDestination(
                label: 'Home',
                icon: Icon(Icons.home_outlined),
              ),
              AppNavigationDestination(
                label: 'Search',
                icon: Icon(Icons.search_outlined),
              ),
              AppNavigationDestination(
                label: 'Create',
                icon: Icon(Icons.add_rounded),
                isPrimary: true,
              ),
              AppNavigationDestination(
                label: 'Files',
                icon: Icon(Icons.folder_outlined),
              ),
              AppNavigationDestination(
                label: 'Profile',
                icon: Icon(Icons.person_outline),
              ),
            ],
            selectedIndex: 4,
            onDestinationSelected: (index) {
              selectedIndex = index;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('app-primary-navigation-button')),
        findsNothing);

    await tester.tap(find.text('Files'));
    await tester.pumpAndSettle();

    expect(selectedIndex, 3);
  });
}
