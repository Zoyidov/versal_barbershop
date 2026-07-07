import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'core/di/injection_container.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Required before any Firebase or platform-channel call when running
  // async setup ahead of runApp.
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initDependencies();

  // Loads Uzbek weekday/month names for DateFormat, and makes 'uz' the
  // default locale used across the app's date formatting.
  await initializeDateFormatting('uz');
  Intl.defaultLocale = 'uz';

  runApp(const VersalApp());
}
