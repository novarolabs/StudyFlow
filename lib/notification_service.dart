import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static Future<void> initialize() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus ==
          AuthorizationStatus.denied) {
        return;
      }

      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await _saveToken(user.uid);
      }

      _messaging.onTokenRefresh.listen((token) async {
        final currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser != null) {
          await _saveToken(
            currentUser.uid,
            token: token,
          );
        }
      });
    } catch (_) {
      // Notifications are optional.
      // The app continues working if FCM setup fails.
    }
  }

  static Future<void> _saveToken(
    String uid, {
    String? token,
  }) async {
    final fcmToken = token ?? await _messaging.getToken();

    if (fcmToken == null || fcmToken.isEmpty) {
      return;
    }

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(fcmToken)
        .set({
      'token': fcmToken,
      'platform': 'android',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
