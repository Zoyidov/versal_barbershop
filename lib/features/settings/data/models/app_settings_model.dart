import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../domain/entities/app_settings.dart';

class AppSettingsModel extends AppSettings {
  const AppSettingsModel({
    required super.reminderWindowMinutes,
    required super.shopName,
    super.scheduleStartHour,
    super.scheduleEndHour,
  });

  factory AppSettingsModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists) return AppSettingsModel.fromEntity(AppSettings.fallback);
    final json = doc.data() ?? const {};
    return AppSettingsModel(
      reminderWindowMinutes: (json[SettingsFields.reminderWindowMinutes] as num?)?.toInt() ?? 40,
      shopName: json[SettingsFields.shopName] as String? ?? AppSettings.fallback.shopName,
      scheduleStartHour:
          (json[SettingsFields.scheduleStartHour] as num?)?.toInt() ?? AppSettings.fallback.scheduleStartHour,
      scheduleEndHour: (json[SettingsFields.scheduleEndHour] as num?)?.toInt() ?? AppSettings.fallback.scheduleEndHour,
    );
  }

  factory AppSettingsModel.fromEntity(AppSettings settings) {
    return AppSettingsModel(
      reminderWindowMinutes: settings.reminderWindowMinutes,
      shopName: settings.shopName,
      scheduleStartHour: settings.scheduleStartHour,
      scheduleEndHour: settings.scheduleEndHour,
    );
  }
}
