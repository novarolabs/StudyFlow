import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationStateService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static User? get _currentUser =>
      FirebaseAuth.instance.currentUser;

  static CollectionReference<Map<String, dynamic>>
      _groupStateCollection(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('groupState');
  }

  static Future<void> markMessagesRead(String groupId) async {
    final user = _currentUser;
    if (user == null) return;

    await _groupStateCollection(user.uid)
        .doc(groupId)
        .set({
      'lastReadMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> markAnnouncementsRead(String groupId) async {
    final user = _currentUser;
    if (user == null) return;

    await _groupStateCollection(user.uid)
        .doc(groupId)
        .set({
      'lastReadAnnouncementAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>>
      getGroupState(String groupId) async {
    final user = _currentUser;

    if (user == null) {
      throw Exception('No signed-in user.');
    }

    return _groupStateCollection(user.uid)
        .doc(groupId)
        .get();
  }
}
