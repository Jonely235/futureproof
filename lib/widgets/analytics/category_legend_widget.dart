import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';

/// Category Legend Widget
///
/// Interactive legend with:
/// - Color swatches
/// - Percentages
/// - Tap to select
/// - Visual feedback for selected category
class CategoryLegendWidget extends StatelessWidget {
  final Map<String, double> categorySpending;
  final double totalSpending;
  final String? selectedCategory;
  final Function(String)? onCategoryTap;

  const CategoryLegendWidget({
    super.key,
    required this.categorySpending,
    required this.totalSpending,
    this.selectedCategory,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: sortedCategories.map((entry) {
        final category = entry.key;
        final amount = entry.value;
        final percentage = (amount / totalSpending * 100);
        final color = AppColors.categoryColors[category] ??
            AppColors.categoryColors['Other']!;
        final isSelected = selectedCategory == category;

        return GestureDetector(
          onTap: () => onCategoryTap?.call(category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.15)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? color
                    : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  category,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
