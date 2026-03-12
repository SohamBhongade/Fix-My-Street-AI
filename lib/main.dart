import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // Add this import
import 'screens/report_screen.dart';

// Create a global variable to hold the list of available cameras
List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fetch the available cameras before starting the app
  cameras = await availableCameras();

  runApp(const FixMyStreetApp());
}

class FixMyStreetApp extends StatelessWidget {
  const FixMyStreetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const ReportScreen(),
    );
  }
}
