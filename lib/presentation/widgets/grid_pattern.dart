import 'package:flutter/material.dart';
 
class GridPattern extends StatelessWidget {
  final Color color;
  final double spacing;

  const GridPattern({
    super.key,
    this.color = const Color(0x1A808080),
    this.spacing = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GridPainter(color: color, spacing: spacing),
      child: Container(),
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  final double spacing;

  GridPainter({required this.color, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

