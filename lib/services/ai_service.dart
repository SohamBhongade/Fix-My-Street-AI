import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

/// Result of Gemini AI analysis for a street issue photo.
class AIAnalysisResult {
  final String category;
  final double severity; // 1-10
  final String description;
  final String priority;

  AIAnalysisResult({
    required this.category,
    required this.severity,
    required this.description,
    required this.priority,
  });

  String get priorityLabel {
    if (severity >= 7) return "HIGH (Hazardous)";
    if (severity >= 4) return "MEDIUM (Infrastructure)";
    return "LOW (Aesthetic)";
  }

  int get severityLevel => severity.round();
}

/// AI service that sends images to Gemini for classification.
/// Replace _kGeminiApiKey with your actual key or use environment variable.
class AIService {
  static const String _kGeminiApiKey =
      'AIzaSyD5jCDm27LwmqJ8_kH0uu5-6xrsTWvznSs'; // <-- Replace with actual key

  static const String _model = 'gemini-1.5-flash';

  static const List<String> _validCategories = [
    'Potholes',
    'Faded Road Markings',
    'Cracked Sidewalks',
    'Broken Street Lights',
    'Exposed Wiring',
    'Malfunctioning Traffic Signals',
    'Illegal Dumping',
    'Overflowing Bins',
    'Litter Accumulation',
    'Graffiti',
    'Broken Signs',
    'Broken Guardrails',
    'Broken pipelines',
    'Water accumulation',
    'Overgrown Vegetation',
  ];

  /// Analyzes an image file using Gemini API.
  /// Returns the best-matching category, severity (1-10), description, and priority.
  static Future<AIAnalysisResult> analyzeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final prompt =
        '''
You are an AI urban maintenance classifier for Ras Al Khaimah, UAE.
Analyze this image and return a JSON object with EXACTLY these keys:
- "category": pick the single best match from this list: ${_validCategories.join(', ')}. If none match well, pick the closest one.
- "severity": a number from 1 to 10 indicating how severe/urgent this issue is.
- "description": a brief 1-2 sentence description of what you see in the image.

Return ONLY valid JSON, no markdown formatting, no explanation.
''';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_kGeminiApiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
              },
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 256},
      }),
    );

    if (response.statusCode != 200) {
      debugPrint('Gemini API error: ${response.statusCode} ${response.body}');
      throw Exception(
        'AI analysis failed with status ${response.statusCode}. Please select a category manually.',
      );
    }

    final data = jsonDecode(response.body);
    final text = data['candidates'][0]['content']['parts'][0]['text'] as String;

    // Extract JSON from possible markdown code block
    String jsonStr = text.trim();
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr.replaceAll('```json', '').replaceAll('```', '').trim();
    }

    final parsed = jsonDecode(jsonStr);
    final category = parsed['category'] as String? ?? 'Unknown';
    final severity = (parsed['severity'] as num?)?.toDouble() ?? 5.0;
    final description =
        parsed['description'] as String? ?? 'An image requiring review';
    final clampedSeverity = severity.clamp(1.0, 10.0);

    return AIAnalysisResult(
      category: category,
      severity: clampedSeverity,
      description: description,
      priority: clampedSeverity >= 7
          ? "HIGH (Hazardous)"
          : clampedSeverity >= 4
          ? "MEDIUM (Infrastructure)"
          : "LOW (Aesthetic)",
    );
  }
}
