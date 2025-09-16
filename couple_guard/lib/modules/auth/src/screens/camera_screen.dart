// camera_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import '../services/camera_service.dart';

enum CaptureMode { photo, video }

class CameraScreen extends StatefulWidget {
  final int selectedChildId;
  final String jwtToken;

  const CameraScreen({
    Key? key,
    required this.selectedChildId,
    required this.jwtToken,
  }) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isLoading = true;
  String? _error;
  int _selectedCameraIndex = 0;
  int get childId => widget.selectedChildId;
  String get token => widget.jwtToken;
  bool _isRecording = false;
  CaptureMode _mode = CaptureMode.photo;
  late Stopwatch _stopwatch;
  Timer? _timer;
  String _recordDuration = "00:00";
  final CameraService _cameraService = CameraService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _stopwatch = Stopwatch();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _timer?.cancel();
    _stopwatch.stop();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        setState(() {
          _error = 'No cameras available';
          _isLoading = false;
        });
        return;
      }

      _selectedCameraIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      if (_selectedCameraIndex == -1) {
        _selectedCameraIndex = 0;
      }

      await _setupCamera(_selectedCameraIndex);
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize camera: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _setupCamera(int cameraIndex) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    final camera = _cameras[cameraIndex];

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to setup camera: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    try {
      final newIndex = (_selectedCameraIndex + 1) % _cameras.length;
      _selectedCameraIndex = newIndex;

      // dispose dulu biar gak conflict
      await _cameraController?.dispose();

      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error switching camera: $e");
    }
  }

  Future<void> _takePicture() async {
    if (!_cameraController!.value.isInitialized) return;

    try {
      final XFile picture = await _cameraController!.takePicture();
      final File file = File(picture.path);

      // tampilkan loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _cameraService.uploadPhoto(file, childId, token);

      // tutup loading
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result["success"]
                  ? "Foto berhasil diupload!"
                  : "Upload gagal: ${result["message"]}",
            ),
            backgroundColor: result["success"] ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // pastikan loading ditutup
      print("Take picture error: $e");
    }
  }

  void _startTimer() {
    _stopwatch.reset();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = _stopwatch.elapsed;
      final minutes = elapsed.inMinutes
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      final seconds = elapsed.inSeconds
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      setState(() {
        _recordDuration = "$minutes:$seconds";
      });
    });
  }

  void _stopTimer() {
    _stopwatch.stop();
    _timer?.cancel();
    setState(() {
      _recordDuration = "00:00";
    });
  }

  Future<void> _toggleRecording() async {
    if (!_cameraController!.value.isInitialized) return;

    try {
      if (_isRecording) {
        final XFile video = await _cameraController!.stopVideoRecording();
        _stopTimer();
        setState(() => _isRecording = false);

        final File file = File(video.path);

        // tampilkan loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );

        final result = await _cameraService.uploadVideo(file, childId, token);

        // tutup loading
        if (mounted) Navigator.of(context).pop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result["success"]
                    ? "Video berhasil diupload!"
                    : "Upload gagal: ${result["message"]}",
              ),
              backgroundColor: result["success"] ? Colors.green : Colors.red,
            ),
          );
        }
      } else {
        await _cameraController!.startVideoRecording();
        _startTimer();
        setState(() => _isRecording = true);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // pastikan loading ditutup
      print("Recording error: $e");
    }
  }

  Widget _buildButton({
    required IconData icon,
    required bool isBig,
    required VoidCallback onTap,
    Color? color,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: isBig ? 80 : 60,
        height: isBig ? 80 : 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? Colors.white,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.black,
          size: isBig ? 35 : 28,
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 60,
      left: 20,
      right: 20,
      child: SizedBox(
        height: 100,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Foto button
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              alignment:
                  _mode == CaptureMode.photo
                      ? Alignment.bottomCenter
                      : Alignment.bottomLeft,
              child:
                  _mode == CaptureMode.photo
                      ? _buildButton(
                        icon: Icons.camera_alt,
                        isBig: true,
                        onTap: _takePicture,
                      )
                      : _buildButton(
                        icon: Icons.camera_alt,
                        isBig: false,
                        onTap: () {
                          setState(() => _mode = CaptureMode.photo);
                        },
                      ),
            ),

            // Video button
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              alignment:
                  _mode == CaptureMode.video
                      ? Alignment.bottomCenter
                      : Alignment.bottomLeft,
              child:
                  _mode == CaptureMode.video
                      ? _buildButton(
                        icon: _isRecording ? Icons.stop : Icons.videocam,
                        isBig: true,
                        onTap: _toggleRecording,
                        color: _isRecording ? Colors.red : Colors.white,
                        iconColor: _isRecording ? Colors.white : Colors.black,
                      )
                      : _buildButton(
                        icon: Icons.videocam,
                        isBig: false,
                        onTap: () {
                          setState(() => _mode = CaptureMode.video);
                        },
                      ),
            ),

            // Switch camera
            Align(
              alignment: Alignment.bottomRight,
              child:
                  _cameras.length > 1
                      ? _buildButton(
                        icon: Icons.flip_camera_ios,
                        isBig: false,
                        onTap: _switchCamera,
                        color: Colors.black.withOpacity(0.5),
                        iconColor: Colors.white,
                      )
                      : const SizedBox(width: 60),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    if (!_isRecording) return const SizedBox.shrink();
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fiber_manual_record, color: Colors.red, size: 14),
          const SizedBox(width: 6),
          Text(
            "REC $_recordDuration",
            style: const TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Camera', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (_cameraController != null &&
              _cameraController!.value.isInitialized)
            Center(child: CameraPreview(_cameraController!))
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          _buildControls(),
          _buildRecordingIndicator(),
        ],
      ),
    );
  }
}
