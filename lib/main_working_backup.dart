import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (_) {
    // StudyFlow can still operate in offline mode.
  }

  runApp(const StudyFlowApp());
}

// =====================================================
// APP
// =====================================================

class StudyFlowApp extends StatelessWidget {
  const StudyFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1220),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37),
          brightness: Brightness.dark,
        ),
      ),
      home: const StartupScreen(),
    );
  }
}

// =====================================================
// STARTUP
// =====================================================

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  bool loading = true;
  bool seenWelcome = false;

  @override
  void initState() {
    super.initState();
    checkStartup();
  }

  Future<void> checkStartup() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      seenWelcome = prefs.getBool('seen_welcome') ?? false;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!seenWelcome) {
      return const WelcomeScreen();
    }

    return const HomeScreen();
  }
}

// =====================================================
// WELCOME
// =====================================================

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> continueToApp(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_welcome', true);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AuthChoiceScreen(),
        ),
      );
    }
  }

  Future<void> continueOffline(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_welcome', true);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),

              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(35),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 75,
                  color: Color(0xFF0B1220),
                ),
              ),

              const SizedBox(height: 35),

              const Text(
                'STUDYFLOW',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Your School Life, Organized.',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Organize your notes, assignments, tasks and timetable in one powerful learning space.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 16,
                  height: 1.6,
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => continueToApp(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(18),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextButton.icon(
                onPressed: () => continueOffline(context),
                icon: const Icon(Icons.offline_bolt),
                label: const Text('Continue Offline'),
              ),

              const SizedBox(height: 20),

              const Text(
                'Created by Cypher Digital Labs',
                style: TextStyle(
                  color: Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// AUTH CHOICE
// =====================================================

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyFlow'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Icon(
              Icons.account_circle_rounded,
              size: 90,
              color: Color(0xFFD4AF37),
            ),

            const SizedBox(height: 25),

            const Text(
              'Welcome to StudyFlow',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Choose how you want to continue.',
              style: TextStyle(
                color: Color(0xFF94A3B8),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Login'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Create Account'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            TextButton.icon(
              icon: const Icon(Icons.offline_bolt),
              label: const Text('Use StudyFlow Offline'),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// LOGIN
// =====================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String error = '';

  Future<void> login() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        error =
            'Unable to login. Check your internet connection and account details.';
      });
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 30),

          const Icon(
            Icons.lock_rounded,
            size: 70,
            color: Color(0xFFD4AF37),
          ),

          const SizedBox(height: 30),

          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 18),

          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
          ),

          if (error.isNotEmpty) ...[
            const SizedBox(height: 15),
            Text(
              error,
              style: const TextStyle(
                color: Colors.redAccent,
              ),
            ),
          ],

          const SizedBox(height: 25),

          ElevatedButton(
            onPressed: loading ? null : login,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// REGISTER
// =====================================================

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String role = 'Student';
  bool loading = false;
  String error = '';

  Future<void> register() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'profile_name',
        nameController.text.trim(),
      );

      await prefs.setString(
        'profile_role',
        role,
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        error =
            'Unable to create account. Please check your internet connection and try again.';
      });
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 18),

          DropdownButtonFormField<String>(
            value: role,
            decoration: const InputDecoration(
              labelText: 'Account Type',
              prefixIcon: Icon(Icons.school),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'Student',
                child: Text('Student'),
              ),
              DropdownMenuItem(
                value: 'Teacher',
                child: Text('Teacher'),
              ),
              DropdownMenuItem(
                value: 'Tutor',
                child: Text('Tutor'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  role = value;
                });
              }
            },
          ),

          const SizedBox(height: 18),

          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 18),

          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
          ),

          if (error.isNotEmpty) ...[
            const SizedBox(height: 15),
            Text(
              error,
              style: const TextStyle(
                color: Colors.redAccent,
              ),
            ),
          ],

          const SizedBox(height: 25),

          ElevatedButton(
            onPressed: loading ? null : register,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Create Account'),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// HOME
// =====================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  final screens = const [
    DashboardScreen(),
    TasksScreen(),
    TimetableScreen(),
    NotesScreen(),
    GroupsScreen(),
    ProfileScreen(),
  ];

  final titles = [
    'Dashboard',
    'Tasks',
    'Timetable',
    'Notes',
    'Groups',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
      ),
      body: screens[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() {
            index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.note_outlined),
            selectedIcon: Icon(Icons.note),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// =====================================================
// DASHBOARD
// =====================================================

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isOnline(),
      builder: (context, snapshot) {
        final online = snapshot.data ?? false;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Icon(
                  online ? Icons.cloud_done : Icons.cloud_off,
                  color: online
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                ),
                const SizedBox(width: 10),
                Text(
                  online
                      ? 'Online and ready to sync'
                      : 'Offline mode active',
                ),
              ],
            ),

            const SizedBox(height: 25),

            const Text(
              'Your Learning Hub',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Stay organized and keep your school life under control.',
              style: TextStyle(
                color: Color(0xFF94A3B8),
              ),
            ),

            const SizedBox(height: 25),

            const DashboardCard(
              icon: Icons.checklist,
              title: 'Tasks',
              subtitle: 'Plan and complete your assignments',
            ),

            const SizedBox(height: 15),

            const DashboardCard(
              icon: Icons.calendar_month,
              title: 'Timetable',
              subtitle: 'Keep track of your classes',
            ),

            const SizedBox(height: 15),

            const DashboardCard(
              icon: Icons.note,
              title: 'Offline Notes',
              subtitle: 'Read and write notes without internet',
            ),

            const SizedBox(height: 15),

            const DashboardCard(
              icon: Icons.groups,
              title: 'Learning Groups',
              subtitle: 'Connect with students, teachers and tutors',
            ),
          ],
        );
      },
    );
  }
}

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          size: 35,
          color: const Color(0xFFD4AF37),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

