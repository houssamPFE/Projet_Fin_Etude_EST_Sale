import 'package:flutter/material.dart';

class GlowingIconContainer extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final bool isRounded;

  const GlowingIconContainer({
    super.key,
    required this.icon,
    this.size = 120,
    this.color = const Color(0xFF6366F1), // Default Nexora Purple/Blue
    this.isRounded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Intense core glow
        Container(
          width: size * 0.8,
          height: size * 0.8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(120),
                blurRadius: 40,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: color.withAlpha(60),
                blurRadius: 80,
                spreadRadius: 30,
              ),
            ],
          ),
        ),
        
        // Outer glassmorphic border/container
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isRounded ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isRounded ? BorderRadius.circular(size * 0.3) : null,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha(40),
                Colors.white.withAlpha(5),
              ],
            ),
            border: Border.all(
              color: Colors.white.withAlpha(30),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              size: size * 0.45,
              color: Colors.white,
            ),
          ),
        ),
        
        // Subtle inner ring reflection
        Container(
          width: size - 10,
          height: size - 10,
          decoration: BoxDecoration(
            shape: isRounded ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isRounded ? BorderRadius.circular((size - 10) * 0.3) : null,
            border: Border.all(
              color: color.withAlpha(150),
              width: 1,
            ),
          ),
        ),
      ],
    );
  }
}
