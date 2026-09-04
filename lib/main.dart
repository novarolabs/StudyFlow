import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Offline mode remains available even if Firebase cannot initialize.
  }
  runApp(const StudyFlowApp());
}

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
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B1220),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const AppLoader(),
    );
  }
}

// =====================================================
// STARTUP / ONBOARDING / AUTH
// =====================================================

class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  bool loading = true;
  bool onboardingCompleted = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      onboardingCompleted =
          prefs.getBool('studyflow_onboarding_completed') ?? false;
      loading = false;
    });
  }

  Future<void> _finishWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('studyflow_onboarding_completed', true);
    if (!mounted) return;
    setState(() => onboardingCompleted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!onboardingCompleted) {
      return WelcomeScreen(onFinished: _finishWelcome);
    }
    return const AuthGate();
  }
}

class WelcomeScreen extends StatefulWidget {
  final Future<void> Function() onFinished;
  const WelcomeScreen({super.key, required this.onFinished});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final controller = PageController();
  int currentPage = 0;

  final pages = const [
    _WelcomePageData(
      icon: Icons.school_rounded,
      title: 'Welcome to StudyFlow',
      description:
          'Your school life, organized. Keep your notes, tasks and timetable in one beautiful place.',
    ),
    _WelcomePageData(
      icon: Icons.auto_awesome_rounded,
      title: 'Stay Organized',
      description:
          'Write notes, track assignments and manage your weekly study schedule with ease.',
    ),
    _WelcomePageData(
      icon: Icons.rocket_launch_rounded,
      title: 'Built for Better Learning',
      description: 'Created by Cypher Digital Labs\nDesigned by Papy',
    ),
  ];

  Future<void> finish() async => widget.onFinished();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: finish, child: const Text('Skip')),
              ),
              Expanded(
                child: PageView.builder(
                  controller: controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => currentPage = i),
                  itemBuilder: (_, index) {
                    final item = pages[index];
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B2940),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Icon(item.icon,
                                size: 76, color: const Color(0xFFD4AF37)),
                          ),
                          const SizedBox(height: 45),
                          Text(item.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 32, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 18),
                          Text(item.description,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 17,
                                  height: 1.6,
                                  color: Color(0xFFE5E7EB))),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: currentPage == i
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFF41516B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (currentPage == pages.length - 1) {
                      finish();
                    } else {
                      controller.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: Text(
                    currentPage == pages.length - 1
                        ? 'Get Started'
                        : 'Continue',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomePageData {
  final IconData icon;
  final String title;
  final String description;
  const _WelcomePageData(
      {required this.icon, required this.title, required this.description});
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) return const MainNavigation();
        return const AuthChoiceScreen();
      },
    );
  }
}

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school_rounded,
                  size: 100, color: Color(0xFFD4AF37)),
              const SizedBox(height: 25),
              const Text('STUDYFLOW',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Sign in to continue your learning journey.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFE5E7EB))),
              const SizedBox(height: 40),
              _GoldButton(
                text: 'Login',
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen())),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54)),
                child: const Text('Create Account'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavigation()),
                    (_) => false,
                  );
                },
                child: const Text('Continue offline'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  bool obscure = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      _message('Enter your email and password.');
      return;
    }
    setState(() => busy = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(), password: password.text);
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      _message(e.message ?? 'Login failed.');
    } catch (_) {
      _message('Could not connect to Firebase. Check your internet connection.');
    }
    if (mounted) setState(() => busy = false);
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return AuthForm(
      title: 'Welcome Back',
      subtitle: 'Login to your StudyFlow account.',
      fields: [
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
              labelText: 'Email', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: password,
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: 'Password',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => obscure = !obscure)),
          ),
        ),
      ],
      button: busy
          ? const Center(child: CircularProgressIndicator())
          : _GoldButton(text: 'Login', onPressed: login),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (name.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.length < 6) {
      _message('Enter your name, a valid email and a password of at least 6 characters.');
      return;
    }
    setState(() => busy = true);
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(), password: password.text);
      await credential.user?.updateDisplayName(name.text.trim());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_name', name.text.trim());
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      _message(e.message ?? 'Account creation failed.');
    } catch (_) {
      _message('Could not create the account.');
    }
    if (mounted) setState(() => busy = false);
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return AuthForm(
      title: 'Create Account',
      subtitle: 'Join StudyFlow and organize your learning.',
      fields: [
        TextField(
          controller: name,
          decoration: const InputDecoration(
              labelText: 'Your name', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
              labelText: 'Email', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(
              labelText: 'Password (minimum 6 characters)',
              border: OutlineInputBorder()),
        ),
      ],
      button: busy
          ? const Center(child: CircularProgressIndicator())
          : _GoldButton(text: 'Create Account', onPressed: register),
    );
  }
}

