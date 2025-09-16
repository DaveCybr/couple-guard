import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../services/album_camera_service.dart';

class AlbumCameraScreen extends StatefulWidget {
  final int selectedChildId;
  final String jwtToken;

  const AlbumCameraScreen({
    super.key,
    required this.selectedChildId,
    required this.jwtToken,
  });

  @override
  State<AlbumCameraScreen> createState() => _AlbumCameraScreenState();
}

class _AlbumCameraScreenState extends State<AlbumCameraScreen> {
  final String _baseUrl = "http://192.168.100.106:8000";
  final AlbumCameraService _albumService = AlbumCameraService();
  bool _isLoading = true;
  List<dynamic> _captures = [];

  @override
  void initState() {
    super.initState();
    _fetchCaptures();
  }

  Future<void> _fetchCaptures() async {
    setState(() => _isLoading = true);

    final result = await _albumService.listCaptures(
      widget.selectedChildId,
      widget.jwtToken,
    );

    if (result["success"]) {
      setState(() {
        _captures = result["data"]["captures"];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result["message"] ?? "Error")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Album Kamera"),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _captures.isEmpty
              ? const Center(child: Text("Belum ada foto atau video"))
              : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _captures.length,
                itemBuilder: (context, index) {
                  final item = _captures[index];
                  final type = item["type"]; // photo / video
                  final url =
                      type == "video"
                          ? item["stream_url"]
                          : _baseUrl + item["file_url"];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => CaptureDetailScreen(
                                type: type,
                                url: url,
                                jwtToken: widget.jwtToken,
                              ),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            image:
                                type == "photo"
                                    ? DecorationImage(
                                      image: NetworkImage(url),
                                      fit: BoxFit.cover,
                                    )
                                    : null,
                          ),
                          child:
                              type == "video"
                                  ? Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.black54,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.video_library,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                  : null,
                        ),
                        if (type == "video")
                          const Positioned(
                            bottom: 8,
                            right: 8,
                            child: Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}

/// Detail foto / video dengan error handling yang lebih baik
class CaptureDetailScreen extends StatefulWidget {
  final String type;
  final String url;
  final String jwtToken;

  const CaptureDetailScreen({
    super.key,
    required this.type,
    required this.url,
    required this.jwtToken,
  });

  @override
  State<CaptureDetailScreen> createState() => _CaptureDetailScreenState();
}

class _CaptureDetailScreenState extends State<CaptureDetailScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;
  String? _videoErrorMessage;
  bool _isLoadingVideo = false;

  @override
  void initState() {
    super.initState();
    if (widget.type == "video") {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    print('Playing URL: ${widget.url}');

    setState(() {
      _isLoadingVideo = true;
      _hasVideoError = false;
      _videoErrorMessage = null;
    });

    try {
      print('Initializing video: ${widget.url}');

      // Dispose previous controllers
      await _disposeControllers();

      // Create new video controller dengan headers
      final headers = {'Authorization': 'Bearer ${widget.jwtToken}'};

      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        httpHeaders: headers,
      );

      // Add listener untuk error handling
      _videoController!.addListener(_videoPlayerListener);

      // Initialize dengan timeout
      await _videoController!.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout saat memuat video');
        },
      );

      if (mounted && _videoController!.value.isInitialized) {
        print('Video initialized successfully');
        print('Duration: ${_videoController!.value.duration}');
        print('Size: ${_videoController!.value.size}');

        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: false, // Changed to false untuk kontrol manual
          looping: false,
          allowFullScreen: true,
          allowMuting: true,
          showControls: true,
          errorBuilder: (context, errorMessage) {
            return _buildVideoError(errorMessage);
          },
        );

        setState(() {
          _isVideoInitialized = true;
          _isLoadingVideo = false;
          _hasVideoError = false;
        });
      }
    } catch (e) {
      print('Video initialization error: $e');

      if (mounted) {
        setState(() {
          _hasVideoError = true;
          _videoErrorMessage = _getReadableError(e.toString());
          _isLoadingVideo = false;
          _isVideoInitialized = false;
        });
      }

      // Coba fallback tanpa headers
      await _initializeVideoFallback();
    }
  }

  Future<void> _initializeVideoFallback() async {
    try {
      print('Trying video initialization without headers...');

      await _disposeControllers();

      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );
      _videoController!.addListener(_videoPlayerListener);

      await _videoController!.initialize().timeout(const Duration(seconds: 30));

      if (mounted && _videoController!.value.isInitialized) {
        print('Video initialized successfully (fallback)');

        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: false,
          looping: false,
          allowFullScreen: true,
          allowMuting: true,
          showControls: true,
          errorBuilder: (context, errorMessage) {
            return _buildVideoError(errorMessage);
          },
        );

        setState(() {
          _isVideoInitialized = true;
          _isLoadingVideo = false;
          _hasVideoError = false;
        });
      }
    } catch (e) {
      print('Video fallback initialization error: $e');

      if (mounted) {
        setState(() {
          _hasVideoError = true;
          _videoErrorMessage = _getReadableError(e.toString());
          _isLoadingVideo = false;
          _isVideoInitialized = false;
        });
      }
    }
  }

  void _videoPlayerListener() {
    if (_videoController != null && _videoController!.value.hasError) {
      final error =
          _videoController!.value.errorDescription ?? 'Unknown video error';
      print('Video player listener error: $error');

      if (mounted) {
        setState(() {
          _hasVideoError = true;
          _videoErrorMessage = _getReadableError(error);
          _isVideoInitialized = false;
        });
      }
    }
  }

  String _getReadableError(String error) {
    final lowerError = error.toString().toLowerCase();

    if (lowerError.contains('source error') ||
        lowerError.contains('exoplaybackexception')) {
      return 'Tidak dapat memuat video. Periksa koneksi internet atau format video.';
    } else if (lowerError.contains('timeout')) {
      return 'Koneksi timeout. Pastikan koneksi internet stabil.';
    } else if (lowerError.contains('403') || lowerError.contains('forbidden')) {
      return 'Akses ditolak. Periksa izin akses video.';
    } else if (lowerError.contains('404') || lowerError.contains('not found')) {
      return 'Video tidak ditemukan.';
    } else if (lowerError.contains('network')) {
      return 'Masalah koneksi jaringan.';
    } else {
      return 'Terjadi kesalahan saat memuat video.';
    }
  }

  Future<void> _disposeControllers() async {
    _videoController?.removeListener(_videoPlayerListener);
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
  }

  Widget _buildVideoError(String errorMessage) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _initializeVideo,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_isLoadingVideo) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Memuat video...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    if (_hasVideoError) {
      return _buildVideoError(_videoErrorMessage ?? 'Error loading video');
    }

    if (_isVideoInitialized && _chewieController != null) {
      return Chewie(controller: _chewieController!);
    }

    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'Video tidak tersedia',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoPlayerListener);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == "photo" ? "Detail Foto" : "Detail Video"),
        backgroundColor: const Color(0xFF1E3A8A),
        actions:
            widget.type == "video"
                ? [
                  IconButton(
                    onPressed: _initializeVideo,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Reload Video',
                  ),
                ]
                : null,
      ),
      body: Center(
        child:
            widget.type == "photo"
                ? InteractiveViewer(
                  child: Image.network(
                    widget.url,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Gagal memuat foto: $error'),
                        ],
                      );
                    },
                  ),
                )
                : _buildVideoContent(),
      ),
    );
  }
}
