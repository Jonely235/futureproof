import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

/// Provider for managing settings accordion expansion state
///
/// Handles:
/// - Expansion state for each settings section
/// - Persistence to SharedPreferences
/// - Default expansion states for priority sections
class SettingsExpansionProvider extends ChangeNotifier {
  static const String _storageKey = 'settings_expansion_state';

  // Expansion state map: sectionId -> isExpanded
  Map<String, bool> _expansionState = {};

  // Default expansion states
  static const Map<String, bool> _defaultStates = {
    'finance': true,      // Finance: expanded by default
    'appearance': true,   // Appearance: expanded by default
    'ai': true,          // AI Settings: expanded by default
    'data': false,       // Data & Sync: collapsed by default
    'about': false,      // About: collapsed by default
    'advanced': false,   // Advanced: collapsed by default
  };

  bool _isLoading = true;

  /// Get current expansion state for a section
  bool isExpanded(String sectionId) {
    return _expansionState[sectionId] ?? _defaultStates[sectionId] ?? false;
  }

  /// Toggle expansion state for a section
  Future<void> toggle(String sectionId) async {
    final currentState = isExpanded(sectionId);
    _expansionState[sectionId] = !currentState;
    AppLogger.ui.info('Toggled $sectionId: ${!currentState}');
    notifyListeners();
    await _saveState();
  }

  /// Set expansion state for a section
  Future<void> setExpanded(String sectionId, bool expanded) async {
    _expansionState[sectionId] = expanded;
    notifyListeners();
    await _saveState();
  }

  /// Check if loading
  bool get isLoading => _isLoading;

  /// Load expansion state from SharedPreferences
  Future<void> loadState() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_storageKey);

      if (stateJson != null) {
        final decoded = jsonDecode(stateJson) as Map<String, dynamic>;
        _expansionState = decoded.map(
          (key, value) => MapEntry(key, value as bool),
        );
        AppLogger.ui.info('Loaded expansion state: $_expansionState');
      } else {
        // First load - use defaults
        _expansionState = Map<String, bool>.from(_defaultStates);
        AppLogger.ui.info('Using default expansion states');
      }
    } catch (e, st) {
      AppLogger.ui.warning('Error loading expansion state: $e');
      // Fallback to defaults on error
      _expansionState = Map<String, bool>.from(_defaultStates);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save expansion state to SharedPreferences
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = jsonEncode(_expansionState);
      await prefs.setString(_storageKey, stateJson);
      AppLogger.ui.info('Saved expansion state');
    } catch (e) {
      AppLogger.ui.warning('Error saving expansion state: $e');
    }
  }

  /// Reset all sections to default states
  Future<void> resetToDefaults() async {
    _expansionState = Map<String, bool>.from(_defaultStates);
    notifyListeners();
    await _saveState();
    AppLogger.ui.info('Reset expansion state to defaults');
  }

  @override
  void dispose() {
    super.dispose();
  }
}
