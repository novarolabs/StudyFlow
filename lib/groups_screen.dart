import 'package:flutter/material.dart';

import 'create_group_screen.dart';
import 'group_service.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  bool loading = true;
  List<Map<String, dynamic>> groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final documents = await GroupService.getMyGroups();

      if (!mounted) return;

      setState(() {
        groups = documents.map((doc) {
          final data = doc.data() ?? <String, dynamic>{};
          data['id'] = doc.id;
          return data;
        }).toList();

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load groups: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _openCreateGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateGroupScreen(),
      ),
    );

    if (result != null) {
      await _loadGroups();
    }
  }

  void _showJoinGroupDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool joining = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF121D2F),
              title: const Text(
                'Join a Study Group',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Join Code',
                  hintText: 'e.g. AB-527',
                  labelStyle: const TextStyle(
                    color: Color(0xFFB8C2D1),
                  ),
                  hintStyle: const TextStyle(
                    color: Color(0xFF6B7280),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF162238),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: joining
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFFB8C2D1),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: joining
                      ? null
                      : () async {
                          final code = controller.text.trim();

                          if (code.isEmpty) {
                            return;
                          }

                          setDialogState(() {
                            joining = true;
                          });

                          try {
                            await GroupService.joinGroup(
                              joinCode: code,
                            );

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            await _loadGroups();

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'You joined the group successfully.',
                                ),
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              joining = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Could not join group: $e',
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF0B1424),
                  ),
                  child: joining
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0B1424),
                          ),
                        )
                      : const Text('Join'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      controller.dispose();
    });
  }

  Future<void> _deleteGroup(Map<String, dynamic> group) async {
    final groupId = group['id']?.toString();

    if (groupId == null || groupId.isEmpty) {
      return;
    }

    final name = group['name']?.toString() ?? 'this group';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121D2F),
          title: const Text(
            'Delete Group?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to permanently delete "$name"?\n\n'
            'This action cannot be undone.',
            style: const TextStyle(
              color: Color(0xFFB8C2D1),
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFFB8C2D1),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await GroupService.deleteGroup(groupId);

      if (!mounted) return;

      await _loadGroups();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group deleted successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete group: $e'),
        ),
      );
    }
  }

  void _openGroup(Map<String, dynamic> group) {
    final name = group['name']?.toString() ?? 'Study Group';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$name — Group Home will be added next.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1424),
      appBar: AppBar(
        title: const Text(
          'Study Groups',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0B1424),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadGroups,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD4AF37),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadGroups,
              color: const Color(0xFFD4AF37),
              child: groups.isEmpty
                  ? _buildEmptyState()
                  : _buildGroupsList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateGroup,
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: const Color(0xFF0B1424),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Create Group',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 55),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: const Color(0xFF162238),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Icon(
            Icons.groups_rounded,
            size: 64,
            color: Color(0xFFD4AF37),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'No Study Groups Yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Create a group for your class, subject, '
          'study team, or classmates.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFB8C2D1),
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 30),
        _buildActionButton(
          icon: Icons.add_rounded,
          label: 'Create Your First Group',
          filled: true,
          onPressed: _openCreateGroup,
        ),
        const SizedBox(height: 14),
        _buildActionButton(
          icon: Icons.login_rounded,
          label: 'Join a Group',
          filled: false,
          onPressed: _showJoinGroupDialog,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onPressed,
  }) {
    if (filled) {
      return SizedBox(
        height: 54,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            foregroundColor: const Color(0xFF0B1424),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFD4AF37),
          side: const BorderSide(
            color: Color(0xFFD4AF37),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsList() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        120,
      ),
      children: [
        _buildTopActions(),
        const SizedBox(height: 20),
        const Text(
          'Your Groups',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        ...groups.map(_buildGroupCard),
      ],
    );
  }

  Widget _buildTopActions() {
    return Row(
      children: [
        Expanded(
          child: _smallAction(
            icon: Icons.login_rounded,
            label: 'Join Group',
            onPressed: _showJoinGroupDialog,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _smallAction(
            icon: Icons.add_rounded,
            label: 'Create Group',
            onPressed: _openCreateGroup,
          ),
        ),
      ],
    );
  }

  Widget _smallAction({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 19,
        ),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFD4AF37),
          side: const BorderSide(
            color: Color(0xFFD4AF37),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final name =
        group['name']?.toString() ?? 'Unnamed Group';

    final subject =
        group['subject']?.toString() ?? '';

    final description =
        group['description']?.toString() ?? '';

    final joinCode =
        group['joinCode']?.toString() ?? '';

    final ownerId =
        group['ownerId']?.toString() ?? '';

    final currentUserId =
        GroupService.currentUser?.uid ?? '';

    final isOwner =
        ownerId.isNotEmpty &&
        ownerId == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF121D2F),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFF263754),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openGroup(group),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: Color(0xFF0B1424),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (subject.isNotEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 4),
                            child: Text(
                              subject,
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isOwner)
                    PopupMenuButton<String>(
                      color: const Color(0xFF162238),
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Color(0xFFB8C2D1),
                      ),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteGroup(group);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Delete Group',
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
              if (description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB8C2D1),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
              if (joinCode.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1424),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.key_rounded,
                        color: Color(0xFFD4AF37),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Join code:',
                        style: TextStyle(
                          color: Color(0xFFB8C2D1),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          joinCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF6B7280),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Tap to open group',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
