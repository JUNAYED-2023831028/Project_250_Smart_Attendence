import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'prefs_service.dart';
import 'login_screen.dart';
import 'admin_dashboard.dart';
import 'teacher_dashboard.dart';
import 'student_dashboard.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  Widget initialScreen = const LoginScreen();
  bool isLoggedIn = await PrefsService.isLoggedIn();

  if (isLoggedIn) {
    String role = await PrefsService.getUserRole();
    switch (role) {
      case 'admin':
        initialScreen = const AdminDashboard();
        break;
      case 'teacher':
        initialScreen = const TeacherDashboard();
        break;
      case 'student':
        initialScreen = const StudentDashboard();
        break;
      default:
        initialScreen = const LoginScreen();
    }
  }

  runApp(QrAttendanceApp(startScreen: initialScreen));
}

class QrAttendanceApp extends StatelessWidget {
  final Widget startScreen;
  const QrAttendanceApp({Key? key, required this.startScreen})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure QR Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      home: startScreen,
    );
  }
}
