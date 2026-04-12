import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tokenizers/src/app/app_scope.dart';
import 'package:tokenizers/src/app/app_theme.dart';

const double _desktopNavigationBreakpoint = 900;
const List<_ShellDestination> _shellDestinations = <_ShellDestination>[
  _ShellDestination(
    icon: Icons.today_outlined,
    label: 'Today',
    selectedIcon: Icons.today,
  ),
  _ShellDestination(
    icon: Icons.auto_awesome_outlined,
    label: 'Assistant',
    selectedIcon: Icons.auto_awesome,
  ),
  _ShellDestination(
    icon: Icons.medication_outlined,
    label: 'Calendar',
    selectedIcon: Icons.medication,
  ),
  _ShellDestination(
    icon: Icons.history_outlined,
    label: 'History',
    selectedIcon: Icons.history,
  ),
  _ShellDestination(
    icon: Icons.settings_outlined,
    label: 'Settings',
    selectedIcon: Icons.settings,
  ),
];

/// Shared scaffold with the primary app navigation.
class AppShell extends StatelessWidget {
  /// Creates the shared app shell.
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final bootstrap = AppScope.of(context);
    return ListenableBuilder(
      listenable: bootstrap.aiSettingsController,
      builder: (context, child) {
        final configurationError =
            bootstrap.aiSettingsController.configurationError;
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop =
                constraints.maxWidth >= _desktopNavigationBreakpoint;
            return Scaffold(
              body: _ShellBackground(
                child: SafeArea(
                  child: isDesktop
                      ? _DesktopShellLayout(
                          configurationError: configurationError,
                          navigationShell: navigationShell,
                        )
                      : _ShellContent(
                          configurationError: configurationError,
                          navigationShell: navigationShell,
                        ),
                ),
              ),
              bottomNavigationBar: isDesktop
                  ? null
                  : _AppNavigationBar(navigationShell: navigationShell),
            );
          },
        );
      },
    );
  }
}

class _ShellBackground extends StatelessWidget {
  const _ShellBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shellPalette = Theme.of(context).extension<AppShellPalette>();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            shellPalette?.gradientStart ?? const Color(0xFFF4F8F5),
            shellPalette?.gradientEnd ?? const Color(0xFFE5EEE8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

class _DesktopShellLayout extends StatelessWidget {
  const _DesktopShellLayout({
    required this.configurationError,
    required this.navigationShell,
  });

  final String? configurationError;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          _DesktopNavigationRail(navigationShell: navigationShell),
          const SizedBox(width: 16),
          Expanded(
            child: _ShellContent(
              configurationError: configurationError,
              navigationShell: navigationShell,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopNavigationRail extends StatelessWidget {
  const _DesktopNavigationRail({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w700,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: isDark ? 0.82 : 0.9),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.85),
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            blurRadius: 30,
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.2 : 0.08),
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: NavigationRail(
        backgroundColor: Colors.transparent,
        extended: true,
        groupAlignment: -1,
        minExtendedWidth: 216,
        onDestinationSelected: navigationShell.goBranch,
        selectedIndex: navigationShell.currentIndex,
        destinations: _shellDestinations
            .map((destination) {
              return NavigationRailDestination(
                icon: Icon(destination.icon),
                label: Text(destination.label),
                selectedIcon: Icon(destination.selectedIcon),
              );
            })
            .toList(growable: false),
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 24),
          child: SizedBox(
            width: 168,
            child: Row(
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.space_dashboard_outlined,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tokenizers',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellContent extends StatelessWidget {
  const _ShellContent({
    required this.configurationError,
    required this.navigationShell,
  });

  final String? configurationError;
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (configurationError case final message?) ...<Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _ConfigurationBanner(message: message),
          ),
          const SizedBox(height: 8),
        ],
        Expanded(child: navigationShell),
      ],
    );
  }
}

class _AppNavigationBar extends StatelessWidget {
  const _AppNavigationBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: navigationShell.goBranch,
      destinations: _shellDestinations
          .map((destination) {
            return NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
              selectedIcon: Icon(destination.selectedIcon),
            );
          })
          .toList(growable: false),
    );
  }
}

class _ConfigurationBanner extends StatelessWidget {
  const _ConfigurationBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.icon,
    required this.label,
    required this.selectedIcon,
  });

  final IconData icon;
  final String label;
  final IconData selectedIcon;
}
