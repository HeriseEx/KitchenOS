import 'resource.dart';

/// 用户厨房配置
/// 对应 PRD 中的 kitchen_resources 表
class KitchenProfile {
  final String userId;
  final List<Resource> resources;
  final bool isConfigured;
  final DateTime? lastUpdated;

  KitchenProfile({
    required this.userId,
    required this.resources,
    this.isConfigured = false,
    this.lastUpdated,
  });

  /// 获取有效资源池（与可用资源取交集）
  List<Resource> getEffectiveResources(List<String>? availableResourceIds) {
    if (availableResourceIds == null || availableResourceIds.isEmpty) {
      return resources;
    }
    return resources
        .where((r) => availableResourceIds.contains(r.id))
        .toList();
  }

  KitchenProfile copyWith({
    String? userId,
    List<Resource>? resources,
    bool? isConfigured,
    DateTime? lastUpdated,
  }) {
    return KitchenProfile(
      userId: userId ?? this.userId,
      resources: resources ?? this.resources,
      isConfigured: isConfigured ?? this.isConfigured,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'resources': resources.map((e) => e.toJson()).toList(),
      'is_configured': isConfigured,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  factory KitchenProfile.fromJson(Map<String, dynamic> json) {
    return KitchenProfile(
      userId: json['user_id'],
      resources: (json['resources'] as List)
          .map((e) => Resource.fromJson(e))
          .toList(),
      isConfigured: json['is_configured'] ?? false,
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated'])
          : null,
    );
  }

  /// 默认配置（若用户跳过）
  factory KitchenProfile.defaultProfile(String userId) {
    return KitchenProfile(
      userId: userId,
      resources: Resource.defaultResources,
      isConfigured: false,
      lastUpdated: DateTime.now(),
    );
  }
}