class AuthForm extends StatelessWidget {
  final String title, subtitle;
  final List<Widget> fields;
  final Widget button;
  const AuthForm(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.fields,
      required this.button});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 35),
            Text(title,
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Color(0xFFD4AF37))),
            const SizedBox(height: 35),
            ...fields,
            const SizedBox(height: 25),
            button,
          ],
        ),
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const _GoldButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 17)),
          child: Text(text,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      );
}

// =====================================================
// MODELS / STORAGE
// =====================================================

class Note {
  String title, content;
  DateTime updatedAt;
  Note({required this.title, required this.content, required this.updatedAt});
  Map<String, dynamic> toJson() =>
      {'title': title, 'content': content, 'updatedAt': updatedAt.toIso8601String()};
  factory Note.fromJson(Map<String, dynamic> j) => Note(
      title: j['title'] ?? '',
      content: j['content'] ?? '',
      updatedAt: DateTime.tryParse(j['updatedAt'] ?? '') ?? DateTime.now());
}

class StudyTask {
  String title, description, subject, priority, dueDate;
  bool completed;
  StudyTask(
      {required this.title,
      required this.description,
      required this.subject,
      required this.priority,
      required this.dueDate,
      required this.completed});
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'subject': subject,
        'priority': priority,
        'dueDate': dueDate,
        'completed': completed
      };
  factory StudyTask.fromJson(Map<String, dynamic> j) => StudyTask(
      title: j['title'] ?? '',
      description: j['description'] ?? '',
      subject: j['subject'] ?? '',
      priority: j['priority'] ?? 'Medium',
      dueDate: j['dueDate'] ?? '',
      completed: j['completed'] ?? false);
}

class TimetableItem {
  String subject, teacher, day, startTime, endTime;
  TimetableItem(
      {required this.subject,
      required this.teacher,
      required this.day,
      required this.startTime,
      required this.endTime});
  Map<String, dynamic> toJson() => {
        'subject': subject,
        'teacher': teacher,
        'day': day,
        'startTime': startTime,
        'endTime': endTime
      };
  factory TimetableItem.fromJson(Map<String, dynamic> j) => TimetableItem(
      subject: j['subject'] ?? '',
      teacher: j['teacher'] ?? '',
      day: j['day'] ?? 'Monday',
      startTime: j['startTime'] ?? '08:00',
      endTime: j['endTime'] ?? '09:00');
}

class StorageService {
  static const notesKey = 'studyflow_notes';
  static const tasksKey = 'studyflow_tasks';
  static const timetableKey = 'studyflow_timetable';

  static Future<List<T>> _load<T>(
      String key, T Function(Map<String, dynamic>) fromJson) async {
    final data = (await SharedPreferences.getInstance()).getString(key);
    if (data == null) return [];
    try {
      return (jsonDecode(data) as List)
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save<T>(
      String key, List<T> data, Map<String, dynamic> Function(T) toJson) async {
    await (await SharedPreferences.getInstance())
        .setString(key, jsonEncode(data.map(toJson).toList()));
  }

  static Future<List<Note>> loadNotes() => _load(notesKey, Note.fromJson);
  static Future<void> saveNotes(List<Note> v) =>
      _save(notesKey, v, (x) => x.toJson());
  static Future<List<StudyTask>> loadTasks() => _load(tasksKey, StudyTask.fromJson);
  static Future<void> saveTasks(List<StudyTask> v) =>
      _save(tasksKey, v, (x) => x.toJson());
  static Future<List<TimetableItem>> loadTimetable() =>
      _load(timetableKey, TimetableItem.fromJson);
  static Future<void> saveTimetable(List<TimetableItem> v) =>
      _save(timetableKey, v, (x) => x.toJson());
}

// =====================================================
// NAVIGATION / HOME
// =====================================================

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      HomeScreen(onNavigate: (i) => setState(() => selectedIndex = i)),
      const NotesScreen(),
      const TasksScreen(),
      const TimetableScreen(),
      const GroupsScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: selectedIndex, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) => setState(() => selectedIndex = i),
          backgroundColor: const Color(0xFF121D2F),
          indicatorColor: const Color(0xFFD4AF37),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Notes'),
            NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Tasks'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Schedule'),
            NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Groups'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      );
}

class HomeScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;
  const HomeScreen({super.key, required this.onNavigate});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int noteCount = 0, pendingTaskCount = 0, todayClassCount = 0;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final n = await StorageService.loadNotes();
    final t = await StorageService.loadTasks();
    final s = await StorageService.loadTimetable();
    final day = const ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'][DateTime.now().weekday - 1];
    if (!mounted) return;
    setState(() {
      noteCount = n.length;
      pendingTaskCount = t.where((x) => !x.completed).length;
      todayClassCount = s.where((x) => x.day == day).length;
    });
  }

  String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning 👋';
    if (h < 18) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: RefreshIndicator(
          onRefresh: loadDashboard,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(greeting(), style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 17)),
              const SizedBox(height: 5),
              const Text('STUDYFLOW', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Your school life, organized.', style: TextStyle(fontSize: 16, color: Color(0xFFE5E7EB))),
              const SizedBox(height: 28),
              Row(children: [
                Expanded(child: DashboardCard(icon: Icons.menu_book_rounded, title: 'Notes', value: '$noteCount', subtitle: 'Saved notes', onTap: () => widget.onNavigate(1))),
                const SizedBox(width: 14),
                Expanded(child: DashboardCard(icon: Icons.checklist_rounded, title: 'Tasks', value: '$pendingTaskCount', subtitle: 'Pending', onTap: () => widget.onNavigate(2))),
              ]),
              const SizedBox(height: 14),
              DashboardCard(icon: Icons.calendar_month_rounded, title: 'Today', value: '$todayClassCount classes', subtitle: 'View your schedule', wide: true, onTap: () => widget.onNavigate(3)),
              const SizedBox(height: 30),
              const Text('Quick Actions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              QuickAction(icon: Icons.note_add_outlined, title: 'Create a new note', subtitle: 'Capture an idea or study material', onTap: () => widget.onNavigate(1)),
              const SizedBox(height: 12),
              QuickAction(icon: Icons.add_task, title: 'Add a task', subtitle: 'Keep track of homework and assignments', onTap: () => widget.onNavigate(2)),
            ],
          ),
        ),
      );
}

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title, value, subtitle;
  final VoidCallback onTap;
  final bool wide;
  const DashboardCard({super.key, required this.icon, required this.title, required this.value, required this.subtitle, required this.onTap, this.wide = false});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF162238), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFF273650))),
          child: wide
              ? Row(children: [
                  Icon(icon, size: 42, color: const Color(0xFFD4AF37)),
                  const SizedBox(width: 18),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Color(0xFFE5E7EB))),
                  ])),
                  Text(value, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(icon, color: const Color(0xFFD4AF37)),
                  const SizedBox(height: 20),
                  Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFFE5E7EB))),
                ]),
        ),
      );
}

