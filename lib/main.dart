import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'core/di/injection_container.dart';
import 'core/services/push_notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Required before any Firebase or platform-channel call when running
  // async setup ahead of runApp.
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initDependencies();

  // Android/iOS only - the web build is the public, no-login booking link
  // (see app.dart) and desktop isn't a push-capable target at all.
  if (isPushCapablePlatform) {
    await sl<PushNotificationService>().initialize();
  }

  // Loads Uzbek weekday/month names for DateFormat, and makes 'uz' the
  // default locale used across the app's date formatting.
  await initializeDateFormatting('uz');
  Intl.defaultLocale = 'uz';

  runApp(const VersalApp());
}
