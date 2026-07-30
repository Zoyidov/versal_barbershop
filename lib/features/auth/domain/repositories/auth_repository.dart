import '../entities/barber.dart';

abstract class AuthRepository {
  /// Verifies phone+password against the `users` collection server-side
  /// (via a Cloud Function) and establishes a real Firebase Auth session
  /// using a minted custom token. Throws [AppException] on bad credentials.
  Future<Barber> login({required String phoneNumber, required String password});

  /// Creates a new barber account (starts `approved: false`) and signs it
  /// in immediately, same as [login] - the app routes it to a "pending
  /// approval" screen until an admin approves it.
  Future<Barber> register({required String phoneNumber, required String password, required String name});

  Future<void> logout();

  /// Emits the currently authenticated barber (or null when signed out),
  /// driven by [FirebaseAuth.authStateChanges] plus a `users/{uid}` lookup.
  Stream<Barber?> watchAuthState();

  /// One-shot fetch of the barber profile for the current session, used
  /// to restore state on app relaunch before the stream emits.
  Future<Barber?> getCurrentBarber();

  /// Sets a barber's own working hours. [uid] may be the caller's own uid
  /// (self-service, from Settings) or another barber's (admin-only, from
  /// the user-management screen) - firestore.rules allows both.
  Future<void> updateScheduleHours({required String uid, required int startHour, required int endHour});

  /// Live profile of an arbitrary barber (not necessarily the signed-in
  /// caller), used to keep the dashboard's schedule in sync with whichever
  /// barber's timetable is on screen - the caller's own on the main
  /// dashboard, or an admin's current picker selection on the cross-barber
  /// schedule screen. Firestore rules restrict this to self or admin.
  Stream<Barber?> watchBarberProfile(String uid);
}
