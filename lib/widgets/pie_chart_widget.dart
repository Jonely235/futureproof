import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Custom Pie Chart Widget
///
/// Displays spending breakdown by category as a pie chart.
/// Shows percentages with a color-coded legend.
class PieChartWidget extends StatelessWidget {
  final Map<String, double> data;
  final Map<String, String>? categoryEmojis;
  final double size;

  const PieChartWidget({
    super.key,
    required this.data,
    this.categoryEmojis,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        width: 200,
        height: 200,
        child: Center(
          child: Text('No data to display'),
        ),
      );
    }

    final total = data.values.fold(0.0, (a, b) => a + b);
    final colors = _generateColors(data.length);

    return Column(
      children: [
        // Pie chart
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _PieChartPainter(
              data: data,
              colors: colors,
              total: total,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Legend
        _buildLegend(colors, total),
      ],
    );
  }

  Widget _buildLegend(List<Color> colors, double total) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: data.entries.map((entry) {
        final index = data.keys.toList().indexOf(entry.key);
        final color = colors[index];
        final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
        final emoji = categoryEmojis?[entry.key] ?? '';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            if (emoji.isNotEmpty)
              Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
            if (emoji.isNotEmpty) const SizedBox(width: 4),
            Text(
              entry.key,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<Color> _generateColors(int count) {
    final baseColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];

    final colors = <Color>[];
    for (int i = 0; i < count; i++) {
      if (i < baseColors.length) {
        colors.add(baseColors[i]);
      } else {
        // Generate variations by adjusting hue
        final hue = (i * 137.5) % 360; // Golden angle approximation
        colors.add(
          HSVColor.fromAHSV(1.0, hue, 0.7, 0.9).toColor(),
        );
      }
    }
    return colors;
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<String, double> data;
  final List<Color> colors;
  final double total;

  _PieChartPainter({
    required this.data,
    required this.colors,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    double startAngle = -math.pi / 2; // Start from top

    final entries = data.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final value = entry.value;
      final sweepAngle = (value / total) * 2 * math.pi;

      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw white border between slices
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }

    // Draw center hole (donut chart style)
    final holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      radius * 0.5,
      holePaint,
    );

    // Draw total in center
    final textPainter = TextPainter(
      text: TextSpan(
        text: '\$${total.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_PieChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.colors != colors ||
        oldDelegate.total != total;
  }
}
