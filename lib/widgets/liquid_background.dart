import 'package:flutter/material.dart';
import 'package:animated_background/animated_background.dart'; // Make sure this import is here

class LiquidBackground extends StatefulWidget {
  final Widget child;

  const LiquidBackground({super.key, required this.child});

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

// We need to use SingleTickerProviderStateMixin for the AnimatedBackground controller
class _LiquidBackgroundState extends State<LiquidBackground> with SingleTickerProviderStateMixin {
  // Define the particle options for the background
  final BubblesParticleOptions particleOptions = const BubblesParticleOptions(
    bubbleCount: 40,
    minTargetRadius: 5.0,
    maxTargetRadius: 20.0,
    bubbleFillColor: Color.fromARGB(150, 150, 200, 250),
    maxSpeed: 20,
    // You can experiment with more properties here for different visual effects
    // glow: true,
    // linesWidth: 1.0,
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      vsync: this, // Required for animations, provided by SingleTickerProviderStateMixin

      // Use the 'background' property for the static gradient behind the particles.
      // DecoratedBoxBackground is a specific type of background provided by the package
      // that takes a BoxDecoration (like a gradient).
      background: DecoratedBoxBackground(
        decoration: const BoxDecoration( // Make this const
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 70, 130, 180), // Deeper blue
              Color.fromARGB(255, 100, 150, 200), // Medium blue
            ],
          ),
        ),
      ),

      // The 'behaviour' property defines the animated elements (like bubbles).
      // RandomParticleBehaviour makes particles move randomly.
      behaviour: RandomParticleBehaviour(options: particleOptions),

      // The 'child' property is where your actual UI content (like the login form) goes.
      child: widget.child,
    );
  }
}