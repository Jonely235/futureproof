import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/ai_provider.dart';
import '../services/ai/llama_model_manager.dart';
import '../config/app_colors.dart';
import '../design/design_tokens.dart';
import 'package:provider/provider.dart';
import 'dart:io';

/// AI Settings Screen
/// Manages Llama model download, deletion, and configuration
class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Initialize and check model status
    final aiProvider = context.read<AIProvider>();
    final hasModel = await aiProvider.hasModel();

    if (hasModel && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'AI Settings',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.black),
      ),
      body: Consumer<AIProvider>(
        builder: (context, aiProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Status card
              _buildStatusCard(aiProvider),

              const SizedBox(height: 24),

              // Model management section
              _buildSectionHeader('AI Model'),
              const SizedBox(height: 12),
              _buildModelManagement(aiProvider),

              const SizedBox(height: 24),

              // Available models section
              _buildSectionHeader('Available Models'),
              const SizedBox(height: 12),
              ..._buildAvailableModels(),

              const SizedBox(height: 24),

              // Storage info
              _buildSectionHeader('Storage'),
              const SizedBox(height: 12),
              _buildStorageInfo(),

              const SizedBox(height: 24),

              // Troubleshooting
              _buildSectionHeader('Troubleshooting'),
              const SizedBox(height: 12),
              _buildTroubleshooting(aiProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(AIProvider aiProvider) {
    final isReady = aiProvider.isReady;
    final isInitializing = aiProvider.isInitializing;
    final hasError = aiProvider.errorMessage != null;

    Color cardColor;
    Color borderColor;
    IconData iconData;
    Color iconColor;
    String statusText;
    String messageText;

    if (isReady) {
      cardColor = AppColors.success.withOpacity(0.1);
      borderColor = AppColors.success.withOpacity(0.3);
      iconData = Icons.check_circle;
      iconColor = AppColors.success;
      statusText = 'AI Ready';
      messageText = 'Your AI advisor is ready to help!';
    } else if (hasError) {
      cardColor = AppColors.danger.withOpacity(0.1);
      borderColor = AppColors.danger.withOpacity(0.3);
      iconData = Icons.error;
      iconColor = AppColors.danger;
      statusText = 'AI Error';
      messageText = aiProvider.errorMessage ?? 'Unknown error';
    } else if (isInitializing) {
      cardColor = AppColors.fintechTeal.withOpacity(0.1);
      borderColor = AppColors.fintechTeal.withOpacity(0.3);
      iconData = Icons.downloading;
      iconColor = AppColors.fintechTeal;
      statusText = 'Initializing...';
      messageText = 'Please wait while we set up AI...';
    } else {
      cardColor = AppColors.gray200;
      borderColor = AppColors.gray400;
      iconData = Icons.info;
      iconColor = AppColors.gray700;
      statusText = 'AI Not Ready';
      messageText = 'Download a model to get started';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            iconData,
            size: 48,
            color: iconColor,
          ),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            messageText,
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.gray700,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (aiProvider.currentModel != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                aiProvider.currentModel!.name,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.black,
      ),
    );
  }

  Widget _buildModelManagement(AIProvider aiProvider) {
    return FutureBuilder<List<ModelSpec>>(
      future: aiProvider.getAvailableModels(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final models = snapshot.data!;

        if (models.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: models.map((model) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: DesignTokens.borderRadiusLg,
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.fintechTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                  ),
                  child: const Icon(
                    Icons.model_training,
                    color: AppColors.fintechTeal,
                    size: 20,
                  ),
                ),
                title: Text(
                  model.name,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                subtitle: Text(
                  model.fileSizeFormatted,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: AppColors.gray700,
                  ),
                ),
                trailing: model.recommended
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                        ),
                        child: Text(
                          'In Use',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.danger),
                        onPressed: () => _confirmDeleteModel(model, aiProvider),
                      ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off,
            size: 64,
            color: AppColors.gray500,
          ),
          const SizedBox(height: 16),
          Text(
            'No Model Downloaded',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Download a model below to enable AI features',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.gray700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAvailableModels() {
    return LlamaModelManager.availableModels.entries.map((entry) {
      final model = entry.value;
      final isRecommended = model.recommended;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              model.name,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.black,
                              ),
                            ),
                            if (isRecommended) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.fintechTeal, Color(0xFF00A896)],
                                  ),
                                  borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                                ),
                                child: Text(
                                  'RECOMMENDED',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${model.fileSizeFormatted} • ${model.contextLength} tokens',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.gray700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isDownloading && _downloadStatus.contains(model.id))
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _downloadProgress,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.fintechTeal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _downloadStatus,
                      style: GoogleFonts.spaceGrotesk(fontSize: 12),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _downloadModel(model),
                    icon: const Icon(Icons.download),
                    label: Text(
                      'Download Model',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.fintechTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildStorageInfo() {
    return FutureBuilder<int>(
      future: context.read<AIProvider>().getModelsStorageSize(),
      builder: (context, snapshot) {
        final storageUsed = snapshot.data ?? 0;
        final storageFormatted = _formatBytes(storageUsed);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Storage Used',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        color: AppColors.gray700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      storageFormatted,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _confirmClearAll(),
                  icon: const Icon(Icons.delete_sweep),
                  label: Text(
                    'Clear All',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTroubleshooting(AIProvider aiProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.refresh, color: AppColors.gray700),
            title: Text(
              'Reset AI Service',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            subtitle: Text(
              'Restart AI if experiencing issues',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: AppColors.gray700,
              ),
            ),
            trailing: aiProvider.isInitializing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: aiProvider.isInitializing
                ? null
                : () => _resetAIService(aiProvider),
          ),
          Divider(height: 1, color: AppColors.border),
          ListTile(
            leading: const Icon(Icons.help_outline, color: AppColors.gray700),
            title: Text(
              'Build Instructions',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            subtitle: Text(
              'How to compile llama.cpp',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: AppColors.gray700,
              ),
            ),
            onTap: () => _showBuildInstructions(),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadModel(ModelSpec model) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatus = 'Starting download...';
    });

    try {
      // In a real implementation, you would:
      // 1. Use dio or http package to download with progress
      // 2. Save to app documents directory
      // 3. Verify the download

      // For now, simulate download
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        setState(() {
          _downloadProgress = i / 100;
          _downloadStatus = 'Downloading ${model.name}... ${i}%';
        });
      }

      setState(() {
        _downloadStatus = 'Download complete!';
      });

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${model.name} downloaded successfully!',
              style: GoogleFonts.spaceGrotesk(),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Download failed: ${e.toString()}',
              style: GoogleFonts.spaceGrotesk(),
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> _confirmDeleteModel(ModelSpec model, AIProvider aiProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: DesignTokens.borderRadiusLg),
        title: Text(
          'Delete Model?',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${model.name}?',
          style: GoogleFonts.spaceGrotesk(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: DesignTokens.borderRadiusSm,
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await aiProvider.deleteModel(model.id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${model.name} deleted',
              style: GoogleFonts.spaceGrotesk(),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: DesignTokens.borderRadiusLg),
        title: Text(
          'Clear All Models?',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        content: const Text(
          'This will delete all downloaded AI models. AI features will be unavailable until you download a new model.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: DesignTokens.borderRadiusSm,
              ),
            ),
            child: Text(
              'Clear All',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<AIProvider>().clearAllModels();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'All models cleared',
              style: GoogleFonts.spaceGrotesk(),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _resetAIService(AIProvider aiProvider) async {
    await aiProvider.reset();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'AI service reset',
            style: GoogleFonts.spaceGrotesk(),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showBuildInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: DesignTokens.borderRadiusLg),
        title: Text(
          'Build llama.cpp',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            'To build llama.cpp for your platform:\n\n'
            '1. See LLAMA_CPP_BUILD_GUIDE.md in the project root\n'
            '2. iOS: Use Xcode with Metal support\n'
            '3. Android: Use NDK with ARM64\n\n'
            'Quick start:\n'
            '- Download pre-built libraries from llama.cpp releases\n'
            '- Place in ios/libs/ or android/jniLibs/arm64-v8a/\n\n'
            'For detailed instructions, check the build guide.',
            style: GoogleFonts.spaceGrotesk(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
