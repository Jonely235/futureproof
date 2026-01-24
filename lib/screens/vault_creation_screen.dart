import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../design/design_tokens.dart';
import '../domain/entities/vault_entity.dart';
import '../providers/vault_provider.dart';
import '../widgets/vault_card_widget.dart';
import '../widgets/vault_type_card_selector.dart';

/// Vault creation screen - redesigned modal with live preview
///
/// Features:
/// - Modal bottom sheet presentation
/// - Live preview card that updates as you type
/// - Card-based vault type selector
/// - Collapsible sections for progressive disclosure
/// - Color and icon customization
class VaultCreationScreen extends StatefulWidget {
  const VaultCreationScreen({super.key});

  @override
  State<VaultCreationScreen> createState() => _VaultCreationScreenState();
}

class _VaultCreationScreenState extends State<VaultCreationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  VaultType _selectedType = VaultType.personal;
  Color _selectedColor = AppColors.fintechTeal;
  String _selectedIcon = '📁';
  double _monthlyIncome = 0.0;
  double _savingsGoal = 0.0;

  // Collapsible section states
  bool _basicExpanded = true;
  bool _appearanceExpanded = false;
  bool _settingsExpanded = false;

  // Available colors
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

  // Available icons
  static const List<String> _vaultIcons = [
    '📁', '💼', '🏠', '💰', '💎', '🚀',
    '🎯', '⭐', '🔥', '💡', '📊', '📈',
    '💳', '🏦', '💵', '🪙',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {}); // Rebuild to update preview
    });
  }

  @override
  void dispose() {
    _nameController.removeListener(() {});
    _nameController.dispose();
    super.dispose();
  }

  VaultEntity get _previewVault {
    return VaultEntity(
      id: 'preview',
      name: _nameController.text.trim().isEmpty ? 'My Vault' : _nameController.text.trim(),
      type: _selectedType,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      transactionCount: 0,
      isActive: true,
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final vaultProvider = context.read<VaultProvider>();

    final vault = await vaultProvider.createVault(
      name: _nameController.text.trim(),
      type: _selectedType,
      settings: VaultSettings(
        monthlyIncome: _monthlyIncome,
        savingsGoal: _savingsGoal,
        themeIndex: _vaultColors.indexOf(_selectedColor),
      ),
    );

    if (vault != null && mounted) {
      Navigator.pop(context, vault);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusXxl)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create New Vault',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 16),

                  // Live Preview Card
                  _buildPreviewCard(),

                  const SizedBox(height: 24),

                  // Collapsible Sections
                  _buildBasicSection(),
                  _buildAppearanceSection(),
                  _buildSettingsSection(),

                  const SizedBox(height: 100), // Space for buttons
                ],
              ),
            ),
          ),

          // Bottom action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gray700,
                        side: BorderSide(color: AppColors.gray300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.fintechTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        ),
                      ),
                      child: Text(
                        'Create Vault',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.gray500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        VaultCardWidget(
          vault: _previewVault,
          isActive: true,
          enableGestures: false,
        ),
      ],
    );
  }

  Widget _buildBasicSection() {
    return _buildCollapsibleSection(
      title: 'Basic Information',
      isExpanded: _basicExpanded,
      onTap: () => setState(() => _basicExpanded = !_basicExpanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Vault name
          Text(
            'Vault Name',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            style: GoogleFonts.spaceGrotesk(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'My Personal Finances',
              hintStyle: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                color: AppColors.gray500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a vault name';
              }
              if (value.trim().length < 2) {
                return 'Vault name must be at least 2 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Vault type
          VaultTypeCardSelector(
            selectedType: _selectedType,
            onTypeSelected: (type) {
              setState(() => _selectedType = type);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return _buildCollapsibleSection(
      title: 'Appearance',
      isExpanded: _appearanceExpanded,
      onTap: () => setState(() => _appearanceExpanded = !_appearanceExpanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Color picker
          Text(
            'Accent Color',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
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
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedColor = color);
                },
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
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Icon picker
          Text(
            'Icon',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _vaultIcons.length,
            itemBuilder: (context, index) {
              final icon = _vaultIcons[index];
              final isSelected = _selectedIcon == icon;
              return InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedIcon = icon);
                },
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.fintechTeal.withOpacity(0.1)
                        : AppColors.gray100,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    border: Border.all(
                      color: isSelected ? AppColors.fintechTeal : Colors.transparent,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return _buildCollapsibleSection(
      title: 'Settings (Optional)',
      isExpanded: _settingsExpanded,
      onTap: () => setState(() => _settingsExpanded = !_settingsExpanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Monthly income
          Text(
            'Monthly Income',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.spaceGrotesk(fontSize: 15),
            decoration: InputDecoration(
              hintText: '5000',
              hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.gray500),
              prefixText: '\$ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (value) {
              _monthlyIncome = double.tryParse(value) ?? 0.0;
            },
          ),

          const SizedBox(height: 16),

          // Savings goal
          Text(
            'Savings Goal',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.spaceGrotesk(fontSize: 15),
            decoration: InputDecoration(
              hintText: '1000',
              hintStyle: GoogleFonts.spaceGrotesk(color: AppColors.gray500),
              prefixText: '\$ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (value) {
              _savingsGoal = double.tryParse(value) ?? 0.0;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusMd)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.expand_more,
                      color: isExpanded ? AppColors.fintechTeal : AppColors.gray700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }
}
