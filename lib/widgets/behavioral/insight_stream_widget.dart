import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/behavioral_insight_entity.dart';
import '../../domain/value_objects/life_stage.dart';
import '../../domain/value_objects/insight_category.dart';
import '../../providers/behavioral_insight_provider.dart';
import 'behavioral_insight_card.dart';

/// A scrollable stream of behavioral insights
/// Displays active insights with filtering and pull-to-refresh
class InsightStreamWidget extends StatefulWidget {
  final InsightCategory? filter;
  final int? maxInsights;
  final bool showEmptyState;
  final bool compact;
  final VoidCallback? onInsightAction;

  const InsightStreamWidget({
    super.key,
    this.filter,
    this.maxInsights,
    this.showEmptyState = true,
    this.compact = false,
    this.onInsightAction,
  });

  @override
  State<InsightStreamWidget> createState() => _InsightStreamWidgetState();
}

class _InsightStreamWidgetState extends State<InsightStreamWidget> {
  bool _refreshing = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BehavioralInsightProvider>();

    // Filter insights
    var insights = provider.insights;
    if (widget.filter != null) {
      insights = provider.getInsightsByCategory(widget.filter!);
    }
    if (widget.maxInsights != null && insights.length > widget.maxInsights!) {
      insights = insights.take(widget.maxInsights!).toList();
    }

    if (provider.isLoading && insights.isEmpty) {
      return const _LoadingState();
    }

    if (insights.isEmpty) {
      return widget.showEmptyState ? const _EmptyState() : const SizedBox.shrink();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: insights.length,
        itemBuilder: (context, index) {
          final insight = insights[index];
          final isLast = index == insights.length - 1;

          if (widget.compact) {
            return CompactInsightCard(
              insight: insight,
              onTap: () => _showInsightDetail(context, insight),
              onDismiss: () => _dismissInsight(provider, insight.id),
            );
          }

          return Column(
            children: [
              BehavioralInsightCard(
                insight: insight,
                onAction: () => _performAction(provider, insight),
                onDismiss: () => _dismissInsight(provider, insight.id),
              ),
              if (!isLast) const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshing = true);
    final provider = context.read<BehavioralInsightProvider>();
    await provider.refreshInsights();
    setState(() => _refreshing = false);
  }

  void _showInsightDetail(BuildContext context, BehavioralInsightEntity insight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _InsightDetailSheet(
        insight: insight,
        onAction: () => _performAction(context.read<BehavioralInsightProvider>(), insight),
        onDismiss: () => _dismissInsight(context.read<BehavioralInsightProvider>(), insight.id),
      ),
    );
  }

  void _performAction(BehavioralInsightProvider provider, BehavioralInsightEntity insight) {
    provider.performAction(insight.id);
    if (insight.actionDeepLink != null) {
      // Handle deep link navigation
      // This would integrate with your app's navigation system
    }
    widget.onInsightAction?.call();
  }

  void _dismissInsight(BehavioralInsightProvider provider, String insightId) {
    provider.dismissInsight(insightId);
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 16),
            Text(
              'All caught up!',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'No new insights right now. Check back later!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for insight details
class _InsightDetailSheet extends StatelessWidget {
  final BehavioralInsightEntity insight;
  final VoidCallback onAction;
  final VoidCallback onDismiss;

  const _InsightDetailSheet({
    required this.insight,
    required this.onAction,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Insight card (expanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: BehavioralInsightCard(
                insight: insight,
                onAction: onAction,
                isExpanded: true,
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  if (insight.actionLabel != null)
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          onAction();
                          Navigator.of(context).pop();
                        },
                        child: Text(insight.actionLabel!),
                      ),
                    ),
                  if (insight.actionLabel != null && onDismiss != null)
                    const SizedBox(width: 12),
                  if (onDismiss != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          onDismiss();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Dismiss'),
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

/// Horizontal scrollable list of insights for home screen
class InsightCarousel extends StatelessWidget {
  final int maxInsights;
  final VoidCallback? onViewAll;

  const InsightCarousel({
    super.key,
    this.maxInsights = 5,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BehavioralInsightProvider>();

    if (provider.insights.isEmpty) {
      return const SizedBox.shrink();
    }

    final insights = provider.insights.take(maxInsights).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Insights',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: const Text('View all'),
                ),
            ],
          ),
        ),

        // Carousel
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: insights.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final insight = insights[index];
              return SizedBox(
                width: 280,
                child: CompactInsightCard(
                  insight: insight,
                  onDismiss: () => provider.dismissInsight(insight.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Insights filter chips for category selection
class InsightsFilterBar extends StatefulWidget {
  final Set<InsightCategory> selectedCategories;
  final ValueChanged<Set<InsightCategory>> onFilterChanged;

  const InsightsFilterBar({
    super.key,
    required this.selectedCategories,
    required this.onFilterChanged,
  });

  @override
  State<InsightsFilterBar> createState() => _InsightsFilterBarState();
}

class _InsightsFilterBarState extends State<InsightsFilterBar> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: InsightCategory.values.length + 1, // +1 for "All"
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _FilterChip(
              label: 'All',
              isSelected: widget.selectedCategories.isEmpty ||
                  widget.selectedCategories.length == InsightCategory.values.length,
              onSelected: (_) {
                widget.onFilterChanged(InsightCategory.values.toSet());
              },
            );
          }

          final category = InsightCategory.values[index - 1];
          return _FilterChip(
            label: _getCategoryLabel(category),
            isSelected: widget.selectedCategories.contains(category),
            onSelected: (_) {
              final newSet = Set<InsightCategory>.from(widget.selectedCategories);
              if (newSet.contains(category)) {
                newSet.remove(category);
              } else {
                newSet.add(category);
              }
              widget.onFilterChanged(newSet);
            },
          );
        },
      ),
    );
  }

  String _getCategoryLabel(InsightCategory category) {
    switch (category) {
      case InsightCategory.budgetHealth:
        return 'Budget';
      case InsightCategory.anomalyDetection:
        return 'Anomalies';
      case InsightCategory.goalProgress:
        return 'Goals';
      case InsightCategory.cashFlowForecast:
        return 'Cash Flow';
      case InsightCategory.debtPayoff:
        return 'Debt';
      case InsightCategory.subscriptionManagement:
        return 'Subscriptions';
      case InsightCategory.scenarioAlert:
        return 'Alerts';
      case InsightCategory.streakAndMomentum:
        return 'Streaks';
      case InsightCategory.warMode:
        return 'War Mode';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
      labelStyle: Theme.of(context).textTheme.labelSmall,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
