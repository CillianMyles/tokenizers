import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> loadDebugEnvImpl() async {
  dotenv.loadFromString(envString: '', isOptional: true);
}
