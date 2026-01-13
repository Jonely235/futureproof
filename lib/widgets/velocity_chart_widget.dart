import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/spending_analysis.dart';

/// Spend Velocity Chart Widget
///
/// Displays spending trends as a smooth Bézier curve line chart
/// with gradient fill and refined editorial aesthetics.
class VelocityChartWidget extends StatelessWidget {
  final List<MonthlySpending> data;
  final double height;

  const VelocityChartWidget({
    super.key,
    required this.data,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data to display',
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFF9E9E9E),
            ),
          ),
        ),
      );
    }

    return Container(
      height: height,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A0A0A).withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _VelocityChartPainter(data: data),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _VelocityChartPainter extends CustomPainter {
  final List<MonthlySpending> data;

  _VelocityChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 24);
    final chartWidth = size.width - padding.horizontal;
    final chartHeight = size.height - padding.vertical;

    // Find min/max values
    final values = data.map((d) => d.amount).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final valueRange = maxValue - minValue;

    // Calculate point positions
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = padding.left + (i / (data.length - 1)) * chartWidth;
      final normalizedValue =
          valueRange > 0 ? (data[i].amount - minValue) / valueRange : 0.5;
      final y = padding.top + chartHeight - (normalizedValue * chartHeight);
      points.add(Offset(x, y));
    }

    // Create smooth Bézier curve path
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final currentPoint = points[i];
      final nextPoint = points[i + 1];

      // Control points for smooth curve
      final controlPoint1 = Offset(
        currentPoint.dx + (nextPoint.dx - currentPoint.dx) * 0.5,
        currentPoint.dy,
      );
      final controlPoint2 = Offset(
        currentPoint.dx + (nextPoint.dx - currentPoint.dx) * 0.5,
        nextPoint.dy,
      );

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        nextPoint.dx,
        nextPoint.dy,
      );
    }

    // Draw gradient fill
    final fillPath = Path()..addPath(path, Offset.zero);
    fillPath.lineTo(points.last.dx, size.height - padding.bottom);
    fillPath.lineTo(points.first.dx, size.height - padding.bottom);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0A0A0A).withOpacity(0.2),
        const Color(0xFF0A0A0A).withOpacity(0.02),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(
        fillPath,
        Paint()
          ..shader = gradient
          ..style = PaintingStyle.fill);

    // Draw line
    final linePaint = Paint()
      ..color = const Color(0xFF0A0A0A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Draw points
    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      // Outer glow
      canvas.drawCircle(
        point,
        8,
        Paint()
          ..color = const Color(0xFF0A0A0A).withOpacity(0.15)
          ..style = PaintingStyle.fill,
      );

      // Inner circle
      canvas.drawCircle(
        point,
        5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );

      // Center dot
      canvas.drawCircle(
        point,
        3,
        Paint()
          ..color = const Color(0xFF0A0A0A)
          ..style = PaintingStyle.fill,
      );
    }

    // Draw month labels
    final textStyle = GoogleFonts.spaceGrotesk(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF6B6B6B),
    );

    for (int i = 0; i < data.length; i++) {
      final point = points[i];
      final parts = data[i].month.split('-');
      final monthLabel = _getMonthAbbreviation(int.parse(parts[1]));

      final textPainter = TextPainter(
        text: TextSpan(text: monthLabel, style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final textX = point.dx - textPainter.width / 2;
      final textY = size.height - 8;

      textPainter.paint(canvas, Offset(textX, textY));
    }

    // Draw value labels for first and last points
    _drawValueLabel(
      canvas,
      points.first,
      data.first.amount,
      maxValue,
      minValue,
      isLeft: true,
    );

    _drawValueLabel(
      canvas,
      points.last,
      data.last.amount,
      maxValue,
      minValue,
      isLeft: false,
    );
  }

  void _drawValueLabel(
    Canvas canvas,
    Offset point,
    double value,
    double maxValue,
    double minValue, {
    required bool isLeft,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '\$${value.toStringAsFixed(0)}',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0A0A0A),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final textX = isLeft ? point.dx : point.dx - textPainter.width;
    final textY = point.dy - 28;

    // Background for text
    final bgRect = Rect.fromLTWH(
      textX - 4,
      textY - 4,
      textPainter.width + 8,
      textPainter.height + 8,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
      Paint()
        ..color = const Color(0xFF0A0A0A).withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    textPainter.paint(canvas, Offset(textX, textY));
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  @override
  bool shouldRepaint(_VelocityChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
