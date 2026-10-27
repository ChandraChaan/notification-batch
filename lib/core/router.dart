import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/apps/presentation/apps_page.dart';
import '../features/inbox/presentation/inbox_page.dart';
import '../features/onboarding/presentation/setup_page.dart';
import '../features/onboarding/presentation/welcome_page.dart';
import '../features/rules/presentation/rules_page.dart';
import '../features/schedule/presentation/schedule_page.dart';
import '../features/settings/presentation/settings_controller.dart';
import '../features/shell/presentation/home_shell.dart';
import '../features/stats/presentation/stats_page.dart';
import '../features/status/presentation/status_controller.dart';
import 'widgets/states.dart';

const _gatePaths = {'/start', '/welcome', '/setup'};

final routerProvider = Provider<GoRouter>((ref) {
  final gate = ValueNotifier(ref.read(gateProvider));
  ref.listen(gateProvider, (_, next) => gate.value = next);
  final router = GoRouter(
    initialLocation: '/start',
    refreshListenable: gate,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final target = switch (gate.value) {
        Gate.loading || Gate.error => '/start',
        Gate.needsAccess => '/welcome',
        Gate.needsSetup => '/setup',
        Gate.ready => null,
      };
      if (target != null) return location == target ? null : target;
      return _gatePaths.contains(location) ? '/' : null;
    },
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const _StartPage()),
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomePage()),
      GoRoute(path: '/setup', builder: (context, state) => const SetupPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (context, state) => const InboxPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/apps', builder: (context, state) => const AppsPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/schedule', builder: (context, state) => const SchedulePage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/rules', builder: (context, state) => const RulesPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/stats', builder: (context, state) => const StatsPage())],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    gate.dispose();
  });
  return router;
});

/// Shown while the first status and settings load, or if they fail.
class _StartPage extends ConsumerWidget {
  const _StartPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ref.watch(gateProvider) == Gate.error
          ? ErrorView(
              onRetry: () {
                ref.invalidate(statusControllerProvider);
                ref.invalidate(settingsControllerProvider);
              },
            )
          : const LoadingView(),
    );
  }
}