class QuickAction extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const QuickAction({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tileColor: const Color(0xFF162238),
        leading: CircleAvatar(backgroundColor: const Color(0xFF253A5A), child: Icon(icon, color: const Color(0xFFD4AF37))),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      );
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
  List<Note> notes = [];
  bool loading = true;
  @override
  void initState() { super.initState(); loadNotes(); }

  Future<void> loadNotes() async {
    final n = await StorageService.loadNotes();
    n.sort((a,b) => b.updatedAt.compareTo(a.updatedAt));
    if (mounted) setState(() { notes = n; loading = false; });
  }

  Future<void> openEditor({Note? note, int? index}) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditorScreen(
      note: note,
      onSave: (saved) async {
        setState(() {
          if (note == null) notes.add(saved); else notes[index!] = saved;
          notes.sort((a,b) => b.updatedAt.compareTo(a.updatedAt));
        });
        await StorageService.saveNotes(notes);
      },
    )));
    loadNotes();
  }

  Future<void> deleteNote(int index) async {
    final yes = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Note?'),
      content: Text('Delete "${notes[index].title}" permanently?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    ));
    if (yes == true) { setState(() => notes.removeAt(index)); await StorageService.saveNotes(notes); }
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: Scaffold(
    floatingActionButton: FloatingActionButton(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black, onPressed: () => openEditor(), child: const Icon(Icons.add)),
    body: loading ? const Center(child: CircularProgressIndicator()) : notes.isEmpty
      ? const EmptyState(icon: Icons.menu_book_rounded, title: 'No notes yet', message: 'Create your first note and keep your study ideas organized.')
      : ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: notes.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) return const _ScreenHeader(title: 'My Notes', subtitle: 'Keep your study materials organized.');
            final index = i - 1; final note = notes[index];
            return Card(color: const Color(0xFF162238), margin: const EdgeInsets.only(bottom: 12), child: ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF253A5A), child: Icon(Icons.description_outlined, color: Color(0xFFD4AF37))),
              title: Text(note.title.isEmpty ? 'Untitled Note' : note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(note.content.trim().isEmpty ? 'No additional text' : note.content.trim(), maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => deleteNote(index)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteViewerScreen(note: note, onEdit: () async {
                Navigator.pop(context); await openEditor(note: note, index: index);
              }))),
            ));
          },
        ),
  ));
}

class NoteViewerScreen extends StatelessWidget {
  final Note note;
  final Future<void> Function() onEdit;
  const NoteViewerScreen({super.key, required this.note, required this.onEdit});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Note'), actions: [IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined))]),
    body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(note.title.isEmpty ? 'Untitled Note' : note.title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Last updated ${formatDate(note.updatedAt)}', style: const TextStyle(color: Color(0xFFD4AF37))),
      const SizedBox(height: 25), const Divider(), const SizedBox(height: 20),
      SelectableText(note.content.isEmpty ? 'No content in this note.' : note.content, style: const TextStyle(fontSize: 18, height: 1.7)),
    ]),
  );
}

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final Future<void> Function(Note) onSave;
  const NoteEditorScreen({super.key, this.note, required this.onSave});
  @override State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}
class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController title, content;
  @override void initState() { super.initState(); title = TextEditingController(text: widget.note?.title ?? ''); content = TextEditingController(text: widget.note?.content ?? ''); }
  @override void dispose() { title.dispose(); content.dispose(); super.dispose(); }
  Future<void> save() async {
    if (title.text.trim().isEmpty && content.text.trim().isEmpty) return;
    await widget.onSave(Note(title: title.text.trim().isEmpty ? 'Untitled Note' : title.text.trim(), content: content.text.trim(), updatedAt: DateTime.now()));
    if (mounted) Navigator.pop(context);
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.note == null ? 'New Note' : 'Edit Note'), actions: [TextButton(onPressed: save, child: const Text('SAVE', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)))]),
    body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      TextField(controller: title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), decoration: const InputDecoration(hintText: 'Title', border: InputBorder.none)),
      const Divider(),
      Expanded(child: TextField(controller: content, maxLines: null, expands: true, textAlignVertical: TextAlignVertical.top, style: const TextStyle(fontSize: 18, height: 1.6), decoration: const InputDecoration(hintText: 'Start writing your note...', border: InputBorder.none))),
    ])),
  );
}

