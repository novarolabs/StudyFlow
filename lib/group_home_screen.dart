import 'package:flutter/material.dart';

import 'group_service.dart';
import 'group_chat_screen.dart';
import 'group_members_screen.dart';
import 'announcements_screen.dart';

class GroupHomeScreen extends StatefulWidget {
  final String groupId;

  const GroupHomeScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<GroupHomeScreen> createState() => _GroupHomeScreenState();
}

class _GroupHomeScreenState extends State<GroupHomeScreen> {
  bool loading = true;
  Map<String, dynamic>? groupData;
  String? errorMessage;

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
          loading = false;
          errorMessage = 'This group no longer exists.';
        });
        return;
      }

      setState(() {
        groupData =
            document.data() ?? <String, dynamic>{};
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = 'Could not load group: $e';
      });
    }
  }

  String get groupName {
    return groupData?['name']?.toString() ??
        'Study Group';
  }

  String get subject {
    return groupData?['subject']?.toString() ?? '';
  }

  String get description {
    return groupData?['description']?.toString() ?? '';
  }

  String get ownerId {
    return groupData?['ownerId']?.toString() ?? '';
  }

  bool get isOwner {
    final userId =
        GroupService.currentUser?.uid ?? '';

    return userId.isNotEmpty &&
        userId == ownerId;
  }

  int get memberCount {
    final members =
        groupData?['memberIds'];

    if (members is List) {
      return members.length;
    }

    return 0;
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature will be available next.',
        ),
      ),
    );
  }

  Future<void> _leaveGroup() async {
    if (isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The group owner cannot leave the group. Delete the group instead.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121D2F),
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
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFFB8C2D1),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await GroupService.leaveGroup(
        widget.groupId,
      );

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You left the group.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not leave group: $e',
          ),
        ),
      );
    }
  }

  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121D2F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              20,
              24,
              30,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A4963),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Group Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _infoRow(
                  Icons.groups_rounded,
                  'Group',
                  groupName,
                ),
                if (subject.isNotEmpty)
                  _infoRow(
                    Icons.menu_book_rounded,
                    'Subject',
                    subject,
                  ),
                _infoRow(
                  Icons.people_alt_rounded,
                  'Members',
                  '$memberCount',
                ),
                if (description.isNotEmpty)
                  _infoRow(
                    Icons.description_rounded,
                    'Description',
                    description,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFFD4AF37),
            size: 22,
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
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget   icon: Icons.campaign_rounded,
  title: 'Announcements',
  subtitle: 'Important updates from your group',
    Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AnnouncementsScreen(
        groupId: widget.groupId,
        groupName: groupName,
        isOwner: isOwner,
      ),
    ),
  );
},
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AnnouncementsScreen(
        groupId: widget.groupId,
        groupName: groupName,
        isOwner: isOwner,
      ),
    ),
  );
},
),_buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: const Color(0xFF121D2F),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFF263754),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2A43),
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFD4AF37),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8E9AAF),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF68758A),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1424),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1424),
        foregroundColor: Colors.white,
        elevation: 0,
        title: loading
            ? const Text('Study Group')
            : Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    groupName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subject.isNotEmpty)
                    Text(
                      subject,
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
        actions: [
          IconButton(
            onPressed: _showGroupInfo,
            icon: const Icon(
              Icons.info_outline_rounded,
            ),
            tooltip: 'Group information',
          ),
          PopupMenuButton<String>(
            color: const Color(0xFF162238),
            onSelected: (value) {
              if (value == 'leave') {
                _leaveGroup();
              }

              if (value == 'info') {
                _showGroupInfo();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'info',
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFD4AF37),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Group Information',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isOwner)
                const PopupMenuItem<String>(
                  value: 'leave',
                  child: Row(
                    children: [
                      Icon(
                        Icons.exit_to_app_rounded,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Leave Group',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD4AF37),
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadGroup,
                  color: const Color(0xFFD4AF37),
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      40,
                    ),
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF121D2F),
                          borderRadius:
                              BorderRadius.circular(22),
                          border: Border.all(
                            color:
                                const Color(0xFF263754),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(0xFFD4AF37),
                                borderRadius:
                                    BorderRadius.circular(
                                  18,
                                ),
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
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    groupName,
                                    style:
                                        const TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                  if (subject.isNotEmpty)
                                    Padding(
                                      padding:
                                          const EdgeInsets
                                              .only(top: 5),
                                      child: Text(
                                        subject,
                                        style:
                                            const TextStyle(
                                          color:
                                              Color(0xFFD4AF37),
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 7),
                                  Text(
                                    '$memberCount member'
                                    '${memberCount == 1 ? '' : 's'}',
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Group',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildFeatureCard(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Group Chat',
                        subtitle:
                            'Talk with classmates in real time.',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GroupChatScreen(
                                groupId: widget.groupId,
                                groupName: groupName,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildFeatureCard(
                        icon: Icons.campaign_outlined,
                        title: 'Announcements',
                        subtitle:
                            'Important messages from the group owner.',
                        onTap: () {
                          _showComingSoon(
                            'Announcements',
                          );
                        },
                      ),
                      _buildFeatureCard(
                        icon: Icons.people_outline_rounded,
                        title: 'Members',
                        subtitle:
                            'See everyone who belongs to this group.',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GroupMembersScreen(
                                groupId: widget.groupId,
                                groupName: groupName,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildFeatureCard(
                        icon: Icons.folder_outlined,
                        title: 'Learning Materials',
                        subtitle:
                            'Notes, documents, videos and other study resources.',
                        onTap: () {
                          _showComingSoon(
                            'Learning Materials',
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      if (description.isNotEmpty) ...[
                        const Text(
                          'About this group',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          description,
                          style: const TextStyle(
                            color: Color(0xFFB8C2D1),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
