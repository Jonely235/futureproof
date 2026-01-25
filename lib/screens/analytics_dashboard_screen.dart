import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../design/design_tokens.dart';
import '../models/app_error.dart';
import '../models/spending_analysis.dart';
import '../providers/transaction_provider.dart';
import '../services/analytics_service.dart';
import '../utils/app_logger.dart';
import '../utils/error_display.dart';

/// Analytics Dashboard - Modern Design
///
/// Clean, modern UI with:
/// - Subtle cards with shadows
/// - Clean typography
/// - Accent color highlights
/// - Good visual hierarchy
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
  int _previousTransactionCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAnalytics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final transactionProvider = context.read<TransactionProvider>();
    final currentTransactionCount = transactionProvider.transactions.length;

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
      _loadAnalytics();
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
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
    final transactionProvider = context.watch<TransactionProvider>();
    final currentTransactionCount = transactionProvider.transactions.length;

    if (_hasLoadedOnce && currentTransactionCount != _previousTransactionCount) {
      _previousTransactionCount = currentTransactionCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isLoading) {
          _loadAnalytics();
        }
      });
    }

    return Scaffold(
      backgroundColor: DesignTokens.scaffoldBackground,
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
                      const SizedBox(height: DesignTokens.spacingLg),
                      Text(
                        'Error loading analytics',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.gray700,
                          fontSize: 16,
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
                        expandedHeight: 120,
                        floating: false,
                        pinned: true,
                        elevation: 0,
                        backgroundColor: Colors.white,
                        flexibleSpace: FlexibleSpaceBar(
                          titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
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
                      SliverPadding(
                        padding: DesignTokens.paddingLg,
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Overview Cards
                              _buildOverviewCards(),
                              const SizedBox(height: DesignTokens.spacingXl),

                              // Monthly Trend
                              if (_analysis!.monthlyTrends.length >= 2)
                                _buildTrendSection(),
                              const SizedBox(height: DesignTokens.spacingXl),

                              // Categories
                              if (_analysis!.byCategory.isNotEmpty)
                                _buildCategoriesSection(),
                              const SizedBox(height: DesignTokens.spacingXl),

                              // Insights
                              if (_analysis!.insights.isNotEmpty)
                                _buildInsightsSection(),
                              const SizedBox(height: DesignTokens.spacingXxl),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main spending card
        _buildMainSpendingCard(),
        const SizedBox(height: DesignTokens.spacingLg),

        // Secondary stats row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Monthly Average',
                '\$${_analysis!.averageMonthlySpending.toStringAsFixed(0)}',
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Savings',
                '\$${_quickStats!['savings'].toStringAsFixed(0)}',
                Icons.savings,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Savings Rate',
                '${_quickStats!['savingsRate'].toStringAsFixed(0)}%',
                Icons.percent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainSpendingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        borderRadius: DesignTokens.borderRadiusXl,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A2E).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Spending',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            '\$${_analysis!.totalSpending.toStringAsFixed(0)}',
            style: DesignTokens.currencyLarge(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: DesignTokens.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.fintechTeal.withOpacity(0.1),
              borderRadius: DesignTokens.borderRadiusMd,
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.fintechTeal,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.gray700,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXxs),
          Text(
            value,
            style: DesignTokens.currencyMedium(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendSection() {
    final trends = _analysis!.monthlyTrends.take(6).toList();
    final maxAmount =
        trends.map((t) => t.amount).reduce((a, b) => a > b ? a : b) * 1.1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: DesignTokens.borderRadiusXl,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Trend',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXl),
          ...trends.map((trend) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        trend.month,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          color: AppColors.gray700,
                        ),
                      ),
                      Text(
                        '\$${trend.amount.toStringAsFixed(0)}',
                        style: DesignTokens.currencySmall(),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacingXs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                    child: LinearProgressIndicator(
                      value: trend.amount / maxAmount,
                      backgroundColor: const Color(0xFFF0F0F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.fintechTeal,
                      ),
                      minHeight: 6,
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

  Widget _buildCategoriesSection() {
    final categories = _analysis!.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = _analysis!.byCategory.values.fold(0.0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: DesignTokens.borderRadiusXl,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingXl),
          ...categories.take(5).map((entry) {
            final percent = (entry.value / total * 100).toStringAsFixed(0);
            final color = AppColors.categoryColors[entry.key] ??
                AppColors.categoryColors['Other']!;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacingXxs),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: entry.value / total,
                            backgroundColor: const Color(0xFFF0F0F0),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$percent%',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700,
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

  Widget _buildInsightsSection() {
    final insights = _analysis!.insights.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'Insights',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
        ),
        ...insights.map((insight) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: DesignTokens.borderRadiusLg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: insight.color.withOpacity(0.15),
                    borderRadius: DesignTokens.borderRadiusMd,
                  ),
                  child: Center(
                    child: Text(
                      insight.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacingXxs),
                      Text(
                        insight.description,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          color: AppColors.gray700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
