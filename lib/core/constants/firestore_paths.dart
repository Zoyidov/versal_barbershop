/// Centralized Firestore collection / document path names.
///
/// Keeping these in one place means a rename never turns into a
/// multi-file find-and-replace across the data layer.
class FirestorePaths {
  FirestorePaths._();

  static const String users = 'users';
  static const String appointments = 'appointments';
  static const String clients = 'clients';
  static const String settings = 'settings';

  /// Singleton document inside [settings] holding shop-wide configuration.
  static const String globalSettingsDoc = 'global';
}

/// Field names used across the `appointments` collection.
class AppointmentFields {
  AppointmentFields._();

  static const String clientPhone = 'clientPhone';
  static const String clientName = 'clientName';
  static const String serviceType = 'serviceType';
  static const String barberId = 'barberId';
  static const String appointmentTime = 'appointmentTime';
  static const String status = 'status';
  static const String sendSms = 'sendSms';
  static const String smsSent = 'smsSent';
  static const String smsSentAt = 'smsSentAt';
  static const String smsStatus = 'smsStatus';
  static const String reminderTaskName = 'reminderTaskName';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String createdBy = 'createdBy';
}

/// Field names used across the `clients` collection (per-phone aggregates).
class ClientFields {
  ClientFields._();

  static const String phoneNumber = 'phoneNumber';
  static const String lastName = 'lastName';
  static const String totalVisits = 'totalVisits';
  static const String totalCancellations = 'totalCancellations';
  static const String updatedAt = 'updatedAt';
}

/// Field names used inside `settings/global`.
class SettingsFields {
  SettingsFields._();

  static const String reminderWindowMinutes = 'reminderWindowMinutes';
  static const String shopName = 'shopName';
  static const String scheduleStartHour = 'scheduleStartHour';
  static const String scheduleEndHour = 'scheduleEndHour';
  static const String updatedAt = 'updatedAt';
  static const String updatedBy = 'updatedBy';
}

/// Field names used inside the `users` (barber accounts) collection.
class UserFields {
  UserFields._();

  static const String phoneNumber = 'phoneNumber';
  static const String name = 'name';
  static const String role = 'role';
  static const String active = 'active';
  static const String createdAt = 'createdAt';
}
