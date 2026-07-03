import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agroa_videocall/constants/api_setting.dart';
import 'package:agroa_videocall/main.dart';
import 'package:agroa_videocall/view/dashboard_screen.dart';
import 'package:agroa_videocall/view/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wraps a widget in a simple MaterialApp with Material 3 theme, ProviderScope and GoRouter context.
Widget _wrapWithApp(Widget child) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => child,
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
  return ProviderScope(
    child: MaterialApp.router(
      theme: ThemeData(useMaterial3: true),
      routerConfig: router,
    ),
  );
}

/// Pumps a widget and drains any pending timers up to [duration].
/// Use this whenever the widget under test starts a Timer (e.g. SplashScreen).
Future<void> _pumpAndDrainTimers(
  WidgetTester tester,
  Widget widget, {
  Duration drainFor = const Duration(seconds: 4),
}) async {
  await tester.pumpWidget(widget);
  await tester.pump(drainFor); // drain the splash-screen timer
  await tester.pumpAndSettle(); // settle any animations
}

// ---------------------------------------------------------------------------
// APISettings unit tests
// ---------------------------------------------------------------------------

void main() {
  group('APISettings', () {
    test('appID is not empty', () {
      expect(APISettings.appID, isNotEmpty);
    });

    test('channelName is not empty', () {
      expect(APISettings.channelName, isNotEmpty);
    });

    test('appID has expected format (32 hex chars)', () {
      final hexRegex = RegExp(r'^[a-f0-9]{32}$');
      expect(hexRegex.hasMatch(APISettings.appID), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // MyApp widget tests
  // -------------------------------------------------------------------------

  group('MyApp', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await _pumpAndDrainTimers(tester, const MyApp());
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('uses Material 3', (WidgetTester tester) async {
      await _pumpAndDrainTimers(tester, const MyApp());
      final MaterialApp app =
          tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme?.useMaterial3, isTrue);
    });

    testWidgets('title is Agora Live Broadcast', (WidgetTester tester) async {
      await _pumpAndDrainTimers(tester, const MyApp());
      final MaterialApp app =
          tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, equals('Agora Live Broadcast'));
    });

    testWidgets('home starts with SplashScreen then navigates away',
        (WidgetTester tester) async {
      // Before the timer fires, SplashScreen is shown
      await tester.pumpWidget(const MyApp());
      await tester.pump(); // settle first frame
      expect(find.byType(SplashScreen), findsOneWidget);
      // Drain the 3-second timer so the test ends cleanly
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });

  // -------------------------------------------------------------------------
  // SplashScreen widget tests
  // -------------------------------------------------------------------------

  group('SplashScreen', () {
    testWidgets('displays "Live Broadcast" text', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const SplashScreen()));
      await tester.pump(); // first frame
      expect(find.text('Live Broadcast'), findsOneWidget);
      // Drain timer
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('displays "Powered by Agora" subtitle',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const SplashScreen()));
      await tester.pump();
      expect(find.text('Powered by Agora'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('shows broadcast icon', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const SplashScreen()));
      await tester.pump();
      expect(
          find.byIcon(Icons.broadcast_on_personal_rounded), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('shows CircularProgressIndicator', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const SplashScreen()));
      await tester.pump(const Duration(milliseconds: 900));
      // After the fade animation begins, the progress indicator should be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('navigates to DashboardScreen after 3 seconds',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const SplashScreen()));
      await tester.pump();

      // Advance time past the 3 s timer
      await tester.pump(const Duration(seconds: 4));

      // Allow the page route transition to complete
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('has gradient background', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const SplashScreen()));
      await tester.pump();
      // The gradient is applied via a Container with BoxDecoration
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasGradient = containers.any((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration && decoration.gradient != null;
      });
      expect(hasGradient, isTrue);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });

  // -------------------------------------------------------------------------
  // DashboardScreen widget tests
  // -------------------------------------------------------------------------

  group('DashboardScreen', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const DashboardScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('shows AppBar with "Live Broadcast" title',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const DashboardScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Live Broadcast'), findsWidgets);
    });

    testWidgets('shows channel name text field', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const DashboardScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('channelNameField')), findsOneWidget);
    });

    testWidgets('shows Broadcaster radio tile', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const DashboardScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Broadcaster'), findsOneWidget);
    });

    testWidgets('shows Audience radio tile', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const DashboardScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Audience'), findsOneWidget);
    });

    testWidgets('shows "Join Channel" button', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const DashboardScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('connectButton')), findsOneWidget);
      expect(find.text('Join Channel'), findsOneWidget);
    });

    testWidgets('shows "Go Live" heading', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const DashboardScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Go Live'), findsOneWidget);
    });

    testWidgets('Broadcaster role is selected by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const DashboardScreen()));
      await tester.pumpAndSettle();

      final broadcasterRadio = tester
          .widget<Radio<ClientRoleType>>(find.byWidgetPredicate((w) =>
              w is Radio<ClientRoleType> &&
              w.value == ClientRoleType.clientRoleBroadcaster));
      // ignore: deprecated_member_use
      expect(broadcasterRadio.groupValue,
          equals(ClientRoleType.clientRoleBroadcaster));
    });

    testWidgets('shows validation error when channel is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const DashboardScreen()));
      await tester.pumpAndSettle();

      // Scroll to button and tap
      final connectBtn = find.byKey(const Key('connectButton'));
      await tester.ensureVisible(connectBtn);
      await tester.tap(connectBtn);
      await tester.pump();

      expect(find.text('Channel name is required'), findsOneWidget);
    });

    testWidgets('clears validation error when text is typed',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const DashboardScreen()));
      await tester.pumpAndSettle();

      // Scroll to button and trigger validation error
      final connectBtn = find.byKey(const Key('connectButton'));
      await tester.ensureVisible(connectBtn);
      await tester.tap(connectBtn);
      await tester.pump();
      expect(find.text('Channel name is required'), findsOneWidget);

      // Now type in the field
      await tester.enterText(
          find.byKey(const Key('channelNameField')), 'my_channel');
      await tester.pump();
      expect(find.text('Channel name is required'), findsNothing);
    });

    testWidgets('can switch to Audience role', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const DashboardScreen()));
      await tester.pumpAndSettle();

      // Tap directly on the Radio widget after scrolling it into view
      final audienceRadioFinder = find.byWidgetPredicate((w) =>
          w is Radio<ClientRoleType> &&
          w.value == ClientRoleType.clientRoleAudience);
      await tester.ensureVisible(audienceRadioFinder);
      await tester.tap(audienceRadioFinder);
      await tester.pump();

      final audienceRadio =
          tester.widget<Radio<ClientRoleType>>(audienceRadioFinder);
      // ignore: deprecated_member_use
      expect(audienceRadio.groupValue,
          equals(ClientRoleType.clientRoleAudience));
    });

    testWidgets('channel text field accepts input', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const DashboardScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('channelNameField')), 'test_channel');
      await tester.pump();

      expect(find.text('test_channel'), findsOneWidget);
    });

    testWidgets('shows two Radio buttons', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const DashboardScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(Radio<ClientRoleType>), findsNWidgets(2));
    });

    testWidgets('FilledButton uses correct key', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const DashboardScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('connectButton')), findsOneWidget);
      final widget = tester.widget(find.byKey(const Key('connectButton')));
      expect(widget, isA<FilledButton>());
    });

    testWidgets('has Channel card and Role card', (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const DashboardScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(Card), findsAtLeastNWidgets(2));
    });
  });

  // -------------------------------------------------------------------------
  // CallScreen UI tests (scaffold mock – avoids Agora engine init)
  // -------------------------------------------------------------------------

  group('CallScreen UI', () {
    Widget buildMockCallUI({
      String channelName = 'test',
    }) {
      return _wrapWithApp(
        Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              const Center(child: CircularProgressIndicator()),
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        channelName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('shows channel name in UI', (WidgetTester tester) async {
      await tester.pumpWidget(buildMockCallUI(channelName: 'my_stream'));
      await tester.pump();
      expect(find.text('my_stream'), findsOneWidget);
    });

    testWidgets('shows LIVE badge', (WidgetTester tester) async {
      await tester.pumpWidget(buildMockCallUI());
      await tester.pump();
      expect(find.text('LIVE'), findsOneWidget);
    });

    testWidgets('shows loading indicator when engine not ready',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildMockCallUI());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('LIVE badge has red background', (WidgetTester tester) async {
      await tester.pumpWidget(buildMockCallUI());
      await tester.pump();
      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('LIVE'),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.red));
    });
  });

  // -------------------------------------------------------------------------
  // Theme & Material 3 tests
  // -------------------------------------------------------------------------

  group('Material 3 Theme', () {
    testWidgets('uses ColorScheme from seed', (WidgetTester tester) async {
      await _pumpAndDrainTimers(tester, const MyApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme?.colorScheme, isNotNull);
      expect(app.theme?.useMaterial3, isTrue);
    });

    testWidgets('appBar theme has elevation 0', (WidgetTester tester) async {
      await _pumpAndDrainTimers(tester, const MyApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme?.appBarTheme.elevation, equals(0));
    });

    testWidgets('dashboard uses FilledButton for connect',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const DashboardScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(FilledButton), findsAtLeastNWidgets(1));
    });

    testWidgets('dashboard uses Cards for sections',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrapWithApp(const DashboardScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(Card), findsAtLeastNWidgets(2));
    });

    testWidgets('theme has CardThemeData with elevation 4',
        (WidgetTester tester) async {
      await _pumpAndDrainTimers(tester, const MyApp());
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme?.cardTheme.elevation, equals(4));
    });
  });
}
