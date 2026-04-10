import 'package:flutter/widgets.dart';

import 'package:tokenizers/env/env.dart';
import 'package:tokenizers/src/app/care_pal_app.dart';
import 'package:tokenizers/src/bootstrap/demo_app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  final bootstrap = await createDemoAppBootstrap();
  runApp(CarePalApp(bootstrap: bootstrap));
}
