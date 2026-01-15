import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import '../config/app_colors.dart';
import '../domain/repositories/cloud_backup_repository.dart';
import '../utils/app_logger.dart';
import '../models/app_error.dart';

/// Firebase Setup Wizard - 5-step configuration flow
///
/// Replaces raw JSON paste with guided step-by-step setup.
/// Each step validates user input before allowing progression.
///
/// Steps:
/// 1. Welcome & Overview
/// 2. API Key
/// 3. Project ID
/// 4. App ID & Messaging Sender ID
/// 5. Review & Confirm
class FirebaseSetupWizard extends StatefulWidget {
  final CloudBackupRepository cloudBackupRepo;
  final VoidCallback onSetupComplete;

  const FirebaseSetupWizard({
    super.key,
    required this.cloudBackupRepo,
    required this.onSetupComplete,
  });

  @override
  State<FirebaseSetupWizard> createState() => _FirebaseSetupWizardState();
}

class _FirebaseSetupWizardState extends State<FirebaseSetupWizard> {
  int _currentStep = 0;
  bool _isConnecting = false;

  // Form controllers
  final _apiKeyController = TextEditingController();
  final _appIdController = TextEditingController();
  final _projectIdController = TextEditingController();
  final _senderIdController = TextEditingController();

  // Validation state
  final Map<int, bool> _stepValid = {
    0: true, // Welcome always valid
    1: false,
    2: false,
    3: false,
    4: false,
  };

  @override
  void dispose() {
    _apiKeyController.dispose();
    _appIdController.dispose();
    _projectIdController.dispose();
    _senderIdController.dispose();
    super.dispose();
  }

  bool _validateAppDetails() {
    final appIdValid = _appIdController.text.isNotEmpty &&
        _appIdController.text.contains(':');
    final senderIdValid = _senderIdController.text.isNotEmpty &&
        int.tryParse(_senderIdController.text) != null;
    return appIdValid && senderIdValid;
  }

  bool _isCurrentStepValid() {
    return _stepValid[_currentStep] ?? false;
  }

