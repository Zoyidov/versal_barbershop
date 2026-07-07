import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:versal/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App login and time picker test', (WidgetTester tester) async {
    // 1. Run main app
    app.main();
    await tester.pumpAndSettle();

    // 2. Load credentials from integration_test/test_credentials.json
    final file = File('integration_test/test_credentials.json');
    if (!file.existsSync()) {
      debugPrint('========================================================================');
      debugPrint('WARNING: test_credentials.json not found!');
      debugPrint('Please create integration_test/test_credentials.json with your credentials:');
      debugPrint('{');
      debugPrint('  "phoneNumber": "+998XXXXXXXXX",');
      debugPrint('  "password": "YOUR_PASSWORD"');
      debugPrint('}');
      debugPrint('========================================================================');
      return;
    }

    final data = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    final phoneNumber = data['phoneNumber'] as String;
    final password = data['password'] as String;

    // Wait for the app to bootstrap and check if we are on splash screen
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Check if we are on the login screen or already authenticated
    final phoneFieldFinder = find.byType(EditableText).first;
    final passwordFieldFinder = find.byType(EditableText).last;

    if (find.text('Kirish').evaluate().isNotEmpty) {
      // Input phone
      await tester.enterText(phoneFieldFinder, phoneNumber);
      await tester.pumpAndSettle();

      // Input password
      await tester.enterText(passwordFieldFinder, password);
      await tester.pumpAndSettle();

      // Tap Kirish button
      final loginBtnFinder = find.text('Kirish');
      await tester.tap(loginBtnFinder);
      
      // Wait for login request and navigation
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }

    // Now we should be on the Dashboard
    expect(find.text('Bosh sahifa'), findsOneWidget);

    // Tap FloatingActionButton to open Appointment Form
    final fabFinder = find.byType(FloatingActionButton);
    expect(fabFinder, findsOneWidget);
    await tester.tap(fabFinder);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify we are on the "Yangi uchrashuv" form
    expect(find.text('Yangi uchrashuv'), findsOneWidget);

    // Find the time card (it has "Uchrashuv vaqtini tanlang" if null)
    final timePickerCardFinder = find.text('Uchrashuv vaqtini tanlang');
    expect(timePickerCardFinder, findsOneWidget);

    // Tap the time picker card
    await tester.tap(timePickerCardFinder);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify platform specific date picker opened
    final isIOS = Platform.isIOS || Platform.isMacOS;
    if (isIOS) {
      // On iOS, CupertinoDatePicker should be visible
      expect(find.text('Vaqtni tanlang'), findsOneWidget);
      expect(find.text('Tayyor'), findsOneWidget);
      expect(find.byType(CupertinoDatePicker), findsOneWidget);

      // Tap the Tayyor button to select initial time and close
      final tayyorButtonFinder = find.text('Tayyor');
      await tester.tap(tayyorButtonFinder);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } else {
      // On Android/other, Material TimePicker should be visible
      expect(find.byType(TimePickerDialog), findsOneWidget);
      final okBtnFinder = find.text('OK');
      await tester.tap(okBtnFinder);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    // Verify that the time picker card text changed from 'Uchrashuv vaqtini tanlang'
    expect(find.text('Uchrashuv vaqtini tanlang'), findsNothing);
  });
}
