import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/error/app_exception.dart';
import '../models/barber_model.dart';

abstract class AuthRemoteDataSource {
  Future<BarberModel> login({required String phoneNumber, required String password});
  Future<BarberModel> register({required String phoneNumber, required String password, required String name});
  Future<void> logout();
  Future<void> deleteAccount();
  Stream<BarberModel?> watchAuthState();
  Future<BarberModel?> getCurrentBarber();
  Future<void> updateScheduleHours({required String uid, required int startHour, required int endHour});
  Stream<BarberModel?> watchBarberProfile(String uid);
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

      return _barberFromCallableResponse(uid: uid, data: data, fallbackPhoneNumber: phoneNumber);
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

  @override
  Future<BarberModel> register({required String phoneNumber, required String password, required String name}) async {
    debugPrint('[Auth] register() called with phoneNumber=$phoneNumber');
    try {
      final callable = _functions.httpsCallable('registerBarber');
      final result = await callable.call<Map<String, dynamic>>({
        'phoneNumber': phoneNumber,
        'password': password,
        'name': name,
      });

      final data = result.data;
      final token = data['token'] as String?;
      if (token == null) {
        throw const AppException('Ro\'yxatdan o\'tish amalga oshmadi. Iltimos, qayta urinib ko\'ring.');
      }

      final credential = await _auth.signInWithCustomToken(token);
      final uid = credential.user?.uid;
      if (uid == null) {
        throw const AppException('Ro\'yxatdan o\'tish amalga oshmadi. Iltimos, qayta urinib ko\'ring.');
      }

      return _barberFromCallableResponse(uid: uid, data: data, fallbackPhoneNumber: phoneNumber);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[Auth] FirebaseFunctionsException: code=${e.code} message=${e.message} details=${e.details}');
      throw AppException(_mapRegisterFunctionError(e));
    } on fb_auth.FirebaseAuthException catch (e) {
      debugPrint('[Auth] FirebaseAuthException: code=${e.code} message=${e.message}');
      throw AppException(e.message ?? 'Ro\'yxatdan o\'tish amalga oshmadi. Iltimos, qayta urinib ko\'ring.');
    } catch (e, stackTrace) {
      debugPrint('[Auth] Unexpected error: $e');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  BarberModel _barberFromCallableResponse({
    required String uid,
    required Map<String, dynamic> data,
    required String fallbackPhoneNumber,
  }) {
    return BarberModel(
      uid: uid,
      phoneNumber: data['phoneNumber'] as String? ?? fallbackPhoneNumber,
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? 'barber',
      approved: data['approved'] as bool? ?? true,
      smsLimit: (data['smsLimit'] as num?)?.toInt() ?? 0,
    );
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

  String _mapRegisterFunctionError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'already-exists':
        return 'Bu telefon raqami allaqachon ro\'yxatdan o\'tgan.';
      case 'invalid-argument':
        return e.message ?? 'Ma\'lumotlarni to\'g\'ri kiriting.';
      case 'unavailable':
        return 'Internet aloqasi yo\'q. Iltimos, tekshirib qayta urinib ko\'ring.';
      default:
        return e.message ?? 'Ro\'yxatdan o\'tish amalga oshmadi. Iltimos, qayta urinib ko\'ring.';
    }
  }

  @override
  Future<void> logout() => _auth.signOut();

  /// Calls the `deleteOwnAccount` callable (deletes `users/{uid}` + the
  /// Firebase Auth user server-side via the Admin SDK - a client can't
  /// delete its own Firebase Auth user account any other way here since
  /// this app never signs in through Firebase Auth's own flows, only via
  /// custom-token exchange), then signs out locally so the app's auth
  /// state stream reflects it immediately.
  @override
  Future<void> deleteAccount() async {
    try {
      final callable = _functions.httpsCallable('deleteOwnAccount');
      await callable.call<Map<String, dynamic>>();
      await _auth.signOut();
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[Auth] deleteAccount() FirebaseFunctionsException: code=${e.code} message=${e.message}');
      throw AppException(_mapDeleteAccountFunctionError(e));
    } catch (e, stackTrace) {
      debugPrint('[Auth] deleteAccount() unexpected error: $e');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  String _mapDeleteAccountFunctionError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Admin hisobini bu orqali o\'chirib bo\'lmaydi.';
      case 'unauthenticated':
        return 'Iltimos, qaytadan tizimga kiring.';
      case 'unavailable':
        return 'Internet aloqasi yo\'q. Iltimos, tekshirib qayta urinib ko\'ring.';
      default:
        return e.message ?? 'Hisobni o\'chirib bo\'lmadi. Iltimos, qayta urinib ko\'ring.';
    }
  }

  /// Live for as long as the app is signed in: re-subscribes to
  /// `users/{uid}` on every Firebase Auth change and keeps pushing profile
  /// updates as that document changes (smsLimit top-ups, schedule-hour
  /// edits, approval, etc.), instead of only fetching once per sign-in.
  /// This is purely a post-auth read - it never touches how a session is
  /// established (that's still entirely login()/register() + the custom
  /// token exchange, untouched here).
  @override
  Stream<BarberModel?> watchAuthState() {
    late final StreamController<BarberModel?> controller;
    StreamSubscription<fb_auth.User?>? authSubscription;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? profileSubscription;

    void listenToProfile(String uid) {
      profileSubscription?.cancel();
      profileSubscription = _firestore.collection(FirestorePaths.users).doc(uid).snapshots().listen(
        (doc) => controller.add(doc.exists ? BarberModel.fromSnapshot(doc) : null),
        onError: controller.addError,
      );
    }

    controller = StreamController<BarberModel?>.broadcast(
      onListen: () {
        authSubscription = _auth.authStateChanges().listen((user) {
          if (user == null) {
            profileSubscription?.cancel();
            profileSubscription = null;
            controller.add(null);
          } else {
            listenToProfile(user.uid);
          }
        });
      },
      onCancel: () {
        profileSubscription?.cancel();
        authSubscription?.cancel();
      },
    );

    return controller.stream;
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

  @override
  Future<void> updateScheduleHours({required String uid, required int startHour, required int endHour}) async {
    try {
      await _firestore.collection(FirestorePaths.users).doc(uid).update({
        UserFields.scheduleStartHour: startHour,
        UserFields.scheduleEndHour: endHour,
      });
    } catch (e) {
      throw AppException('Ish vaqtini yangilab bo\'lmadi: $e');
    }
  }

  @override
  Stream<BarberModel?> watchBarberProfile(String uid) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? BarberModel.fromSnapshot(doc) : null)
        .handleError((error) {
      throw AppException('Sartarosh profilini yuklab bo\'lmadi: $error');
    });
  }
}
