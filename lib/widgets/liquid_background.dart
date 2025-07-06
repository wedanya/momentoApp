import 'package:flutter/material.dart';
import 'dart:math' as math; // For sin and cos

class LiquidBackground extends StatefulWidget {
  final Widget child; // The content to display over the background

  const LiquidBackground({
    super.key,
    required this.child,
  });

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // Define colors for your liquid effect
  final List<Color> _colors = [
    Colors.purple.shade900.withOpacity(0.6),
    Colors.blue.shade900.withOpacity(0.6),
    Colors.deepPurple.shade900.withOpacity(0.6),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Duration for one full animation cycle
    )..repeat(); // Repeat the animation indefinitely
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // This container will fill the available space and draw the background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _colors[0],
                    _colors[1],
                    _colors[2],
                  ],
                ),
              ),
              child: CustomPaint(
                painter: LiquidPainter(_controller.value),
                child: Container(), // A dummy child to ensure CustomPaint takes space
              ),
            ),
            // The actual content of the page is placed on top
            Positioned.fill(
              child: widget.child,
            ),
          ],
        );
      },
      child: widget.child, // Optimisation: child is built once
    );
  }
}

class LiquidPainter extends CustomPainter {
  final double animationValue;

  LiquidPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1) // Color of the "liquid" shapes
      ..style = PaintingStyle.fill;

    // A simple way to create dynamic shapes:
    // We'll create a few undulating "waves" or blobs
    final path = Path();
    path.moveTo(0, size.height * 0.8 * (1 + 0.1 * math.sin(animationValue * 2 * math.pi)));

    for (double i = 0; i <= size.width; i += size.width / 50) {
      path.lineTo(
        i,
        size.height * 0.8 + 
            size.height * 0.1 * math.sin((i / size.width * 2 * math.pi) + animationValue * 2 * math.pi) +
            size.height * 0.05 * math.cos((i / size.width * 3 * math.pi) + animationValue * 2 * math.pi * 0.5) // Second wave for more complexity
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // Add another layer for more depth
    final path2 = Path();
    path2.moveTo(0, size.height * 0.7 * (1 + 0.1 * math.cos(animationValue * 2 * math.pi * 0.7)));
    for (double i = 0; i <= size.width; i += size.width / 50) {
      path2.lineTo(
        i,
        size.height * 0.7 + 
            size.height * 0.08 * math.cos((i / size.width * 2.5 * math.pi) + animationValue * 2 * math.pi * 1.2) +
            size.height * 0.04 * math.sin((i / size.width * 3.5 * math.pi) + animationValue * 2 * math.pi * 0.8)
      );
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint..color = Colors.white.withOpacity(0.07)); // Slightly different color/opacity
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return (oldDelegate as LiquidPainter).animationValue != animationValue;
  }
}