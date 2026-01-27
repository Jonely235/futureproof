import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../config/app_colors.dart';
import '../design/design_tokens.dart';
import '../config/app_strings.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../providers/anti_fragile_wallet_provider.dart';
import '../providers/vault_provider.dart';
import '../services/icloud_sync_manager.dart';
import '../utils/validators.dart';

/// Add Expense Screen - Number-First Experience
///
/// Design Philosophy: Amount is the most important input
/// - Large, prominent number display
/// - Category selection as visual bottom sheet
/// - Minimal distractions, focused entry
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _focusNode = FocusNode();

  String _selectedCategory = AppStrings.groceries;
  bool _isExpense = true;
  bool _isSaving = false;

  final List<Map<String, String>> _categories = [
    {
      'name': AppStrings.groceries,
      'emoji': AppStrings.groceriesEmoji,
      'color': '4CAF50'
    },
    {
      'name': AppStrings.diningOut,
      'emoji': AppStrings.diningOutEmoji,
      'color': 'FF9800'
    },
    {
      'name': AppStrings.transport,
      'emoji': AppStrings.transportEmoji,
      'color': '2196F3'
    },
    {
      'name': AppStrings.entertainment,
      'emoji': AppStrings.entertainmentEmoji,
      'color': '9C27B0'
    },
    {
      'name': AppStrings.health,
      'emoji': AppStrings.healthEmoji,
      'color': 'F44336'
    },
    {
      'name': AppStrings.shopping,
      'emoji': AppStrings.shoppingEmoji,
      'color': 'E91E63'
    },
    {
      'name': AppStrings.subscriptions,
      'emoji': AppStrings.subscriptionsEmoji,
      'color': '00BCD4'
    },
    {
      'name': AppStrings.housing,
      'emoji': AppStrings.housingEmoji,
      'color': '795548'
    },
    {
      'name': AppStrings.other,
      'emoji': AppStrings.otherEmoji,
      'color': '9E9E9E'
    },
  ];

  /// Map display category names to internal category names
  String _mapDisplayCategoryToInternal(String displayName) {
    final mapping = {
      AppStrings.groceries: 'groceries',
      AppStrings.diningOut: 'dining',
      AppStrings.transport: 'transport',
      AppStrings.entertainment: 'entertainment',
      AppStrings.health: 'health',
      AppStrings.shopping: 'shopping',
      AppStrings.subscriptions: 'subscriptions',
      AppStrings.housing: 'housing',
      AppStrings.other: 'other', // Fixed: was 'housing'
    };
    return mapping[displayName] ?? 'other'; // Fixed: better default
  }

  @override
  void initState() {
    super.initState();
    // Auto-focus amount field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Show friction dialog when user tries to add a "Want" expense in Red Mode
  Future<bool> _showWarModeFrictionDialog(String category, double runwayDays) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: DesignTokens.borderRadiusLg),
        title: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'War Mode Active',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: DesignTokens.borderRadiusSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 20, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Text(
                        '${runwayDays.toStringAsFixed(0)} days of cash left',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This expense puts you at risk. Consider if this is truly necessary.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      color: AppColors.gray700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Do you want to proceed anyway?',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Never mind',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.gray700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: DesignTokens.borderRadiusSm,
              ),
            ),
            child: Text(
              'I understand, proceed',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _saveExpense() async {
    _focusNode.unfocus(); // Dismiss keyboard before saving

    // Validate amount with proper bounds checking
    final validation = MoneyValidator.validate(_amountController.text);
    if (!validation.isValid) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.errorMessage ?? 'Invalid amount'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final amount = validation.value!;

    setState(() {
      _isSaving = true;
    });

    try {
      final transaction = Transaction(
        id: const Uuid().v4(),
        amount: _isExpense ? -amount : amount,
        category: _mapDisplayCategoryToInternal(_selectedCategory),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        date: DateTime.now(),
        householdId: '',
        createdAt: DateTime.now(),
      );

      final provider = context.read<TransactionProvider>();
      final vaultProvider = context.read<VaultProvider>();

      final success = await provider.addTransaction(
        transaction,
        onCompleted: (t) {
          // Trigger debounced iCloud sync after transaction is added
          final activeVault = vaultProvider.activeVault;
          if (activeVault != null) {
            final transactionProviders = <String, TransactionProvider>{
              activeVault.id: provider,
            };

            ICloudSyncManager.instance.scheduleSync(
              reason: SyncReason.transactionAdded,
              vaultProvider: vaultProvider,
              transactionProviders: transactionProviders,
              detail: '\$${t.amount.toStringAsFixed(2)}',
            );
          }
        },
      );

      if (!success) {
        throw Exception(provider.error ?? 'Failed to save transaction');
      }

      HapticFeedback.lightImpact();

      if (mounted) {
        final categoryIndex = _categories.indexWhere(
          (c) => c['name'] == _selectedCategory,
        );
        final category = categoryIndex >= 0
            ? _categories[categoryIndex]
            : _categories.first; // Fallback to first category

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(
                  '${category['emoji']} ',
                  style: const TextStyle(fontSize: 20),
                ),
                Expanded(
                  child: Text(
                    '${_isExpense ? "Expense" : "Income"} saved',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.black,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showCategoryPicker() async {
    _focusNode.unfocus(); // Dismiss keyboard before showing picker
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CategoryBottomSheet(
        categories: _categories,
        selectedCategory: _selectedCategory,
        onSelect: (category) async {
          final internalCategory = _mapDisplayCategoryToInternal(category);

          // Check if this category should be restricted in War Mode
          final walletProvider = context.read<AntiFragileWalletProvider>();
          if (walletProvider.isCategoryRestricted(internalCategory)) {
            final warMode = walletProvider.warMode;
            if (warMode != null) {
              // Show friction dialog
              final confirmed = await _showWarModeFrictionDialog(
                category,
                warMode.runwayDays,
              );
              if (!confirmed) {
                return; // User cancelled, don't select category
              }
              HapticFeedback.heavyImpact(); // Acknowledge the risk
            }
          }

          setState(() {
            _selectedCategory = category;
          });
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryIndex = _categories.indexWhere(
      (c) => c['name'] == _selectedCategory,
    );
    final selectedCategoryData = categoryIndex >= 0
        ? _categories[categoryIndex]
        : _categories.first; // Fallback to first category

    return Scaffold(
      backgroundColor: DesignTokens.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add ${_isExpense ? "Expense" : "Income"}',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Expense/Income Toggle
          TextButton(
            onPressed: () {
              setState(() {
                _isExpense = !_isExpense;
              });
              HapticFeedback.lightImpact();
            },
            child: Text(
              _isExpense ? 'Income' : 'Expense',
              style: GoogleFonts.spaceGrotesk(
                color: _isExpense ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          final currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: SafeArea(
          child: Column(
            children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),

                    // Large Amount Input
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Currency Symbol
                          Text(
                            '\$',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 48,
                              color: AppColors.black,
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          // Amount Field
                          TextField(
                            controller: _amountController,
                            focusNode: _focusNode,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 64,
                              fontWeight: FontWeight.w500,
                              color: AppColors.black,
                              letterSpacing: -2,
                            ),
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                color: AppColors.gray300,
                                fontSize: 64,
                                fontWeight: FontWeight.w300,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Category Selector
                    GestureDetector(
                      onTap: _showCategoryPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: DesignTokens.borderRadiusLg,
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              selectedCategoryData['emoji']!,
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              selectedCategoryData['name']!,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: AppColors.black,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: AppColors.gray700,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Note Input
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: 'Add a note (optional)',
                        hintStyle: GoogleFonts.spaceGrotesk(
                          color: AppColors.gray500,
                          fontSize: 15,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: DesignTokens.borderRadiusMd,
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: 2,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        color: AppColors.black,
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Save Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.border,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: DesignTokens.borderRadiusLg,
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.black),
                          ),
                        )
                      : Text(
                          'Save ${_isExpense ? "Expense" : "Income"}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Category Selection Bottom Sheet
class _CategoryBottomSheet extends StatelessWidget {
  final List<Map<String, String>> categories;
  final String selectedCategory;
  final Function(String) onSelect;

  const _CategoryBottomSheet({
    required this.categories,
    required this.selectedCategory,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusXxl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text(
                  'Select Category',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Category Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category['name'] == selectedCategory;
              final color = _parseCategoryColor(category);

              return GestureDetector(
                onTap: () => onSelect(category['name']!),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withOpacity(0.15)
                        : AppColors.offWhite,
                    borderRadius: DesignTokens.borderRadiusLg,
                    border: Border.all(
                      color: isSelected ? color : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category['emoji']!,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['name']!,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.black,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Safely parse category color hex string.
  /// Returns a fallback gray color if parsing fails.
  Color _parseCategoryColor(Map<String, String> category) {
    final colorHex = category["color"];
    if (colorHex == null || colorHex.length != 6) {
      return AppColors.gray700;
    }
    try {
      return Color(int.parse('0xFF$colorHex'));
    } on FormatException {
      return AppColors.gray700;
    }
  }
}
