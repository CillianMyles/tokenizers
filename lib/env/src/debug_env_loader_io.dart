import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> loadDebugEnvImpl() async {
  if (!_supportsDebugEnv()) {
    dotenv.loadFromString(envString: '', isOptional: true);
    return;
  }

  const envFile = '.env';
  final file = File(envFile);
  if (!await file.exists()) {
    dotenv.loadFromString(envString: '', isOptional: true);
    return;
  }

  final envString = await file.readAsString();
  dotenv.loadFromString(envString: envString, isOptional: true);
}

bool _supportsDebugEnv() {
  if (kIsWeb) {
    return false;
  }

  if (!kDebugMode) {
    return false;
  }

  return Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isLinux ||
      Platform.isWindows;
}
