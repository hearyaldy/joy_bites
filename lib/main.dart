import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/entry_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/mood_tracker_screen.dart';
import 'screens/global_feed_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/constants.dart';

// Global theme notifier for dynamic theme switching.
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    print("Supabase initialized successfully.");
  } catch (e) {
    print("Failed to initialize Supabase: $e");
    runApp(ErrorScreen(errorMessage: "Failed to initialize Supabase: $e"));
    return;
  }

  final session = Supabase.instance.client.auth.currentSession;
  runApp(MyApp(
    home: session != null ? const MainScreen() : const AuthScreen(),
  ));
}

class MyApp extends StatelessWidget {
  final Widget home;
  const MyApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'JoyBites',
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.teal,
            fontFamily: 'Roboto',
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.teal,
            fontFamily: 'Roboto',
            useMaterial3: true,
          ),
          themeMode: themeMode,
          home: home,
          routes: {
            '/profile': (context) => const ProfileScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // List of pages – ensure these pages do NOT include their own AppBar.
  final List<Widget> _pages = const [
    EntryScreen(),
    MoodTrackerScreen(),
    GlobalFeedScreen(),
    ProfileScreen(),
  ];

  // Titles for the pages.
  final List<String> _pageTitles = [
    "Entry",
    "Mood Tracker",
    "Global Feed",
    "Profile",
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  // Custom header with a gradient background.
  // Top row: Drawer burger icon and "JoyBites" title on the left; small profile avatar on the right.
  // Second row: current page title on left and welcome message on right.
  Widget _buildHeader() {
    final user = Supabase.instance.client.auth.currentUser;
    final String displayName = user?.userMetadata?['full_name'] as String? ?? "Guest";
    final String pageTitle = _pageTitles[_selectedIndex];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top row: Drawer icon and main title on left; small avatar on right.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "JoyBites",
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundImage: user?.userMetadata?['avatar_url'] != null
                      ? NetworkImage(user!.userMetadata!['avatar_url'] as String)
                      : null,
                  backgroundColor: Colors.white,
                  child: user?.userMetadata?['avatar_url'] == null
                      ? const Icon(Icons.person, color: Colors.teal, size: 18)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Second row: current page title on left, greeting on right.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pageTitle,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.white70),
                ),
                Text(
                  "Welcome, $displayName",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] as String? ?? 'Guest User',
              ),
              accountEmail: Text(
                Supabase.instance.client.auth.currentUser?.email ?? 'No Email',
              ),
              currentAccountPicture: CircleAvatar(
                backgroundImage: Supabase.instance.client.auth.currentUser?.userMetadata?['avatar_url'] != null
                    ? NetworkImage(Supabase.instance.client.auth.currentUser!.userMetadata!['avatar_url'] as String)
                    : null,
                child: Supabase.instance.client.auth.currentUser?.userMetadata?['avatar_url'] == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              decoration: BoxDecoration(
                color: Colors.teal,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () async {
                bool? updated = await Navigator.pushNamed(context, '/profile') as bool?;
                if (updated == true) {
                  setState(() {}); // Refresh drawer when profile is updated.
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.edit_outlined), label: 'Entry'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Mood'),
          NavigationDestination(icon: Icon(Icons.public_outlined), label: 'Global'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String errorMessage;
  const ErrorScreen({super.key, required this.errorMessage});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              errorMessage,
              style: const TextStyle(fontSize: 18, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
