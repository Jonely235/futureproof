import 'package:flutter/material.dart';
import '../../domain/entities/behavioral_insight_entity.dart';
import '../../domain/value_objects/life_stage.dart';

/// Card widget for displaying a behavioral insight
/// Supports actions, dismissal, and expandable details
class BehavioralInsightCard extends StatelessWidget {
  final BehavioralInsightEntity insight;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final bool isExpanded;

  const BehavioralInsightCard({
    super.key,
    required this.insight,
    this.onAction,
    this.onDismiss,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get color based on priority
    final color = _getPriorityColor(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: _getElevation(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: insight.priority == InsightPriority.critical ? 2 : 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: _getGradient(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            _buildHeader(context, color),

            // Message
            _buildMessage(context),

            // Metadata details (if expanded)
            if (isExpanded && insight.metadata != null)
              _buildMetadata(context),

            // Action buttons
            if (insight.actionLabel != null || onDismiss != null)
              _buildActions(context, color),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                insight.icon,
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (_getCategoryLabel() != null)
                  Text(
                    _getCategoryLabel()!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                        ),
                  ),
              ],
            ),
          ),

          // Dismiss button
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        insight.message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
            ),
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    final metadata = insight.metadata!;
    if (metadata.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 8),
          ...metadata.entries.where((e) => _shouldShowMetadata(e.key)).map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatMetadataKey(entry.key),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _formatMetadataValue(entry.value),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          if (insight.actionLabel != null)
            Expanded(
              child: FilledButton.tonal(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: color.withOpacity(0.15),
                  foregroundColor: color,
                ),
                child: Text(insight.actionLabel!),
              ),
            ),
        ],
      ),
    );
  }

  Color _getPriorityColor(BuildContext context) {
    final theme = Theme.of(context);

    switch (insight.priority) {
      case InsightPriority.critical:
        return theme.colorScheme.error;
      case InsightPriority.high:
        return theme.colorScheme.error.withOpacity(0.8);
      case InsightPriority.medium:
        return theme.colorScheme.tertiary;
      case InsightPriority.low:
        return theme.colorScheme.primary;
    }
  }

  int _getElevation() {
    switch (insight.priority) {
      case InsightPriority.critical:
        return 4;
      case InsightPriority.high:
        return 3;
      case InsightPriority.medium:
        return 2;
      case InsightPriority.low:
        return 1;
    }
  }

  Gradient? _getGradient(BuildContext context) {
    if (insight.priority == InsightPriority.critical) {
      final color = Theme.of(context).colorScheme.error.withOpacity(0.05);
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, Colors.transparent],
      );
    }
    return null;
  }

  String? _getCategoryLabel() {
    switch (insight.category) {
      case InsightCategory.budgetHealth:
        return 'Budget Health';
      case InsightCategory.anomalyDetection:
        return 'Unusual Spending';
      case InsightCategory.goalProgress:
        return 'Goal Progress';
      case InsightCategory.cashFlowForecast:
        return 'Cash Flow';
      case InsightCategory.debtPayoff:
        return 'Debt Payoff';
      case InsightCategory.subscriptionManagement:
        return 'Subscriptions';
      case InsightCategory.scenarioAlert:
        return 'Alert';
      case InsightCategory.streakAndMomentum:
        return 'Streak';
      case InsightCategory.warMode:
        return 'War Mode';
    }
  }

  bool _shouldShowMetadata(String key) {
    // Show only user-friendly metadata keys
    const visibleKeys = {
      'safeToSpend',
      'dailyBudget',
      'remaining',
      'daysLeft',
      'ratio',
      'velocity',
      'recentSpent',
      'expectedSpent',
      'streak',
      'milestone',
      'runwayDays',
    };
    return visibleKeys.contains(key);
  }

  String _formatMetadataKey(String key) {
    switch (key) {
      case 'safeToSpend':
        return 'Safe to spend';
      case 'dailyBudget':
        return 'Daily budget';
      case 'remaining':
        return 'Remaining';
      case 'daysLeft':
        return 'Days left';
      case 'ratio':
        return 'Ratio';
      case 'velocity':
        return 'Velocity';
      case 'recentSpent':
        return 'Recent spend';
      case 'expectedSpent':
        return 'Expected spend';
      case 'streak':
        return 'Current streak';
      case 'milestone':
        return 'Milestone';
      case 'runwayDays':
        return 'Runway';
      default:
        return key;
    }
  }

  String _formatMetadataValue(dynamic value) {
    if (value is double) {
      // Format as currency if it looks like money
      if (value > 1000 || value < -1000) {
        return '\$${value.toStringAsFixed(0)}';
      }
      return '\$${value.toStringAsFixed(2)}';
    }
    if (value is int) {
      return value.toString();
    }
    if (value is bool) {
      return value ? 'Yes' : 'No';
    }
    return value.toString();
  }
}

/// Compact version of the insight card for use in lists
class CompactInsightCard extends StatelessWidget {
  final BehavioralInsightEntity insight;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const CompactInsightCard({
    super.key,
    required this.insight,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getPriorityColor(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              Text(insight.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      insight.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Priority indicator
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Dismiss button
              if (onDismiss != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(BuildContext context) {
    final theme = Theme.of(context);

    switch (insight.priority) {
      case InsightPriority.critical:
        return theme.colorScheme.error;
      case InsightPriority.high:
        return theme.colorScheme.error.withOpacity(0.8);
      case InsightPriority.medium:
        return theme.colorScheme.tertiary;
      case InsightPriority.low:
        return theme.colorScheme.primary;
    }
  }
}
