import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      debugShowCheckedModeBanner: false,
      title: 'StudyFlow',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1220),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F8CFF),
          brightness: Brightness.dark,
        ),
      ),
      home: const AppLoader(),
    );
  }
}

// =====================================================
// APP LOADER
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
    checkOnboarding();
  }

  Future<void> checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    onboardingCompleted =
        prefs.getBool('studyflow_onboarding_completed') ?? false;

    if (!mounted) return;

    setState(() {
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

    if (!onboardingCompleted) {
      return WelcomeScreen(
        onFinished: () {
          setState(() {
            onboardingCompleted = true;
          });
        },
      );
    }

    return const MainNavigation();
  }
}

// =====================================================
// WELCOME / ONBOARDING
// =====================================================

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const WelcomeScreen({
    super.key,
    required this.onFinished,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController controller = PageController();
  int currentPage = 0;

  final List<_WelcomePageData> pages = const [
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
      description:
          'Created by Novaro Digital Labs\nDesigned by Papy',
    ),
  ];

  Future<void> finishWelcome() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      'studyflow_onboarding_completed',
      true,
    );

    widget.onFinished();
  }

  void nextPage() {
    if (currentPage == pages.length - 1) {
      finishWelcome();
      return;
    }

    controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = pages[currentPage];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: finishWelcome,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: controller,
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
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
                            child: Icon(
                              item.icon,
                              size: 76,
                              color: const Color(0xFFD4AF37),
                            ),
                          ),
                          const SizedBox(height: 45),
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            item.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              height: 1.6,
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
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
                  (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: currentPage == index
                            ? const Color(0xFFD4AF37)
                            : const Color(0xFF41516B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: nextPage,
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
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
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

  const _WelcomePageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

// =====================================================
// MODELS
// =====================================================

class Note {
  String title;
  String content;
  DateTime updatedAt;

  Note({
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      updatedAt:
          DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class StudyTask {
  String title;
  String description;
  String subject;
  String priority;
  String dueDate;
  bool completed;

  StudyTask({
    required this.title,
    required this.description,
    required this.subject,
    required this.priority,
    required this.dueDate,
    required this.completed,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'subject': subject,
      'priority': priority,
      'dueDate': dueDate,
      'completed': completed,
    };
  }

  factory StudyTask.fromJson(Map<String, dynamic> json) {
    return StudyTask(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      subject: json['subject'] ?? '',
      priority: json['priority'] ?? 'Medium',
      dueDate: json['dueDate'] ?? '',
      completed: json['completed'] ?? false,
    );
  }
}

class TimetableItem {
  String subject;
  String teacher;
  String day;
  String startTime;
  String endTime;

  TimetableItem({
    required this.subject,
    required this.teacher,
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'teacher': teacher,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  factory TimetableItem.fromJson(Map<String, dynamic> json) {
    return TimetableItem(
      subject: json['subject'] ?? '',
      teacher: json['teacher'] ?? '',
      day: json['day'] ?? 'Monday',
      startTime: json['startTime'] ?? '08:00',
      endTime: json['endTime'] ?? '09:00',
    );
  }
}

// =====================================================
// STORAGE SERVICE
// =====================================================

class StorageService {
  static const String notesKey = 'studyflow_notes';
  static const String tasksKey = 'studyflow_tasks';
  static const String timetableKey = 'studyflow_timetable';

  static Future<List<Note>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(notesKey);

    if (data == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);

      return decoded
          .map(
            (item) => Note.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      notesKey,
      jsonEncode(
        notes.map((note) => note.toJson()).toList(),
      ),
    );
  }

  static Future<List<StudyTask>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(tasksKey);

    if (data == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);

      return decoded
          .map(
            (item) => StudyTask.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTasks(List<StudyTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      tasksKey,
      jsonEncode(
        tasks.map((task) => task.toJson()).toList(),
      ),
    );
  }

  static Future<List<TimetableItem>> loadTimetable() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(timetableKey);

    if (data == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);

      return decoded
          .map(
            (item) => TimetableItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTimetable(
    List<TimetableItem> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      timetableKey,
      jsonEncode(
        items.map((item) => item.toJson()).toList(),
      ),
    );
  }
}

// =====================================================
// MAIN NAVIGATION
// =====================================================

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;

  void changePage(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  Widget currentPage() {
    switch (selectedIndex) {
      case 0:
        return HomeScreen(
          onNavigate: changePage,
        );
      case 1:
        return const NotesScreen();
      case 2:
        return const TasksScreen();
      case 3:
        return const TimetableScreen();
      case 4:
        return const AboutScreen();
      default:
        return const NotesScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: changePage,
        backgroundColor: const Color(0xFF121D2F),
        indicatorColor: const Color(0xFFD4AF37),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'About',
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
  final ValueChanged<int> onNavigate;

  const HomeScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int noteCount = 0;
  int pendingTaskCount = 0;
  int todayClassCount = 0;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final notes = await StorageService.loadNotes();
    final tasks = await StorageService.loadTasks();
    final timetable = await StorageService.loadTimetable();

    final today = weekdayName(DateTime.now().weekday);

    if (!mounted) return;

    setState(() {
      noteCount = notes.length;
      pendingTaskCount =
          tasks.where((task) => !task.completed).length;
      todayClassCount =
          timetable.where((item) => item.day == today).length;
    });
  }

  String weekdayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final greeting = greetingText();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              greeting,
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'STUDYFLOW',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your school life, organized.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFE5E7EB),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    icon: Icons.menu_book_rounded,
                    title: 'Notes',
                    value: '$noteCount',
                    subtitle: 'Saved notes',
                    onTap: () => widget.onNavigate(1),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: DashboardCard(
                    icon: Icons.checklist_rounded,
                    title: 'Tasks',
                    value: '$pendingTaskCount',
                    subtitle: 'Pending',
                    onTap: () => widget.onNavigate(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DashboardCard(
              icon: Icons.calendar_month_rounded,
              title: 'Today',
              value: '$todayClassCount classes',
              subtitle: 'View your schedule',
              wide: true,
              onTap: () => widget.onNavigate(3),
            ),
            const SizedBox(height: 30),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              tileColor: const Color(0xFF162238),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF253A5A),
                child: Icon(
                  Icons.note_add_outlined,
                  color: Color(0xFFD4AF37),
                ),
              ),
              title: const Text('Create a new note'),
              subtitle: const Text(
                'Capture an idea or study material',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => widget.onNavigate(1),
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              tileColor: const Color(0xFF162238),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF253A5A),
                child: Icon(
                  Icons.add_task,
                  color: Color(0xFFD4AF37),
                ),
              ),
              title: const Text('Add a task'),
              subtitle: const Text(
                'Keep track of homework and assignments',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => widget.onNavigate(2),
            ),
          ],
        ),
      ),
    );
  }

  String greetingText() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good morning 👋';
    if (hour < 18) return 'Good afternoon 👋';

    return 'Good evening 👋';
  }
}

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback onTap;
  final bool wide;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF162238),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF273650),
          ),
        ),
        child: wide
            ? Row(
                children: [
                  Icon(
                    icon,
                    size: 42,
                    color: const Color(0xFFD4AF37),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    color: const Color(0xFFD4AF37),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE5E7EB),
                    ),
                  ),
                ],
              ),
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
  List<Note> notes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    final loadedNotes = await StorageService.loadNotes();

    loadedNotes.sort(
      (a, b) => b.updatedAt.compareTo(a.updatedAt),
    );

    if (!mounted) return;

    setState(() {
      notes = loadedNotes;
      loading = false;
    });
  }

  Future<void> deleteNote(int index) async {
    final note = notes[index];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Note?'),
          content: Text(
            'Delete "${note.title}" permanently?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      notes.removeAt(index);
    });

    await StorageService.saveNotes(notes);
  }

  Future<void> openEditor({
    Note? note,
    int? index,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          note: note,
          onSave: (savedNote) async {
            setState(() {
              if (note == null) {
                notes.add(savedNote);
              } else {
                notes[index!] = savedNote;
              }

              notes.sort(
                (a, b) => b.updatedAt.compareTo(a.updatedAt),
              );
            });

            await StorageService.saveNotes(notes);
          },
        ),
      ),
    );

    await loadNotes();
  }

  String preview(String text) {
    if (text.trim().isEmpty) {
      return 'No additional text';
    }

    return text.trim();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFD4AF37),
          foregroundColor: Colors.black,
          onPressed: () => openEditor(),
          child: const Icon(Icons.add),
        ),
        body: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : notes.isEmpty
                ? const EmptyState(
                    icon: Icons.menu_book_rounded,
                    title: 'No notes yet',
                    message:
                        'Create your first note and keep your study ideas organized.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: notes.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const Padding(
                          padding: EdgeInsets.only(
                            bottom: 20,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Notes',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Keep your study materials organized.',
                                style: TextStyle(
                                  color:
                                      Color(0xFFD4AF37),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final noteIndex = index - 1;
                      final note = notes[noteIndex];

                      return Card(
                        color: const Color(0xFF162238),
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          leading: const CircleAvatar(
                            backgroundColor:
                                Color(0xFF253A5A),
                            child: Icon(
                              Icons.description_outlined,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                          title: Text(
                            note.title.isEmpty
                                ? 'Untitled Note'
                                : note.title,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            preview(note.content),
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () =>
                                deleteNote(noteIndex),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    NoteViewerScreen(
                                  note: note,
                                  onEdit: () async {
                                    Navigator.pop(
                                      context,
                                    );

                                    await openEditor(
                                      note: note,
                                      index: noteIndex,
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class NoteViewerScreen extends StatelessWidget {
  final Note note;
  final Future<void> Function() onEdit;

  const NoteViewerScreen({
    super.key,
    required this.note,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note'),
        actions: [
          IconButton(
            onPressed: () async {
              await onEdit();
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                note.title.isEmpty
                    ? 'Untitled Note'
                    : note.title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated ${formatDate(note.updatedAt)}',
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                ),
              ),
              const SizedBox(height: 25),
              const Divider(),
              const SizedBox(height: 20),
              SelectableText(
                note.content.isEmpty
                    ? 'No content in this note.'
                    : note.content,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final Future<void> Function(Note note) onSave;

  const NoteEditorScreen({
    super.key,
    this.note,
    required this.onSave,
  });

  @override
  State<NoteEditorScreen> createState() =>
      _NoteEditorScreenState();
}

class _NoteEditorScreenState
    extends State<NoteEditorScreen> {
  late TextEditingController titleController;
  late TextEditingController contentController;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.note?.title ?? '',
    );

    contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Future<void> saveNote() async {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      return;
    }

    final note = Note(
      title: title.isEmpty
          ? 'Untitled Note'
          : title,
      content: content,
      updatedAt: DateTime.now(),
    );

    await widget.onSave(note);

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.note == null
              ? 'New Note'
              : 'Edit Note',
        ),
        actions: [
          TextButton(
            onPressed: saveNote,
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                ),
              ),
              const Divider(),
              Expanded(
                child: TextField(
                  controller: contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical:
                      TextAlignVertical.top,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.6,
                  ),
                  decoration: const InputDecoration(
                    hintText:
                        'Start writing your note...',
                    border: InputBorder.none,
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

// =====================================================
// TASKS
// =====================================================

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() =>
      _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<StudyTask> tasks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final loaded = await StorageService.loadTasks();

    if (!mounted) return;

    setState(() {
      tasks = loaded;
      loading = false;
    });
  }

  Future<void> saveTasks() async {
    await StorageService.saveTasks(tasks);
  }

  Future<void> openEditor({
    StudyTask? task,
    int? index,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TaskEditorScreen(
          task: task,
          onSave: (savedTask) async {
            setState(() {
              if (task == null) {
                tasks.add(savedTask);
              } else {
                tasks[index!] = savedTask;
              }
            });

            await saveTasks();
          },
        ),
      ),
    );

    await loadTasks();
  }

  Future<void> deleteTask(int index) async {
    setState(() {
      tasks.removeAt(index);
    });

    await saveTasks();
  }

  Future<void> toggleTask(int index) async {
    setState(() {
      tasks[index].completed =
          !tasks[index].completed;
    });

    await saveTasks();
  }

  List<StudyTask> get pendingTasks =>
      tasks.where((task) => !task.completed).toList();

  List<StudyTask> get completedTasks =>
      tasks.where((task) => task.completed).toList();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFD4AF37),
          foregroundColor: Colors.black,
          onPressed: () => openEditor(),
          child: const Icon(Icons.add),
        ),
        body: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : tasks.isEmpty
                ? const EmptyState(
                    icon: Icons.checklist_rounded,
                    title: 'No tasks yet',
                    message:
                        'Add homework, assignments and study goals here.',
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'My Tasks',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Stay on top of your work.',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(height: 25),
                      if (pendingTasks.isNotEmpty)
                        const SectionTitle(
                          title: 'Pending',
                        ),
                      ...pendingTasks.map(
                        (task) {
                          final index =
                              tasks.indexOf(task);

                          return TaskTile(
                            task: task,
                            onToggle: () =>
                                toggleTask(index),
                            onEdit: () =>
                                openEditor(
                              task: task,
                              index: index,
                            ),
                            onDelete: () =>
                                deleteTask(index),
                          );
                        },
                      ),
                      if (completedTasks.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const SectionTitle(
                          title: 'Completed',
                        ),
                        ...completedTasks.map(
                          (task) {
                            final index =
                                tasks.indexOf(task);

                            return TaskTile(
                              task: task,
                              onToggle: () =>
                                  toggleTask(index),
                              onEdit: () =>
                                  openEditor(
                                task: task,
                                index: index,
                              ),
                              onDelete: () =>
                                  deleteTask(index),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class TaskTile extends StatelessWidget {
  final StudyTask task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  Color priorityColor() {
    switch (task.priority) {
      case 'High':
        return Colors.redAccent;
      case 'Low':
        return Colors.greenAccent;
      default:
        return const Color(0xFFD4AF37);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF162238),
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Checkbox(
                value: task.completed,
                activeColor:
                    const Color(0xFFD4AF37),
                onChanged: (_) => onToggle(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                          decoration: task.completed
                              ? TextDecoration
                                  .lineThrough
                              : null,
                        ),
                      ),
                      if (task.description
                          .isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          TaskChip(
                            label: task.subject.isEmpty
                                ? 'General'
                                : task.subject,
                            color:
                                const Color(0xFF4F8CFF),
                          ),
                          TaskChip(
                            label: task.priority,
                            color: priorityColor(),
                          ),
                          if (task.dueDate.isNotEmpty)
                            TaskChip(
                              label:
                                  'Due ${task.dueDate}',
                              color:
                                  const Color(0xFFE5E7EB),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskChip extends StatelessWidget {
  final String label;
  final Color color;

  const TaskChip({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.15),
        border: Border.all(
          color: color.withOpacity(0.45),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
        ),
      ),
    );
  }
}

class TaskEditorScreen extends StatefulWidget {
  final StudyTask? task;
  final Future<void> Function(
    StudyTask task,
  ) onSave;

  const TaskEditorScreen({
    super.key,
    this.task,
    required this.onSave,
  });

  @override
  State<TaskEditorScreen> createState() =>
      _TaskEditorScreenState();
}

class _TaskEditorScreenState
    extends State<TaskEditorScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController subjectController;
  late TextEditingController dueDateController;

  String priority = 'Medium';

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.task?.title ?? '',
    );

    descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );

    subjectController = TextEditingController(
      text: widget.task?.subject ?? '',
    );

    dueDateController = TextEditingController(
      text: widget.task?.dueDate ?? '',
    );

    priority =
        widget.task?.priority ?? 'Medium';
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    subjectController.dispose();
    dueDateController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (selected == null) return;

    setState(() {
      dueDateController.text =
          '${selected.day}/${selected.month}/${selected.year}';
    });
  }

  Future<void> saveTask() async {
    final title = titleController.text.trim();

    if (title.isEmpty) return;

    final task = StudyTask(
      title: title,
      description:
          descriptionController.text.trim(),
      subject: subjectController.text.trim(),
      priority: priority,
      dueDate: dueDateController.text.trim(),
      completed:
          widget.task?.completed ?? false,
    );

    await widget.onSave(task);

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.task == null
              ? 'New Task'
              : 'Edit Task',
        ),
        actions: [
          TextButton(
            onPressed: saveTask,
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Task title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'High',
                  child: Text('High'),
                ),
                DropdownMenuItem(
                  value: 'Medium',
                  child: Text('Medium'),
                ),
                DropdownMenuItem(
                  value: 'Low',
                  child: Text('Low'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  priority = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dueDateController,
              readOnly: true,
              onTap: pickDate,
              decoration: const InputDecoration(
                labelText: 'Due date',
                suffixIcon:
                    Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
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

class _TimetableScreenState
    extends State<TimetableScreen> {
  List<TimetableItem> items = [];
  bool loading = true;

  final days = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  @override
  void initState() {
    super.initState();
    loadTimetable();
  }

  Future<void> loadTimetable() async {
    final loaded =
        await StorageService.loadTimetable();

    if (!mounted) return;

    setState(() {
      items = loaded;
      loading = false;
    });
  }

  Future<void> saveTimetable() async {
    await StorageService.saveTimetable(items);
  }

  Future<void> openEditor({
    TimetableItem? item,
    int? index,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TimetableEditorScreen(
          item: item,
          onSave: (savedItem) async {
            setState(() {
              if (item == null) {
                items.add(savedItem);
              } else {
                items[index!] = savedItem;
              }

              items.sort(
                (a, b) =>
                    a.startTime.compareTo(
                  b.startTime,
                ),
              );
            });

            await saveTimetable();
          },
        ),
      ),
    );

    await loadTimetable();
  }

  Future<void> deleteItem(int index) async {
    setState(() {
      items.removeAt(index);
    });

    await saveTimetable();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFD4AF37),
          foregroundColor: Colors.black,
          onPressed: () => openEditor(),
          child: const Icon(Icons.add),
        ),
        body: loading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Timetable',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Plan your school week.',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  const SizedBox(height: 25),
                  if (items.isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.only(top: 80),
                      child: EmptyState(
                        icon:
                            Icons.calendar_month,
                        title:
                            'Your timetable is empty',
                        message:
                            'Add your classes to build your weekly schedule.',
                      ),
                    )
                  else
                    ...days.map(
                      (day) {
                        final dayItems = items
                            .where(
                              (item) =>
                                  item.day == day,
                            )
                            .toList();

                        if (dayItems.isEmpty) {
                          return const SizedBox();
                        }

                        return Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            SectionTitle(title: day),
                            ...dayItems.map(
                              (item) {
                                final index =
                                    items.indexOf(item);

                                return Card(
                                  color:
                                      const Color(
                                    0xFF162238,
                                  ),
                                  child: ListTile(
                                    leading:
                                        const CircleAvatar(
                                      backgroundColor:
                                          Color(
                                        0xFF253A5A,
                                      ),
                                      child: Icon(
                                        Icons
                                            .school_outlined,
                                        color: Color(
                                          0xFFD4AF37,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      item.subject,
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${item.startTime} – ${item.endTime}'
                                      '${item.teacher.isEmpty ? '' : '\n${item.teacher}'}',
                                    ),
                                    isThreeLine:
                                        item.teacher
                                            .isNotEmpty,
                                    onTap: () =>
                                        openEditor(
                                      item: item,
                                      index: index,
                                    ),
                                    trailing:
                                        IconButton(
                                      icon:
                                          const Icon(
                                        Icons
                                            .delete_outline,
                                        color: Colors
                                            .redAccent,
                                      ),
                                      onPressed: () =>
                                          deleteItem(
                                        index,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                          ],
                        );
                      },
                    ),
                ],
              ),
      ),
    );
  }
}

class TimetableEditorScreen
    extends StatefulWidget {
  final TimetableItem? item;
  final Future<void> Function(
    TimetableItem item,
  ) onSave;

  const TimetableEditorScreen({
    super.key,
    this.item,
    required this.onSave,
  });

  @override
  State<TimetableEditorScreen>
      createState() =>
          _TimetableEditorScreenState();
}

class _TimetableEditorScreenState
    extends State<TimetableEditorScreen> {
  late TextEditingController subjectController;
  late TextEditingController teacherController;

  String day = 'Monday';
  TimeOfDay startTime =
      const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime =
      const TimeOfDay(hour: 9, minute: 0);

  final days = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  @override
  void initState() {
    super.initState();

    subjectController = TextEditingController(
      text: widget.item?.subject ?? '',
    );

    teacherController = TextEditingController(
      text: widget.item?.teacher ?? '',
    );

    day = widget.item?.day ?? 'Monday';

    if (widget.item != null) {
      startTime =
          parseTime(widget.item!.startTime);
      endTime =
          parseTime(widget.item!.endTime);
    }
  }

  TimeOfDay parseTime(String time) {
    try {
      final parts = time.split(':');

      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (_) {
      return const TimeOfDay(
        hour: 8,
        minute: 0,
      );
    }
  }

  String formatTime(TimeOfDay time) {
    final hour =
        time.hour.toString().padLeft(2, '0');
    final minute =
        time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<void> pickStartTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: startTime,
    );

    if (selected == null) return;

    setState(() {
      startTime = selected;
    });
  }

  Future<void> pickEndTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: endTime,
    );

    if (selected == null) return;

    setState(() {
      endTime = selected;
    });
  }

  Future<void> saveItem() async {
    final subject =
        subjectController.text.trim();

    if (subject.isEmpty) return;

    final item = TimetableItem(
      subject: subject,
      teacher:
          teacherController.text.trim(),
      day: day,
      startTime:
          formatTime(startTime),
      endTime: formatTime(endTime),
    );

    await widget.onSave(item);

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  void dispose() {
    subjectController.dispose();
    teacherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null
              ? 'Add Class'
              : 'Edit Class',
        ),
        actions: [
          TextButton(
            onPressed: saveItem,
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: teacherController,
              decoration: const InputDecoration(
                labelText:
                    'Teacher / Tutor (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: day,
              decoration: const InputDecoration(
                labelText: 'Day',
                border: OutlineInputBorder(),
              ),
              items: days
                  .map(
                    (day) =>
                        DropdownMenuItem(
                      value: day,
                      child: Text(day),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  day = value;
                });
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12),
                side: const BorderSide(
                  color: Color(0xFF41516B),
                ),
              ),
              title:
                  const Text('Start time'),
              subtitle:
                  Text(formatTime(startTime)),
              trailing: const Icon(
                Icons.access_time,
              ),
              onTap: pickStartTime,
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12),
                side: const BorderSide(
                  color: Color(0xFF41516B),
                ),
              ),
              title: const Text('End time'),
              subtitle:
                  Text(formatTime(endTime)),
              trailing: const Icon(
                Icons.access_time,
              ),
              onTap: pickEndTime,
            ),
          ],
        ),
      ),
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
    return SafeArea(
      child: ListView(
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
          InfoCard(
            icon: Icons.business_rounded,
            title: 'Created by',
            value: 'Novaro Digital Labs',
          ),
          const SizedBox(height: 14),
          InfoCard(
            icon: Icons.design_services_rounded,
            title: 'Designed by',
            value: 'Papy',
          ),
          const SizedBox(height: 14),
          InfoCard(
            icon: Icons.info_outline,
            title: 'Version',
            value: 'StudyFlow 2.0',
          ),
          const SizedBox(height: 40),
          const Text(
            'StudyFlow helps students keep their notes, tasks and school schedules organized in one simple place.',
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
      color: const Color(0xFF162238),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFFD4AF37),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFE5E7EB),
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// =====================================================
// REUSABLE COMPONENTS
// =====================================================

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: const Color(0xFFD4AF37),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFE5E7EB),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// =====================================================
// DATE FORMAT
// =====================================================

String formatDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
