import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/app_exception.dart';
import '../models/barber_model.dart';

abstract class AuthRemoteDataSource {
  Future<BarberModel> login({required String phoneNumber, required String password});
  Future<void> logout();
  Stream<BarberModel?> watchAuthState();
  Future<BarberModel?> getCurrentBarber();
}

/// Talks to Firebase Auth + the `loginWithPhonePassword` callable Cloud
/// Function. Password verification never happens on-device: the callable
/// checks the hash stored in `users/{uid}` server-side with the Admin SDK
/// and, on success, mints a Firebase custom token. We then exchange that
/// token for a real client session via [signInWithCustomToken], which is
/// what makes `request.auth` meaningful in Firestore security rules.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final fb_auth.FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    required fb_auth.FirebaseAuth auth,
    required FirebaseFunctions functions,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _functions = functions,
        _firestore = firestore;

  @override
  Future<BarberModel> login({required String phoneNumber, required String password}) async {
    debugPrint('[Auth] login() called with phoneNumber=$phoneNumber');
    try {
      final callable = _functions.httpsCallable('loginWithPhonePassword');
      debugPrint('[Auth] calling loginWithPhonePassword callable...');
      final result = await callable.call<Map<String, dynamic>>({
        'phoneNumber': phoneNumber,
        'password': password,
      });
      debugPrint('[Auth] callable returned: ${result.data}');

      final data = result.data;
      final token = data['token'] as String?;
      if (token == null) {
        debugPrint('[Auth] ERROR: response had no token field.');
        throw const AppException('Kirish amalga oshmadi. Iltimos, qayta urinib ko\'ring.');
      }

      debugPrint('[Auth] signing in with custom token...');
      final credential = await _auth.signInWithCustomToken(token);
      final uid = credential.user?.uid;
      debugPrint('[Auth] signInWithCustomToken succeeded, uid=$uid');
      if (uid == null) {
        throw const AppException('Kirish amalga oshmadi. Iltimos, qayta urinib ko\'ring.');
      }

      return BarberModel(
        uid: uid,
        phoneNumber: data['phoneNumber'] as String? ?? phoneNumber,
        name: data['name'] as String? ?? '',
        role: data['role'] as String? ?? 'barber',
      );
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[Auth] FirebaseFunctionsException: code=${e.code} message=${e.message} details=${e.details}');
      throw AppException(_mapFunctionError(e));
    } on fb_auth.FirebaseAuthException catch (e) {
      debugPrint('[Auth] FirebaseAuthException: code=${e.code} message=${e.message}');
      throw AppException(e.message ?? 'Kirish amalga oshmadi. Iltimos, qayta urinib ko\'ring.');
    } catch (e, stackTrace) {
      debugPrint('[Auth] Unexpected error: $e');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  String _mapFunctionError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'not-found':
      case 'unauthenticated':
      case 'permission-denied':
        return 'Telefon raqami yoki parol noto\'g\'ri.';
      case 'unavailable':
        return 'Internet aloqasi yo\'q. Iltimos, tekshirib qayta urinib ko\'ring.';
      default:
        return e.message ?? 'Kirish amalga oshmadi. Iltimos, qayta urinib ko\'ring.';
    }
  }

  @override
  Future<void> logout() => _auth.signOut();

  @override
  Stream<BarberModel?> watchAuthState() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return _fetchProfile(user.uid);
    });
  }

  @override
  Future<BarberModel?> getCurrentBarber() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _fetchProfile(user.uid);
  }

  Future<BarberModel?> _fetchProfile(String uid) async {
    final doc = await _firestore.collection(FirestorePaths.users).doc(uid).get();
    if (!doc.exists) return null;
    return BarberModel.fromSnapshot(doc);
  }
}
