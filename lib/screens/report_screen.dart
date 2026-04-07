import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'camera_screen.dart';
import 'ai_preview_screen.dart';
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

  // --- PROFESSIONAL GLASSMORPHIC SELECTION DIALOG ---
  void _showImageSourceOptions(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "SourceSelector",
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.cyanAccent.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "SELECT SOURCE",
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 25),
                        _buildSourceOption(
                          context,
                          icon: Icons.camera_enhance_rounded,
                          label: "LIVE CAMERA",
                          subtitle: "AI real-time detection",
                          onTap: () async {
                            Navigator.pop(context);
                            final String? imagePath = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CameraScreen(),
                              ),
                            );
                            if (imagePath != null && mounted)
                              _navigateToAI(imagePath);
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildSourceOption(
                          context,
                          icon: Icons.grid_view_rounded,
                          label: "GALLERY",
                          subtitle: "Upload existing report",
                          onTap: () async {
                            Navigator.pop(context);
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (image != null && mounted)
                              _navigateToAI(image.path);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.cyanAccent, size: 28),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAI(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AIPreviewScreen(imagePath: path)),
    );
  }

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
                  _buildCategoryList(),
                  const Spacer(),
                  _buildVolunteerSection(),
                  const SizedBox(height: 15),
                  _buildReportButton(),
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
                "FIX MY STREET AI",
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
      child: const Row(
        children: [
          Icon(
            Icons.cleaning_services_rounded,
            color: Colors.white70,
            size: 22,
          ),
          SizedBox(width: 15),
          Expanded(
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
        onPressed: () => _showImageSourceOptions(context),
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