// =====================================================
// TASKS
// =====================================================

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override State<TasksScreen> createState() => _TasksScreenState();
}
class _TasksScreenState extends State<TasksScreen> {
  List<StudyTask> tasks = []; bool loading = true;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { final v = await StorageService.loadTasks(); if (mounted) setState(() { tasks=v; loading=false; }); }
  Future<void> save() => StorageService.saveTasks(tasks);
  Future<void> edit({StudyTask? task, int? index}) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => TaskEditorScreen(task: task, onSave: (x) async {
      setState(() { if(task==null) tasks.add(x); else tasks[index!]=x; }); await save();
    })));
    load();
  }
  @override Widget build(BuildContext context) {
    final pending = tasks.where((x)=>!x.completed).toList(), completed = tasks.where((x)=>x.completed).toList();
    return SafeArea(child: Scaffold(
      floatingActionButton: FloatingActionButton(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black, onPressed: ()=>edit(), child: const Icon(Icons.add)),
      body: loading ? const Center(child:CircularProgressIndicator()) : tasks.isEmpty
        ? const EmptyState(icon: Icons.checklist_rounded,title:'No tasks yet',message:'Add homework, assignments and study goals here.')
        : ListView(padding: const EdgeInsets.all(20), children:[
          const _ScreenHeader(title:'My Tasks',subtitle:'Stay on top of your work.'),
          if(pending.isNotEmpty) const SectionTitle(title:'Pending'),
          ...pending.map((x)=>_taskTile(x,tasks.indexOf(x))),
          if(completed.isNotEmpty) ...[const SizedBox(height:20), const SectionTitle(title:'Completed'), ...completed.map((x)=>_taskTile(x,tasks.indexOf(x)))],
        ]),
    ));
  }
  Widget _taskTile(StudyTask task,int index)=>Card(color:const Color(0xFF162238),child:ListTile(
    leading: Checkbox(value:task.completed,activeColor:const Color(0xFFD4AF37),onChanged:(_){setState(()=>task.completed=!task.completed);save();}),
    title: Text(task.title,style:TextStyle(fontWeight:FontWeight.bold,decoration:task.completed?TextDecoration.lineThrough:null)),
    subtitle: Text('${task.subject.isEmpty?'General':task.subject} • ${task.priority}${task.dueDate.isEmpty?'':' • Due ${task.dueDate}'}'),
    trailing: IconButton(icon:const Icon(Icons.delete_outline,color:Colors.redAccent),onPressed:(){setState(()=>tasks.removeAt(index));save();}),
    onTap:()=>edit(task:task,index:index),
  ));
}

class TaskEditorScreen extends StatefulWidget {
  final StudyTask? task; final Future<void> Function(StudyTask) onSave;
  const TaskEditorScreen({super.key,this.task,required this.onSave});
  @override State<TaskEditorScreen> createState()=>_TaskEditorScreenState();
}
class _TaskEditorScreenState extends State<TaskEditorScreen>{
  late final TextEditingController title,description,subject,due; String priority='Medium';
  @override void initState(){super.initState(); final t=widget.task; title=TextEditingController(text:t?.title??'');description=TextEditingController(text:t?.description??'');subject=TextEditingController(text:t?.subject??'');due=TextEditingController(text:t?.dueDate??'');priority=t?.priority??'Medium';}
  @override void dispose(){title.dispose();description.dispose();subject.dispose();due.dispose();super.dispose();}
  Future<void> pickDate()async{final d=await showDatePicker(context:context,initialDate:DateTime.now(),firstDate:DateTime(2024),lastDate:DateTime(2100));if(d!=null)setState(()=>due.text='${d.day}/${d.month}/${d.year}');}
  Future<void> save()async{if(title.text.trim().isEmpty)return;await widget.onSave(StudyTask(title:title.text.trim(),description:description.text.trim(),subject:subject.text.trim(),priority:priority,dueDate:due.text.trim(),completed:widget.task?.completed??false));if(mounted)Navigator.pop(context);}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.task==null?'New Task':'Edit Task'),actions:[TextButton(onPressed:save,child:const Text('SAVE',style:TextStyle(color:Color(0xFFD4AF37),fontWeight:FontWeight.bold)))]),body:ListView(padding:const EdgeInsets.all(20),children:[
    TextField(controller:title,decoration:const InputDecoration(labelText:'Task title',border:OutlineInputBorder())),const SizedBox(height:16),
    TextField(controller:description,maxLines:4,decoration:const InputDecoration(labelText:'Description',border:OutlineInputBorder())),const SizedBox(height:16),
    TextField(controller:subject,decoration:const InputDecoration(labelText:'Subject',border:OutlineInputBorder())),const SizedBox(height:16),
    DropdownButtonFormField<String>(value:priority,decoration:const InputDecoration(labelText:'Priority',border:OutlineInputBorder()),items:const [DropdownMenuItem(value:'High',child:Text('High')),DropdownMenuItem(value:'Medium',child:Text('Medium')),DropdownMenuItem(value:'Low',child:Text('Low'))],onChanged:(v){if(v!=null)setState(()=>priority=v);}),const SizedBox(height:16),
    TextField(controller:due,readOnly:true,onTap:pickDate,decoration:const InputDecoration(labelText:'Due date',suffixIcon:Icon(Icons.calendar_today),border:OutlineInputBorder())),
  ]));
}

