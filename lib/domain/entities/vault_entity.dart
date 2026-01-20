import 'dart:convert';

/// Vault entity - represents a finance vault (like Obsidian vaults)
///
/// Each vault contains its own isolated set of transactions,
/// settings, and data. Users can have multiple vaults for
/// different purposes (personal, business, family, etc.).
class VaultEntity {
  final String id;
  final String name;
  final VaultType type;
  final DateTime createdAt;
  final DateTime lastModified;
  final int transactionCount;
  final VaultSettings settings;
  final bool isActive;
  final bool cloudKitSyncEnabled;
  final DateTime? lastCloudSync;

  VaultEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    required this.lastModified,
    this.transactionCount = 0,
    VaultSettings? settings,
    this.isActive = false,
    this.cloudKitSyncEnabled = true,
    this.lastCloudSync,
  }) : settings = settings ?? const VaultSettings();

  /// Create a copy with modified fields
  VaultEntity copyWith({
    String? id,
    String? name,
    VaultType? type,
    DateTime? createdAt,
    DateTime? lastModified,
    int? transactionCount,
    VaultSettings? settings,
    bool? isActive,
    bool? cloudKitSyncEnabled,
    DateTime? lastCloudSync,
  }) {
    return VaultEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      transactionCount: transactionCount ?? this.transactionCount,
      settings: settings ?? this.settings,
      isActive: isActive ?? this.isActive,
      cloudKitSyncEnabled: cloudKitSyncEnabled ?? this.cloudKitSyncEnabled,
      lastCloudSync: lastCloudSync ?? this.lastCloudSync,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'transactionCount': transactionCount,
      'settings': settings.toJson(),
      'isActive': isActive,
      'cloudKitSyncEnabled': cloudKitSyncEnabled,
      'lastCloudSync': lastCloudSync?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory VaultEntity.fromJson(Map<String, dynamic> json) {
    return VaultEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      type: VaultType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => VaultType.custom,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: DateTime.parse(json['lastModified'] as String),
      transactionCount: json['transactionCount'] as int? ?? 0,
      settings: json['settings'] != null
          ? VaultSettings.fromJson(json['settings'] as Map<String, dynamic>)
          : null,
      isActive: json['isActive'] as bool? ?? false,
      cloudKitSyncEnabled: json['cloudKitSyncEnabled'] as bool? ?? true,
      lastCloudSync: json['lastCloudSync'] != null
          ? DateTime.parse(json['lastCloudSync'] as String)
          : null,
    );
  }

  /// Serialize to string
  String serialize() {
    return jsonEncode(toJson());
  }

  /// Deserialize from string
  static VaultEntity deserialize(String data) {
    return VaultEntity.fromJson(jsonDecode(data) as Map<String, dynamic>);
  }
}

/// Vault settings - configurable options for a vault
class VaultSettings {
  final double monthlyIncome;
  final double savingsGoal;
  final int themeIndex;

  const VaultSettings({
    this.monthlyIncome = 0.0,
    this.savingsGoal = 0.0,
    this.themeIndex = 0,
  });

  /// Create a copy with modified fields
  VaultSettings copyWith({
    double? monthlyIncome,
    double? savingsGoal,
    int? themeIndex,
  }) {
    return VaultSettings(
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      savingsGoal: savingsGoal ?? this.savingsGoal,
      themeIndex: themeIndex ?? this.themeIndex,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'monthlyIncome': monthlyIncome,
      'savingsGoal': savingsGoal,
      'themeIndex': themeIndex,
    };
  }

  /// Create from JSON
  factory VaultSettings.fromJson(Map<String, dynamic> json) {
    return VaultSettings(
      monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble() ?? 0.0,
      savingsGoal: (json['savingsGoal'] as num?)?.toDouble() ?? 0.0,
      themeIndex: json['themeIndex'] as int? ?? 0,
    );
  }
}

/// Vault type - predefined categories for organization
enum VaultType {
  personal,
  business,
  family,
  custom,
}

/// Vault type extension for display names
extension VaultTypeExtension on VaultType {
  String get displayName {
    switch (this) {
      case VaultType.personal:
        return 'Personal';
      case VaultType.business:
        return 'Business';
      case VaultType.family:
        return 'Family';
      case VaultType.custom:
        return 'Custom';
    }
  }

  String get icon {
    switch (this) {
      case VaultType.personal:
        return '👤';
      case VaultType.business:
        return '💼';
      case VaultType.family:
        return '👨‍👩‍👧‍👦';
      case VaultType.custom:
        return '📁';
    }
  }
}
