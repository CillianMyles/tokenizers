import 'package:flutter/widgets.dart';

import 'src/app/tokenizers_app.dart';
import 'src/bootstrap/demo_app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await createDemoAppBootstrap();
  runApp(TokenizersApp(bootstrap: bootstrap));
}
