import 'package:flutter/material.dart';
import '../models/spending_analysis.dart';

/// Bar Chart Widget for Monthly Trends
///
/// Displays monthly spending comparison as vertical bars.
class BarChartWidget extends StatelessWidget {
  final List<MonthlySpending> data;
  final double height;
  final bool showValues;

  const BarChartWidget({
    super.key,
    required this.data,
    this.height = 200,
    this.showValues = true,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('No data to display'),
        ),
      );
    }

    // Find max value for scaling
    final maxValue =
        data.map((m) => m.amount).fold(0.0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.map((monthly) {
            return _buildBar(
              context,
              monthly,
              maxValue,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBar(
    BuildContext context,
    MonthlySpending monthly,
    double maxValue,
  ) {
    final barHeight =
        maxValue > 0 ? (monthly.amount / maxValue) * (height - 60) : 0.0;

    // Format month label
    final parts = monthly.month.split('-');
    final label = _getMonthAbbreviation(int.parse(parts[1]));

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Value on top (optional)
          if (showValues)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '\$${monthly.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
          // Bar
          Container(
            height: barHeight,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.blue.shade400,
                  Colors.blue.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          // Month label
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}

/// Horizontal Bar Chart Widget
///
/// Displays category spending as horizontal bars.
class HorizontalBarChartWidget extends StatelessWidget {
  final Map<String, double> data;
  final Map<String, String>? categoryEmojis;
  final double barHeight;

  const HorizontalBarChartWidget({
    super.key,
    required this.data,
    this.categoryEmojis,
    this.barHeight = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text('No data to display'),
        ),
      );
    }

    // Sort by amount (descending)
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxValue = sortedEntries.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedEntries.map((entry) {
        return _buildHorizontalBar(context, entry, maxValue);
      }).toList(),
    );
  }

  Widget _buildHorizontalBar(
    BuildContext context,
    MapEntry<String, double> entry,
    double maxValue,
  ) {
    final barWidth = maxValue > 0 ? (entry.value / maxValue) * 0.7 : 0.0;
    final emoji = categoryEmojis?[entry.key] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Category label
          SizedBox(
            width: 100,
            child: Row(
              children: [
                if (emoji.isNotEmpty)
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                if (emoji.isNotEmpty) const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Bar
          Expanded(
            child: Stack(
              children: [
                // Background bar
                Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                // Value bar
                FractionallySizedBox(
                  widthFactor: barWidth.clamp(0.0, 1.0),
                  child: Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade400,
                          Colors.blue.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Amount
          SizedBox(
            width: 70,
            child: Text(
              '\$${entry.value.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
