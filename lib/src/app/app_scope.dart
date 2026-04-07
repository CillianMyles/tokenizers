import 'package:flutter/widgets.dart';

import 'package:tokenizers/src/bootstrap/demo_app_bootstrap.dart';

/// Makes app services available to the widget tree.
class AppScope extends InheritedWidget {
  /// Creates an app scope.
  const AppScope({required this.bootstrap, required super.child, super.key});

  final AppBootstrap bootstrap;

  /// Returns the current app scope.
  static AppBootstrap of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context.');
    return scope!.bootstrap;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return bootstrap != oldWidget.bootstrap;
  }
}
