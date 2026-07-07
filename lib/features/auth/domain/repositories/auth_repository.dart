import '../entities/barber.dart';

abstract class AuthRepository {
  /// Verifies phone+password against the `users` collection server-side
  /// (via a Cloud Function) and establishes a real Firebase Auth session
  /// using a minted custom token. Throws [AppException] on bad credentials.
  Future<Barber> login({required String phoneNumber, required String password});

  Future<void> logout();

  /// Emits the currently authenticated barber (or null when signed out),
  /// driven by [FirebaseAuth.authStateChanges] plus a `users/{uid}` lookup.
  Stream<Barber?> watchAuthState();

  /// One-shot fetch of the barber profile for the current session, used
  /// to restore state on app relaunch before the stream emits.
  Future<Barber?> getCurrentBarber();
}
