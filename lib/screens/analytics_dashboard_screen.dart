import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/spending_analysis.dart';
import '../services/analytics_service.dart';
import '../widgets/pie_chart_widget.dart';
import '../widgets/bar_chart_widget.dart';
import '../widgets/trend_indicator.dart';
import '../widgets/velocity_chart_widget.dart';

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

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  SpendingAnalysis? _analysis;
  Map<String, dynamic>? _quickStats;
  bool _isLoading = true;

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
    _loadAnalytics();
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
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
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
                        color: Color(0xFF9E9E9E),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading analytics',
                        style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFF6B6B6B),
                        ),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // App Bar
                    SliverAppBar(
                      expandedHeight: 140,
                      floating: false,
                      pinned: true,
                      elevation: 0,
                      backgroundColor: Colors.white,
                      flexibleSpace: FlexibleSpaceBar(
                        titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
                        title: Text(
                          'Analytics',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0A0A0A),
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Color(0xFF0A0A0A)),
                          onPressed: _loadAnalytics,
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),

                    // Content
                    SliverToBoxAdapter(
                      child: RefreshIndicator(
                        onRefresh: _loadAnalytics,
                        color: const Color(0xFF0A0A0A),
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
                    ),
                  ],
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
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Financial Overview',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A0A0A),
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
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Spend Velocity',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A0A0A),
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
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF0A0A0A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B6B6B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isPositive
                  ? const Color(0xFF0A0A0A)
                  : const Color(0xFFD4483A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendSection() {
    if (_analysis!.monthlyTrends.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Monthly Trends',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Trend indicator
        Center(
          child: TrendIndicator(
            percentage: _analysis!.trendPercentage,
            label: 'vs last month',
          ),
        ),
        const SizedBox(height: 16),
        // Bar chart
        SizedBox(
          height: 200,
          child: BarChartWidget(
            data: _analysis!.monthlyTrends,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    if (_analysis!.byCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Spending by Category',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Pie chart
        Center(
          child: PieChartWidget(
            data: _analysis!.byCategory,
            categoryEmojis: _categoryEmojis,
          ),
        ),
        const SizedBox(height: 24),
        // Horizontal bar chart
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: HorizontalBarChartWidget(
            data: _analysis!.byCategory,
            categoryEmojis: _categoryEmojis,
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
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    '$overBudget over budget',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'AI Insights',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...topInsights.map((insight) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Card(
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: insight.color.withOpacity(0.2),
                  child: Text(
                    insight.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                title: Text(
                  insight.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(insight.description),
                trailing: Icon(
                  _getInsightIcon(insight.type),
                  color: insight.color,
                ),
              ),
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
    } catch (e) {
      print('Error loading insights: $e');
      setState(() {
        _isLoading = false;
      });
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
