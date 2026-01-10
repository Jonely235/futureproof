import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import 'package:uuid/uuid.dart';

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

  String _selectedCategory = 'Groceries';
  bool _isExpense = true;
  bool _isSaving = false;

  final List<Map<String, String>> _categories = [
    {'name': 'Groceries', 'emoji': '🛒', 'color': '4CAF50'},
    {'name': 'Dining Out', 'emoji': '🍽️', 'color': 'FF9800'},
    {'name': 'Transport', 'emoji': '🚗', 'color': '2196F3'},
    {'name': 'Entertainment', 'emoji': '🎭', 'color': '9C27B0'},
    {'name': 'Health', 'emoji': '💊', 'color': 'F44336'},
    {'name': 'Shopping', 'emoji': '🛍️', 'color': 'E91E63'},
    {'name': 'Subscriptions', 'emoji': '📱', 'color': '00BCD4'},
    {'name': 'Housing', 'emoji': '🏠', 'color': '795548'},
    {'name': 'Other', 'emoji': '💸', 'color': '9E9E9E'},
  ];

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

  void _saveExpense() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Color(0xFFD4483A),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final transaction = Transaction(
        id: const Uuid().v4(),
        amount: _isExpense ? -amount : amount,
        category: _selectedCategory,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        date: DateTime.now(),
        householdId: '',
        createdAt: DateTime.now(),
      );

      final provider = context.read<TransactionProvider>();
      final success = await provider.addTransaction(transaction);

      if (!success) {
        throw Exception(provider.error ?? 'Failed to save transaction');
      }

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
            backgroundColor: const Color(0xFF0A0A0A),
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
            backgroundColor: const Color(0xFFD4483A),
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

  void _showCategoryPicker() {
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
          Navigator.pop(context);
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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF0A0A0A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add ${_isExpense ? "Expense" : "Income"}',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFF0A0A0A),
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
                color: _isExpense
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFD4483A),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
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
                              color: const Color(0xFF0A0A0A),
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
                              color: const Color(0xFF0A0A0A),
                              letterSpacing: -2,
                            ),
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              hintStyle: TextStyle(
                                color: Color(0xFFD4D4D4),
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
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE0E0E0),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0A0A0A).withOpacity(0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
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
                                color: const Color(0xFF0A0A0A),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFF6B6B6B),
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
                          color: const Color(0xFF9E9E9E),
                          fontSize: 15,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: 2,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        color: const Color(0xFF0A0A0A),
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
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0A0A0A).withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A0A0A),
                    foregroundColor: const Color(0xFFFFFFFF),
                    disabledBackgroundColor: const Color(0xFFE0E0E0),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
                                AlwaysStoppedAnimation<Color>(Color(0xFF0A0A0A)),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
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
                    color: const Color(0xFF0A0A0A),
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
                        : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? color : const Color(0xFFE0E0E0),
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
                          color: const Color(0xFF0A0A0A),
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
