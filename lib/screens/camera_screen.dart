import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../main.dart'; // Accessing the global 'cameras' list

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  int _selectedCameraIndex = 0; // 0 is usually back, 1 is usually front

  @override
  void initState() {
    super.initState();
    _initializeCamera(cameras[_selectedCameraIndex]);
  }

  Future<void> _initializeCamera(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller!.dispose();
    }

    controller = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  Future<void> _toggleCamera() async {
    if (cameras.length < 2) return;

    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras.length;
    });

    await _initializeCamera(cameras[_selectedCameraIndex]);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
      );
    }

    // --- SCALING CALCULATIONS FOR FULLSCREEN ---
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * controller!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. LIVE CAMERA FEED (PRO SCALING)
          ClipRect(
            child: Transform.scale(
              scale: scale,
              child: Center(child: CameraPreview(controller!)),
            ),
          ),

          // 2. DARK GRADIENT OVERLAY (For a professional look)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),

          // 3. FLIP CAMERA BUTTON
          Positioned(
            bottom: 65,
            right: 40,
            child: IconButton(
              icon: const Icon(
                Icons.flip_camera_android_rounded,
                color: Colors.white,
                size: 35,
              ),
              onPressed: _toggleCamera,
            ),
          ),

          // 4. CAPTURE BUTTON
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: GestureDetector(
                onTap: () async {
                  try {
                    final image = await controller!.takePicture();
                    if (mounted) {
                      Navigator.pop(context, image.path);
                    }
                  } catch (e) {
                    debugPrint("Error taking picture: $e");
                  }
                },
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 5. CLOSE BUTTON
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
