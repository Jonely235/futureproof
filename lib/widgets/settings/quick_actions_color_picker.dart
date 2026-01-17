import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_colors.dart';

/// Quick Actions Color Picker Widget
///
/// Curated color picker with:
/// - 8 preset colors
/// - Live preview
/// - Visual feedback for selected color
class QuickActionsColorPicker extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorSelected;

  static const List<Color> curatedColors = [
    Color(0xFF00BFA5),  // Teal
    Color(0xFF1A237E),  // Navy
    Color(0xFF2196F3),  // Blue
    Color(0xFF9C27B0),  // Purple
    Color(0xFFE91E63),  // Pink
    Color(0xFFF44336),  // Red
    Color(0xFFFF9800),  // Orange
    Color(0xFF4CAF50),  // Green
  ];

  const QuickActionsColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions Color',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: curatedColors.length,
          itemBuilder: (context, index) {
            final color = curatedColors[index];
            final isSelected = selectedColor.value == color.value;

            return GestureDetector(
              onTap: () => onColorSelected(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: color.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      )
                    : null,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Preview
        _buildPreview(),
      ],
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: AppColors.gray700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPreviewButton('Add Expense', Icons.add, selectedColor),
              const SizedBox(width: 8),
              _buildPreviewButton('Analytics', Icons.bar_chart, selectedColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewButton(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
