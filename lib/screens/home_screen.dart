import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../services/finance_calculator.dart';
import 'transaction_history_screen.dart';

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
  bool _isCalculating = false;
  int _previousTransactionCount = 0;

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

  void _calculateStatus() async {
    // Prevent multiple simultaneous calculations
    if (_isCalculating) return;
    if (!mounted) return;

    _isCalculating = true;

    // Reload settings first to get latest values
    await _loadSettings();

    if (!mounted) {
      _isCalculating = false;
      return;
    }

    final provider = context.read<TransactionProvider>();
    final totalExpenses = provider.totalExpenses;

    setState(() {
      _status = FinanceCalculator.calculateStatus(
        monthlyIncome: _monthlyIncome,
        monthlyExpenses: totalExpenses,
        savingsGoal: _savingsGoal,
      );
      _isCalculating = false;
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
    final currentTransactionCount = provider.transactions.length;

    // Recalculate status if transaction count changed AND we're not already calculating
    if (currentTransactionCount != _previousTransactionCount && !_isCalculating) {
      _previousTransactionCount = currentTransactionCount;
      // Recalculate status asynchronously without blocking UI
      Future.microtask(() => _calculateStatus());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FutureProof',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Hero Section - Financial Health Status
              _buildHeroSection(context),

              const SizedBox(height: 32),

              // Monthly Overview Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'MONTHLY OVERVIEW',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                    color: const Color(0xFF6B6B6B),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Quick Stats Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildModernStatCard(
                            context,
                            title: 'INCOME',
                            value: '\$${_monthlyIncome.toStringAsFixed(0)}',
                            trend: '+12%',
                            trendUp: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildModernStatCard(
                            context,
                            title: 'EXPENSES',
                            value: '\$${provider.totalExpenses.toStringAsFixed(0)}',
                            trend: '+8%',
                            trendUp: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildWideStatCard(
                      context,
                      title: 'REMAINING',
                      value: _status != null
                          ? '\$${_status!.remaining.toStringAsFixed(0)}'
                          : '\$0',
                      subtitle: '${_status != null && _status!.remaining >= 0 ? "On track" : "Review spending"}',
                      percentage: _monthlyIncome > 0
                          ? ((_status?.remaining ?? 0) / _monthlyIncome * 100).round()
                          : 0,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Recent Transactions Preview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RECENT ACTIVITY',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                        color: const Color(0xFF6B6B6B),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to transaction history screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TransactionHistoryScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'View all',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (provider.transactions.isEmpty)
                _buildEmptyState(context)
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: provider.getRecentTransactions(3).map((t) =>
                      _buildTimelineItem(context, t)).toList(),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final status = _status;
    final isLoading = _isLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good Morning',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: const Color(0xFF6B6B6B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Financial Health',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 60,
            height: 3,
            decoration: BoxDecoration(
              color: status?.color ?? Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            GestureDetector(
              onTap: _onAreWeOkayPressed,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(
                      status?.emoji ?? '✨',
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      status?.level == StatusLevel.good
                          ? 'Strong'
                          : status?.level == StatusLevel.caution
                              ? 'Caution'
                              : 'Review',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: status?.color ?? const Color(0xFF0A0A0A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status?.message ?? 'Tap to check your status',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        color: const Color(0xFF6B6B6B),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String trend,
    required bool trendUp,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
              color: const Color(0xFF6B6B6B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: const Color(0xFF0A0A0A),
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0A0A0A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWideStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required int percentage,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                  color: const Color(0xFF6B6B6B),
                ),
              ),
              Text(
                '$percentage%',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0A0A0A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0A0A0A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              color: const Color(0xFF6B6B6B),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFFC9A962),
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, Transaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: transaction.amount < 0
                  ? const Color(0xFF0A0A0A)
                  : const Color(0xFFC9A962),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.category,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0A0A0A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.formattedAmount,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: transaction.amount < 0
                        ? const Color(0xFF0A0A0A)
                        : const Color(0xFF6B6B6B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${transaction.date.month}/${transaction.date.day}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              color: const Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 48,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No activity yet',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF404040),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first transaction to get started',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: const Color(0xFF6B6B6B),
            ),
          ),
        ],
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