// =====================================================
// TASKS
// =====================================================

class Task {
  String title;
  bool completed;
  String priority;

  Task({
    required this.title,
    this.completed = false,
    this.priority = 'Normal',
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'completed': completed,
      'priority': priority,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'] ?? '',
      completed: json['completed'] ?? false,
      priority: json['priority'] ?? 'Normal',
    );
  }
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('tasks');

    if (saved != null) {
      final List data = jsonDecode(saved);

      setState(() {
        tasks = data
            .map((item) => Task.fromJson(item))
            .toList();
      });
    }
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();

    final data = tasks
        .map((task) => task.toJson())
        .toList();

    await prefs.setString(
      'tasks',
      jsonEncode(data),
    );
  }

  Future<void> addTask() async {
    final controller = TextEditingController();
    String priority = 'Normal';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text('New Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Task title',
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Low',
                        child: Text('Low'),
                      ),
                      DropdownMenuItem(
                        value: 'Normal',
                        child: Text('Normal'),
                      ),
                      DropdownMenuItem(
                        value: 'High',
                        child: Text('High'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        dialogSetState(() {
                          priority = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (controller.text.trim().isEmpty) {
                      return;
                    }

                    setState(() {
                      tasks.add(
                        Task(
                          title: controller.text.trim(),
                          priority: priority,
                        ),
                      );
                    });

                    await saveTasks();

                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
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
    if (tasks.isEmpty) {
      return Scaffold(
        body: const Center(
          child: Text(
            'No tasks yet.\nStart organizing your work!',
            textAlign: TextAlign.center,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: addTask,
          child: const Icon(Icons.add),
        ),
      );
    }

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];

          return Card(
            child: CheckboxListTile(
              value: task.completed,
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: task.completed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: Text(
                'Priority: ${task.priority}',
              ),
              onChanged: (value) async {
                setState(() {
                  task.completed = value ?? false;
                });

                await saveTasks();
              },
              secondary: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                ),
                onPressed: () async {
                  setState(() {
                    tasks.removeAt(index);
                  });

                  await saveTasks();
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// =====================================================
// TIMETABLE
// =====================================================

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() =>
      _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  List<String> classes = [];

  @override
  void initState() {
    super.initState();
    loadClasses();
  }

  Future<void> loadClasses() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      classes =
          prefs.getStringList('classes') ?? [];
    });
  }

  Future<void> saveClasses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'classes',
      classes,
    );
  }

  Future<void> addClass() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Class'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Subject / Class',
              hintText: 'Example: Mathematics - Monday 8:00 AM',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) {
                  return;
                }

                setState(() {
                  classes.add(
                    controller.text.trim(),
                  );
                });

                await saveClasses();

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: classes.isEmpty
          ? const Center(
              child: Text(
                'Your timetable is empty.\nAdd your first class.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.school,
                      color: Color(0xFFD4AF37),
                    ),
                    title: Text(classes[index]),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                      ),
                      onPressed: () async {
                        setState(() {
                          classes.removeAt(index);
                        });

                        await saveClasses();
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: addClass,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// =====================================================
// NOTES
// =====================================================

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<String> notes = [];

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      notes =
          prefs.getStringList('notes') ?? [];
    });
  }

  Future<void> saveNotes() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'notes',
      notes,
    );
  }

  Future<void> addNote() async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Note'),
          content: TextField(
            controller: controller,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Write your note here...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) {
                  return;
                }

                setState(() {
                  notes.add(
                    controller.text.trim(),
                  );
                });

                await saveNotes();

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: notes.isEmpty
          ? const Center(
              child: Text(
                'No notes yet.\nYour offline notes will appear here.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.note,
                      color: Color(0xFFD4AF37),
                    ),
                    title: Text(
                      notes[index],
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {},
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                      ),
                      onPressed: () async {
                        setState(() {
                          notes.removeAt(index);
                        });

                        await saveNotes();
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: addNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// =====================================================
// GROUPS
// =====================================================

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups,
              size: 80,
              color: Color(0xFFD4AF37),
            ),
            SizedBox(height: 20),
            Text(
              'Learning Groups',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Groups will allow Students, Teachers and Tutors to collaborate and share learning materials.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// PROFILE
// =====================================================

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<Map<String, String>> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'name': prefs.getString('profile_name') ?? 'StudyFlow User',
      'role': prefs.getString('profile_role') ?? 'Offline User',
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: loadProfile(),
      builder: (context, snapshot) {
        final data = snapshot.data ??
            {
              'name': 'StudyFlow User',
              'role': 'Offline User',
            };

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 20),

            const CircleAvatar(
              radius: 55,
              backgroundColor: Color(0xFFD4AF37),
              child: Icon(
                Icons.person,
                size: 65,
                color: Color(0xFF0B1220),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              data['name']!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              data['role']!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFD4AF37),
              ),
            ),

            const SizedBox(height: 35),

            ListTile(
              leading: const Icon(
                Icons.info_outline,
              ),
              title: const Text('About StudyFlow'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AboutScreen(),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(
                Icons.logout,
              ),
              title: const Text('Logout'),
              onTap: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                } catch (_) {}

                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AuthChoiceScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}

// =====================================================
// ABOUT
// =====================================================

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About StudyFlow'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 30),

          const Icon(
            Icons.school_rounded,
            size: 90,
            color: Color(0xFFD4AF37),
          ),

          const SizedBox(height: 20),

          const Text(
            'STUDYFLOW',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Your School Life, Organized.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 17,
            ),
          ),

          const SizedBox(height: 35),

          const InfoCard(
            icon: Icons.business_rounded,
            title: 'Created by',
            value: 'Cypher Digital Labs',
          ),

          const SizedBox(height: 14),

          const InfoCard(
            icon: Icons.design_services_rounded,
            title: 'Designed by',
            value: 'Papy',
          ),

          const SizedBox(height: 14),

          const InfoCard(
            icon: Icons.info_outline,
            title: 'Version',
            value: 'StudyFlow 3.0',
          ),

          const SizedBox(height: 40),

          const Text(
            'StudyFlow is an offline-first learning platform designed to help students, teachers and tutors organize notes, assignments, tasks and school schedules in one simple place.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFE5E7EB),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFFD4AF37),
        ),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}
