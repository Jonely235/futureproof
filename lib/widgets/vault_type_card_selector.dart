import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_colors.dart';
import '../domain/entities/vault_entity.dart';

/// Vault type card selector - card-based type selection
///
/// Displays vault types as cards with icons instead of radio buttons.
/// Used in vault creation screen for better UX.
class VaultTypeCardSelector extends StatelessWidget {
  final VaultType selectedType;
  final Function(VaultType) onTypeSelected;

  const VaultTypeCardSelector({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vault Type',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.gray700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: VaultType.values.map((type) {
            final isSelected = selectedType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTypeSelected(type);
                },
                child: _buildTypeCard(type, isSelected),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeCard(VaultType type, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          // Card container
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppColors.fintechTeal.withOpacity(0.2),
                        AppColors.fintechTeal.withOpacity(0.05),
                      ],
                    )
                  : null,
              color: isSelected ? null : AppColors.gray100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.fintechTeal
                    : Colors.transparent,
                width: isSelected ? 2 : 0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.fintechTeal.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                type.icon,
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Type name
          Text(
            type.displayName,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.fintechTeal : AppColors.gray700,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
