import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/colors.dart';

/// Blinking cursor widget for terminal effect in title
class BlinkingCursor extends StatefulWidget {
  final String cursor;
  final Duration duration;

  const BlinkingCursor({
    super.key,
    this.cursor = '>',
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Text(
            widget.cursor,
            style: GoogleFonts.shareTechMono(
              color: AppColors.neonGreen,
              fontSize: 20,
              letterSpacing: 1.0,
              shadows: [
                Shadow(
                  color: AppColors.neonGreen.withValues(alpha: 0.8),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
