import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'camera_screen.dart';
import 'ai_preview_screen.dart';
// Import your new AI screen
import 'package:image_picker/image_picker.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isMapExpanded = false;
  bool _isHeatmapEnabled = false;

  static const CameraPosition _initialLocation = CameraPosition(
    target: LatLng(25.7895, 55.9432),
    zoom: 14.5,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () => setState(() => _isMapExpanded = !_isMapExpanded),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                    height: _isMapExpanded
                        ? MediaQuery.of(context).size.height * 0.75
                        : 240,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.cyanAccent.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: _initialLocation,
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                          ),
                          Positioned(
                            top: 15,
                            right: 15,
                            child: FloatingActionButton.small(
                              backgroundColor: Colors.black.withOpacity(0.6),
                              onPressed: () => setState(
                                () => _isHeatmapEnabled = !_isHeatmapEnabled,
                              ),
                              child: Icon(
                                Icons.layers_outlined,
                                color: _isHeatmapEnabled
                                    ? Colors.cyanAccent
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!_isMapExpanded) ...[
                  const SizedBox(height: 20),
                  _buildCategoryList(), // Updated for 1-line fit
                  const Spacer(),
                  _buildVolunteerSection(),
                  const SizedBox(height: 15),
                  _buildReportButton(), // Updated with AI navigation
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
          if (_isMapExpanded)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: () => setState(() => _isMapExpanded = false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black54,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    "CLOSE FULL VIEW",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "FIX MY STREET",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                "SNAP A PIC OF THE PROBLEM",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Icon(
            Icons.auto_awesome_outlined,
            color: Colors.cyanAccent.withOpacity(0.7),
          ),
        ],
      ),
    );
  }

  // UPDATED: Fits all items in 1 line using a Row with Expanded/Flexible
  Widget _buildCategoryList() {
    final List<Map<String, dynamic>> cats = [
      {"icon": Icons.warning_rounded, "label": "Pothole"},
      {"icon": Icons.lightbulb_outline, "label": "Light"},
      {"icon": Icons.delete_outline, "label": "Garbage"},
      {"icon": Icons.chair_alt, "label": "Hazard"},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: cats.map((cat) {
          return Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(cat['icon'], color: Colors.cyanAccent, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  cat['label'],
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVolunteerSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cleaning_services_rounded,
            color: Colors.white70,
            size: 22,
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "VOLUNTEER OPPORTUNITIES",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Help clean up garbage near you",
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
        ],
      ),
    );
  }

  // UPDATED: Handles the logic to jump from Camera -> AI Preview
  Widget _buildReportButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 25),
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF00E5FF), Color(0xFF00838F)],
        ),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        onPressed: () async {
          // 1. Wait for photo path from Camera
          final String? imagePath = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CameraScreen()),
          );

          // 2. If we got a photo, immediately go to the AI Preview Screen
          if (imagePath != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AIPreviewScreen(imagePath: imagePath),
              ),
            );
          }
        },
        child: const Text(
          "+ REPORT ISSUE",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
