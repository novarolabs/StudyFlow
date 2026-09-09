import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'group_service.dart';

class GroupMembersScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupMembersScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupMembersScreen> createState() =>
      _GroupMembersScreenState();
}

class _GroupMembersScreenState
    extends State<GroupMembersScreen> {
  bool _loading = true;
  bool _working = false;

  List<Map<String, dynamic>> _members = [];
  String _ownerId = '';
  String _ownerName = '';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final group =
          await GroupService.getGroup(widget.groupId);

      if (!group.exists) {
        if (!mounted) return;

        setState(() {
          _loading = false;
        });

        return;
      }

      final groupData =
          group.data() ?? <String, dynamic>{};

      final membersSnapshot =
          await GroupService.getMembers(
        widget.groupId,
      );

      final members = membersSnapshot.docs
          .map(
            (document) => document.data(),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _members = members;
        _ownerId =
            groupData['ownerId']?.toString() ?? '';
        _ownerName =
            groupData['ownerName']?.toString() ??
                'Group Owner';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade900,
          content: Text(
            'Could not load members: $e',
          ),
        ),
      );
    }
  }

  bool get isOwner {
    final uid =
        GroupService.currentUser?.uid ?? '';

    return uid.isNotEmpty && uid == _ownerId;
  }

  Future<void> _removeMember(
    String userId,
    String memberName,
  ) async {
    if (!isOwner) return;

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF121D2F),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: const Text(
            'Remove member?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Remove $memberName from "${widget.groupName}"?',
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

      await _loadMembers();

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

  Widget _memberCard(
    Map<String, dynamic> member,
    int index,
  ) {
    final userId =
        member['userId']?.toString() ?? '';

    final name =
        member['name']?.toString().trim() ?? '';

    final email =
        member['email']?.toString().trim() ?? '';

    final role =
        member['role']?.toString() ?? 'member';

    final displayName =
        name.isNotEmpty
            ? name
            : email.isNotEmpty
                ? email
                : 'StudyFlow User';

    final memberIsOwner =
        userId == _ownerId ||
        role == 'owner';

    final initial =
        displayName.isNotEmpty
            ? displayName[0].toUpperCase()
            : '?';

    return TweenAnimationBuilder<double>(
      duration: Duration(
        milliseconds: 350 + (index * 70),
      ),
      tween: Tween(
        begin: 0,
        end: 1,
      ),
      curve: Curves.easeOutCubic,
      builder: (
        context,
        value,
        child,
      ) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              0,
              20 * (1 - value),
            ),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
            const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF121D2F),
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: memberIsOwner
                ? const Color(0xFF8A7028)
                : const Color(0xFF263754),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: 0.15,
              ),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient:
                    const LinearGradient(
                  colors: [
                    Color(0xFFD4AF37),
                    Color(0xFFFFE58A),
                  ],
                  begin:
                      Alignment.topLeft,
                  end:
                      Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color:
                        Color(0xFF0B1424),
                    fontSize: 21,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                      if (memberIsOwner) ...[
                        const SizedBox(
                          width: 7,
                        ),
                        const Icon(
                          Icons.verified_rounded,
                          color:
                              Color(0xFFFFD95A),
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
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
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color:
                            Color(0xFF687991),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (memberIsOwner)
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF2B2410),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Text(
                  'OWNER',
                  style: TextStyle(
                    color:
                        Color(0xFFFFD95A),
                    fontSize: 9,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
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
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF172A47),
            Color(0xFF101B30),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color:
              const Color(0xFF30466B),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFD4AF37),
              borderRadius:
                  BorderRadius.circular(19),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color:
                  Color(0xFF0B1424),
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Group Members',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_members.length} member'
                  '${_members.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color:
                        Color(0xFFFFD95A),
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                if (_ownerName.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Owned by $_ownerName',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF8190A7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
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
        title: Text(
          widget.groupName,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFFFFD95A),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadMembers,
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
                  _buildHeader(),
                  const SizedBox(height: 22),
                  if (_members.isEmpty)
                    Container(
                      padding:
                          const EdgeInsets.all(
                        30,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFF121D2F,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                        border: Border.all(
                          color:
                              const Color(
                            0xFF263754,
                          ),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons
                                .person_search_rounded,
                            color:
                                Color(0xFFFFD95A),
                            size: 42,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No members found',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._members
                        .asMap()
                        .entries
                        .map(
                          (entry) =>
                              _memberCard(
                            entry.value,
                            entry.key,
                          ),
                        ),
                  if (_working)
                    const Padding(
                      padding:
                          EdgeInsets.all(20),
                      child: Center(
                        child:
                            CircularProgressIndicator(
                          color:
                              Color(0xFFFFD95A),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
