import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../design/design_tokens.dart';
import '../domain/entities/vault_entity.dart';
import '../providers/vault_provider.dart';

/// Vault edit screen - edit vault metadata
///
/// Allows editing vault name, type, description, income/savings goals,
/// and customizing vault colors and icons.
class VaultEditScreen extends StatefulWidget {
  final VaultEntity vault;

  const VaultEditScreen({
    super.key,
    required this.vault,
  });

  @override
  State<VaultEditScreen> createState() => _VaultEditScreenState();
}

class _VaultEditScreenState extends State<VaultEditScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _incomeController;
  late final TextEditingController _savingsController;

  late VaultType _selectedType;
  Color _selectedColor = AppColors.fintechTeal;
  String _selectedIcon = '📁';

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Available colors for vault customization
  static const List<Color> _vaultColors = [
    Color(0xFF00BFA5), // fintechTeal
    Color(0xFF2196F3), // Blue
    Color(0xFF9C27B0), // Purple
    Color(0xFFE91E63), // Pink
    Color(0xFFFF9800), // Orange
    Color(0xFFFFC107), // Amber
    Color(0xFF4CAF50), // Green
    Color(0xFFF44336), // Red
  ];

  // Available icons for vault customization
  static const List<String> _vaultIcons = [
    '📁', '💼', '🏠', '💰', '💎', '🚀',
    '🎯', '⭐', '🔥', '💡', '📊', '📈',
    '💳', '🏦', '💵', '🪙',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vault.name);
    _descriptionController = TextEditingController(text: '');
    _incomeController = TextEditingController(
      text: widget.vault.settings.monthlyIncome > 0
          ? widget.vault.settings.monthlyIncome.toStringAsFixed(2)
          : '',
    );
    _savingsController = TextEditingController(
      text: widget.vault.settings.savingsGoal > 0
          ? widget.vault.settings.savingsGoal.toStringAsFixed(2)
          : '',
    );
    _selectedType = widget.vault.type;
    _selectedIcon = widget.vault.type.icon;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _incomeController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<VaultProvider>();

      // Create updated vault
      final updatedVault = widget.vault.copyWith(
        name: _nameController.text.trim(),
        type: _selectedType,
        settings: VaultSettings(
          monthlyIncome:
              double.tryParse(_incomeController.text.trim()) ?? 0.0,
          savingsGoal:
              double.tryParse(_savingsController.text.trim()) ?? 0.0,
          themeIndex: widget.vault.settings.themeIndex,
        ),
      );

      final success = await provider.updateVault(updatedVault);

      if (success && mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, updatedVault);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vault "${updatedVault.name}" updated'),
            backgroundColor: AppColors.fintechTeal,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showArchiveDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusLg,
          ),
          title: Text(
            'Archive Vault',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Are you sure you want to archive "${widget.vault.name}"? It will be hidden from the main list but can be restored later.',
            style: GoogleFonts.spaceGrotesk(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.spaceGrotesk(),
              ),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                final provider = context.read<VaultProvider>();
                await provider.archiveVault(widget.vault.id);
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gray700,
              ),
              child: Text(
                'Archive',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusLg,
          ),
          title: Text(
            'Export Vault Data',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export all transactions and settings from "${widget.vault.name}"',
                style: GoogleFonts.spaceGrotesk(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildExportOption('CSV', Icons.table_chart,
                  'Export as spreadsheet'),
              const SizedBox(height: 8),
              _buildExportOption('JSON', Icons.code, 'Export as data file'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.spaceGrotesk(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExportOption(String format, IconData icon, String description) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$format export coming soon!'),
          ),
        );
      },
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gray200),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.fintechTeal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    format,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: AppColors.gray700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Vault',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.fintechTeal,
                    ),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.fintechTeal,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Vault name
            _buildSectionTitle('Vault Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              style: GoogleFonts.spaceGrotesk(),
              decoration: InputDecoration(
                hintText: 'Enter vault name',
                hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.gray500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a vault name';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Vault type
            _buildSectionTitle('Vault Type'),
            const SizedBox(height: 8),
            _buildTypeSelector(),

            const SizedBox(height: 24),

            // Monthly income (optional)
            _buildSectionTitle('Monthly Income (Optional)', '(for budgeting)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _incomeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.spaceGrotesk(),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.gray500),
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),

            const SizedBox(height: 24),

            // Savings goal (optional)
            _buildSectionTitle('Savings Goal (Optional)', '(per month)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _savingsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.spaceGrotesk(),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.gray500),
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),

            const SizedBox(height: 24),

            // Customization options
            _buildSectionTitle('Customization'),
            const SizedBox(height: 8),
            _buildColorSelector(),
            const SizedBox(height: 16),
            _buildIconSelector(),

            const SizedBox(height: 32),

            // Danger zone
            _buildSectionTitle('Actions'),
            const SizedBox(height: 8),
            _buildActionButtons(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, [String? subtitle]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.gray700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: AppColors.gray500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      children: VaultType.values.map((type) {
        final isSelected = _selectedType == type;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => setState(() => _selectedType = type),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.fintechTeal.withOpacity(0.1)
                    : Colors.white,
                border: Border.all(
                  color: isSelected ? AppColors.fintechTeal : AppColors.gray200,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Row(
                children: [
                  Text(
                    type.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      type.displayName,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.fintechTeal : AppColors.black,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.fintechTeal,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accent Color',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _vaultColors.map((color) {
              final isSelected = _selectedColor.value == color.value;
              return InkWell(
                onTap: () => setState(() => _selectedColor = color),
                borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIconSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Icon',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _vaultIcons.map((icon) {
              final isSelected = _selectedIcon == icon;
              return InkWell(
                onTap: () => setState(() => _selectedIcon = icon),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.fintechTeal.withOpacity(0.1)
                        : AppColors.gray100,
                    border: Border.all(
                      color: isSelected ? AppColors.fintechTeal : AppColors.gray200,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Archive button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showArchiveDialog,
            icon: const Icon(Icons.archive),
            label: Text(
              'Archive Vault',
              style: GoogleFonts.spaceGrotesk(),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gray700,
              side: BorderSide(color: AppColors.gray300),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Export button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showExportDialog,
            icon: const Icon(Icons.download),
            label: Text(
              'Export Data',
              style: GoogleFonts.spaceGrotesk(),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.fintechTeal,
              side: BorderSide(color: AppColors.fintechTeal),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
