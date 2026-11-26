import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if ([
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const SholatKuApp());
}

class SholatKuApp extends StatefulWidget {
  const SholatKuApp({super.key});

  @override
  State<SholatKuApp> createState() => _SholatKuAppState();
}

class _SholatKuAppState extends State<SholatKuApp> {
  bool isDarkMode = false;
  bool isLoggedIn = false;
  bool isCheckingSession = true;
  String userName = 'Pengguna';

  @override
  void initState() {
    super.initState();
    loadSession();
  }

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      isDarkMode = prefs.getBool('darkTheme') ?? false;
      isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      userName = prefs.getString('userName') ?? 'Pengguna';
      isCheckingSession = false;
    });
  }

  void updateTheme(bool value) {
    setState(() => isDarkMode = value);
  }

  void loginSuccess(String name) {
    setState(() {
      userName = name;
      isLoggedIn = true;
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (!mounted) return;
    setState(() => isLoggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SholatKu',
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF167D55),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F8F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF167D55),
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF167D55),
          brightness: Brightness.dark,
        ),
      ),
      home: isCheckingSession
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: isLoggedIn
                  ? HomeScreen(
                      key: const ValueKey('home'),
                      isDarkMode: isDarkMode,
                      onThemeChanged: updateTheme,
                      onLogout: logout,
                    )
                  : LoginScreen(
                      key: const ValueKey('login'),
                      onLoginSuccess: loginSuccess,
                    ),
            ),
    );
  }
}
