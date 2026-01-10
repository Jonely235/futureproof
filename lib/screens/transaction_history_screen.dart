import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import 'edit_transaction_screen.dart';

/// Transaction History Screen - Timeline View
///
/// Design Philosophy: Editorial timeline aesthetic
/// - Visual timeline with connected nodes
/// - Magazine-style date headers
/// - Cards with subtle shadows and refined typography
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  Map<String, List<Transaction>> _groupTransactionsByDate(
      List<Transaction> transactions) {
    final Map<String, List<Transaction>> grouped = {};

    for (var transaction in _filteredTransactions(transactions)) {
      final dateKey = _getDateKey(transaction.date);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }

    return grouped;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  List<Transaction> _filteredTransactions(List<Transaction> transactions) {
    if (_searchQuery.isEmpty) {
      return transactions;
    }

    return transactions.where((t) {
      return t.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.note?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
          t.amount.toString().contains(_searchQuery);
    }).toList();
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    try {
      HapticFeedback.mediumImpact();

      final provider = context.read<TransactionProvider>();
      final success = await provider.deleteTransaction(transaction.id);

      if (success && mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Transaction deleted',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFF0A0A0A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFD4483A),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final transactions = provider.transactions;
    final filtered = _filteredTransactions(transactions);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          // App Bar with Search
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                alignment: Alignment.bottomLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'History',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A0A0A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${filtered.length} transaction${filtered.length == 1 ? '' : 's'}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        color: const Color(0xFF6B6B6B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    hintStyle: GoogleFonts.spaceGrotesk(
                      color: const Color(0xFF9E9E9E),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF6B6B6B),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Color(0xFF6B6B6B),
                            ),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    color: const Color(0xFF0A0A0A),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
          ),

          // Content
          provider.isLoading
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE0E0E0),
                              width: 2,
                            ),
                          ),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF0A0A0A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading transactions...',
                          style: GoogleFonts.spaceGrotesk(
                            color: const Color(0xFF6B6B6B),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : filtered.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF5F5F5),
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                size: 48,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No transactions yet'
                                  : 'No transactions found',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0A0A0A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Add your first expense to get started'
                                  : 'Try a different search term',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                color: const Color(0xFF6B6B6B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverToBoxAdapter(
                      child: RefreshIndicator(
                        onRefresh: () => provider.refresh(),
                        color: const Color(0xFF0A0A0A),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _groupTransactionsByDate(transactions).length,
                          itemBuilder: (context, index) {
                            final grouped = _groupTransactionsByDate(transactions);
                            final dateKey = grouped.keys.elementAt(index);
                            final transactionsForDate = grouped[dateKey]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date Header
                                Container(
                                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0A0A0A),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        dateKey,
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF0A0A0A),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Timeline Cards
                                ...transactionsForDate.asMap().entries.map((entry) {
                                  final itemIndex = entry.key;
                                  final transaction = entry.value;
                                  final isLast = itemIndex == transactionsForDate.length - 1;

                                  return _TimelineTransactionCard(
                                    transaction: transaction,
                                    isFirst: itemIndex == 0,
                                    isLast: isLast,
                                    onDelete: () => _deleteTransaction(transaction),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}

/// Timeline Transaction Card with Visual Connector
class _TimelineTransactionCard extends StatelessWidget {
  final Transaction transaction;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onDelete;

  const _TimelineTransactionCard({
    required this.transaction,
    required this.isFirst,
    required this.isLast,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.amount < 0;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: const BoxDecoration(
          color: Color(0xFFD4483A),
          borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.heavyImpact();
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Delete Transaction?',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: Text(
                'Are you sure you want to delete this transaction?',
                style: GoogleFonts.spaceGrotesk(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Delete',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFD4483A),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) => onDelete(),
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.lightImpact();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditTransactionScreen(
                transaction: transaction,
              ),
            ),
          );
          if (result == true || result == false) {
            context.read<TransactionProvider>().refresh();
          }
        },
        child: Container(
          margin: EdgeInsets.only(
            left: 24,
            right: 16,
            bottom: isLast ? 24 : 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline Line
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    if (!isFirst)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: const Color(0xFFE0E0E0),
                        ),
                      ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isExpense
                            ? const Color(0xFF0A0A0A)
                            : const Color(0xFF4CAF50),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: const Color(0xFFE0E0E0),
                        ),
                      ),
                  ],
                ),
              ),

              // Card Content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 1,
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
                    children: [
                      // Emoji Avatar
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            transaction.categoryEmoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.category,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0A0A0A),
                              ),
                            ),
                            if (transaction.note?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 4),
                              Text(
                                transaction.note!,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  color: const Color(0xFF6B6B6B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Amount & Time
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            transaction.formattedAmount,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isExpense
                                  ? const Color(0xFF0A0A0A)
                                  : const Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${transaction.date.hour}:${transaction.date.minute.toString().padLeft(2, '0')}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                    ],
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
