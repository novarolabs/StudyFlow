import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static FirebaseFirestore get db => FirebaseFirestore.instance;

  static User? get currentUser => FirebaseAuth.instance.currentUser;

  static DocumentReference<Map<String, dynamic>> get notesDocument {
    final user = currentUser;

    if (user == null) {
      throw Exception('No signed-in user.');
    }

    return db
        .collection('users')
        .doc(user.uid)
        .collection('data')
        .doc('notes');
  }

  static Future<void> saveNotes(
    List<Map<String, dynamic>> notes,
  ) async {
    await notesDocument.set({
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> loadNotes() async {
    final snapshot = await notesDocument.get();

    if (!snapshot.exists) {
      return [];
    }

    final data = snapshot.data();

    if (data == null || data['notes'] == null) {
      return [];
    }

    return List<Map<String, dynamic>>.from(
      (data['notes'] as List).map(
        (item) => Map<String, dynamic>.from(item),
      ),
    );
  }

  static Future<void> deleteNotes() async {
    await notesDocument.delete();
  }
}
