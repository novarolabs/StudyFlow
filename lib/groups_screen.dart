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
  } catch (_) {
    if (!mounted) return;

    setState(() {
      loading = false;
    });
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
      builder: (context) {
        bool joining = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF121D2F),
              title: const Text(
                'Join a Study Group',
                style: TextStyle(color: Colors.white),
              ),
              content: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Join Code',
                  hintText: 'e.g. MATH-7K42',
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
                      : () => Navigator.pop(context),
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
                          final code =
                              controller.text.trim();

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

                            if (!context.mounted) return;

                            Navigator.pop(context);
                            await _loadGroups();

                            if (!mounted) return;

                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'You joined the group successfully.',
                                ),
                              ),
                            );
                          } catch (_) {
                            if (!context.mounted) return;

                            setDialogState(() {
                              joining = false;
                            });

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not join the group. Check the join code and try again.',
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
        const SizedBox(height: 70),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFF162238),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Icon(
            Icons.groups_rounded,
            size: 48,
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
          'study team, or classmates. You will get a '
          'join code that you can share with others.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFB8C2D1),
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _openCreateGroup,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Your First Group'),
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
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _showJoinGroupDialog,
          icon: const Icon(Icons.login_rounded),
          label: const Text('Join a Group'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFD4AF37),
            side: const BorderSide(
              color: Color(0xFFD4AF37),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        100,
      ),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];

        final name =
            group['name']?.toString() ?? 'Unnamed Group';
        final subject =
            group['subject']?.toString() ?? '';
        final description =
            group['description']?.toString() ?? '';
        final joinCode =
            group['joinCode']?.toString() ?? '';

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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37),
                        borderRadius:
                            BorderRadius.circular(16),
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
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          if (subject.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.only(
                                top: 4,
                              ),
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
                        ],
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    description,
                    maxLines: 3,
                    overflow:
                        TextOverflow.ellipsis,
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
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1424),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.key_rounded,
                          color:
                              Color(0xFFD4AF37),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Join code:',
                          style: TextStyle(
                            color:
                                Color(0xFFB8C2D1),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          joinCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight:
                                FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
