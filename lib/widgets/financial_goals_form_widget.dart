import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_colors.dart';
import '../design/design_tokens.dart';
import '../models/app_error.dart';
import '../utils/app_logger.dart';
import '../utils/error_display.dart';

/// Financial Goals Form Widget
///
/// A self-contained form widget for managing monthly income and savings targets.
/// Refactored with clear semantic distinction between "Growth/Budgeting" concepts.
///
/// Uses SharedPreferences for persistence and provides haptic feedback.
class FinancialGoalsFormWidget extends StatefulWidget {
  const FinancialGoalsFormWidget({super.key});

  @override
  State<FinancialGoalsFormWidget> createState() =>
      _FinancialGoalsFormWidgetState();
}

class _FinancialGoalsFormWidgetState extends State<FinancialGoalsFormWidget> {
  final _incomeController = TextEditingController();
  final _savingsController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  // Slider values (synced with text controllers)
  double _incomeSliderValue = 5000.0;
  double _savingsSliderValue = 1000.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    AppLogger.widgets.info('FinancialGoalsFormWidget initialized');
  }

  Future<void> _loadSettings() async {
    AppLogger.widgets.info('Loading financial goals settings');

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final monthlyIncome = prefs.getDouble('monthly_income') ?? 5000.0;
      final savingsGoal = prefs.getDouble('savings_goal') ?? 1000.0;

      AppLogger.widgets.info(
          'Settings loaded: income=\$$monthlyIncome, savings=\$$savingsGoal');

      setState(() {
        _incomeController.text = monthlyIncome.toStringAsFixed(0);
        _savingsController.text = savingsGoal.toStringAsFixed(0);
        _incomeSliderValue = monthlyIncome;
        _savingsSliderValue = savingsGoal;
        _isLoading = false;
      });
    } catch (e, st) {
      AppLogger.widgets.severe('Error loading settings', e, st);
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        final error = AppError.fromException(
          e,
          type: AppErrorType.validation,
          stackTrace: st,
        );
        ErrorDisplay.showErrorSnackBar(context, error);
      }
    }
  }

  /// Calculate savings rate as percentage
  double _getSavingsRate() {
    final income = double.tryParse(_incomeController.text) ?? 0;
    final savings = double.tryParse(_savingsController.text) ?? 0;
    if (income <= 0) return 0.0;
    return (savings / income * 100).clamp(0, 100);
  }

  Future<void> _saveSettings() async {
    HapticFeedback.mediumImpact();
    AppLogger.widgets.info('Saving financial goals settings');

    final income = double.tryParse(_incomeController.text);
    final savings = double.tryParse(_savingsController.text);

    // Validate income
    if (income == null || income <= 0) {
      HapticFeedback.heavyImpact();
      AppLogger.widgets.warning('Invalid income: $_incomeController.text');

      ErrorDisplay.showErrorSnackBar(
        context,
        const AppError(
          type: AppErrorType.validation,
          message: 'Please enter a valid monthly income',
        ),
      );
      return;
    }

    // Validate savings
    if (savings == null || savings < 0) {
      HapticFeedback.heavyImpact();
      AppLogger.widgets.warning('Invalid savings: $_savingsController.text');

      ErrorDisplay.showErrorSnackBar(
        context,
        const AppError(
          type: AppErrorType.validation,
          message: 'Please enter a valid savings target',
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('monthly_income', income);
      await prefs.setDouble('savings_goal', savings);

      // Verify save by reading back
      final savedIncome = prefs.getDouble('monthly_income');
      final savedSavings = prefs.getDouble('savings_goal');

      if (savedIncome == income && savedSavings == savings) {
        HapticFeedback.lightImpact();
        AppLogger.widgets.info(
            'Settings saved successfully: income=\$$income, savings=\$$savings');

        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          ErrorDisplay.showSuccessSnackBar(
            context,
            'Financial goals saved successfully',
          );
        }
      } else {
        throw Exception('Settings verification failed');
      }
    } catch (e, st) {
      HapticFeedback.heavyImpact();
      AppLogger.widgets.severe('Error saving settings', e, st);

      if (mounted) {
        final error = e is AppError
            ? e
            : AppError.fromException(
                e,
                type: AppErrorType.validation,
                stackTrace: st,
              );
        setState(() {
          _isSaving = false;
        });
        ErrorDisplay.showErrorSnackBar(context, error);
      }
    }
  }

  Future<void> _resetToDefaults() async {
    AppLogger.widgets.info('Resetting financial goals to defaults');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset to Defaults?',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
            'This will reset your income and savings target to default values. Continue?',
            style: GoogleFonts.spaceGrotesk()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.gray700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Reset',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      HapticFeedback.mediumImpact();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('monthly_income');
        await prefs.remove('savings_goal');

        HapticFeedback.lightImpact();
        AppLogger.widgets.info('Settings reset to defaults');

        await _loadSettings();

        if (mounted) {
          ErrorDisplay.showSuccessSnackBar(
            context,
            'Settings reset to defaults',
          );
        }
      } catch (e, st) {
        HapticFeedback.heavyImpact();
        AppLogger.widgets.severe('Error resetting settings', e, st);

        if (mounted) {
          final error = e is AppError
              ? e
              : AppError.fromException(
                  e,
                  type: AppErrorType.validation,
                  stackTrace: st,
                );
          ErrorDisplay.showErrorSnackBar(context, error);
        }
      }
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _savingsController.dispose();
    AppLogger.widgets.info('FinancialGoalsFormWidget disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        _buildSectionHeader(
          icon: Icons.trending_up,
          title: 'PRIMARY FINANCIAL GOALS',
          subtitle: 'Growth & Accumulation',
          color: AppColors.fintechTeal,
        ),

        const SizedBox(height: DesignTokens.spacingMd),

        // Income Card
        _buildIncomeCard(),

        const SizedBox(height: DesignTokens.spacingMd),

        // Savings Target Card
        _buildSavingsTargetCard(),

        const SizedBox(height: DesignTokens.spacingXl),

        // Action Buttons
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeCard() {
    return _buildGrowthCard(
      icon: Icons.arrow_downward,
      iconColor: AppColors.fintechTeal,
      title: 'Total Monthly Income',
      subtitle: 'Net take-home pay from all sources',
      value: _incomeController.text,
      prefix: '\$',
      controller: _incomeController,
      sliderValue: _incomeSliderValue,
      minSliderValue: 0,
      maxSliderValue: 20000,
      sliderStep: 100,
      tooltipMessage:
          'Your total monthly household income after taxes. This is used to calculate your savings rate and daily budget.',
      onSliderChanged: (value) {
        setState(() {
          _incomeSliderValue = value;
          _incomeController.text = value.toStringAsFixed(0);
        });
      },
      onTextChanged: (value) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          setState(() {
            _incomeSliderValue = parsed;
          });
        }
      },
    );
  }

  Widget _buildSavingsTargetCard() {
    final savingsRate = _getSavingsRate();

    return _buildGrowthCard(
      icon: Icons.savings,
      iconColor: AppColors.fintechGrowth,
      title: 'Monthly Savings Target',
      subtitle: 'Amount to set aside each month for accumulation',
      value: _savingsController.text,
      prefix: '\$',
      controller: _savingsController,
      sliderValue: _savingsSliderValue,
      minSliderValue: 0,
      maxSliderValue: 5000,
      sliderStep: 50,
      tooltipMessage:
          'The amount you aim to save each month. This is tracked in your financial health analytics and helps measure your savings progress.',
      onSliderChanged: (value) {
        setState(() {
          _savingsSliderValue = value;
          _savingsController.text = value.toStringAsFixed(0);
        });
      },
      onTextChanged: (value) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          setState(() {
            _savingsSliderValue = parsed;
          });
        }
      },
      trailingWidget: _buildSavingsRateBadge(savingsRate),
    );
  }

  Widget _buildSavingsRateBadge(double rate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.fintechGrowth.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.fintechGrowth.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.percent,
            size: 12,
            color: AppColors.fintechGrowth,
          ),
          const SizedBox(width: 4),
          Text(
            '${rate.toStringAsFixed(1)}% of income',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.fintechGrowth,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String value,
    required String prefix,
    required TextEditingController controller,
    required double sliderValue,
    required double minSliderValue,
    required double maxSliderValue,
    required double sliderStep,
    required String tooltipMessage,
    required ValueChanged<double> onSliderChanged,
    required ValueChanged<String> onTextChanged,
    Widget? trailingWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: AppColors.gray700,
                      ),
                    ),
                  ],
                ),
              ),
              // Info tooltip
              InkWell(
                onTap: () => _showTooltipDialog(context, title, tooltipMessage),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.gray500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: iconColor,
              inactiveTrackColor: iconColor.withOpacity(0.2),
              thumbColor: iconColor,
              overlayColor: iconColor.withOpacity(0.15),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: sliderValue.clamp(minSliderValue, maxSliderValue),
              min: minSliderValue,
              max: maxSliderValue,
              divisions: ((maxSliderValue - minSliderValue) / sliderStep).round(),
              label: '$prefix${sliderValue.toStringAsFixed(0)}',
              onChanged: (value) => onSliderChanged(value),
            ),
          ),

          const SizedBox(height: 8),

          // Text input with trailing badge
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: onTextChanged,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: iconColor.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    prefixText: prefix,
                    prefixStyle: GoogleFonts.jetBrainsMono(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                  ),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
              ),
              if (trailingWidget != null) ...[
                const SizedBox(width: 12),
                trailingWidget,
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Save Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.fintechTeal,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.border,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Save Financial Goals',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        // Reset Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _resetToDefaults,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gray700,
              side: BorderSide(color: AppColors.gray300),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Reset to Defaults',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showTooltipDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: AppColors.fintechTeal,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            height: 1.5,
            color: AppColors.gray700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.fintechTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