// =====================================================
// TIMETABLE
// =====================================================

class TimetableScreen extends StatefulWidget { const TimetableScreen({super.key}); @override State<TimetableScreen> createState()=>_TimetableScreenState(); }
class _TimetableScreenState extends State<TimetableScreen>{
  List<TimetableItem> items=[]; bool loading=true;
  final days=const['Monday','Tuesday','Wednesday','Thursday','Friday'];
  @override void initState(){super.initState();load();}
  Future<void> load()async{final v=await StorageService.loadTimetable();if(mounted)setState(()=>{items=v,loading=false});}
  Future<void> save()=>StorageService.saveTimetable(items);
  Future<void> edit({TimetableItem? item,int? index})async{await Navigator.push(context,MaterialPageRoute(builder:(_)=>TimetableEditorScreen(item:item,onSave:(x)async{setState((){if(item==null)items.add(x);else items[index!]=x;items.sort((a,b)=>a.startTime.compareTo(b.startTime));});await save();})));load();}
  @override Widget build(BuildContext context)=>SafeArea(child:Scaffold(floatingActionButton:FloatingActionButton(backgroundColor:const Color(0xFFD4AF37),foregroundColor:Colors.black,onPressed:()=>edit(),child:const Icon(Icons.add)),body:loading?const Center(child:CircularProgressIndicator()):ListView(padding:const EdgeInsets.all(20),children:[
    const _ScreenHeader(title:'Timetable',subtitle:'Plan your school week.'),
    if(items.isEmpty)const Padding(padding:EdgeInsets.only(top:80),child:EmptyState(icon:Icons.calendar_month,title:'Your timetable is empty',message:'Add your classes to build your weekly schedule.')),
    ...days.map((day){final list=items.where((x)=>x.day==day).toList();if(list.isEmpty)return const SizedBox();return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[SectionTitle(title:day),...list.map((x){final i=items.indexOf(x);return Card(color:const Color(0xFF162238),child:ListTile(leading:const CircleAvatar(backgroundColor:Color(0xFF253A5A),child:Icon(Icons.school_outlined,color:Color(0xFFD4AF37))),title:Text(x.subject,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text('${x.startTime} – ${x.endTime}${x.teacher.isEmpty?'':'\n${x.teacher}'}'),isThreeLine:x.teacher.isNotEmpty,onTap:()=>edit(item:x,index:i),trailing:IconButton(icon:const Icon(Icons.delete_outline,color:Colors.redAccent),onPressed:(){setState(()=>items.removeAt(i));save();})));}),const SizedBox(height:18)]);} ),
  ])));
}

