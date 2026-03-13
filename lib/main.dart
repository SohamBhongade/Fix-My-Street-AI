import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart'; // Added for database
import 'screens/report_screen.dart';

// Global cameras list for the whole app to use
List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase so your 'Confirm' button works
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase not configured yet: $e");
    // App will still run, but Firestore saves will fail until config is added
  }

  // 2. Fetch the available cameras (Front/Back)
  cameras = await availableCameras();

  runApp(const FixMyStreetApp());
}

class FixMyStreetApp extends StatelessWidget {
  const FixMyStreetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fix My Street AI',
      debugShowCheckedModeBanner: false,
      // Customizing the theme to match your dark/cyan aesthetic
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        primaryColor: Colors.cyanAccent,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
            // FIX: fontWeight must be wrapped in textStyle: TextStyle(...)
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const ReportScreen(),
    );
  }
}
