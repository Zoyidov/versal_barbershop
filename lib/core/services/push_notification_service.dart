import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/firestore_paths.dart';

/// Must be a top-level (or static) function - FCM calls this in its own
/// background isolate, which has no access to any app state built up in
/// `main()`. It only needs to exist so background/terminated-state pushes
/// are handled by the OS the same way as any other app's notifications;
/// there's nothing else to do here since the notification itself is
/// already shown by the OS from the FCM payload in that state.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Registers this device for push notifications (new bookings, approvals,
/// SMS-limit updates - see functions/src/notifications.ts) and displays
/// them while the app is in the foreground, where FCM doesn't auto-show a
/// notification the way it does in the background.
///
/// Device tokens are stored per-account on `users/{uid}.fcmTokens` (a list,
/// since one account can be signed in on more than one device over time).
/// [registerForUser] moves the token from whichever account it was
/// previously attached to onto the newly signed-in one, so a shared/reused
/// device never keeps pushing notifications meant for the previous barber.
class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'versal_default',
    'Bildirishnomalar',
    description: 'Yangi band qilish, tasdiqlash va SMS limiti haqida xabarlar',
    importance: Importance.high,
  );

  String? _registeredUid;

  PushNotificationService({required FirebaseFirestore firestore}) : _firestore = firestore;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    // Without this, iOS silently drops a notification-carrying message
    // while the app is foregrounded instead of surfacing it - Android has
    // no equivalent switch, it always hands foreground messages to
    // onMessage below regardless.
    await _messaging.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen(_showLocalNotification);
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
    );
  }

  /// Call once a barber/admin is signed in. Best-effort: a push token is a
  /// nice-to-have, never something a screen should block or show an error
  /// for, so failures (permission denied, no Google Play services, etc)
  /// are swallowed after a debug log.
  Future<void> registerForUser(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      if (_registeredUid != null && _registeredUid != uid) {
        await _removeToken(_registeredUid!, token);
      }
      await _addToken(uid, token);
      _registeredUid = uid;

      _messaging.onTokenRefresh.listen((newToken) => _addToken(uid, newToken));
    } catch (e) {
      debugPrint('[PushNotificationService] registerForUser failed: $e');
    }
  }

  /// Call on sign-out so a shared/reused device stops receiving pushes
  /// meant for whoever was signed in before.
  Future<void> unregisterCurrentUser() async {
    final uid = _registeredUid;
    if (uid == null) return;
    try {
      final token = await _messaging.getToken();
      if (token != null) await _removeToken(uid, token);
    } catch (e) {
      debugPrint('[PushNotificationService] unregisterCurrentUser failed: $e');
    } finally {
      _registeredUid = null;
    }
  }

  Future<void> _addToken(String uid, String token) {
    return _firestore.collection(FirestorePaths.users).doc(uid).update({
      UserFields.fcmTokens: FieldValue.arrayUnion([token]),
    });
  }

  Future<void> _removeToken(String uid, String token) {
    return _firestore.collection(FirestorePaths.users).doc(uid).update({
      UserFields.fcmTokens: FieldValue.arrayRemove([token]),
    });
  }
}

/// True on the two platforms `firebase_messaging` actually supports push
/// delivery on natively (Android and iOS) - web/desktop either need a
/// different setup (service worker + VAPID key) or aren't targeted by this
/// app's push feature at all, so [PushNotificationService.initialize] is
/// only called when this is true.
bool get isPushCapablePlatform => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