class TimetableEditorScreen extends StatefulWidget{
  final TimetableItem? item; final Future<void> Function(TimetableItem) onSave;
  const TimetableEditorScreen({super.key,this.item,required this.onSave});
  @override State<TimetableEditorScreen> createState()=>_TimetableEditorScreenState();
}
class _TimetableEditorScreenState extends State<TimetableEditorScreen>{
  late final TextEditingController subject,teacher; String day='Monday'; TimeOfDay start=const TimeOfDay(hour:8,minute:0),end=const TimeOfDay(hour:9,minute:0);
  final days=const['Monday','Tuesday','Wednesday','Thursday','Friday'];
  @override void initState(){super.initState();subject=TextEditingController(text:widget.item?.subject??'');teacher=TextEditingController(text:widget.item?.teacher??'');day=widget.item?.day??'Monday';if(widget.item!=null){start=parse(widget.item!.startTime);end=parse(widget.item!.endTime);}}
  TimeOfDay parse(String s){try{final p=s.split(':');return TimeOfDay(hour:int.parse(p[0]),minute:int.parse(p[1]));}catch(_){return const TimeOfDay(hour:8,minute:0);}}
  String fmt(TimeOfDay t)=>'${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
  Future<void> pick(bool isStart)async{final v=await showTimePicker(context:context,initialTime:isStart?start:end);if(v!=null)setState(()=>isStart?start=v:end=v);}
  Future<void> save()async{if(subject.text.trim().isEmpty)return;await widget.onSave(TimetableItem(subject:subject.text.trim(),teacher:teacher.text.trim(),day:day,startTime:fmt(start),endTime:fmt(end)));if(mounted)Navigator.pop(context);}
  @override void dispose(){subject.dispose();teacher.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.item==null?'Add Class':'Edit Class'),actions:[TextButton(onPressed:save,child:const Text('SAVE',style:TextStyle(color:Color(0xFFD4AF37),fontWeight:FontWeight.bold)))]),body:ListView(padding:const EdgeInsets.all(20),children:[
    TextField(controller:subject,decoration:const InputDecoration(labelText:'Subject',border:OutlineInputBorder())),const SizedBox(height:16),
    TextField(controller:teacher,decoration:const InputDecoration(labelText:'Teacher / Tutor (optional)',border:OutlineInputBorder())),const SizedBox(height:16),
    DropdownButtonFormField<String>(value:day,decoration:const InputDecoration(labelText:'Day',border:OutlineInputBorder()),items:days.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v){if(v!=null)setState(()=>day=v);}),const SizedBox(height:16),
    ListTile(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12),side:const BorderSide(color:Color(0xFF41516B))),title:const Text('Start time'),subtitle:Text(fmt(start)),trailing:const Icon(Icons.access_time),onTap:()=>pick(true)),const SizedBox(height:12),
    ListTile(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12),side:const BorderSide(color:Color(0xFF41516B))),title:const Text('End time'),subtitle:Text(fmt(end)),trailing:const Icon(Icons.access_time),onTap:()=>pick(false)),
  ]));
}

// =====================================================
// GROUPS / PROFILE / ABOUT
// =====================================================

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(child:ListView(padding:const EdgeInsets.all(24),children:[
    const _ScreenHeader(title:'Learning Groups',subtitle:'Collaborate and learn together.'),
    const SizedBox(height:50),
    const EmptyState(icon:Icons.groups,title:'Groups are coming soon',message:'StudyFlow Groups will allow students, teachers and tutors to collaborate and share learning materials.'),
  ]));
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState()=>_ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen>{
  Future<Map<String,String>> load()async{final p=await SharedPreferences.getInstance();final u=FirebaseAuth.instance.currentUser;return {'name':u?.displayName??p.getString('profile_name')??'StudyFlow User','email':u?.email??'Offline mode','role':u==null?'Offline User':'StudyFlow Member'};}
  @override Widget build(BuildContext context)=>SafeArea(child:FutureBuilder<Map<String,String>>(future:load(),builder:(_,s){final d=s.data??{'name':'StudyFlow User','email':'Loading...','role':'StudyFlow Member'};return ListView(padding:const EdgeInsets.all(24),children:[
    const SizedBox(height:20),const CircleAvatar(radius:55,backgroundColor:Color(0xFFD4AF37),child:Icon(Icons.person,size:65,color:Color(0xFF0B1220))),const SizedBox(height:20),
    Text(d['name']!,textAlign:TextAlign.center,style:const TextStyle(fontSize:25,fontWeight:FontWeight.bold)),const SizedBox(height:5),
    Text(d['email']!,textAlign:TextAlign.center,style:const TextStyle(color:Color(0xFFE5E7EB))),const SizedBox(height:5),
    Text(d['role']!,textAlign:TextAlign.center,style:const TextStyle(color:Color(0xFFD4AF37))),const SizedBox(height:35),
    ListTile(leading:const Icon(Icons.info_outline),title:const Text('About StudyFlow'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AboutScreen()))),
    ListTile(leading:const Icon(Icons.wifi),title:const Text('Connection status'),subtitle:const ConnectionStatus()),
    ListTile(leading:const Icon(Icons.logout),title:const Text('Logout'),onTap:()async{try{await FirebaseAuth.instance.signOut();}catch(_){}if(context.mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const AuthChoiceScreen()),(_)=>false);}),
  ]);} ));
}

