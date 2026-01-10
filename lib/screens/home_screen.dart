import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../services/finance_calculator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _monthlyIncome = 5000.0;
  double _savingsGoal = 1000.0;

  FinanceStatus? _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Load transactions via provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
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

  void _calculateStatus() {
    final provider = context.read<TransactionProvider>();
    final totalExpenses = provider.totalExpenses;

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
            _buildSummaryRow('Expenses', '\$${context.watch<TransactionProvider>().totalExpenses.toStringAsFixed(0)}'),
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
    final provider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('FutureProof'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'FutureProof',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Quick Stats Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.account_balance_wallet,
                        title: 'Income',
                        value: '\$${_monthlyIncome.toStringAsFixed(0)}',
                        color: Colors.grey[900]!,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.shopping_cart,
                        title: 'Expenses',
                        value: '\$${provider.totalExpenses.toStringAsFixed(0)}',
                        color: Colors.grey[700]!,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.savings,
                        title: 'Savings Goal',
                        value: '\$${_savingsGoal.toStringAsFixed(0)}',
                        color: Colors.grey[600]!,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        icon: Icons.show_chart,
                        title: 'Remaining',
                        value: _status != null
                            ? '\$${_status!.remaining.toStringAsFixed(0)}'
                            : '\$0',
                        valueColor: _status?.color,
                        color: Colors.grey[800]!,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // "Are We Okay?" Button Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Financial Check',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onAreWeOkayPressed,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            elevation: 0,
                          ),
                          child: Column(
                            children: [
                              Text(
                                _status?.emoji ?? '❓',
                                style: const TextStyle(fontSize: 48),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Are We Okay?',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_status != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _status!.remaining >= 0
                                      ? 'Tap to see details'
                                      : 'Review your spending',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Recent Transactions Preview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Recent Transactions',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to transaction history
                          },
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (provider.transactions.isEmpty)
                      _buildEmptyTransactions(context)
                    else
                      ...provider.getRecentTransactions(3).map((t) =>
                        _buildTransactionTile(context, t)),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, Transaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: transaction.amount < 0
              ? Colors.grey[200]
              : Colors.grey[900],
          child: Text(
            transaction.categoryEmoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          transaction.category,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${transaction.date.month}/${transaction.date.day}/${transaction.date.year}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Text(
          transaction.formattedAmount,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: transaction.amount < 0 ? Colors.grey[900] : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your first expense to get started',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
