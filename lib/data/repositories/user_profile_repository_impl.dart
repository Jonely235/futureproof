import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../../domain/value_objects/money_personality_type.dart';
import '../../domain/value_objects/life_stage.dart';
import '../../domain/value_objects/insight_category.dart';
import '../../services/database_service.dart';

/// User profile repository implementation
/// Stores user preferences for behavioral insights
class UserProfileRepositoryImpl implements UserProfileRepository {
  final DatabaseService _databaseService;

  // Cache for reactive updates
  final _controller = StreamController<UserProfileEntity?>.broadcast();
  UserProfileEntity? _cachedProfile;

  UserProfileRepositoryImpl({
    DatabaseService? databaseService,
  }) : _databaseService = databaseService ?? DatabaseService();

  @override
  Future<UserProfileEntity?> getCurrentProfile() async {
    if (_cachedProfile != null) return _cachedProfile;

    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'user_profiles',
        limit: 1,
      );

      if (maps.isEmpty) {
        // Create default profile if none exists
        final defaultProfile = UserProfileEntity.create(id: 'default');
        await saveProfile(defaultProfile);
        _cachedProfile = defaultProfile;
        return defaultProfile;
      }

      _cachedProfile = _mapToEntity(maps.first);
      return _cachedProfile;
    } catch (e) {
      // Return default profile on error
      final defaultProfile = UserProfileEntity.create(id: 'default');
      return defaultProfile;
    }
  }

  @override
  Future<UserProfileEntity?> getProfileById(String id) async {
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'user_profiles',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return _mapToEntity(maps.first);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveProfile(UserProfileEntity profile) async {
    try {
      final db = await _databaseService.database;
      final data = _entityToMap(profile);

      await db.insert(
        'user_profiles',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _cachedProfile = profile;
      _controller.add(profile);
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }

  @override
  Future<void> updatePersonalityType(MoneyPersonalityType type) async {
    final profile = await getCurrentProfile();
    if (profile == null) {
      throw Exception('No profile found');
    }

    final updated = profile.copyWith(
      personalityType: type,
      updatedAt: DateTime.now(),
    );

    await saveProfile(updated);
  }

  @override
  Future<void> updateLifeStage(LifeStage stage) async {
    final profile = await getCurrentProfile();
    if (profile == null) {
      throw Exception('No profile found');
    }

    final updated = profile.copyWith(
      lifeStage: stage,
      updatedAt: DateTime.now(),
    );

    await saveProfile(updated);
  }

  @override
  Future<void> updateStressLevel(FinancialStressLevel level) async {
    final profile = await getCurrentProfile();
    if (profile == null) {
      throw Exception('No profile found');
    }

    final updated = profile.copyWith(
      stressLevel: level,
      updatedAt: DateTime.now(),
    );

    await saveProfile(updated);
  }

  @override
  Future<void> updateDeliveryPreferences({
    int? maxInsightsPerDay,
    int? cooldownHours,
    DateTime? preferredDailyTime,
  }) async {
    final profile = await getCurrentProfile();
    if (profile == null) {
      throw Exception('No profile found');
    }

    TimeOfDay? newTime;
    if (preferredDailyTime != null) {
      newTime = TimeOfDay(
        hour: preferredDailyTime.hour,
        minute: preferredDailyTime.minute,
      );
    }

    final updated = profile.copyWith(
      maxInsightsPerDay: maxInsightsPerDay,
      cooldownHours: cooldownHours,
      preferredDailyTime: newTime,
      updatedAt: DateTime.now(),
    );

    await saveProfile(updated);
  }

  @override
  Future<void> setCategoryEnabled(String categoryId, bool enabled) async {
    final profile = await getCurrentProfile();
    if (profile == null) {
      throw Exception('No profile found');
    }

    final category = InsightCategory.values.firstWhere(
      (c) => c.name == categoryId,
      orElse: () => InsightCategory.budgetHealth,
    );

    final newCategories = Set<InsightCategory>.from(profile.enabledInsightCategories);

    if (enabled) {
      newCategories.add(category);
    } else {
      // Don't allow disabling essential categories
      if (!category.isEssential) {
        newCategories.remove(category);
      }
    }

    final updated = profile.copyWith(
      enabledInsightCategories: newCategories,
      updatedAt: DateTime.now(),
    );

    await saveProfile(updated);
  }

  @override
  Future<void> setWarModeEnabled(bool enabled) async {
    final profile = await getCurrentProfile();
    if (profile == null) {
      throw Exception('No profile found');
    }

    final updated = profile.copyWith(
      warModeEnabled: enabled,
      updatedAt: DateTime.now(),
    );

    await saveProfile(updated);
  }

  @override
  Future<void> setLocationAlertsEnabled(bool enabled) async {
    final profile = await getCurrentProfile();
    if (profile == null) {
      throw Exception('No profile found');
    }

    final updated = profile.copyWith(
      locationAlertsEnabled: enabled,
      updatedAt: DateTime.now(),
    );

    await saveProfile(updated);
  }

  @override
  Stream<UserProfileEntity?> observeProfile() {
    getCurrentProfile().then((profile) {
      if (profile != null) {
        _controller.add(profile);
      }
    });

    return _controller.stream;
  }

  @override
  Future<void> deleteProfile(String id) async {
    try {
      final db = await _databaseService.database;
      await db.delete(
        'user_profiles',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (_cachedProfile?.id == id) {
        _cachedProfile = null;
        _controller.add(null);
      }
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
    }
  }

  void dispose() {
    _controller.close();
  }

  // Mappers

  UserProfileEntity _mapToEntity(Map<String, dynamic> map) {
    return UserProfileEntity(
      id: map['id'] as String,
      personalityType: MoneyPersonalityType.values.firstWhere(
        (e) => e.name == map['personality_type'],
        orElse: () => MoneyPersonalityType.spender,
      ),
      lifeStage: LifeStage.values.firstWhere(
        (e) => e.name == map['life_stage'],
        orElse: () => LifeStage.earlyCareer,
      ),
      stressLevel: FinancialStressLevel.values.firstWhere(
        (e) => e.name == map['stress_level'],
        orElse: () => FinancialStressLevel.medium,
      ),
      enabledInsightCategories: _parseCategories(map['enabled_categories'] as String?),
      preferredDailyTime: _parseTimeOfDay(map['preferred_time'] as String?),
      maxInsightsPerDay: map['max_insights_per_day'] as int? ?? 5,
      cooldownHours: map['cooldown_hours'] as int? ?? 4,
      warModeEnabled: (map['war_mode_enabled'] as int?) == 1,
      locationAlertsEnabled: (map['location_alerts_enabled'] as int?) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> _entityToMap(UserProfileEntity entity) {
    return {
      'id': entity.id,
      'personality_type': entity.personalityType.name,
      'life_stage': entity.lifeStage.name,
      'stress_level': entity.stressLevel.name,
      'enabled_categories': _serializeCategories(entity.enabledInsightCategories),
      'preferred_time': entity.preferredDailyTime.format(),
      'max_insights_per_day': entity.maxInsightsPerDay,
      'cooldown_hours': entity.cooldownHours,
      'war_mode_enabled': entity.warModeEnabled ? 1 : 0,
      'location_alerts_enabled': entity.locationAlertsEnabled ? 1 : 0,
      'created_at': entity.createdAt.millisecondsSinceEpoch,
      'updated_at': entity.updatedAt.millisecondsSinceEpoch,
    };
  }

  Set<InsightCategory> _parseCategories(String? data) {
    if (data == null || data.isEmpty) {
      return InsightCategory.values.toSet();
    }

    try {
      final names = data.split(',');
      return names
          .map((name) => InsightCategory.values.firstWhere(
                (e) => e.name == name,
                orElse: () => InsightCategory.budgetHealth,
              ))
          .toSet();
    } catch (e) {
      return InsightCategory.values.toSet();
    }
  }

  String _serializeCategories(Set<InsightCategory> categories) {
    return categories.map((c) => c.name).join(',');
  }

  TimeOfDay _parseTimeOfDay(String? data) {
    if (data == null || data.isEmpty) {
      return const TimeOfDay(hour: 8, minute: 0);
    }

    try {
      return TimeOfDay.parse(data);
    } catch (e) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }
}
