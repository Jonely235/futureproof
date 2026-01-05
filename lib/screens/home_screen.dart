import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/finance_calculator.dart';
import '../services/database_service.dart';
import 'add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _transactions = [];
  double _monthlyIncome = 5000.0;
  double _savingsGoal = 1000.0;

  FinanceStatus? _status;
  bool _isLoading = false;
  bool _isLoadingTransactions = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoadingTransactions = true;
    });

    try {
      final dbService = DatabaseService();
      final transactions = await dbService.getAllTransactions();

      setState(() {
        _transactions = transactions;
        _isLoadingTransactions = false;
      });

      _calculateStatus();
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() {
        _isLoadingTransactions = false;
      });
    }
  }

  void _calculateStatus() {
    final totalExpenses = FinanceCalculator.calculateTotalExpenses(_transactions);

    setState(() {
      _status = FinanceCalculator.calculateStatus(
        monthlyIncome: _monthlyIncome,
        monthlyExpenses: totalExpenses,
        savingsGoal: _savingsGoal,
      );
    });
  }

  Future<void> _onAreWeOkayPressed() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate calculation time (replace with actual calculation)
    await Future.delayed(const Duration(milliseconds: 500));

    _calculateStatus();

    setState(() {
      _isLoading = false;
    });

    if (_status != null) {
      _showStatusDialog();
    }
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(
              _status!.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 8),
            const Text('Financial Health'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _status!.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status!.message,
                style: TextStyle(
                  fontSize: 16,
                  color: _status!.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Monthly Income', '\$${_monthlyIncome.toStringAsFixed(0)}'),
            _buildSummaryRow('Expenses', '\$${FinanceCalculator.calculateTotalExpenses(_transactions).toStringAsFixed(0)}'),
            _buildSummaryRow('Savings Goal', '\$${_savingsGoal.toStringAsFixed(0)}'),
            _buildSummaryRow(
              'Remaining',
              '\$${_status!.remaining.toStringAsFixed(0)}',
              valueColor: _status!.color,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FutureProof'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main "Are We Okay?" Button
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite,
                      size: 64,
                      color: Colors.pink,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'FutureProof',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Financial peace for couples',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 48),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: _onAreWeOkayPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 32,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Are We Okay?',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (_status != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _status!.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _status!.emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _status!.remaining >= 0 ? 'On Track' : 'Review Spending',
                              style: TextStyle(
                                color: _status!.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddExpenseScreen(),
                          ),
                        ).then((_) => _loadTransactions());
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Expense'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Show transactions list
                      },
                      icon: const Icon(Icons.list),
                      label: const Text('History'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
