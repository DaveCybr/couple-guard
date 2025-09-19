import 'package:flutter/material.dart';

class ParentalControlLoading extends StatefulWidget {
  final String? message;
  final Color? primaryColor;
  final Color? secondaryColor;
  final double size;
  final LoadingType type;

  const ParentalControlLoading({
    Key? key,
    this.message,
    this.primaryColor,
    this.secondaryColor,
    this.size = 100.0,
    this.type = LoadingType.shield,
  }) : super(key: key);

  @override
  State<ParentalControlLoading> createState() => _ParentalControlLoadingState();
}

enum LoadingType { shield, family, lock, dots }

class _ParentalControlLoadingState extends State<ParentalControlLoading>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? Theme.of(context).primaryColor;
    final secondaryColor =
        widget.secondaryColor ?? primaryColor.withOpacity(0.3);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: _buildLoadingAnimation(primaryColor, secondaryColor),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Text(
                    widget.message!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingAnimation(Color primaryColor, Color secondaryColor) {
    switch (widget.type) {
      case LoadingType.shield:
        return _buildShieldAnimation(primaryColor, secondaryColor);
      case LoadingType.family:
        return _buildFamilyAnimation(primaryColor, secondaryColor);
      case LoadingType.lock:
        return _buildLockAnimation(primaryColor, secondaryColor);
      case LoadingType.dots:
        return _buildDotsAnimation(primaryColor, secondaryColor);
    }
  }

  Widget _buildShieldAnimation(Color primaryColor, Color secondaryColor) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: secondaryColor, width: 2),
                ),
                child: CustomPaint(
                  painter: _LoadingRingPainter(
                    progress: _controller.value,
                    color: primaryColor,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
            // Shield icon
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: widget.size * 0.5,
                    height: widget.size * 0.5,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.security,
                      color: Colors.white,
                      size: widget.size * 0.25,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFamilyAnimation(Color primaryColor, Color secondaryColor) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Background circle
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: secondaryColor,
                    ),
                  ),
                );
              },
            ),
            // Family icon with rotation
            Transform.rotate(
              angle: _rotationAnimation.value * 0.5,
              child: Container(
                width: widget.size * 0.6,
                height: widget.size * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.family_restroom,
                  color: Colors.white,
                  size: widget.size * 0.3,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLockAnimation(Color primaryColor, Color secondaryColor) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Rotating border
            Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor, width: 3),
                ),
              ),
            ),
            // Lock icon
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: widget.size * 0.3,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDotsAnimation(Color primaryColor, Color secondaryColor) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final animValue = (_controller.value + delay) % 1.0;
            final scale =
                0.5 + 0.5 * (1 - (animValue - 0.5).abs() * 2).clamp(0.0, 1.0);

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }
}

// Custom painter for loading ring
class _LoadingRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _LoadingRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    const startAngle = -3.14159 / 2;
    final sweepAngle = 2 * 3.14159 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Loading overlay widget
