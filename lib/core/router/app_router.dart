import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agroa_videocall/view/call_screen.dart';
import 'package:agroa_videocall/view/dashboard_screen.dart';
import 'package:agroa_videocall/view/splash_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/call',
        builder: (context, state) {
          final channelName = state.uri.queryParameters['channelName'] ?? '';
          final roleIndexStr = state.uri.queryParameters['roleIndex'];
          final roleIndex = roleIndexStr != null ? int.tryParse(roleIndexStr) : null;
          final userRole = roleIndex != null && roleIndex >= 0 && roleIndex < ClientRoleType.values.length
              ? ClientRoleType.values[roleIndex]
              : ClientRoleType.clientRoleBroadcaster;

          return CallScreen(
            channelName: channelName,
            userRole: userRole,
          );
        },
      ),
    ],
  );
});
