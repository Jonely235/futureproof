import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_colors.dart';
import '../domain/entities/vault_entity.dart';

/// Vault type filter chips widget
///
/// Provides filter chips for filtering vaults by type.
/// Displays horizontal scrollable list of chips.
class VaultTypeFilter extends StatelessWidget {
  final Set<VaultType> selectedTypes;
  final ValueChanged<VaultType> onToggle;
  final bool showLabel;

  const VaultTypeFilter({
    super.key,
    required this.selectedTypes,
    required this.onToggle,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final allTypes = VaultType.values;

    if (!showLabel) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: allTypes.map((type) => _buildChip(type)).toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Filter by type',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.gray700,
              ),
            ),
          ),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allTypes.map((type) => _buildChip(type)).toList(),
        ),
      ],
    );
  }

  Widget _buildChip(VaultType type) {
    final isSelected = selectedTypes.contains(type);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            type.icon,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            type.displayName,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.gray700,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onToggle(type),
      backgroundColor: Colors.white,
      selectedColor: AppColors.fintechTeal,
      checkmarkColor: Colors.white,
      elevation: 0,
      side: BorderSide(
        color: isSelected ? AppColors.fintechTeal : AppColors.gray300,
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    );
  }
}
