import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/app_sfx_service.dart';
import 'core/services/firebase_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseInitializer.initialize();
  await AppSfxService.instance.init();

  runApp(const ProviderScope(child: EarthScienceApp()));
}
