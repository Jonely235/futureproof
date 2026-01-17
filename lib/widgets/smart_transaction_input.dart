import 'package:flutter/material.dart';
import '../services/ai/ai_service.dart';
import '../providers/ai_provider.dart';
import 'package:provider/provider.dart';

/// A smart text input widget that parses natural language transaction descriptions
/// Example: "Lunch at Chipotle for $18" -> extracts amount, category, description
class SmartTransactionInput extends StatefulWidget {
  final Function(double amount, String category, String description) onTransactionParsed;
  final TextEditingController? controller;
  final String hintText;
  final bool enabled;

  const SmartTransactionInput({
    super.key,
    required this.onTransactionParsed,
    this.controller,
    this.hintText = 'Try "Lunch at Chipotle \$18"',
    this.enabled = true,
  });

  @override
  State<SmartTransactionInput> createState() => _SmartTransactionInputState();
}

class _SmartTransactionInputState extends State<SmartTransactionInput> {
  late TextEditingController _controller;
  bool _isParsing = false;
  ParsedTransaction? _parsedTransaction;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _parsedTransaction = null;
        _errorMessage = '';
      });
      return;
    }

    // Check if input looks like a transaction (contains a dollar amount)
    if (!_containsAmount(text)) {
      setState(() {
        _parsedTransaction = null;
        _errorMessage = '';
      });
      return;
    }

    // Parse after user stops typing for 500ms
    _debounceParse();
  }

  bool _containsAmount(String text) {
    // Match $XX, XX dollars, etc.
    return RegExp(r'[\$]?\s?\d+(\.\d{2})?').hasMatch(text);
  }

  Timer? _debounceTimer;
  void _debounceParse() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _parseTransaction();
    });
  }

  Future<void> _parseTransaction() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final aiProvider = context.read<AIProvider>();

    if (!aiProvider.isReady) {
      setState(() {
        _errorMessage = 'AI not ready - check settings';
        _parsedTransaction = null;
      });
      return;
    }

    setState(() {
      _isParsing = true;
      _errorMessage = '';
    });

    try {
      final parsed = await aiProvider.parseTransaction(text);

      if (parsed != null) {
        setState(() {
          _parsedTransaction = parsed;
          _isParsing = false;
        });

        // Auto-submit if confidence is high
        if (parsed.confidence > 0.85) {
          widget.onTransactionParsed(
            parsed.amount,
            parsed.category,
            parsed.description,
          );
        }
      } else {
        setState(() {
          _parsedTransaction = null;
          _isParsing = false;
          _errorMessage = 'Could not parse transaction';
        });
      }
    } catch (e) {
      setState(() {
        _parsedTransaction = null;
        _isParsing = false;
        _errorMessage = 'Parse error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input field with parsing indicator
        TextField(
          controller: _controller,
          enabled: widget.enabled,
          decoration: InputDecoration(
            hintText: widget.hintText,
            suffixIcon: _buildSuffixIcon(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: widget.enabled ? null : Colors.grey[100],
          ),
          maxLines: null,
          textCapitalization: TextCapitalization.sentences,
        ),

        // Parsed transaction preview
        if (_parsedTransaction != null) _buildParsedPreview(),

        // Error message
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuffixIcon() {
    if (_isParsing) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_parsedTransaction != null) {
      return Icon(
        Icons.check_circle,
        color: Colors.green[700],
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Icon(
        Icons.error,
        color: Theme.of(context).colorScheme.error,
      );
    }

    return const Icon(Icons.edit);
  }

  Widget _buildParsedPreview() {
    final parsed = _parsedTransaction!;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                parsed.isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: parsed.isExpense ? Colors.red[700] : Colors.green[700],
              ),
              const SizedBox(width: 8),
              Text(
                parsed.isExpense ? 'Expense' : 'Income',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(parsed.confidence),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(parsed.confidence * 100).toInt()}% confident',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '\$${parsed.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parsed.category,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      parsed.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (parsed.confidence <= 0.85) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => widget.onTransactionParsed(
                      parsed.amount,
                      parsed.category,
                      parsed.description,
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Confirm & Add'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _parsedTransaction = null;
                    });
                  },
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancel',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.85) return Colors.green;
    if (confidence >= 0.7) return Colors.orange;
    return Colors.red;
  }
}

// Add Timer import
import 'dart:async';
