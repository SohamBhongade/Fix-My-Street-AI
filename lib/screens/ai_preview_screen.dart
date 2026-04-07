import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../services/ai_service.dart';
import '../services/firestore_service.dart';

class AIPreviewScreen extends StatefulWidget {
  final String imagePath;
  const AIPreviewScreen({super.key, required this.imagePath});

  @override
  State<AIPreviewScreen> createState() => _AIPreviewScreenState();
}

class _AIPreviewScreenState extends State<AIPreviewScreen> {
  // Location state
  Position? _currentPosition;
  String _coordinates = "Fetching GPS...";
  String _streetName = "Locating street...";

  // AI state
  bool _isAnalyzing = true;
  String _aiStatusText = "Running AI Analysis...";
  bool _aiFailed = false;
  AIAnalysisResult? _aiResult;
  String? _manuallySelectedCategory;

  // Submission state
  bool _isSubmitting = false;

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
    _runAIAnalysis();
  }

  // --- REAL GEMINI AI ANALYSIS ---
  Future<void> _runAIAnalysis() async {
    try {
      final result = await AIService.analyzeImage(File(widget.imagePath));
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _aiFailed = false;
        _aiResult = result;
        _aiStatusText = "AI Analysis Complete";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _aiFailed = true;
        _aiStatusText = "AI Analysis Failed";
      });
    }
  }

  // --- GPS LOCATION ---
  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _coordinates = "Location services disabled";
            _streetName = "Enable GPS in settings";
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _coordinates = "Permission denied";
              _streetName = "Grant location access";
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _coordinates = "Permission permanently denied";
            _streetName = "Enable in app settings";
          });
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = position;

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        Placemark place = placemarks[0];
        if (mounted) {
          setState(() {
            _coordinates =
                "${position.latitude.toStringAsFixed(4)}° N, ${position.longitude.toStringAsFixed(4)}° E";
            _streetName = "${place.street ?? "Unknown Street"}, ${place.subLocality ?? ""}";
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _coordinates =
                "${position.latitude.toStringAsFixed(4)}° N, ${position.longitude.toStringAsFixed(4)}° E";
            _streetName = "Reverse geocoding unavailable";
          });
        }
      }
    } catch (e) {
      debugPrint("Location Error: $e");
      if (mounted) {
        setState(() {
          _coordinates = "Location error";
          _streetName = "Unable to fetch position";
        });
      }
    }
  }

  // --- SUBMIT REPORT ---
  Future<void> _submitReport() async {
    // Validate category
    final category =
        _manuallySelectedCategory ?? _aiResult?.category;
    if (category == null || !_categories.contains(category)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a category before submitting."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("GPS location required. Please wait a moment."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final reportId = DateTime.now().millisecondsSinceEpoch.toString();

      // Step 1: Upload image to Firebase Storage
      final imageUrl = await FirestoreService.uploadImage(
        File(widget.imagePath),
        reportId: reportId,
      );

      // Step 2: Save metadata to Firestore
      final description = _aiResult?.description ?? "User-reported issue";
      final severity = _aiResult?.severity ?? 5.0;

      await FirestoreService.saveReport(
        reportId: reportId,
        category: category,
        description: description,
        severity: severity,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        imageUrl: imageUrl,
        streetName: _streetName,
      );

      if (!mounted) return;

      // Show success and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Report submitted successfully!"),
          backgroundColor: Colors.greenAccent,
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint("Submit Error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to submit report: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- UI ---
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
            // Image preview
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

            // AI AUTO CLASSIFICATION
            _buildSectionHeader("AI AUTO CLASSIFICATION"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_aiFailed && _aiResult == null)
                    ? Colors.redAccent.withOpacity(0.05)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: (_aiFailed && _aiResult == null)
                      ? Colors.redAccent.withOpacity(0.3)
                      : Colors.white10,
                ),
              ),
              child: Column(
                children: [
                  // AI Status row
                  Row(
                    children: [
                      Icon(
                        _isAnalyzing
                            ? Icons.sync
                            : (_aiResult != null
                                ? Icons.check_circle_outline
                                : Icons.error_outline),
                        color: _isAnalyzing
                            ? Colors.cyanAccent
                            : (_aiResult != null
                                ? Colors.greenAccent
                                : Colors.redAccent),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _aiStatusText,
                        style: TextStyle(
                          color: _isAnalyzing
                              ? Colors.cyanAccent
                              : (_aiResult != null
                                  ? Colors.greenAccent
                                  : Colors.redAccent),
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

                  // Show AI results
                  if (_aiResult != null) ...[
                    const SizedBox(height: 12),
                    _buildAIResultRow("Category", _aiResult!.category),
                    const SizedBox(height: 8),
                    _buildAIResultRow(
                      "Severity",
                      "${_aiResult!.severityLevel}/10",
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _aiResult!.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  // Manual category selection if AI failed or user disagrees
                  if (_aiFailed || _aiResult == null) ...[
                    const SizedBox(height: 12),
                    const Text(
                      "AI could not classify automatically. Please select manually.",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF161B22),
                      value: _manuallySelectedCategory,
                      hint: const Text(
                        "Select category...",
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
                          setState(() => _manuallySelectedCategory = val),
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
                    _manuallySelectedCategory != null
                        ? _getPriority(_manuallySelectedCategory!)
                        : _aiResult?.priority ?? "PENDING",
                    _manuallySelectedCategory != null
                        ? Colors.orangeAccent
                        : (_aiResult != null
                            ? Colors.orangeAccent
                            : Colors.white24),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildInfoCard(
                    "SEVERITY",
                    _aiResult != null
                        ? "${_aiResult!.severityLevel}/10"
                        : "PENDING",
                    Colors.cyanAccent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // GEO-LOCATION
            _buildSectionHeader("GEO-LOCATION DATA"),
            _buildReadOnlyField(
              _coordinates,
              "GPS Coordinates",
              Icons.gps_fixed,
            ),
            const SizedBox(height: 15),
            _buildReadOnlyField(
              _streetName,
              "Street Name",
              Icons.map_outlined,
            ),

            const SizedBox(height: 40),

            // SUBMIT BUTTON
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: (_isSubmitting ||
                        _currentPosition != null &&
                            (_aiResult != null || _manuallySelectedCategory != null))
                    ? const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF00838F)],
                      )
                    : null,
                color: (_isSubmitting ||
                        _currentPosition != null &&
                            (_aiResult != null || _manuallySelectedCategory != null))
                    ? null
                    : Colors.white10,
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                onPressed: (_isSubmitting ||
                        _currentPosition == null ||
                        (_aiResult == null && _manuallySelectedCategory == null))
                    ? null
                    : _submitReport,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "SUBMIT REPORT",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget _buildAIResultRow(String label, String value) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 13,
          ),
        ),
      ],
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

  String _getPriority(String category) {
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
