import 'package:flutter/widgets.dart';

import 'package:tokenizers/env/env.dart';
import 'package:tokenizers/src/app/tokenizers_app.dart';
import 'package:tokenizers/src/bootstrap/demo_app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  final bootstrap = await createDemoAppBootstrap();
  runApp(TokenizersApp(bootstrap: bootstrap));
}