  Future<void> _connectToFirebase() async {
    HapticFeedback.mediumImpact();
    setState(() => _isConnecting = true);

    try {
      // Initialize Firebase
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: _apiKeyController.text.trim(),
            appId: _appIdController.text.trim(),
            messagingSenderId: _senderIdController.text.trim(),
            projectId: _projectIdController.text.trim(),
          ),
        );
        AppLogger.widgets.info('Firebase initialized via wizard');
      }

      // Authenticate
      await widget.cloudBackupRepo.authenticate();

      if (mounted) {
        widget.onSetupComplete();
        Navigator.pop(context);
      }
    } catch (e) {
      AppLogger.widgets.severe('Firebase setup failed', e);
      setState(() => _isConnecting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Firebase Setup',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
      ),
      body: _isConnecting
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: _currentStep,
              onStepContinue: _currentStep < 4
                  ? () {
                      if (_isCurrentStepValid()) {
                        setState(() => _currentStep++);
                      }
                    }
                  : _connectToFirebase,
              onStepCancel: _currentStep > 0
                  ? () => setState(() => _currentStep--)
                  : null,
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: Text(
                            'Back',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (_currentStep < 4 && !_isCurrentStepValid()) ||
                                  (_currentStep == 4 && _isConnecting)
                              ? null
                              : details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.black,
                            foregroundColor: AppColors.white,
                            disabledBackgroundColor: AppColors.border,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _currentStep == 4 ? 'Complete Setup' : 'Next',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              steps: [
                _buildWelcomeStep(),
                _buildApiKeyStep(),
                _buildProjectIdStep(),
                _buildAppDetailsStep(),
                _buildReviewStep(),
              ],
            ),
    );
  }

  Step _buildWelcomeStep() {
    return Step(
      title: const Text('Welcome'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.fintechTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.fintechTeal),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_sync,
                    color: AppColors.fintechTeal, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Set up Firebase Cloud Sync',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildHelpCard(
            'What is Firebase?',
            'Firebase is Google\'s cloud platform that will securely backup your financial data.',
            Icons.info_outline,
          ),
          const SizedBox(height: 16),
          _buildHelpCard(
            'Getting Started',
            '1. Go to console.firebase.google.com\n'
            '2. Create a new project\n'
            '3. Add a web app to your project\n'
            '4. Copy the configuration values from the next steps.',
            Icons.list_alt,
          ),
        ],
      ),
    );
  }

  Step _buildApiKeyStep() {
    return Step(
      title: const Text('API Key'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHelpCard(
            'API Key',
            'A secret key that authenticates your app. Found in your Firebase app configuration.',
            Icons.key,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            onChanged: (value) => setState(() {
              _stepValid[1] = value.isNotEmpty && value.length > 10;
            }),
            decoration: InputDecoration(
              labelText: 'API Key',
              prefixIcon: const Icon(Icons.vpn_key_outlined),
              hintText: 'AIzaSy...',
              border: const OutlineInputBorder(),
              suffixIcon: _stepValid[1] == true
                  ? const Icon(Icons.check_circle, color: AppColors.success)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Step _buildProjectIdStep() {
    return Step(
      title: const Text('Project ID'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHelpCard(
            'Project ID',
            'Your unique Firebase project identifier. Found in Project Settings > General.',
            Icons.badge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _projectIdController,
            onChanged: (value) => setState(() {
              _stepValid[2] = value.isNotEmpty && !value.contains(' ');
            }),
            decoration: InputDecoration(
              labelText: 'Project ID',
              prefixIcon: const Icon(Icons.badge_outlined),
              hintText: 'e.g., my-finance-app',
              border: const OutlineInputBorder(),
              suffixIcon: _stepValid[2] == true
                  ? const Icon(Icons.check_circle, color: AppColors.success)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Step _buildAppDetailsStep() {
    return Step(
      title: const Text('App Details'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHelpCard(
            'App Details',
            'Your Firebase app identifier and messaging sender ID. Found in your Firebase app configuration.',
            Icons.app_settings_alt,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _appIdController,
            onChanged: (value) => setState(() {
              _stepValid[3] = _validateAppDetails();
            }),
            decoration: InputDecoration(
              labelText: 'App ID',
              prefixIcon: const Icon(Icons.app_registration),
              hintText: '1:123456789:web:abcdef',
              border: const OutlineInputBorder(),
              suffixIcon: _stepValid[3] == true
                  ? const Icon(Icons.check_circle, color: AppColors.success)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _senderIdController,
            onChanged: (value) => setState(() {
              _stepValid[3] = _validateAppDetails();
            }),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Messaging Sender ID',
              prefixIcon: const Icon(Icons.send),
              hintText: '123456789',
              border: const OutlineInputBorder(),
              suffixIcon: _stepValid[3] == true
                  ? const Icon(Icons.check_circle, color: AppColors.success)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Step _buildReviewStep() {
    return Step(
      title: const Text('Review'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.fintechTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.fintechTeal),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.fintechTeal),
                    const SizedBox(width: 12),
                    Text(
                      'Ready to Connect',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildReviewRow('Project ID', _projectIdController.text),
                _buildReviewRow('API Key', _maskApiKey(_apiKeyController.text)),
                _buildReviewRow('App ID', _appIdController.text),
                _buildReviewRow('Sender ID', _senderIdController.text),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap "Complete Setup" to initialize Firebase with these settings.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              color: AppColors.gray700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.fintechTeal, size: 20),
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
                const SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: AppColors.gray700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: AppColors.gray700,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: AppColors.gray700)),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not set' : value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: value.isEmpty ? AppColors.gray500 : AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _maskApiKey(String key) {
    if (key.length <= 8) return key;
    return '${key.substring(0, 8)}...';
  }
}
