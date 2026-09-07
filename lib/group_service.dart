import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupService {
  static FirebaseFirestore get db =>
      FirebaseFirestore.instance;

  static User? get currentUser =>
      FirebaseAuth.instance.currentUser;

  static CollectionReference<Map<String, dynamic>>
      get groupsCollection => db.collection('groups');

  static CollectionReference<Map<String, dynamic>>
      get joinCodesCollection => db.collection('joinCodes');

  // ============================================================
  // JOIN CODE GENERATOR
  // ============================================================

  static String _generateJoinCode() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const numbers = '23456789';

    final random = Random.secure();

    final letter1 =
        letters[random.nextInt(letters.length)];

    final letter2 =
        letters[random.nextInt(letters.length)];

    final number1 =
        numbers[random.nextInt(numbers.length)];

    final number2 =
        numbers[random.nextInt(numbers.length)];

    final number3 =
        numbers[random.nextInt(numbers.length)];

    return '$letter1$letter2-$number1$number2$number3';
  }

  // ============================================================
  // CREATE GROUP
  // ============================================================

  static Future<String> createGroup({
    required String name,
    required String subject,
    required String description,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw Exception('No signed-in user.');
    }

    String? joinCode;
    DocumentReference<Map<String, dynamic>>?
        joinCodeRef;

    // Find a unique join code.
    for (var attempt = 0; attempt < 10; attempt++) {
      final code = _generateJoinCode();

      final codeRef =
          joinCodesCollection.doc(code);

      final existing =
          await codeRef.get();

      if (!existing.exists) {
        joinCode = code;
        joinCodeRef = codeRef;
        break;
      }
    }

    if (joinCode == null ||
        joinCodeRef == null) {
      throw Exception(
        'Could not generate a unique join code.',
      );
    }

    final groupRef =
        groupsCollection.doc();

    final batch = db.batch();

    // Create group.
    batch.set(groupRef, {
      'name': name.trim(),
      'subject': subject.trim(),
      'description': description.trim(),
      'ownerId': user.uid,
      'ownerName': user.displayName ?? '',
      'joinCode': joinCode,
      'memberIds': [user.uid],
      'createdAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    // Create owner membership.
    final memberRef = groupRef
        .collection('members')
        .doc(user.uid);

    batch.set(memberRef, {
      'userId': user.uid,
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'role': 'owner',
      'joinedAt':
          FieldValue.serverTimestamp(),
    });

    // Reserve join code.
    batch.set(joinCodeRef, {
      'groupId': groupRef.id,
      'createdAt':
          FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return groupRef.id;
  }

  // ============================================================
  // GET GROUP
  // ============================================================

  static Future<
      DocumentSnapshot<Map<String, dynamic>>> getGroup(
    String groupId,
  ) async {
    return groupsCollection
        .doc(groupId)
        .get();
  }

  // ============================================================
  // JOIN GROUP
  // ============================================================

  static Future<String> joinGroup({
    required String joinCode,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw Exception('No signed-in user.');
    }

    final normalizedCode =
        joinCode.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      throw Exception(
        'Please enter a join code.',
      );
    }

    final codeSnapshot =
        await joinCodesCollection
            .doc(normalizedCode)
            .get();

    if (!codeSnapshot.exists) {
      throw Exception('Group not found.');
    }

    final codeData =
        codeSnapshot.data();

    if (codeData == null ||
        codeData['groupId'] == null) {
      throw Exception(
        'Invalid join code.',
      );
    }

    final groupId =
        codeData['groupId'].toString();

    final groupSnapshot =
        await getGroup(groupId);

    if (!groupSnapshot.exists) {
      throw Exception(
        'The group no longer exists.',
      );
    }

    final groupData =
        groupSnapshot.data();

    if (groupData == null) {
      throw Exception(
        'Invalid group.',
      );
    }

    if (groupData['ownerId'] ==
        user.uid) {
      throw Exception(
        'You already own this group.',
      );
    }

    final memberRef = groupsCollection
        .doc(groupId)
        .collection('members')
        .doc(user.uid);

    final existingMember =
        await memberRef.get();

    if (existingMember.exists) {
      throw Exception(
        'You are already a member of this group.',
      );
    }

    final batch = db.batch();

    // Add member document.
    batch.set(memberRef, {
      'userId': user.uid,
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'role': 'member',
      'joinedAt':
          FieldValue.serverTimestamp(),
    });

    // Add user to group memberIds.
    batch.update(
      groupsCollection.doc(groupId),
      {
        'memberIds':
            FieldValue.arrayUnion([user.uid]),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();

    return groupId;
  }

  // ============================================================
  // GET MY GROUPS
  // ============================================================

  static Future<
      List<DocumentSnapshot<Map<String, dynamic>>>>
      getMyGroups() async {
    final user = currentUser;

    if (user == null) {
      throw Exception(
        'No signed-in user.',
      );
    }

    // Groups owned by the user.
    final ownedGroups =
        await groupsCollection
            .where(
              'ownerId',
              isEqualTo: user.uid,
            )
            .get();

    // Groups where the user is a member.
    final memberGroups =
        await groupsCollection
            .where(
              'memberIds',
              arrayContains: user.uid,
            )
            .get();

    final groups = <
        String,
        DocumentSnapshot<Map<String, dynamic>>>{
    };

    for (final document
        in ownedGroups.docs) {
      groups[document.id] =
          document;
    }

    for (final document
        in memberGroups.docs) {
      groups[document.id] =
          document;
    }

    return groups.values.toList();
  }

  // ============================================================
  // GET MEMBERS
  // ============================================================

  static Future<
      QuerySnapshot<Map<String, dynamic>>>
      getMembers(
    String groupId,
  ) async {
    return groupsCollection
        .doc(groupId)
        .collection('members')
        .orderBy('joinedAt')
        .get();
  }

  // ============================================================
  // REMOVE MEMBER
  // ============================================================

  static Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw Exception(
        'No signed-in user.',
      );
    }

    final groupSnapshot =
        await getGroup(groupId);

    if (!groupSnapshot.exists) {
      throw Exception(
        'Group not found.',
      );
    }

    final groupData =
        groupSnapshot.data();

    if (groupData == null ||
        groupData['ownerId'] !=
            user.uid) {
      throw Exception(
        'Only the group owner can remove members.',
      );
    }

    if (userId == user.uid) {
      throw Exception(
        'The owner cannot remove themselves.',
      );
    }

    final batch = db.batch();

    batch.delete(
      groupsCollection
          .doc(groupId)
          .collection('members')
          .doc(userId),
    );

    batch.update(
      groupsCollection.doc(groupId),
      {
        'memberIds':
            FieldValue.arrayRemove([userId]),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  // ============================================================
  // LEAVE GROUP
  // ============================================================

  static Future<void> leaveGroup(
    String groupId,
  ) async {
    final user = currentUser;

    if (user == null) {
      throw Exception(
        'No signed-in user.',
      );
    }

    final groupSnapshot =
        await getGroup(groupId);

    if (!groupSnapshot.exists) {
      throw Exception(
        'Group not found.',
      );
    }

    final groupData =
        groupSnapshot.data();

    if (groupData == null) {
      throw Exception(
        'Invalid group.',
      );
    }

    if (groupData['ownerId'] ==
        user.uid) {
      throw Exception(
        'The group owner cannot leave the group. '
        'Delete the group instead.',
      );
    }

    final batch = db.batch();

    batch.delete(
      groupsCollection
          .doc(groupId)
          .collection('members')
          .doc(user.uid),
    );

    batch.update(
      groupsCollection.doc(groupId),
      {
        'memberIds':
            FieldValue.arrayRemove([user.uid]),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }
}
