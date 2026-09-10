import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_state_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AnnouncementsScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final bool isOwner;

  const AnnouncementsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.isOwner,
  });

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _announcementsCollection =>
      _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('announcements');

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8798B0)),
      filled: true,
      fillColor: const Color(0xFF0B1628),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF31527E)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF31527E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD4AF37)),
      ),
    );
  }

  Future<void> _createAnnouncement() async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    bool priority = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF101E35),
              title: const Text(
                'New Announcement',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Title'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: messageController,
                      maxLines: 5,
                      minLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Announcement'),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: priority,
                      onChanged: (value) {
                        setDialogState(() {
                          priority = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Priority announcement',
                        style: TextStyle(color: Colors.white),
                      ),
                      activeColor: const Color(0xFFD4AF37),
                      checkColor: Colors.black,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final message = messageController.text.trim();

                    if (title.isEmpty || message.isEmpty) return;

                    await _announcementsCollection.add({
                      'title': title,
                      'message': message,
                      'priority': priority,
                      'createdBy': _auth.currentUser?.uid,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                  child: const Text(
                    'Publish',
                    style: TextStyle(color: Color(0xFFFFD95A)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    messageController.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1A2940),
          content: Text('Announcement published'),
        ),
      );
    }
  }

  Future<void> _editAnnouncement(
    String id,
    Map<String, dynamic> data,
  ) async {
    final titleController = TextEditingController(
      text: data['title']?.toString() ?? '',
    );
    final messageController = TextEditingController(
      text: data['message']?.toString() ?? '',
    );

    bool priority = data['priority'] == true;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF101E35),
              title: const Text(
                'Edit Announcement',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Title'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: messageController,
                      maxLines: 5,
                      minLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Announcement'),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: priority,
                      onChanged: (value) {
                        setDialogState(() {
                          priority = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Priority announcement',
                        style: TextStyle(color: Colors.white),
                      ),
                      activeColor: const Color(0xFFD4AF37),
                      checkColor: Colors.black,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final message = messageController.text.trim();

                    if (title.isEmpty || message.isEmpty) return;

                    await _announcementsCollection.doc(id).update({
                      'title': title,
                      'message': message,
                      'priority': priority,
                      'edited': true,
                      'editedAt': FieldValue.serverTimestamp(),
                    });

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Color(0xFFFFD95A)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    messageController.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1A2940),
          content: Text('Announcement updated'),
        ),
      );
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    await _announcementsCollection.doc(id).delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF1A2940),
        content: Text('Announcement deleted'),
      ),
    );
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF101E35),
          title: const Text(
            'Delete announcement?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This announcement will be permanently removed.',
            style: TextStyle(color: Color(0xFFB7C5D9)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteAnnouncement(id);
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';

    final date = timestamp.toDate();

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day}/${date.month}/${date.year} • $hour:$minute $period';
  }

  @override
  Future<void> _markAnnouncementsRead() async {
    await NotificationStateService.markAnnouncementsRead(widget.groupId);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1628),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Announcements',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.groupName,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8FA6C4),
              ),
            ),
          ],
        ),
        actions: [
          if (widget.isOwner)
            IconButton(
              onPressed: _createAnnouncement,
              icon: const Icon(Icons.add_rounded),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _announcementsCollection
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _markAnnouncementsRead();
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load announcements.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFB7C5D9),
                  ),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD4AF37),
              ),
            );
          }

          final announcements = snapshot.data?.docs ?? [];

          if (announcements.isEmpty) {
            return _emptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final document = announcements[index];
              return _announcementCard(
                document.id,
                document.data(),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.isOwner
          ? FloatingActionButton.extended(
              onPressed: _createAnnouncement,
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              icon: const Icon(Icons.campaign_rounded),
              label: const Text(
                'Announce',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF14233B),
                border: Border.all(
                  color: const Color(0xFF31527E),
                ),
              ),
              child: const Icon(
                Icons.campaign_rounded,
                size: 42,
                color: Color(0xFFD4AF37),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No announcements yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Important class updates will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8FA6C4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _announcementCard(
    String id,
    Map<String, dynamic> data,
  ) {
    final title = data['title']?.toString() ?? 'Announcement';
    final message = data['message']?.toString() ?? '';
    final priority = data['priority'] == true;
    final edited = data['edited'] == true;

    final timestamp = data['createdAt'] is Timestamp
        ? data['createdAt'] as Timestamp
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF101E35),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: priority
              ? const Color(0xFFD4AF37)
              : const Color(0xFF213B60),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: priority
                        ? const Color(0xFFD4AF37)
                        : const Color(0xFF17345A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    priority
                        ? Icons.priority_high_rounded
                        : Icons.campaign_rounded,
                    color: priority
                        ? Colors.black
                        : const Color(0xFF7DB7FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.isOwner)
                  PopupMenuButton<String>(
                    color: const Color(0xFF17253C),
                    iconColor: const Color(0xFF9EB0C8),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editAnnouncement(id, data);
                      } else if (value == 'delete') {
                        _confirmDelete(id);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          'Edit',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFFD2DCEB),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 15,
                  color: Color(0xFF7189A8),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(timestamp),
                  style: const TextStyle(
                    color: Color(0xFF7189A8),
                    fontSize: 12,
                  ),
                ),
                if (edited) ...[
                  const SizedBox(width: 10),
                  const Text(
                    'Edited',
                    style: TextStyle(
                      color: Color(0xFF7189A8),
                      fontSize: 12,
                    ),
                  ),
                ],
                if (priority) ...[
                  const Spacer(),
                  const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: Color(0xFFD4AF37),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'PRIORITY',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
