import 'package:go_router/go_router.dart';

import '../features/calendar/presentation/medication_calendar_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/history/presentation/conversation_history_screen.dart';
import 'app_shell.dart';

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
