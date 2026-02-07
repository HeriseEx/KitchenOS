import 'enums.dart';

/// 烹饪步骤模型
/// 对应 PRD 中的 S = (d, deps, R, p, cleaning)
class Step {
  final String id;
  final String recipeId;
  final String action;                    // 步骤动作描述
  final String? description;              // 详细说明
  final int durationSeconds;              // 持续时间（秒）
  final List<String> dependencies;        // 依赖的步骤ID
  final String? resourceType;             // 所需资源类型
  final String? resourceId;               // 分配的具体资源ID
  final ParallelLevel parallelLevel;      // 并行等级
  final bool requiresCleaningAfter;       // 是否需要清洗后才能复用
  final bool isPrepRequired;              // 是否需要预处理
  final int orderIndex;                   // 步骤顺序
  
  // 调度相关（CPM计算后填充）
  int? earliestStart;
  int? earliestFinish;
  int? latestStart;
  int? latestFinish;
  int? slack;                             // 松弛时间
  bool isOnCriticalPath;                  // 是否在关键路径上

  Step({
    required this.id,
    required this.recipeId,
    required this.action,
    this.description,
    required this.durationSeconds,
    this.dependencies = const [],
    this.resourceType,
    this.resourceId,
    this.parallelLevel = ParallelLevel.focused,
    this.requiresCleaningAfter = false,
    this.isPrepRequired = false,
    required this.orderIndex,
    this.earliestStart,
    this.earliestFinish,
    this.latestStart,
    this.latestFinish,
    this.slack,
    this.isOnCriticalPath = false,
  });

  Step copyWith({
    String? id,
    String? recipeId,
    String? action,
    String? description,
    int? durationSeconds,
    List<String>? dependencies,
    String? resourceType,
    String? resourceId,
    ParallelLevel? parallelLevel,
    bool? requiresCleaningAfter,
    bool? isPrepRequired,
    int? orderIndex,
    int? earliestStart,
    int? earliestFinish,
    int? latestStart,
    int? latestFinish,
    int? slack,
    bool? isOnCriticalPath,
  }) {
    return Step(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      action: action ?? this.action,
      description: description ?? this.description,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      dependencies: dependencies ?? this.dependencies,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      parallelLevel: parallelLevel ?? this.parallelLevel,
      requiresCleaningAfter: requiresCleaningAfter ?? this.requiresCleaningAfter,
      isPrepRequired: isPrepRequired ?? this.isPrepRequired,
      orderIndex: orderIndex ?? this.orderIndex,
      earliestStart: earliestStart ?? this.earliestStart,
      earliestFinish: earliestFinish ?? this.earliestFinish,
      latestStart: latestStart ?? this.latestStart,
      latestFinish: latestFinish ?? this.latestFinish,
      slack: slack ?? this.slack,
      isOnCriticalPath: isOnCriticalPath ?? this.isOnCriticalPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipe_id': recipeId,
      'action': action,
      'description': description,
      'duration_seconds': durationSeconds,
      'dependencies': dependencies,
      'resource_type': resourceType,
      'resource_id': resourceId,
      'parallel_level': parallelLevel.value,
      'requires_cleaning_after': requiresCleaningAfter,
      'is_prep_required': isPrepRequired,
      'order_index': orderIndex,
    };
  }

  factory Step.fromJson(Map<String, dynamic> json) {
    return Step(
      id: json['id'],
      recipeId: json['recipe_id'],
      action: json['action'],
      description: json['description'],
      durationSeconds: json['duration_seconds'],
      dependencies: List<String>.from(json['dependencies'] ?? []),
      resourceType: json['resource_type'],
      resourceId: json['resource_id'],
      parallelLevel: ParallelLevel.values[json['parallel_level'] ?? 0],
      requiresCleaningAfter: json['requires_cleaning_after'] ?? false,
      isPrepRequired: json['is_prep_required'] ?? false,
      orderIndex: json['order_index'] ?? 0,
    );
  }
}
