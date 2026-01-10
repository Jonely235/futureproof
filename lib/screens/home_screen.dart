import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../services/finance_calculator.dart';
import '../services/database_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSettings();
    loadTransactions();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final monthlyIncome = prefs.getDouble('monthly_income');
      final savingsGoal = prefs.getDouble('savings_goal');

      if (monthlyIncome != null || savingsGoal != null) {
        setState(() {
          _monthlyIncome = monthlyIncome ?? _monthlyIncome;
          _savingsGoal = savingsGoal ?? _savingsGoal;
        });
        _calculateStatus();
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> loadTransactions() async {
    try {
      final dbService = DatabaseService();
      final transactions = await dbService.getAllTransactions();

      if (!mounted) return;

      setState(() {
        _transactions = transactions;
      });

      _calculateStatus();
    } catch (e, stackTrace) {
      print('❌ Error loading transactions: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _transactions = [];
        });
      }
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
    HapticFeedback.heavyImpact();
    setState(() {
      _isLoading = true;
    });

    // Simulate calculation time (replace with actual calculation)
    await Future.delayed(const Duration(milliseconds: 500));

    _calculateStatus();

    setState(() {
      _isLoading = false;
    });

    HapticFeedback.lightImpact();
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
          ],
        ),
      ),
    );
  }
}
