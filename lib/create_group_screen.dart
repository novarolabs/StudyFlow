import 'package:flutter/material.dart';
import 'group_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final nameController = TextEditingController();
  final subjectController = TextEditingController();
  final descriptionController = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    nameController.dispose();
    subjectController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = nameController.text.trim();
    final subject = subjectController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty || subject.isEmpty) {
      _showMessage(
        'Please enter the group name and subject.',
      );
      return;
    }

    if (loading) return;

    setState(() {
      loading = true;
    });

    try {
      final groupId = await GroupService.createGroup(
        name: name,
        subject: subject,
        description: description,
      );

      if (!mounted) return;

      Navigator.pop(context, groupId);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _showMessage(
        'Could not create the group. Please check your connection and try again.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFF162238),
      labelStyle: const TextStyle(
        color: Color(0xFFB8C2D1),
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF6B7280),
      ),
      prefixIconColor: const Color(0xFFD4AF37),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF263754),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF263754),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFD4AF37),
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1424),
      appBar: AppBar(
        title: const Text('Create Group'),
        backgroundColor: const Color(0xFF0B1424),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 600,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create a Study Group',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Create a space where classmates, teachers, '
                    'and study partners can share learning materials '
                    'and announcements.',
                    style: TextStyle(
                      color: Color(0xFFB8C2D1),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 30),

                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: _inputDecoration(
                      'Group / Class Name',
                      'e.g. Grade 10 Mathematics',
                      Icons.groups_rounded,
                    ),
                  ),

                  const SizedBox(height: 18),

                  TextField(
                    controller: subjectController,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: _inputDecoration(
                      'Subject',
                      'e.g. Mathematics',
                      Icons.menu_book_rounded,
                    ),
                  ),

                  const SizedBox(height: 18),

                  TextField(
                    controller: descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: _inputDecoration(
                      'Description',
                      'What is this group for?',
                      Icons.description_rounded,
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : _createGroup,
                      icon: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0B1424),
                              ),
                            )
                          : const Icon(
                              Icons.add_rounded,
                            ),
                      label: Text(
                        loading
                            ? 'Creating Group...'
                            : 'Create Group',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: const Color(0xFF0B1424),
                        disabledBackgroundColor:
                            const Color(0xFF8A7425),
                        disabledForegroundColor:
                            const Color(0xFF0B1424),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'After creating the group, StudyFlow will generate '
                    'a unique join code that you can share with others.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
