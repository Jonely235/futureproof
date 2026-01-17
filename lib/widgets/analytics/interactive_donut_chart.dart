import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';

/// Interactive Donut Chart Widget
///
/// Modern animated donut chart with:
/// - Tap-to-select segments
/// - Animated entry
/// - Center text showing total
/// - Pop-out effect for selected segment
class InteractiveDonutChart extends StatefulWidget {
  final Map<String, double> categorySpending;
  final double totalSpending;
  final Function(String)? onCategoryTap;
  final double size;

  const InteractiveDonutChart({
    super.key,
    required this.categorySpending,
    required this.totalSpending,
    this.onCategoryTap,
    this.size = 280,
  });

  @override
  State<InteractiveDonutChart> createState() => _InteractiveDonutChartState();
}

class _InteractiveDonutChartState extends State<InteractiveDonutChart>
    with SingleTickerProviderStateMixin {
  String? _selectedCategory;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: DonutChartPainter(
            categorySpending: widget.categorySpending,
            selectedCategory: _selectedCategory,
            animation: _animation,
            totalSpending: widget.totalSpending,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: AppColors.gray700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${widget.totalSpending.toStringAsFixed(0)}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _selectedCategory != null
                        ? AppColors.categoryColors[_selectedCategory] ?? AppColors.fintechTeal
                        : AppColors.fintechTeal,
                  ),
                ),
                if (_selectedCategory != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _selectedCategory!,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: AppColors.gray700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final center = Offset(widget.size / 2, widget.size / 2);

    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    final outerRadius = widget.size / 2 - 10;
    final innerRadius = outerRadius * 0.65;

    // Check if tap is within the donut ring
    if (distance >= innerRadius && distance <= outerRadius + 10) {
      // Calculate angle
      double angle = math.atan2(dy, dx);
      if (angle < 0) angle += 2 * math.pi;

      // Adjust for starting position (-pi/2)
      angle = (angle + math.pi / 2) % (2 * math.pi);

      // Determine which category was tapped
      double currentAngle = 0;
      for (final entry in widget.categorySpending.entries) {
        final sweepAngle = (entry.value / widget.totalSpending) * 2 * math.pi;
        if (angle >= currentAngle && angle < currentAngle + sweepAngle) {
          setState(() {
            if (_selectedCategory == entry.key) {
              _selectedCategory = null; // Deselect
            } else {
              _selectedCategory = entry.key;
            }
            widget.onCategoryTap?.call(_selectedCategory ?? entry.key);
          });
          return;
        }
        currentAngle += sweepAngle;
      }
    } else {
      // Tap outside or in center - deselect
      setState(() {
        _selectedCategory = null;
      });
    }
  }
}

class DonutChartPainter extends CustomPainter {
  final Map<String, double> categorySpending;
  final String? selectedCategory;
  final Animation<double> animation;
  final double totalSpending;

  DonutChartPainter({
    required this.categorySpending,
    required this.selectedCategory,
    required this.animation,
    required this.totalSpending,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final innerRadius = radius * 0.65;

    double startAngle = -math.pi / 2; // Start from top

    // Handle empty data gracefully
    if (categorySpending.isEmpty || totalSpending <= 0) {
      // Draw empty donut with gray placeholder
      final paint = Paint()
        ..color = AppColors.gray300
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius - innerRadius
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        0,
        2 * math.pi,
        false,
        paint,
      );

      // Draw center hole
      final holePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        center,
        innerRadius,
        holePaint,
      );
      return;
    }

    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedCategories) {
      final category = entry.key;
      final amount = entry.value;
      final sweepAngle = (amount / totalSpending) * 2 * math.pi * animation.value;
      final isSelected = selectedCategory == category;
      final color = AppColors.categoryColors[category] ??
          AppColors.categoryColors['Other']!;

      // Draw segment
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? radius - innerRadius + 8 : radius - innerRadius
        ..strokeCap = StrokeCap.round;

      // Adjust radius for selected segment (pop out effect)
      final segmentRadius = isSelected ? radius + 4 : radius;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: segmentRadius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      // Draw subtle border between segments
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: segmentRadius),
        startAngle,
        sweepAngle,
        false,
        borderPaint,
      );

      startAngle += sweepAngle;
    }

    // Draw center hole
    final holePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      innerRadius,
      holePaint,
    );
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.animation.value != animation.value;
  }
}
