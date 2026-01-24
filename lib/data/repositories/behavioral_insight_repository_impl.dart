import 'dart:async';
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/behavioral_insight_entity.dart';
import '../../domain/repositories/behavioral_insight_repository.dart';
import '../../domain/value_objects/insight_category.dart';
import '../../domain/value_objects/life_stage.dart';
import '../../services/database_service.dart';
import '../../utils/app_logger.dart';

/// Behavioral insight repository implementation
/// Stores and retrieves behavioral insights
class BehavioralInsightRepositoryImpl implements BehavioralInsightRepository {
  final DatabaseService _databaseService;
  static final _log = Logger('BehavioralInsightRepository');

  // Cache for reactive updates
  final _controller = StreamController<List<BehavioralInsightEntity>>.broadcast();
  List<BehavioralInsightEntity>? _cachedInsights;

  BehavioralInsightRepositoryImpl({
    DatabaseService? databaseService,
  }) : _databaseService = databaseService ?? DatabaseService();

  @override
  Future<List<BehavioralInsightEntity>> getActiveInsights() async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final List<Map<String, dynamic>> maps = await db.query(
        'behavioral_insights',
        where: 'is_dismissed = 0 AND action_performed = 0 AND (expires_at IS NULL OR expires_at > ?)',
        whereArgs: [now],
        orderBy: 'priority DESC, generated_at DESC',
      );

      _cachedInsights = maps.map((map) => BehavioralInsightEntity.fromMap(map)).toList();
      _controller.add(_cachedInsights!);
      return _cachedInsights!;
    } catch (e, st) {
      _log.warning('Failed to get active insights: $e');
      return [];
    }
  }

  @override
  Future<List<BehavioralInsightEntity>> getInsightsByCategory(
    InsightCategory category,
  ) async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final List<Map<String, dynamic>> maps = await db.query(
        'behavioral_insights',
        where: 'category = ? AND is_dismissed = 0 AND action_performed = 0 AND (expires_at IS NULL OR expires_at > ?)',
        whereArgs: [category.name, now],
        orderBy: 'priority DESC, generated_at DESC',
      );

      return maps.map((map) => BehavioralInsightEntity.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<BehavioralInsightEntity>> getInsightsByPriority(
    InsightPriority minPriority,
  ) async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final minPriorityValue = minPriority.sortValue;

      final List<Map<String, dynamic>> maps = await db.query(
        'behavioral_insights',
        where: 'priority >= ? AND is_dismissed = 0 AND action_performed = 0 AND (expires_at IS NULL OR expires_at > ?)',
        whereArgs: [minPriorityValue, now],
        orderBy: 'priority DESC, generated_at DESC',
      );

      return maps.map((map) => BehavioralInsightEntity.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<BehavioralInsightEntity>> getInsightsSince(DateTime since) async {
    try {
      final db = await _databaseService.database;
      final sinceMs = since.millisecondsSinceEpoch;

      final List<Map<String, dynamic>> maps = await db.query(
        'behavioral_insights',
        where: 'generated_at >= ?',
        whereArgs: [sinceMs],
        orderBy: 'generated_at DESC',
      );

      return maps.map((map) => BehavioralInsightEntity.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<BehavioralInsightEntity?> getInsightById(String id) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'behavioral_insights',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return BehavioralInsightEntity.fromMap(maps.first);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveInsight(BehavioralInsightEntity insight) async {
    try {
      final db = await _databaseService.database;
      final data = insight.toMap();

      await db.insert(
        'behavioral_insights',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _invalidateCache();
    } catch (e) {
      throw Exception('Failed to save insight: $e');
    }
  }

  @override
  Future<void> saveInsights(List<BehavioralInsightEntity> insights) async {
    if (insights.isEmpty) return;

    try {
      final db = await _databaseService.database;
      final batch = db.batch();

      for (final insight in insights) {
        batch.insert(
          'behavioral_insights',
          insight.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      _invalidateCache();
    } catch (e) {
      throw Exception('Failed to save insights: $e');
    }
  }

  @override
  Future<void> dismissInsight(String insightId) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'behavioral_insights',
        {'is_dismissed': 1},
        where: 'id = ?',
        whereArgs: [insightId],
      );

      _invalidateCache();
    } catch (e) {
      throw Exception('Failed to dismiss insight: $e');
    }
  }

  @override
  Future<void> markActionPerformed(String insightId) async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.update(
        'behavioral_insights',
        {
          'action_performed': 1,
          'action_performed_at': now,
        },
        where: 'id = ?',
        whereArgs: [insightId],
      );

      _invalidateCache();
    } catch (e) {
      throw Exception('Failed to mark action performed: $e');
    }
  }

  @override
  Future<void> incrementDisplayCount(String insightId) async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      // First get current count
      final current = await getInsightById(insightId);
      if (current == null) return;

      final newCount = current.displayCount + 1;

      await db.update(
        'behavioral_insights',
        {
          'display_count': newCount,
          'last_displayed_at': now,
        },
        where: 'id = ?',
        whereArgs: [insightId],
      );

      _invalidateCache();
    } catch (e, st) {
      _log.fine('Failed to increment display count for insight $insightId: $e');
    }
  }

  @override
  Future<int> clearExpiredInsights() async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final count = await db.delete(
        'behavioral_insights',
        where: 'expires_at IS NOT NULL AND expires_at < ?',
        whereArgs: [now],
      );

      if (count > 0) {
        _invalidateCache();
      }

      return count;
    } catch (e, st) {
      _log.warning('Failed to clear expired insights: $e');
      return 0;
    }
  }

  @override
  Future<void> clearAllInsights() async {
    try {
      final db = await _databaseService.database;
      await db.delete('behavioral_insights');
      _invalidateCache();
    } catch (e) {
      throw Exception('Failed to clear insights: $e');
    }
  }

  @override
  Future<int> getInsightsShownToday() async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

      final result = await db.rawQuery('''
        SELECT COUNT(DISTINCT id) as count
        FROM behavioral_insights
        WHERE last_displayed_at >= ?
      ''', [startOfDay]);

      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<bool> wasInsightShownRecently(
    String ruleId,
    Duration cooldown,
  ) async {
    try {
      final db = await _databaseService.database;
      final cutoff = DateTime.now().subtract(cooldown).millisecondsSinceEpoch;

      final result = await db.query(
        'behavioral_insights',
        where: 'rule_id = ? AND last_displayed_at > ?',
        whereArgs: [ruleId, cutoff],
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<List<BehavioralInsightEntity>> observeInsights() {
    getActiveInsights().then((insights) {
      _controller.add(insights);
    });

    return _controller.stream;
  }

  @override
  Stream<List<BehavioralInsightEntity>> observeInsightsByCategory(
    InsightCategory category,
  ) {
    getInsightsByCategory(category).then((insights) {
      _controller.add(insights);
    });

    return _controller.stream;
  }

  @override
  Future<List<BehavioralInsightEntity>> getPendingActionInsights() async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      final List<Map<String, dynamic>> maps = await db.query(
        'behavioral_insights',
        where: 'action_performed = 0 AND is_dismissed = 0 AND action_label IS NOT NULL AND action_label != "" AND (expires_at IS NULL OR expires_at > ?)',
        whereArgs: [now],
        orderBy: 'priority DESC, generated_at DESC',
      );

      return maps.map((map) => BehavioralInsightEntity.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  void _invalidateCache() {
    _cachedInsights = null;
    getActiveInsights();
  }

  void dispose() {
    _controller.close();
  }
}
