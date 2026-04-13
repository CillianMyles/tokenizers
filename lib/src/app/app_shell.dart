import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tokenizers/src/app/app_scope.dart';
import 'package:tokenizers/src/app/app_theme.dart';
import 'package:tokenizers/src/app/theme_mode_controller.dart';

const double _desktopNavigationBreakpoint = 900;
const int _assistantDestinationIndex = 1;
const int _settingsDestinationIndex = 4;
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
            return _InterpolatedComponentTheme(
              child: Scaffold(
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
              ),
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

/// Overrides component theme colors with values read from the interpolated
/// [ColorScheme] so they transition smoothly during theme animations.
///
/// [ThemeData.lerp] properly interpolates [ColorScheme] but snaps component
/// themes (e.g. [InputDecorationTheme]) at the 50% mark. This widget
/// re-resolves those colors from the already-interpolated color scheme.
class _InterpolatedComponentTheme extends StatelessWidget {
  const _InterpolatedComponentTheme({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          fillColor: colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
        ),
        cardTheme: theme.cardTheme.copyWith(color: colorScheme.surface),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

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
      child: SizedBox(
        width: 216,
        child: Column(
          children: <Widget>[
            Expanded(
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
              ),
            ),
            const _ThemeModeToggle(),
          ],
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
    final showConfigurationBanner =
        navigationShell.currentIndex == _assistantDestinationIndex;
    final configurationMessage = showConfigurationBanner
        ? configurationError
        : null;

    return Column(
      children: <Widget>[
        if (configurationMessage case final message?) ...<Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: _ConfigurationBanner(
                  message: message,
                  onOpenSettings: () {
                    navigationShell.goBranch(_settingsDestinationIndex);
                  },
                ),
              ),
            ),
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
    final controller = AppScope.of(context).themeModeController;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _CompactThemeModeToggle(
              controller: controller,
              isDark: isDark,
              colorScheme: colorScheme,
            ),
          ),
        ),
        NavigationBar(
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
        ),
      ],
    );
  }
}

class _ConfigurationBanner extends StatelessWidget {
  const _ConfigurationBanner({
    required this.message,
    required this.onOpenSettings,
  });

  final String message;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.75),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Open Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeToggle extends StatelessWidget {
  const _ThemeModeToggle();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).themeModeController;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              controller.toggle(MediaQuery.platformBrightnessOf(context)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: <Widget>[
                Icon(
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    isDark ? 'Dark Mode' : 'Light Mode',
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
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

class _CompactThemeModeToggle extends StatelessWidget {
  const _CompactThemeModeToggle({
    required this.controller,
    required this.isDark,
    required this.colorScheme,
  });

  final ThemeModeController controller;
  final bool isDark;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
        size: 18,
      ),
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      onPressed: () =>
          controller.toggle(MediaQuery.platformBrightnessOf(context)),
      style: IconButton.styleFrom(
        foregroundColor: colorScheme.onSurfaceVariant,
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
