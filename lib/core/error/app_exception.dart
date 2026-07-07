/// A single exception type surfaced to the presentation layer.
///
/// Data sources catch platform-specific errors (FirebaseException,
/// FirebaseFunctionsException, etc.) and rethrow as [AppException] so
/// Cubits never need to know about Firebase-specific error shapes.
class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}
