import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:movie_review_app/screens/main_screen.dart';
import 'package:movie_review_app/screens/onboarding/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool shallShowHomeScreen = prefs.getBool('onboarding_completed') ?? false;
  await Firebase.initializeApp();
  runApp(MyApp(onboarding_completed: shallShowHomeScreen,));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.onboarding_completed});
  
  final bool onboarding_completed;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Review App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: Colors.grey[600],
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      ),
      home: onboarding_completed ? const AuthGate() : const OnboardingScreen(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    // Always show the main screen - authentication only required for specific actions
    return const MainScreen();
  }
}
