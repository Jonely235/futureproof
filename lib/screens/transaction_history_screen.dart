import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

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
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbService = DatabaseService();
      final transactions = await dbService.getAllTransactions();

      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, List<Transaction>> _groupTransactionsByDate() {
    final Map<String, List<Transaction>> grouped = {};

    for (var transaction in _filteredTransactions) {
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

  List<Transaction> get _filteredTransactions {
    if (_searchQuery.isEmpty) {
      return _transactions;
    }

    return _transactions.where((t) {
      return t.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.note?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
          t.amount.toString().contains(_searchQuery);
    }).toList();
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    try {
      HapticFeedback.mediumImpact();
      final dbService = DatabaseService();
      await dbService.deleteTransaction(transaction.id);

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted')),
        );
        loadTransactions();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredTransactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Colors.grey[400],
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
                  onRefresh: loadTransactions,
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
                          itemCount: _groupTransactionsByDate().length,
                          itemBuilder: (context, index) {
                            final grouped = _groupTransactionsByDate();
                            final dateKey = grouped.keys.elementAt(index);
                            final transactions = grouped[dateKey]!;

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
                                ...transactions.map((t) => _buildTransactionCard(t)),
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
        color: Colors.red,
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
          leading: CircleAvatar(
            backgroundColor: transaction.amount < 0
                ? Colors.red.shade100
                : Colors.green.shade100,
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
              color: transaction.amount < 0 ? Colors.red : Colors.green,
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
