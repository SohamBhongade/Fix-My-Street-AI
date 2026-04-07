import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/report_screen.dart';

// Global cameras list for the whole app to use
List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase (non-blocking — app works even if Firebase fails)
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCjOx4vD_oULz_rhjoCDX-y4Fc4PBX8lk4",
        authDomain: "fix-mystreet.firebaseapp.com",
        projectId: "fix-mystreet",
        storageBucket: "fix-mystreet.firebasestorage.app",
        messagingSenderId: "153144291585",
        appId: "1:153144291585:web:a5f7e059bf741d07b6eb00",
        measurementId: "G-2J1C5LD27Q",
      ),
    );
    debugPrint("[Firebase] Initialized successfully");
  } catch (e) {
    debugPrint("[Firebase] Init failed: $e");
  }

  // 2. Fetch the available cameras (non-blocking)
  try {
    cameras = await availableCameras();
    debugPrint("[Camera] Found ${cameras.length} camera(s)");
  } catch (e) {
    debugPrint("[Camera] Init failed: $e");
  }

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
