import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import 'group_service.dart';

class GroupInfoScreen extends StatefulWidget {
  final String groupId;

  const GroupInfoScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  bool _loading = true;
  bool _working = false;
  String? _errorMessage;
  Map<String, dynamic>? _groupData;

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    try {
      final document =
          await GroupService.getGroup(widget.groupId);

      if (!mounted) return;

      if (!document.exists) {
        setState(() {
          _loading = false;
          _errorMessage =
              'This group no longer exists.';
        });
        return;
      }

      setState(() {
        _groupData =
            document.data() ??
                <String, dynamic>{};
        _loading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage =
            'Could not load group: $e';
      });
    }
  }

  String get groupName =>
      _groupData?['name']?.toString() ??
      'Study Group';

  String get subject =>
      _groupData?['subject']?.toString() ??
      '';

  String get description =>
      _groupData?['description']?.toString() ??
      '';

  String get ownerId =>
      _groupData?['ownerId']?.toString() ??
      '';

  String get ownerName =>
      _groupData?['ownerName']?.toString() ??
      'Group Owner';

  String get joinCode =>
      _groupData?['joinCode']?.toString() ??
      '';

  List<dynamic> get memberIds {
    final value = _groupData?['memberIds'];

    if (value is List) {
      return value;
    }

    return <dynamic>[];
  }

  bool get isOwner {
    final uid =
        GroupService.currentUser?.uid ?? '';

    return uid.isNotEmpty && uid == ownerId;
  }

  Future<void> _copyJoinCode() async {
    if (joinCode.isEmpty) return;

    await Clipboard.setData(
      ClipboardData(text: joinCode),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF162238),
        content: Text(
          'Join code copied.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _removeMember(
    String userId,
    String memberName,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF121D2F),
          title: const Text(
            'Remove member?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Remove $memberName from "$groupName"?',
            style: const TextStyle(
              color: Color(0xFFB8C2D1),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFFB8C2D1),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.redAccent,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _working = true;
    });

    try {
      await GroupService.removeMember(
        groupId: widget.groupId,
        userId: userId,
      );

      await _loadGroup();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              const Color(0xFF162238),
          content: Text(
            '$memberName was removed.',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade900,
          content: Text(
            'Could not remove member: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<void> _leaveGroup() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF121D2F),
          title: const Text(
            'Leave Group?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to leave "$groupName"?',
            style: const TextStyle(
              color: Color(0xFFB8C2D1),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFFB8C2D1),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.redAccent,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _working = true;
    });

    try {
      await GroupService.leaveGroup(
        widget.groupId,
      );

      if (!mounted) return;

      Navigator.popUntil(
        context,
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _working = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade900,
          content: Text(
            'Could not leave group: $e',
          ),
        ),
      );
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF121D2F),
          title: const Text(
            'Delete Group?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'This permanently deletes "$groupName" and its membership data.',
            style: const TextStyle(
              color: Color(0xFFB8C2D1),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFFB8C2D1),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.redAccent,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _working = true;
    });

    try {
      await GroupService.deleteGroup(
        widget.groupId,
      );

      if (!mounted) return;

      Navigator.popUntil(
        context,
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _working = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade900,
          content: Text(
            'Could not delete group: $e',
          ),
        ),
      );
    }
  }

  Widget _infoTile(
    IconData icon,
    String title,
    String value, {
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121D2F),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF263754),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1B2A43),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFFD95A),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF7F8DA3),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 3,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _memberTile(
    Map<String, dynamic> data,
  ) {
    final userId =
        data['userId']?.toString() ?? '';

    final name =
        data['name']?.toString().trim();

    final email =
        data['email']?.toString().trim();

    final role =
        data['role']?.toString() ?? 'member';

    final displayName =
        (name != null && name.isNotEmpty)
            ? name
            : ((email != null && email.isNotEmpty)
                ? email
                : 'StudyFlow User');

    final memberIsOwner =
        userId == ownerId ||
        role == 'owner';

    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF121D2F),
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFF263754),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  const LinearGradient(
                colors: [
                  Color(0xFFD4AF37),
                  Color(0xFFFFE58A),
                ],
              ),
            ),
            child: Center(
              child: Text(
                displayName.isNotEmpty
                    ? displayName[0]
                        .toUpperCase()
                    : '?',
                style:
                    const TextStyle(
                  color: Color(0xFF0B1424),
                  fontSize: 19,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  memberIsOwner
                      ? 'Group owner'
                      : 'Member',
                  style: TextStyle(
                    color: memberIsOwner
                        ? const Color(
                            0xFFFFD95A,
                          )
                        : const Color(
                            0xFF8E9AAF,
                          ),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (memberIsOwner)
            const Icon(
              Icons.verified_rounded,
              color: Color(0xFFFFD95A),
              size: 20,
            )
          else if (isOwner &&
              userId.isNotEmpty)
            IconButton(
              tooltip: 'Remove member',
              onPressed: _working
                  ? null
                  : () => _removeMember(
                        userId,
                        displayName,
                      ),
              icon: const Icon(
                Icons.person_remove_outlined,
                color: Colors.redAccent,
                size: 21,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF0B1424),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0B1424),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Group Info',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color: Color(0xFFFFD95A),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(24),
                    child: Text(
                      _errorMessage!,
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadGroup,
                  color:
                      const Color(0xFFFFD95A),
                  backgroundColor:
                      const Color(0xFF121D2F),
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      14,
                      20,
                      40,
                    ),
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.all(22),
                        decoration:
                            BoxDecoration(
                          gradient:
                              const LinearGradient(
                            colors: [
                              Color(0xFF172A47),
                              Color(0xFF101B30),
                            ],
                            begin:
                                Alignment.topLeft,
                            end:
                                Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            24,
                          ),
                          border: Border.all(
                            color:
                                const Color(
                              0xFF30466B,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFD4AF37,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                  22,
                                ),
                              ),
                              child: const Icon(
                                Icons.groups_rounded,
                                color:
                                    Color(0xFF0B1424),
                                size: 39,
                              ),
                            ),
                            const SizedBox(
                              height: 14,
                            ),
                            Text(
                              groupName,
                              textAlign:
                                  TextAlign.center,
                              style:
                                  const TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            if (subject.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets
                                        .only(
                                  top: 5,
                                ),
                                child: Text(
                                  subject,
                                  textAlign:
                                      TextAlign.center,
                                  style:
                                      const TextStyle(
                                    color:
                                        Color(
                                      0xFFFFD95A,
                                    ),
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              '${memberIds.length} member'
                              '${memberIds.length == 1 ? '' : 's'}',
                              style:
                                  const TextStyle(
                                color:
                                    Color(0xFF8E9AAF),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (subject.isNotEmpty)
                        _infoTile(
                          Icons.menu_book_rounded,
                          'Subject',
                          subject,
                        ),
                      if (description.isNotEmpty)
                        _infoTile(
                          Icons.description_outlined,
                          'Description',
                          description,
                        ),
                      _infoTile(
                        Icons.workspace_premium_outlined,
                        'Owner',
                        ownerName,
                      ),
                      if (joinCode.isNotEmpty)
                        _infoTile(
                          Icons.key_rounded,
                          'Join Code',
                          joinCode,
                          trailing:
                              IconButton(
                            tooltip:
                                'Copy join code',
                            onPressed:
                                _copyJoinCode,
                            icon: const Icon(
                              Icons.copy_rounded,
                              color:
                                  Color(0xFFFFD95A),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      const Text(
                        'Members',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<
                          QuerySnapshot<
                              Map<String,
                                  dynamic>>>(
                        future:
                            GroupService.getMembers(
                          widget.groupId,
                        ),
                        builder:
                            (context, snapshot) {
                          if (snapshot
                              .connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding:
                                  EdgeInsets.all(24),
                              child: Center(
                                child:
                                    CircularProgressIndicator(
                                  color: Color(
                                    0xFFFFD95A,
                                  ),
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Container(
                              padding:
                                  const EdgeInsets
                                      .all(18),
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFF121D2F,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                  17,
                                ),
                              ),
                              child: Text(
                                'Could not load members: ${snapshot.error}',
                                style:
                                    const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }

                          final members =
                              snapshot.data?.docs ??
                                  [];

                          if (members.isEmpty) {
                            return const Text(
                              'No members found.',
                              style: TextStyle(
                                color:
                                    Color(0xFF8E9AAF),
                              ),
                            );
                          }

                          return Column(
                            children: members
                                .map(
                                  (document) =>
                                      _memberTile(
                                    document.data(),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      if (_working)
                        const Center(
                          child:
                              CircularProgressIndicator(
                            color:
                                Color(0xFFFFD95A),
                          ),
                        ),
                      if (!_working && isOwner)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                _deleteGroup,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                            ),
                            label: const Text(
                              'Delete Group',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  Colors.redAccent,
                              side:
                                  const BorderSide(
                                color:
                                    Colors.redAccent,
                              ),
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),
                      if (!_working && !isOwner)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                _leaveGroup,
                            icon: const Icon(
                              Icons.exit_to_app_rounded,
                            ),
                            label: const Text(
                              'Leave Group',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  Colors.redAccent,
                              side:
                                  const BorderSide(
                                color:
                                    Colors.redAccent,
                              ),
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
