import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static bool initialized = false;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      initialized = true;
    } catch (_) {
      // Firebase is optional for offline use.
      // The app can continue working locally if initialization fails.
      initialized = false;
    }
  }

  static FirebaseAuth? get auth {
    if (!initialized) return null;
    return FirebaseAuth.instance;
  }

  static User? get currentUser {
    return auth?.currentUser;
  }
}
