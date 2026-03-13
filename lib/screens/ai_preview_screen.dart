import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AIPreviewScreen extends StatefulWidget {
  final String imagePath;
  const AIPreviewScreen({super.key, required this.imagePath});

  @override
  State<AIPreviewScreen> createState() => _AIPreviewScreenState();
}

class _AIPreviewScreenState extends State<AIPreviewScreen> {
  String? _selectedCategory;
  String _coordinates = "Fetching GPS...";
  String _streetName = "Locating street...";

  // AI Status States
  bool _isAnalyzing = true;
  String _aiStatusText = "RUNNING AI ANALYSIS...";
  bool _aiFailed = false;

  final List<String> _categories = [
    "Potholes",
    "Faded Road Markings",
    "Cracked Sidewalks",
    "Broken Street Lights",
    "Exposed Wiring",
    "Malfunctioning Traffic Signals",
    "Illegal Dumping",
    "Overflowing Bins",
    "Litter Accumulation",
    "Graffiti",
    "Broken Signs",
    "Broken Guardrails",
    "Broken pipelines",
    "Water accumulation",
    "Overgrown Vegetation",
  ];

  @override
  void initState() {
    super.initState();
    _getLocation();
    _runFakeAI();
  }

  // --- SIMULATED AI LOGIC ---
  Future<void> _runFakeAI() async {
    await Future.delayed(
      const Duration(seconds: 3),
    ); // Simulate processing time
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _aiFailed = true; // Set to true to show the error as requested
        _aiStatusText = "AI ANALYSIS FAILED";
      });
    }
  }

  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks[0];

      if (mounted) {
        setState(() {
          _coordinates =
              "${position.latitude.toStringAsFixed(4)}° N, ${position.longitude.toStringAsFixed(4)}° E";
          _streetName = "${place.street}, ${place.subLocality}";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _streetName = "Location logic error");
    }
  }

  String _getPriority(String? category) {
    if (category == null) return "PENDING";
    if ([
      "Exposed Wiring",
      "Malfunctioning Traffic Signals",
      "Broken pipelines",
      "Water accumulation",
    ].contains(category)) {
      return "HIGH (Hazardous)";
    } else if ([
      "Potholes",
      "Faded Road Markings",
      "Cracked Sidewalks",
      "Broken Street Lights",
      "Broken Signs",
      "Broken Guardrails",
    ].contains(category)) {
      return "MEDIUM (Infrastructure)";
    }
    return "LOW (Aesthetic)";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "REPORT PREVIEW",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                File(widget.imagePath),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 25),

            // --- AI AUTO CLASSIFICATION SECTION ---
            _buildSectionHeader("AI AUTO CLASSIFICATION"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _aiFailed
                    ? Colors.redAccent.withOpacity(0.05)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _aiFailed
                      ? Colors.redAccent.withOpacity(0.3)
                      : Colors.white10,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _isAnalyzing
                            ? Icons.sync
                            : (_aiFailed
                                  ? Icons.error_outline
                                  : Icons.auto_awesome),
                        color: _isAnalyzing
                            ? Colors.cyanAccent
                            : (_aiFailed
                                  ? Colors.redAccent
                                  : Colors.greenAccent),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _aiStatusText,
                        style: TextStyle(
                          color: _aiFailed
                              ? Colors.redAccent
                              : Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      if (_isAnalyzing) const Spacer(),
                      if (_isAnalyzing)
                        const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.cyanAccent,
                          ),
                        ),
                    ],
                  ),
                  if (_aiFailed) ...[
                    const SizedBox(height: 12),
                    const Text(
                      "Neural network could not identify the issue. Please provide manual input below.",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF161B22),
                      value: _selectedCategory,
                      hint: const Text(
                        "Select manually...",
                        style: TextStyle(color: Colors.white38),
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                c,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val),
                      decoration: _inputDecoration("Manual Classification"),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 25),

            // PRIORITY & SEVERITY
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    "PRIORITY",
                    _getPriority(_selectedCategory),
                    _selectedCategory == null
                        ? Colors.white24
                        : Colors.orangeAccent,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildInfoCard(
                    "SEVERITY",
                    _selectedCategory == null ? "PENDING" : "LEVEL 4/5",
                    Colors.cyanAccent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            _buildSectionHeader("GEO-LOCATION DATA"),
            _buildReadOnlyField(
              _coordinates,
              "GPS Coordinates",
              Icons.gps_fixed,
            ),
            const SizedBox(height: 15),
            _buildReadOnlyField(_streetName, "Street Name", Icons.map_outlined),

            const SizedBox(height: 40),

            // SUBMIT BUTTON
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: _selectedCategory == null
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF00838F)],
                      ),
                color: _selectedCategory == null ? Colors.white10 : null,
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                onPressed: _selectedCategory == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Report Logged to Database"),
                          ),
                        );
                      },
                child: const Text(
                  "SUBMIT REPORT",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String value, String label, IconData icon) {
    return TextField(
      controller: TextEditingController(text: value),
      readOnly: true,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _inputDecoration(label).copyWith(
        prefixIcon: Icon(
          icon,
          color: Colors.cyanAccent.withOpacity(0.5),
          size: 18,
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.cyanAccent),
      ),
    );
  }
}
