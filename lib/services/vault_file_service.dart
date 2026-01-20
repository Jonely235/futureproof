import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';
import '../utils/app_logger.dart';
import '../domain/entities/vault_entity.dart';

/// Service for managing vault file operations
///
/// Handles vault directory creation, deletion, and file I/O.
/// Manages vault index registry and metadata storage.
class VaultFileService {
  static final _instance = VaultFileService._internal();
  static final _log = Logger('VaultFileService');
  static const String _vaultsDirName = 'vaults';
  static const String _vaultIndexFileName = 'vault_index.json';
  static const String _vaultFileName = 'vault.json';
  static const String _settingsFileName = 'settings.json';
  static const String _activeVaultKey = 'active_vault_id';

  String? _vaultsBasePath;
  final _vaultsController = StreamController<List<VaultEntity>>.broadcast();
  final _activeVaultController = StreamController<VaultEntity?>.broadcast();

  factory VaultFileService() => _instance;
  VaultFileService._internal();

  /// Get base directory for vaults
  Future<Directory> get _vaultsBaseDir async {
    if (_vaultsBasePath != null) {
      return Directory(_vaultsBasePath!);
    }

    if (kIsWeb) {
      throw UnsupportedError('Vault file operations not supported on web');
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final vaultsDir = Directory(path.join(appDocDir.path, _vaultsDirName));

    // Create vaults directory if it doesn't exist
    if (!await vaultsDir.exists()) {
      await vaultsDir.create(recursive: true);
      AppLogger.vaults.info('📁 Created vaults directory: ${vaultsDir.path}');
    }

    _vaultsBasePath = vaultsDir.path;
    return vaultsDir;
  }

  /// Get all vault IDs from index
  Future<List<String>> getVaultIds() async {
    try {
      if (kIsWeb) return [];

      final indexFile = await _getVaultIndexFile();
      if (!await indexFile.exists()) {
        return [];
      }

      final indexJson = await indexFile.readAsString();
      final index = jsonDecode(indexJson) as Map<String, dynamic>;
      final vaults = index['vaults'] as List?;

      if (vaults == null) return [];

      return vaults
          .map((v) => v as Map<String, dynamic>)
          .map((v) => v['id'] as String)
          .toList();
    } catch (e, st) {
      AppLogger.vaults.severe('❌ Error reading vault IDs', e, st);
      return [];
    }
  }

  /// Get vault index file
  Future<File> _getVaultIndexFile() async {
    final baseDir = await _vaultsBaseDir;
    return File(path.join(baseDir.path, _vaultIndexFileName));
  }

  /// Get vault directory
  Future<Directory> getVaultDirectory(String vaultId) async {
    final baseDir = await _vaultsBaseDir;
    final vaultDir = Directory(path.join(baseDir.path, vaultId));

    if (!await vaultDir.exists()) {
      throw Exception('Vault directory does not exist: $vaultId');
    }

    return vaultDir;
  }

  /// Create vault directory structure
  Future<Directory> createVaultDirectory(String vaultId) async {
    if (kIsWeb) {
      throw UnsupportedError('Vault creation not supported on web');
    }

    final baseDir = await _vaultsBaseDir;
    final vaultDir = Directory(path.join(baseDir.path, vaultId));

    if (await vaultDir.exists()) {
      throw Exception('Vault directory already exists: $vaultId');
    }

    await vaultDir.create(recursive: true);

    // Create subdirectories
    final transactionsDir =
        Directory(path.join(vaultDir.path, 'transactions'));
    await transactionsDir.create(recursive: true);

    AppLogger.vaults.info('📁 Created vault directory: ${vaultDir.path}');
    return vaultDir;
  }

  /// Delete vault directory
  Future<void> deleteVaultDirectory(String vaultId) async {
    if (kIsWeb) {
      throw UnsupportedError('Vault deletion not supported on web');
    }

    final vaultDir = await getVaultDirectory(vaultId);

    // Delete entire directory
    await vaultDir.delete(recursive: true);

    // Remove from index
    await _removeVaultFromIndex(vaultId);

    AppLogger.vaults.info('🗑️ Deleted vault directory: ${vaultDir.path}');
  }

  /// Get vault metadata file
  Future<File> _getVaultMetadataFile(String vaultId) async {
    final vaultDir = await getVaultDirectory(vaultId);
    return File(path.join(vaultDir.path, _vaultFileName));
  }

  /// Save vault metadata
  Future<void> saveVaultMetadata(VaultEntity vault) async {
    if (kIsWeb) {
      throw UnsupportedError('Saving vault metadata not supported on web');
    }

    final metadataFile = await _getVaultMetadataFile(vault.id);
    final json = jsonEncode(vault.toJson());
    await metadataFile.writeAsString(json);

    AppLogger.vaults
        .info('💾 Saved vault metadata: ${vault.name} (${vault.id})');
  }

  /// Load vault metadata
  Future<VaultEntity?> loadVaultMetadata(String vaultId) async {
    try {
      if (kIsWeb) return null;

      final metadataFile = await _getVaultMetadataFile(vaultId);
      if (!await metadataFile.exists()) {
        return null;
      }

      final json = await metadataFile.readAsString();
      final data = jsonDecode(json) as Map<String, dynamic>;
      return VaultEntity.fromJson(data);
    } catch (e, st) {
      AppLogger.vaults.severe('❌ Error loading vault metadata: $vaultId', e, st);
      return null;
    }
  }

  /// Get vault settings file
  Future<File> _getVaultSettingsFile(String vaultId) async {
    final vaultDir = await getVaultDirectory(vaultId);
    return File(path.join(vaultDir.path, _settingsFileName));
  }

  /// Save vault settings
  Future<void> saveVaultSettings(
      String vaultId, Map<String, dynamic> settings) async {
    if (kIsWeb) return;

    final settingsFile = await _getVaultSettingsFile(vaultId);
    final json = jsonEncode(settings);
    await settingsFile.writeAsString(json);

    AppLogger.vaults.info('💾 Saved vault settings: $vaultId');
  }

  /// Load vault settings
  Future<Map<String, dynamic>?> loadVaultSettings(String vaultId) async {
    try {
      if (kIsWeb) return null;

      final settingsFile = await _getVaultSettingsFile(vaultId);
      if (!await settingsFile.exists()) {
        return null;
      }

      final json = await settingsFile.readAsString();
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e, st) {
      AppLogger.vaults.severe('❌ Error loading vault settings: $vaultId', e, st);
      return null;
    }
  }

  /// Get active vault ID from preferences
  Future<String?> getActiveVaultId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeVaultKey);
  }

  /// Set active vault ID in preferences
  Future<void> setActiveVaultId(String vaultId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeVaultKey, vaultId);
    AppLogger.vaults.info('✅ Set active vault: $vaultId');
  }

  /// Clear active vault ID
  Future<void> clearActiveVaultId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeVaultKey);
    AppLogger.vaults.info('🧹 Cleared active vault');
  }

  /// Update vault index with new vault
  ///
  /// Adds a vault to the vault_index.json registry file.
  /// This is required for the vault to appear in getAllVaults().
  Future<void> addVaultToIndex(VaultEntity vault) async {
    if (kIsWeb) return;

    final indexFile = await _getVaultIndexFile();
    Map<String, dynamic> index = {};

    if (await indexFile.exists()) {
      final indexJson = await indexFile.readAsString();
      index = jsonDecode(indexJson) as Map<String, dynamic>;
    }

    final vaults = (index['vaults'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .toList();

    // Add new vault entry
    vaults.add({
      'id': vault.id,
      'name': vault.name,
      'path': '$_vaultsDirName/${vault.id}/',
      'createdAt': vault.createdAt.toIso8601String(),
    });

    index['vaults'] = vaults;
    index['version'] = '1.0';

    await indexFile.writeAsString(jsonEncode(index));
    AppLogger.vaults.info('📝 Added vault to index: ${vault.id}');
  }

  /// Remove vault from index
  Future<void> _removeVaultFromIndex(String vaultId) async {
    if (kIsWeb) return;

    final indexFile = await _getVaultIndexFile();
    if (!await indexFile.exists()) return;

    final indexJson = await indexFile.readAsString();
    final index = jsonDecode(indexJson) as Map<String, dynamic>;
    final vaults = (index['vaults'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .toList();

    vaults.removeWhere((v) => v['id'] == vaultId);

    index['vaults'] = vaults;
    await indexFile.writeAsString(jsonEncode(index));
    AppLogger.vaults.info('📝 Removed vault from index: $vaultId');
  }

  /// Notify vaults changed
  void notifyVaultsChanged(List<VaultEntity> vaults) {
    _vaultsController.add(vaults);
  }

  /// Notify active vault changed
  void notifyActiveVaultChanged(VaultEntity? vault) {
    _activeVaultController.add(vault);
  }

  /// Stream of vaults changes
  Stream<List<VaultEntity>> get vaultsStream => _vaultsController.stream;

  /// Stream of active vault changes
  Stream<VaultEntity?> get activeVaultStream => _activeVaultController.stream;

  /// Generate unique vault ID
  String generateVaultId() {
    return const Uuid().v4();
  }

  /// Check if vault directory exists
  Future<bool> vaultDirectoryExists(String vaultId) async {
    if (kIsWeb) return false;

    try {
      final baseDir = await _vaultsBaseDir;
      final vaultDir = Directory(path.join(baseDir.path, vaultId));
      return await vaultDir.exists();
    } catch (e) {
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _vaultsController.close();
    _activeVaultController.close();
  }
}
