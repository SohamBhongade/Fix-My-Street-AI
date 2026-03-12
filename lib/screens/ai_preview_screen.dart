import 'dart:io';
import 'dart:convert';
import 'dart:ui'; // For the cool Glassmorphism blur
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIPreviewScreen extends StatefulWidget {
  final String imagePath;
  const AIPreviewScreen({super.key, required this.imagePath});

  @override
  State<AIPreviewScreen> createState() => _AIPreviewScreenState();
}

class _AIPreviewScreenState extends State<AIPreviewScreen> {
  // STATE LOGIC
  bool _isAnalyzing = true;
  bool _showSuccess = false; // The "Switch" for the success overlay
  String _detectedIssue = "Analyzing...";
  String _severity = "...";
  String _priority = "...";

  @override
  void initState() {
    super.initState();
    _analyzeImageWithGemini();
  }

  // AI BRAIN LOGIC
  Future<void> _analyzeImageWithGemini() async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: 'AIzaSyD5jCDm27LwmqJ8_kH0uu5-6xrsTWvznSs',
      );

      final imageBytes = await File(widget.imagePath).readAsBytes();

      final prompt = TextPart(
        "Identify the urban maintenance issue in this photo. "
        "Return ONLY a raw JSON object with keys 'type', 'severity', and 'priority'. "
        "Example: {'type': 'Broken Bench', 'severity': 'Medium', 'priority': '3/5'}",
      );

      final content = [
        Content.multi([prompt, DataPart('image/jpeg', imageBytes)]),
      ];

      final response = await model
          .generateContent(content)
          .timeout(const Duration(seconds: 25));

      final text = response.text;
      if (text != null) {
        // Cleaning up any Markdown code blocks Gemini might add
        final cleanJson = text
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final Map<String, dynamic> data = jsonDecode(cleanJson);

        setState(() {
          _detectedIssue = data['type'] ?? "Unknown Issue";
          _severity = data['severity'] ?? "Medium";
          _priority = data['priority'] ?? "3/5";
        });
      }
    } catch (e) {
      debugPrint("GEMINI ERROR: $e");
      setState(() {
        _detectedIssue = "AI Sync Error";
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        // Using Stack to layer the Success Overlay on top
        children: [
          Column(
            children: [
              // 1. THE PHOTO DISPLAY
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Image.file(
                      File(widget.imagePath),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    if (_isAnalyzing)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.cyanAccent,
                              ),
                              SizedBox(height: 20),
                              Text(
                                "AI ANALYZING IMAGE...",
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 2. AI RESULTS CARD
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: const BoxDecoration(
                    color: Color(0xFF161B22),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "AI CLASSIFICATION",
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _detectedIssue,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(color: Colors.white10, height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _infoTile("SEVERITY", _severity),
                          _infoTile("PRIORITY", _priority),
                        ],
                      ),
                      const Spacer(),

                      // CONFIRM BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: () async {
                            // Turn on the "Switch" for the animation
                            setState(() => _showSuccess = true);

                            // Wait for the animation to play
                            await Future.delayed(const Duration(seconds: 2));

                            if (mounted) {
                              Navigator.popUntil(
                                context,
                                (route) => route.isFirst,
                              );
                            }
                          },
                          child: const Text(
                            "CONFIRM & SUBMIT",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. THE GLASSMORPHISM SUCCESS OVERLAY
          if (_showSuccess) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  // SUCCESS OVERLAY UI
  Widget _buildSuccessOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // The Glass Blur
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 700),
                  tween: Tween<double>(begin: 0, end: 1),
                  curve: Curves.elasticOut, // Gives it a nice bounce
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.cyanAccent.withOpacity(0.1),
                          border: Border.all(
                            color: Colors.cyanAccent,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.cyanAccent,
                          size: 80,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                const Text(
                  "REPORT FILED",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Thank you for helping the community!",
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // HELPER FOR INFO TILES
  Widget _infoTile(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
