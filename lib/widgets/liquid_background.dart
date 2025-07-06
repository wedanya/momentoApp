import 'package:flutter/material.dart';

class LiquidBackground extends StatefulWidget {
  final Widget child;

  const LiquidBackground({super.key, required this.child});

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

// We need SingleTickerProviderStateMixin to provide a Ticker for AnimationController
class _LiquidBackgroundState extends State<LiquidBackground> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<AlignmentGeometry> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, // Provided by SingleTickerProviderStateMixin
      duration: const Duration(seconds: 8), // Duration for one full animation cycle
    )..repeat(reverse: true); // Repeat the animation back and forth

    // Define the animation for the gradient's begin and end alignments
    _animation = TweenSequence<AlignmentGeometry>([
      TweenSequenceItem(
        tween: Tween<AlignmentGeometry>(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        weight: 1, // Represents 1/3 of the animation duration for this segment
      ),
      TweenSequenceItem(
        tween: Tween<AlignmentGeometry>(
          begin: Alignment.bottomRight,
          end: Alignment.topRight,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<AlignmentGeometry>(
          begin: Alignment.topRight,
          end: Alignment.topLeft,
        ),
        weight: 1,
      ),
    ]).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose(); // Dispose the controller to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: _animation.value, // Animated begin alignment
              end: -_animation.value, // Animated end alignment (opposite of begin)
              colors: const [
                Color.fromARGB(255, 70, 130, 180), // Deeper blue
                Color.fromARGB(255, 100, 150, 200), // Medium blue
                // Add more colors if you want a more complex gradient
                // const Color.fromARGB(255, 120, 170, 220), // Lighter blue
              ],
            ),
          ),
          child: widget.child, // Your actual content (AuthScreen, DiaryListScreen) will be placed here
        );
      },
      child: widget.child, // This 'child' is passed to the builder as its 'child' argument
    );
  }
}