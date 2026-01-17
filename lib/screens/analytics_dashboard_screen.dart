import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../models/app_error.dart';
import '../models/spending_analysis.dart';
import '../providers/transaction_provider.dart';
import '../services/analytics_service.dart';
import '../utils/app_logger.dart';
import '../utils/error_display.dart';
import '../widgets/analytics/category_legend_widget.dart';
import '../widgets/analytics/insight_card.dart';
import '../widgets/analytics/interactive_donut_chart.dart';
import '../widgets/bar_chart_widget.dart';
import '../widgets/trend_indicator.dart';
import '../widgets/velocity_chart_widget.dart';
import '../widgets/ui_helpers.dart';

/// Analytics Dashboard Screen
///
/// Complete financial intelligence dashboard with:
/// - Spending overview and stats
/// - Category breakdown (pie chart)
/// - Monthly trends (bar chart)
/// - Quick insights
/// - Budget health
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with WidgetsBindingObserver {
  final AnalyticsService _analyticsService = AnalyticsService();
  SpendingAnalysis? _analysis;
  Map<String, dynamic>? _quickStats;
  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  String? _selectedCategory;

  // Track previous transaction count to detect changes
  int _previousTransactionCount = 0;

  final Map<String, String> _categoryEmojis = {
    'Groceries': '🛒',
    'Dining Out': '🍽️',
    'Transport': '🚗',
    'Entertainment': '🎭',
    'Health': '💊',
    'Shopping': '🛍️',
    'Subscriptions': '📱',
    'Housing': '🏠',
    'Other': '💸',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAnalytics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Watch for transaction changes
    final transactionProvider = context.read<TransactionProvider>();
    final currentTransactionCount = transactionProvider.transactions.length;

    // Reload when transaction count changes
    if (currentTransactionCount != _previousTransactionCount) {
      _previousTransactionCount = currentTransactionCount;
      if (_hasLoadedOnce) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadAnalytics();
          }
        });
      }
    }

    // Auto-refresh when returning to this screen (but not on first load)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _hasLoadedOnce) {
        _loadAnalytics();
      } else if (mounted && !_hasLoadedOnce) {
        _hasLoadedOnce = true;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app is resumed
      _loadAnalytics();
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Clear cache to ensure fresh data
      _analyticsService.refresh();

      final analysis = await _analyticsService.analyzeSpending();
      final quickStats = await _analyticsService.getQuickStats();

      setState(() {
        _analysis = analysis;
        _quickStats = quickStats;
        _isLoading = false;
      });
    } catch (e, st) {
      final error = e is AppError
          ? e
          : AppError.fromException(
              e,
              type: AppErrorType.unknown,
              stackTrace: st,
            );
      AppLogger.analyticsUI.severe('Failed to load analytics', error);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ErrorDisplay.showErrorSnackBar(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch TransactionProvider for changes - this will trigger rebuilds when transactions are added/updated
    final transactionProvider = context.watch<TransactionProvider>();
    final currentTransactionCount = transactionProvider.transactions.length;

    // Reload analytics when transaction count changes (but not on first load)
    if (_hasLoadedOnce && currentTransactionCount != _previousTransactionCount) {
      _previousTransactionCount = currentTransactionCount;
      // Schedule analytics reload
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isLoading) {
          _loadAnalytics();
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analysis == null || _quickStats == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.gray500,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading analytics',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.gray700,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  color: AppColors.fintechTeal,
                  backgroundColor: Colors.white,
                  child: CustomScrollView(
                    slivers: [
                      // App Bar
                      SliverAppBar(
                        expandedHeight: 140,
                        floating: false,
                        pinned: true,
                        elevation: 0,
                        backgroundColor: Colors.white,
                        flexibleSpace: FlexibleSpaceBar(
                          titlePadding:
                              const EdgeInsets.only(left: 16, bottom: 12),
                          title: Text(
                            'Analytics',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ),

                      // Content
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Overview Cards
                            _buildOverviewSection(),
                            const SizedBox(height: 24),

                            // Spend Velocity Chart
                            if (_analysis!.monthlyTrends.length >= 2)
                              _buildVelocitySection(),
                            const SizedBox(height: 24),

                            // Category Breakdown
                            _buildCategorySection(),
                            const SizedBox(height: 24),

                            // Budget Comparisons
                            if (_analysis!.budgetComparisons.isNotEmpty)
                              _buildBudgetSection(),
                            const SizedBox(height: 24),

                            // Quick Insights
                            if (_analysis!.insights.isNotEmpty)
                              _buildInsightsSection(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Financial Overview',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),

        // Stats Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildModernStatCard(
                      'Total Spending',
                      '\$${_analysis!.totalSpending.toStringAsFixed(0)}',
                      Icons.account_balance_wallet_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernStatCard(
                      'Average/Month',
                      '\$${_analysis!.averageMonthlySpending.toStringAsFixed(0)}',
                      Icons.calendar_month_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildModernStatCard(
                      'Savings',
                      '\$${_quickStats!['savings'].toStringAsFixed(0)}',
                      Icons.savings_outlined,
                      isPositive: _quickStats!['isOnTrack'] ?? false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModernStatCard(
                      'Savings Rate',
                      '${_quickStats!['savingsRate'].toStringAsFixed(1)}%',
                      Icons.percent_outlined,
                      isPositive: _quickStats!['savingsRate'] >= 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVelocitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Spend Velocity',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: VelocityChartWidget(
            data: _analysis!.monthlyTrends.take(6).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildModernStatCard(
    String title,
    String value,
    IconData icon, {
    bool isPositive = true,
  }) {
    // Use different gradient for each card based on title
    final gradients = {
      'Total Spending': [AppColors.fintechTeal, AppColors.fintechTealLight],
      'Average/Month': [AppColors.fintechNavy, AppColors.fintechIndigo],
      'Savings': [AppColors.fintechTrust, AppColors.fintechGrowth],
      'Savings Rate': [AppColors.fintechTeal, AppColors.fintechIndigo],
    };

    final cardGradient = gradients[title] ?? [
      AppColors.fintechTeal,
      AppColors.fintechTealLight
    ];

    return FadeInWidget(
      delay: const Duration(milliseconds: 100),
      child: FintechStatCard(
        title: title,
        value: value,
        icon: icon,
        gradientColors: cardGradient.map((c) => c).toList(),
        isPositive: isPositive,
      ),
    );
  }

  Widget _buildCategorySection() {
    if (_analysis!.byCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalSpending = _analysis!.byCategory.values.fold(0.0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Spending by Category',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Interactive donut chart
        Center(
          child: InteractiveDonutChart(
            categorySpending: _analysis!.byCategory,
            totalSpending: totalSpending,
            onCategoryTap: (category) {
              setState(() {
                if (_selectedCategory == category) {
                  _selectedCategory = null;
                } else {
                  _selectedCategory = category;
                }
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        // Category legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: CategoryLegendWidget(
            categorySpending: _analysis!.byCategory,
            totalSpending: totalSpending,
            selectedCategory: _selectedCategory,
            onCategoryTap: (category) {
              setState(() {
                if (_selectedCategory == category) {
                  _selectedCategory = null;
                } else {
                  _selectedCategory = category;
                }
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        // Horizontal bar chart
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category Breakdown',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 12),
              HorizontalBarChartWidget(
                data: _analysis!.byCategory,
                categoryEmojis: _categoryEmojis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSection() {
    final comparisons = _analysis!.budgetComparisons;
    final overBudget = comparisons.values.where((c) => c.isOverBudget).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Budget Status',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              if (overBudget > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger),
                  ),
                  child: Text(
                    '$overBudget over budget',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...comparisons.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BudgetHealthIndicator(
              spent: entry.value.spent,
              budget: entry.value.budget,
              label: entry.value.category,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInsightsSection() {
    final insights = _analysis!.insights;
    final topInsights = insights.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Insights',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...topInsights.map((insight) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: InsightCard(
              insight: insight,
              onTap: () {
                // Navigate to insight details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InsightsScreen(),
                  ),
                );
              },
            ),
          );
        }),
        if (insights.length > 5)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton.icon(
              onPressed: () {
                // Navigate to full insights screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InsightsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View All Insights'),
            ),
          ),
      ],
    );
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.success:
        return Icons.check_circle;
      case InsightType.warning:
        return Icons.warning;
      case InsightType.error:
        return Icons.error;
      case InsightType.info:
        return Icons.info;
    }
  }
}

/// Full Insights Screen
///
/// Shows all AI-generated insights with detailed recommendations.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  List<Insight> _insights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final insights = await _analyticsService.generateInsights();

      setState(() {
        _insights = insights;
        _isLoading = false;
      });
    } catch (e, st) {
      final error = e is AppError
          ? e
          : AppError.fromException(
              e,
              type: AppErrorType.unknown,
              stackTrace: st,
            );
      AppLogger.analyticsUI.severe('Failed to load insights', error);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ErrorDisplay.showErrorSnackBar(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _insights.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No insights yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add more transactions to get insights',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadInsights,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _insights.length,
                    itemBuilder: (context, index) {
                      final insight = _insights[index];
                      return _buildInsightCard(insight);
                    },
                  ),
                ),
    );
  }

  Widget _buildInsightCard(Insight insight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: insight.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    insight.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  _getInsightIcon(insight.type),
                  color: insight.color,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              insight.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            if (insight.recommendation != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight.recommendation!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.success:
        return Icons.check_circle;
      case InsightType.warning:
        return Icons.warning;
      case InsightType.error:
        return Icons.error;
      case InsightType.info:
        return Icons.info;
    }
  }
}
