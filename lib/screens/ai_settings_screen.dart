import 'package:flutter/material.dart';
import '../providers/ai_provider.dart';
import '../services/ai/llama_model_manager.dart';
import '../config/app_colors.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<AIProvider>(
        builder: (context, aiProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isReady
            ? Colors.green[50]
            : hasError
                ? Colors.red[50]
                : Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady
              ? Colors.green[200]!
              : hasError
                  ? Colors.red[200]!
                  : Colors.blue[200]!,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isReady
                ? Icons.check_circle
                : hasError
                    ? Icons.error
                    : isInitializing
                        ? Icons.downloading
                        : Icons.info,
            size: 48,
            color: isReady
                ? Colors.green[700]
                : hasError
                    ? Colors.red[700]
                    : Colors.blue[700],
          ),
          const SizedBox(height: 12),
          Text(
            isReady
                ? 'AI Ready'
                : hasError
                    ? 'AI Error'
                    : isInitializing
                        ? 'Initializing...'
                        : 'AI Not Ready',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isReady
                ? 'Your AI advisor is ready to help!'
                : hasError
                    ? aiProvider.errorMessage ?? 'Unknown error'
                    : isInitializing
                        ? 'Please wait while we set up AI...'
                        : 'Download a model to get started',
            style: TextStyle(
              color: Colors.grey[700],
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
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                aiProvider.currentModel!.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
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
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.model_training, color: Colors.white),
                ),
                title: Text(model.name),
                subtitle: Text(model.fileSizeFormatted),
                trailing: model.recommended
                    ? Chip(
                        label: const Text('In Use'),
                        backgroundColor: Colors.green[100],
                        labelStyle: TextStyle(color: Colors.green[900]),
                      )
                    : IconButton(
                        icon: const Icon(Icons.delete),
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
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Model Downloaded',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Download a model below to enable AI features',
            style: TextStyle(color: Colors.grey[600]),
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

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'RECOMMENDED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${model.fileSizeFormatted} • ${model.contextLength} tokens',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
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
                    LinearProgressIndicator(value: _downloadProgress),
                    const SizedBox(height: 8),
                    Text(_downloadStatus, style: TextStyle(fontSize: 12)),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _downloadModel(model),
                    icon: const Icon(Icons.download),
                    label: const Text('Download Model'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
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

        return Card(
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
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      storageFormatted,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _confirmClearAll(),
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[700],
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
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reset AI Service'),
            subtitle: const Text('Restart AI if experiencing issues'),
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
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Build Instructions'),
            subtitle: const Text('How to compile llama.cpp'),
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
            content: Text('${model.name} downloaded successfully!'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: Colors.red[700],
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
        title: const Text('Delete Model?'),
        content: Text('Are you sure you want to delete ${model.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('Delete'),
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
            content: Text('${model.name} deleted'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    }
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Models?'),
        content: const Text('This will delete all downloaded AI models. AI features will be unavailable until you download a new model.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red[700]),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<AIProvider>().clearAllModels();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All models cleared'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _resetAIService(AIProvider aiProvider) async {
    await aiProvider.reset();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI service reset'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showBuildInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Build llama.cpp'),
        content: const SingleChildScrollView(
          child: Text(
            'To build llama.cpp for your platform:\n\n'
            '1. See LLAMA_CPP_BUILD_GUIDE.md in the project root\n'
            '2. iOS: Use Xcode with Metal support\n'
            '3. Android: Use NDK with ARM64\n\n'
            'Quick start:\n'
            '- Download pre-built libraries from llama.cpp releases\n'
            '- Place in ios/libs/ or android/jniLibs/arm64-v8a/\n\n'
            'For detailed instructions, check the build guide.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
