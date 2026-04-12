import 'package:tokenizers/env/src/debug_env_loader_stub.dart'
    if (dart.library.io) 'package:tokenizers/env/src/debug_env_loader_io.dart';

Future<void> loadDebugEnv() => loadDebugEnvImpl();
