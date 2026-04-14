import 'package:flutter/material.dart';
import 'package:tokenizers/src/app/app_router.dart';
import 'package:tokenizers/src/app/app_scope.dart';
import 'package:tokenizers/src/app/app_theme.dart';
import 'package:tokenizers/src/bootstrap/demo_app_bootstrap.dart';

/// Root application widget for the v0 shell.
class TokenizersApp extends StatefulWidget {
  /// Creates the application shell.
  const TokenizersApp({required this.bootstrap, super.key});

  final AppBootstrap bootstrap;

  @override
  State<TokenizersApp> createState() => _TokenizersAppState();
}

class _TokenizersAppState extends State<TokenizersApp> {
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
