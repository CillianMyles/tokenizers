import 'package:go_router/go_router.dart';
import 'package:tokenizers/src/app/app_shell.dart';
import 'package:tokenizers/src/features/assistant/presentation/assistant_screen.dart';
import 'package:tokenizers/src/features/calendar/presentation/medication_calendar_screen.dart';
import 'package:tokenizers/src/features/history/presentation/conversation_history_screen.dart';
import 'package:tokenizers/src/features/today/presentation/today_screen.dart';

/// Creates the application's top-level router.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/today',
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/today',
                pageBuilder: (context, state) {
                  return const NoTransitionPage<void>(child: TodayScreen());
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/assistant',
                pageBuilder: (context, state) {
                  return const NoTransitionPage<void>(child: AssistantScreen());
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/calendar',
                pageBuilder: (context, state) {
                  return const NoTransitionPage<void>(
                    child: MedicationCalendarScreen(),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/history',
                pageBuilder: (context, state) {
                  return const NoTransitionPage<void>(
                    child: ConversationHistoryScreen(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
