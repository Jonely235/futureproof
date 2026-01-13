import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_colors.dart';
import '../models/app_error.dart';
import '../utils/app_logger.dart';
import '../utils/error_display.dart';

/// Financial Goals Form Widget
///
/// A self-contained form widget for managing monthly income and savings goals.
/// Handles loading, validation, saving, and resetting of financial settings.
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
          message: 'Please enter a valid savings goal',
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
            'Settings saved successfully',
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
        title: const Text('Reset to Defaults?'),
        content: const Text(
            'This will reset all settings to default values. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Reset',
              style: TextStyle(color: AppColors.danger),
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
        _buildSettingCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Monthly Income',
          subtitle: 'Your total monthly household income',
          child: TextField(
            controller: _incomeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Income',
              prefixText: '\$',
              border: InputBorder.none,
              filled: true,
            ),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingCard(
          icon: Icons.savings_outlined,
          title: 'Savings Goal',
          subtitle: 'How much you want to save each month',
          child: TextField(
            controller: _savingsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Goal',
              prefixText: '\$',
              border: InputBorder.none,
              filled: true,
            ),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
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
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.black),
                    ),
                  )
                : Text(
                    'Save Settings',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _resetToDefaults,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: const BorderSide(color: AppColors.danger),
            ),
            child: Text(
              'Reset to Defaults',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.black,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: AppColors.gray700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}
