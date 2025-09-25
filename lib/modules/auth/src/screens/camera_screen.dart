// camera_screen.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import '../services/camera_service.dart';
import '../../../../core/constants/app_colors.dart';
import './loading_screen.dart';
import 'package:path/path.dart' as path;

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

  // Zoom variables
  double _currentZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  double _baseScale = 1.0;

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

  Future<File> _prepareVideoFile(File file) async {
    final dir = path.dirname(file.path);
    final newPath = path.join(
      dir,
      "${DateTime.now().millisecondsSinceEpoch}.mp4",
    );
    return await file.copy(newPath);
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

      // Initialize zoom levels
      _maxZoomLevel = await _cameraController!.getMaxZoomLevel();
      _minZoomLevel = await _cameraController!.getMinZoomLevel();
      _currentZoomLevel = _minZoomLevel;

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

      // Reset zoom levels for new camera
      _maxZoomLevel = await _cameraController!.getMaxZoomLevel();
      _minZoomLevel = await _cameraController!.getMinZoomLevel();
      _currentZoomLevel = _minZoomLevel;
      await _cameraController!.setZoomLevel(_currentZoomLevel);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error switching camera: $e");
    }
  }

  // Zoom functions
  Future<void> _onScaleStart(ScaleStartDetails details) async {
    _baseScale = _currentZoomLevel;
  }

  Future<void> _onScaleUpdate(ScaleUpdateDetails details) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    final double scale = (_baseScale * details.scale).clamp(
      _minZoomLevel,
      _maxZoomLevel,
    );

    if (scale != _currentZoomLevel) {
      _currentZoomLevel = scale;
      await _cameraController!.setZoomLevel(_currentZoomLevel);
      setState(() {});
    }
  }

  Future<void> _zoomIn() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    const double step = 0.5;
    final double newZoom = (_currentZoomLevel + step).clamp(
      _minZoomLevel,
      _maxZoomLevel,
    );

    if (newZoom != _currentZoomLevel) {
      _currentZoomLevel = newZoom;
      await _cameraController!.setZoomLevel(_currentZoomLevel);
      setState(() {});
    }
  }

  Future<void> _zoomOut() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    const double step = 0.5;
    final double newZoom = (_currentZoomLevel - step).clamp(
      _minZoomLevel,
      _maxZoomLevel,
    );

    if (newZoom != _currentZoomLevel) {
      _currentZoomLevel = newZoom;
      await _cameraController!.setZoomLevel(_currentZoomLevel);
      setState(() {});
    }
  }

  Future<void> _resetZoom() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _currentZoomLevel = _minZoomLevel;
    await _cameraController!.setZoomLevel(_currentZoomLevel);
    setState(() {});
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
        builder:
            (context) => const Center(
              child: ParentalControlLoading(
                primaryColor: AppColors.primary,
                type: LoadingType.family,
              ),
            ),
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

        final File uploadFile = await _prepareVideoFile(file);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(
                child: ParentalControlLoading(
                  primaryColor: AppColors.primary,
                  type: LoadingType.family,
                ),
              ),
        );

        final result = await _cameraService.uploadVideo(
          uploadFile,
          childId,
          token,
        );

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
    bool hasGlow = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: isBig ? 80 : 60,
        height: isBig ? 80 : 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? Colors.white.withOpacity(0.9),
          border: Border.all(
            color: Colors.white.withOpacity(0.8),
            width: isBig ? 4 : 3,
          ),
          boxShadow:
              hasGlow
                  ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.6),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.grey[800],
          size: isBig ? 35 : 28,
        ),
      ),
    );
  }

  Widget _buildZoomIndicator() {
    // Hanya tampilkan ketika user sedang zoom (zoom level > minimum)
    if (_currentZoomLevel <= _minZoomLevel) return const SizedBox.shrink();

    return Positioned(
      top: 120,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Text(
            "${_currentZoomLevel.toStringAsFixed(1)}x",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    // Tombol zoom dihilangkan, hanya menggunakan pinch gesture
    return const SizedBox.shrink();
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 50,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.7),
              AppColors.primary.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SizedBox(
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Mode indicators
              Positioned(
                top: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tombol FOTO
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _mode = CaptureMode.photo;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _mode == CaptureMode.photo
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          "FOTO",
                          style: TextStyle(
                            color:
                                _mode == CaptureMode.photo
                                    ? Colors.grey[800]
                                    : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Tombol VIDEO
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _mode = CaptureMode.video;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _mode == CaptureMode.video
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          "VIDEO",
                          style: TextStyle(
                            color:
                                _mode == CaptureMode.video
                                    ? Colors.grey[800]
                                    : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main capture button
              Positioned(
                bottom: 0,
                child:
                    _mode == CaptureMode.photo
                        ? _buildButton(
                          icon: Icons.camera_alt,
                          isBig: true,
                          onTap: _takePicture,
                          color: Colors.white,
                          iconColor: AppColors.primary,
                        )
                        : _buildButton(
                          icon: _isRecording ? Icons.stop : Icons.videocam,
                          isBig: true,
                          onTap: _toggleRecording,
                          color: _isRecording ? Colors.red : Colors.white,
                          iconColor:
                              _isRecording ? Colors.white : Colors.red[600],
                          hasGlow: _isRecording,
                        ),
              ),

              // Mode switcher (left)
              Positioned(
                bottom: 10,
                left: 0,
                child: _buildButton(
                  icon:
                      _mode == CaptureMode.photo
                          ? Icons.videocam
                          : Icons.camera_alt,
                  isBig: false,
                  onTap: () {
                    setState(() {
                      _mode =
                          _mode == CaptureMode.photo
                              ? CaptureMode.video
                              : CaptureMode.photo;
                    });
                  },
                  color: Colors.white.withOpacity(0.8),
                  iconColor: Colors.grey[700],
                ),
              ),

              // Switch camera (right)
              Positioned(
                bottom: 10,
                right: 0,
                child:
                    _cameras.length > 1
                        ? _buildButton(
                          icon: Icons.flip_camera_ios,
                          isBig: false,
                          onTap: _switchCamera,
                          color: Colors.white.withOpacity(0.8),
                          iconColor: Colors.grey[700],
                        )
                        : const SizedBox(width: 60),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    if (!_isRecording) return const SizedBox.shrink();
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 145),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fiber_manual_record,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              "REC $_recordDuration",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
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
            GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _cameraController!.value.previewSize!.height,
                    height: _cameraController!.value.previewSize!.width,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            )
          else
            const Center(
              child: ParentalControlLoading(
                primaryColor: AppColors.primary,
                type: LoadingType.family,
                message: "Loading..",
              ),
            ),
          _buildZoomIndicator(),
          _buildControls(),
          _buildRecordingIndicator(),
        ],
      ),
    );
  }
}
