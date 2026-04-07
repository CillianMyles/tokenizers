import 'package:go_router/go_router.dart';
import 'package:tokenizers/src/app/app_shell.dart';
import 'package:tokenizers/src/features/calendar/presentation/medication_calendar_screen.dart';
import 'package:tokenizers/src/features/chat/presentation/chat_screen.dart';
import 'package:tokenizers/src/features/history/presentation/conversation_history_screen.dart';

/// Creates the application's top-level router.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/chat',
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/chat',
                pageBuilder: (context, state) {
                  return const NoTransitionPage<void>(child: ChatScreen());
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
