import 'package:flutter/material.dart';
import 'package:tokenizers/src/app/app_router.dart';
import 'package:tokenizers/src/app/app_scope.dart';
import 'package:tokenizers/src/app/app_theme.dart';
import 'package:tokenizers/src/bootstrap/demo_app_bootstrap.dart';

/// Root application widget for the v0 shell.
class CarePalApp extends StatefulWidget {
  /// Creates the application shell.
  const CarePalApp({required this.bootstrap, super.key});

  final AppBootstrap bootstrap;

  @override
  State<CarePalApp> createState() => _CarePalAppState();
}

class _CarePalAppState extends State<CarePalApp> {
  late final router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      bootstrap: widget.bootstrap,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'CarePal',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: router,
      ),
    );
  }
}
