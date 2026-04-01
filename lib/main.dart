import 'package:flutter/widgets.dart';

import 'src/genui_prototype_page.dart';

void main() {
  runApp(const TokenizersApp());
}

/// Root application widget for the GenUI prototype demo.
class TokenizersApp extends StatelessWidget {
  /// Creates the application shell.
  const TokenizersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const GenUiPrototypeApp();
  }
}
