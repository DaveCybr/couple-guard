import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../services/album_camera_service.dart';
import '../../../../core/constants/app_colors.dart';
import './loading_screen.dart';

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
  final String _baseUrl = "https://parentalcontrol.satelliteorbit.cloud";
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        // title: const Text(
        //   "Album",
        //   style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        // ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                "${_captures.length} item${_captures.length != 1 ? 's' : ''}",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: ParentalControlLoading(
                  primaryColor: AppColors.primary,
                  type: LoadingType.family,
                  message: "Memuat data..",
                ),
              )
              : _captures.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.photo_library_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Belum ada foto atau video",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Foto dan video akan muncul di sini",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
              : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.0,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = _captures[index];
                        final type = item["type"]; // photo / video
                        final url =
                            type == "video"
                                ? item["stream_url"]
                                : _baseUrl + item["file_url"];

                        return Hero(
                          tag: "media_$index",
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (context, animation, _) =>
                                          CaptureDetailScreen(
                                            type: type,
                                            url: url,
                                            jwtToken: widget.jwtToken,
                                            heroTag: "media_$index",
                                          ),
                                  transitionsBuilder: (
                                    context,
                                    animation,
                                    _,
                                    child,
                                  ) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  transitionDuration: const Duration(
                                    milliseconds: 300,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    type == "photo"
                                        ? _buildPhotoThumbnail(url, index)
                                        : _buildVideoThumbnail(url, index),
                              ),
                            ),
                          ),
                        );
                      }, childCount: _captures.length),
                    ),
                  ),
                  // Bottom spacing
                  const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                ],
              ),
    );
  }

  Widget _buildPhotoThumbnail(String url, int index) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[100],
                child: Center(
                  child: CircularProgressIndicator(
                    value:
                        loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                    strokeWidth: 2,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[100],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_outlined,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Error',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Photo indicator
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.photo_outlined,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoThumbnail(String url, int index) {
    return VideoThumbnailWidget(
      videoUrl: url,
      jwtToken: widget.jwtToken,
      index: index,
    );
  }
}

/// Widget untuk menampilkan thumbnail video
class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  final String jwtToken;
  final int index;

  const VideoThumbnailWidget({
    super.key,
    required this.videoUrl,
    required this.jwtToken,
    required this.index,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeThumbnail();
  }

  Future<void> _initializeThumbnail() async {
    try {
      // Headers untuk otentikasi
      final headers = {'Authorization': 'Bearer ${widget.jwtToken}'};

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: headers,
      );

      await _controller!.initialize();

      if (mounted && _controller!.value.isInitialized) {
        // Seek ke detik pertama untuk mendapatkan frame thumbnail
        await _controller!.seekTo(const Duration(seconds: 1));

        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      print('Error initializing video thumbnail: $e');
      // Coba tanpa headers jika gagal
      try {
        _controller?.dispose();
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
        );

        await _controller!.initialize();

        if (mounted && _controller!.value.isInitialized) {
          await _controller!.seekTo(const Duration(seconds: 1));

          setState(() {
            _isInitialized = true;
            _hasError = false;
          });
        }
      } catch (e2) {
        print('Error initializing video thumbnail (fallback): $e2');
        if (mounted) {
          setState(() {
            _hasError = true;
            _isInitialized = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Thumbnail atau fallback
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              _isInitialized && !_hasError
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.size.width,
                        height: _controller!.value.size.height,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  )
                  : _hasError
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 32,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Video',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  )
                  : Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
        ),

        // Video type indicator
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
          ),
        ),

        // Duration overlay
        if (_isInitialized &&
            !_hasError &&
            _controller!.value.duration.inSeconds > 0)
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatDuration(_controller!.value.duration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        // Gradient overlay for better text readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 30,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.4), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }
}

class CaptureDetailScreen extends StatefulWidget {
  final String type;
  final String url;
  final String jwtToken;
  final String heroTag;

  const CaptureDetailScreen({
    super.key,
    required this.type,
    required this.url,
    required this.jwtToken,
    required this.heroTag,
  });

  @override
  State<CaptureDetailScreen> createState() => _CaptureDetailScreenState();
}

class _CaptureDetailScreenState extends State<CaptureDetailScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;
  String? _videoErrorMessage;
  bool _isLoadingVideo = false;

  // UI Enhancement variables
  bool _showAppBar = true;
  bool _isFullscreen = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();

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
          autoPlay: false,
          looping: false,
          allowFullScreen: true,
          allowMuting: true,
          showControls: true,
          showControlsOnInitialize: false,
          hideControlsTimer: const Duration(seconds: 3),
          showOptions: false, // ← Matikan menu default karena kita pakai custom
          materialProgressColors: ChewieProgressColors(
            playedColor: const Color(0xFF1E3A8A),
            handleColor: const Color(0xFF1E3A8A),
            backgroundColor: Colors.grey.shade300,
            bufferedColor: Colors.grey.shade200,
          ),
          placeholder: Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap untuk memutar video',
                    style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
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
          materialProgressColors: ChewieProgressColors(
            playedColor: const Color(0xFF1E3A8A),
            handleColor: const Color(0xFF1E3A8A),
            backgroundColor: Colors.grey.shade300,
            bufferedColor: Colors.grey.shade200,
          ),
          placeholder: Container(
            color: Colors.black,
            child: const Center(
              child: Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 64,
              ),
            ),
          ),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1E1E), Color(0xFF000000)],
        ),
      ),
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Oops! Ada masalah',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _initializeVideo,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Coba Lagi',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1E1E), Color(0xFF000000)],
        ),
      ),
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        backgroundColor: Colors.grey.shade800,
                      ),
                    ),
                    const Icon(
                      Icons.video_library,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Memuat video...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Harap tunggu sebentar',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_isLoadingVideo) {
      return _buildLoadingIndicator();
    }

    if (_hasVideoError) {
      return _buildVideoError(_videoErrorMessage ?? 'Error loading video');
    }

    if (_isVideoInitialized && _chewieController != null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1E1E), Color(0xFF000000)],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: Chewie(controller: _chewieController!),
              ),
            ),

            // Custom menu di posisi atas
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1E1E), Color(0xFF000000)],
        ),
      ),
      child: const Center(
        child: Text(
          'Video tidak tersedia',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    return Container(
      color: Colors.black,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: Hero(
              tag: widget.heroTag,
              child: Image.network(
                widget.url,
                headers: {'Authorization': 'Bearer ${widget.jwtToken}'},
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;

                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF1E1E1E), Color(0xFF000000)],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                  strokeWidth: 3,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF1E3A8A),
                                      ),
                                  backgroundColor: Colors.grey.shade800,
                                ),
                              ),
                              const Icon(
                                Icons.photo,
                                color: Colors.white,
                                size: 24,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Memuat foto...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (loadingProgress.expectedTotalBytes != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${((loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!) * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF1E1E1E), Color(0xFF000000)],
                      ),
                    ),
                    child: Center(
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          margin: const EdgeInsets.all(32),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.red,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Gagal memuat foto',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Periksa koneksi internet Anda dan coba lagi',
                                style: TextStyle(
                                  color: Colors.grey.shade300,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => setState(() {}),
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Coba Lagi',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleAppBar() {
    setState(() {
      _showAppBar = !_showAppBar;
    });
  }

  void _showSpeedDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.black.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'Kecepatan Pemutaran',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSpeedOption('0.5x', 0.5),
                _buildSpeedOption('0.75x', 0.75),
                _buildSpeedOption('Normal', 1.0),
                _buildSpeedOption('1.25x', 1.25),
                _buildSpeedOption('1.5x', 1.5),
                _buildSpeedOption('2x', 2.0),
              ],
            ),
          ),
    );
  }

  Widget _buildSpeedOption(String label, double speed) {
    final isSelected = _videoController?.value.playbackSpeed == speed;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.white,
        ),
      ),
      trailing:
          isSelected ? const Icon(Icons.check, color: Color(0xFF1E3A8A)) : null,
      onTap: () {
        _videoController?.setPlaybackSpeed(speed);
        Navigator.pop(context);
      },
    );
  }

  void _showVideoInfo() {
    final duration = _videoController?.value.duration;
    final size = _videoController?.value.size;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.black.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text(
              'Info Video',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'Durasi',
                  duration != null ? _formatDuration(duration) : 'N/A',
                ),
                _buildInfoRow(
                  'Resolusi',
                  size != null
                      ? '${size.width.toInt()} x ${size.height.toInt()}'
                      : 'N/A',
                ),
                _buildInfoRow('URL', widget.url),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Tutup',
                  style: TextStyle(color: Color(0xFF1E3A8A)),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
          const Text(': ', style: TextStyle(color: Colors.white)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _videoController?.removeListener(_videoPlayerListener);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhoto = widget.type == "photo";

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar:
          _showAppBar
              ? AppBar(
                title: Text(
                  isPhoto ? "Detail Foto" : "Detail Video",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: Colors.black.withOpacity(0.7),
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                actions:
                    !isPhoto
                        ? [
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 10,
                            ), // tambah jarak dari kanan
                            child: PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                              ),
                              color: Colors.black.withOpacity(0.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              itemBuilder:
                                  (context) => [
                                    const PopupMenuItem(
                                      value: 'speed',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.speed,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Kecepatan',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'info',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Info Video',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                              onSelected: (value) {
                                switch (value) {
                                  case 'speed':
                                    _showSpeedDialog();
                                    break;
                                  case 'info':
                                    _showVideoInfo();
                                    break;
                                }
                              },
                            ),
                          ),
                        ]
                        : null,
              )
              : null,

      body: GestureDetector(
        onTap: _toggleAppBar,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: isPhoto ? _buildImageContent() : _buildVideoContent(),
        ),
      ),
    );
  }
}
