import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import 'edit_transaction_screen.dart';

/// Transaction History Screen
///
/// Displays a chronological list of all transactions, grouped by date.
/// Supports pull-to-refresh, swipe-to-delete, and search functionality.
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
    // Load transactions via provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  Map<String, List<Transaction>> _groupTransactionsByDate(List<Transaction> transactions) {
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

      // Delete through provider
      final provider = context.read<TransactionProvider>();
      final success = await provider.deleteTransaction(transaction.id);

      if (success && mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting: $e')),
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
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No transactions yet'
                            : 'No transactions found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Add your first expense to get started'
                            : 'Try a different search term',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.refresh(),
                  child: Column(
                    children: [
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search transactions...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      // Transaction list
                      Expanded(
                        child: ListView.builder(
                          itemCount: _groupTransactionsByDate(transactions).length,
                          itemBuilder: (context, index) {
                            final grouped = _groupTransactionsByDate(transactions);
                            final dateKey = grouped.keys.elementAt(index);
                            final transactionsForDate = grouped[dateKey]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date header
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 16, 16, 8),
                                  child: Text(
                                    dateKey,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Transactions for this date
                                ...transactionsForDate.map((t) => _buildTransactionCard(t)),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Transaction?'),
              content: const Text(
                  'Are you sure you want to delete this transaction?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        _deleteTransaction(transaction);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
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
            // Refresh if transaction was updated or deleted
            if (result == true || result == false) {
              context.read<TransactionProvider>().refresh();
            }
          },
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
            transaction.formattedAmount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: transaction.amount < 0 ? Colors.grey[900] : Colors.grey[600],
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(transaction.category),
              if (transaction.note?.isNotEmpty ?? false)
                Text(
                  transaction.note!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          trailing: Text(
            '${transaction.date.hour}:${transaction.date.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }
}
