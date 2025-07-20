import 'package:MovieHub/screens/main_screen.dart';
import 'package:MovieHub/screens/onboarding/onboarding_screen.dart';
import 'package:MovieHub/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool shallShowHomeScreen = prefs.getBool('onboarding_completed') ?? false;
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(onboarding_completed: shallShowHomeScreen),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.onboarding_completed});
  
  final bool onboarding_completed;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Movie Review App',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeProvider.lightTheme,
          darkTheme: ThemeProvider.darkTheme,
          home: onboarding_completed ? const AuthGate() : const OnboardingScreen(),
        );
      },
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