class ConnectionStatus extends StatelessWidget {
  const ConnectionStatus({super.key});
  @override Widget build(BuildContext context)=>StreamBuilder<List<ConnectivityResult>>(stream:Connectivity().onConnectivityChanged,builder:(_,s){final online=(s.data??[]).any((x)=>x!=ConnectivityResult.none);return Text(online?'Internet connection available':'Offline mode',style:TextStyle(color:online?Colors.greenAccent:Colors.orangeAccent));});
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('About StudyFlow')),body:ListView(padding:const EdgeInsets.all(24),children:[
    const SizedBox(height:30),const Icon(Icons.school_rounded,size:90,color:Color(0xFFD4AF37)),const SizedBox(height:20),
    const Text('STUDYFLOW',textAlign:TextAlign.center,style:TextStyle(fontSize:32,fontWeight:FontWeight.bold)),const SizedBox(height:8),
    const Text('Your School Life, Organized.',textAlign:TextAlign.center,style:TextStyle(color:Color(0xFFD4AF37),fontSize:17)),const SizedBox(height:35),
    const InfoCard(icon:Icons.business_rounded,title:'Created by',value:'Cypher Digital Labs'),const SizedBox(height:14),
    const InfoCard(icon:Icons.design_services_rounded,title:'Designed by',value:'Papy'),const SizedBox(height:14),
    const InfoCard(icon:Icons.info_outline,title:'Version',value:'StudyFlow 3.0'),const SizedBox(height:40),
    const Text('StudyFlow helps students keep their notes, tasks and school schedules organized in one beautiful place. Notes, tasks and timetables remain available offline.',textAlign:TextAlign.center,style:TextStyle(color:Color(0xFFE5E7EB),height:1.6)),
  ]));
}

class InfoCard extends StatelessWidget {
  final IconData icon; final String title,value;
  const InfoCard({super.key,required this.icon,required this.title,required this.value});
  @override Widget build(BuildContext context)=>Card(color:const Color(0xFF162238),child:ListTile(leading:Icon(icon,color:const Color(0xFFD4AF37)),title:Text(title,style:const TextStyle(color:Color(0xFFE5E7EB))),subtitle:Text(value,style:const TextStyle(fontSize:17,fontWeight:FontWeight.bold))));
}

// =====================================================
// REUSABLE
// =====================================================

class _ScreenHeader extends StatelessWidget {
  final String title, subtitle;
  const _ScreenHeader({required this.title,required this.subtitle});
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(title,style:const TextStyle(fontSize:32,fontWeight:FontWeight.bold)),const SizedBox(height:5),Text(subtitle,style:const TextStyle(color:Color(0xFFD4AF37))),
  ]));
}

class EmptyState extends StatelessWidget {
  final IconData icon; final String title,message;
  const EmptyState({super.key,required this.icon,required this.title,required this.message});
  @override Widget build(BuildContext context)=>Center(child:Padding(padding:const EdgeInsets.all(30),child:Column(mainAxisSize:MainAxisSize.min,children:[
    Icon(icon,size:80,color:const Color(0xFFD4AF37)),const SizedBox(height:20),
    Text(title,textAlign:TextAlign.center,style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const SizedBox(height:10),
    Text(message,textAlign:TextAlign.center,style:const TextStyle(color:Color(0xFFE5E7EB),height:1.5)),
  ])));
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key,required this.title});
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:10),child:Text(title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)));
}

String formatDate(DateTime date) {
  const months=['January','February','March','April','May','June','July','August','September','October','November','December'];
  return '${date.day} ${months[date.month-1]} ${date.year}';
}
