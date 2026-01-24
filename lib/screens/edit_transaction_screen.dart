import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_colors.dart';
import '../design/design_tokens.dart';
import '../config/app_strings.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

/// Edit Transaction Screen
///
/// A refined, modern interface for editing existing transactions
/// Features bold typography, elegant spacing, and intuitive category selection
class EditTransactionScreen extends StatefulWidget {
  final Transaction transaction;

  const EditTransactionScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  final _focusNode = FocusNode();

  late String _selectedCategory;
  late bool _isExpense;
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
      AppStrings.other: 'other',
    };
    return mapping[displayName] ?? 'other';
  }

  /// Map internal category names to display category names
  String _mapInternalCategoryToDisplay(String internalName) {
    final mapping = {
      'groceries': AppStrings.groceries,
      'dining': AppStrings.diningOut,
      'transport': AppStrings.transport,
      'entertainment': AppStrings.entertainment,
      'health': AppStrings.health,
      'shopping': AppStrings.shopping,
      'subscriptions': AppStrings.subscriptions,
      'housing': AppStrings.housing,
      'income': 'Income',
    };
    return mapping[internalName] ?? AppStrings.other;
  }

  @override
  void initState() {
    super.initState();

    // Pre-populate form with existing transaction data
    _amountController = TextEditingController(
      text: widget.transaction.amount.abs().toStringAsFixed(2),
    );
    _noteController = TextEditingController(
      text: widget.transaction.note ?? '',
    );
    _selectedCategory = _mapInternalCategoryToDisplay(widget.transaction.category);
    _isExpense = widget.transaction.amount < 0;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    _focusNode.unfocus();
    HapticFeedback.lightImpact();

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid amount',
            style: GoogleFonts.spaceGrotesk(),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create updated transaction
      final updatedTransaction = Transaction(
        id: widget.transaction.id,
        amount: _isExpense ? -amount : amount,
        category: _mapDisplayCategoryToInternal(_selectedCategory),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        date: widget.transaction.date,
        householdId: widget.transaction.householdId,
        createdAt: widget.transaction.createdAt,
      );

      // Update in local database
      final dbService = DatabaseService();
      await dbService.updateTransaction(updatedTransaction);

      // Note: Cloud sync removed in MVP (Phase 1)

      HapticFeedback.lightImpact();

      if (mounted) {
        final category = _categories.firstWhere(
          (c) => c['name'] == _selectedCategory,
        );

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
                    'Transaction updated',
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

        // Return to previous screen with success
        Navigator.pop(context, true);
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error updating transaction: $e',
              style: GoogleFonts.spaceGrotesk(),
            ),
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

  void _deleteTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: DesignTokens.borderRadiusLg),
        title: Text(
          'Delete Transaction?',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this transaction? This cannot be undone.',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            color: AppColors.gray700,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
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
              'Delete',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      HapticFeedback.mediumImpact();

      try {
        // Delete from local database
        final dbService = DatabaseService();
        await dbService.deleteTransaction(widget.transaction.id);

        // Note: Cloud sync removed in MVP (Phase 1)

        HapticFeedback.lightImpact();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.delete_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Transaction deleted',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.black,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, false); // Return to history
        }
      } catch (e) {
        HapticFeedback.heavyImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error deleting: $e',
                style: GoogleFonts.spaceGrotesk(),
              ),
              backgroundColor: AppColors.danger,
            ),
          );
        }
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
        onSelect: (category) {
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
    final selectedCategoryData = _categories.firstWhere(
      (c) => c['name'] == _selectedCategory,
    );

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
          'Edit Transaction',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: _deleteTransaction,
            tooltip: 'Delete',
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),

                        // Original Date Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: AppColors.gray700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.transaction.date.month}/${widget.transaction.date.day}/${widget.transaction.date.year}',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray700,
                                ),
                              ),
                            ],
                          ),
                        ),

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
                              TextFormField(
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
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an amount';
                                  }
                                  final amount = double.tryParse(value);
                                  if (amount == null || amount <= 0) {
                                    return 'Please enter a valid amount';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Expense/Income Toggle
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Expense Option
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _isExpense = true;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isExpense
                                        ? AppColors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                                    boxShadow: _isExpense
                                        ? [
                                            BoxShadow(
                                              color: AppColors.shadow,
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_upward,
                                        size: 18,
                                        color: _isExpense
                                            ? AppColors.danger
                                            : AppColors.gray700,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Expense',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: _isExpense
                                              ? AppColors.danger
                                              : AppColors.gray700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Income Option
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _isExpense = false;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_isExpense
                                        ? AppColors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                                    boxShadow: !_isExpense
                                        ? [
                                            BoxShadow(
                                              color: AppColors.shadow,
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_downward,
                                        size: 18,
                                        color: !_isExpense
                                            ? AppColors.success
                                            : AppColors.gray700,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Income',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: !_isExpense
                                              ? AppColors.success
                                              : AppColors.gray700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

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
                        TextFormField(
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
                              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 3,
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
                    onPressed: _isSaving ? null : _saveChanges,
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
                            'Save Changes',
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
              final color = Color(
                int.parse('0xFF${category["color"]}'),
              );

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
}
