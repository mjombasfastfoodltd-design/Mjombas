import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:mjombas/app_state.dart';
import 'package:mjombas/screens/screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (_) {
    // The app can still show the local menu if authentication fails.
  }

  runApp(const MjombasApp());
}

class MjombasApp extends StatelessWidget {
  const MjombasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MJOMBAS FAST FOOD',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: orange),
        scaffoldBackgroundColor: cream,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: dark,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: orange,
              width: 1.5,
            ),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFFFE0B2),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    HomeScreen(),
    FavoritesScreen(),
    CartScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // IMPORTANT:
    // Start the menu loader immediately.
    // Do NOT wait for SharedPreferences/profile/cart loading first.
    appState.loadFoods();

    // Load saved profile, cart, favorites, notifications, etc.
    appState.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final cartCount = appState.count;

        return Scaffold(
          body: IndexedStack(
            index: selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: appState.favorites.isNotEmpty,
                  child: const Icon(Icons.favorite_border),
                ),
                selectedIcon: const Icon(Icons.favorite),
                label: 'Favorites',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: cartCount > 0,
                  label: Text('$cartCount'),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                  ),
                ),
                selectedIcon: Badge(
                  isLabelVisible: cartCount > 0,
                  label: Text('$cartCount'),
                  child: const Icon(
                    Icons.shopping_bag,
                  ),
                ),
                label: 'Cart',
              ),
              const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Orders',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}