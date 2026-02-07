import 'enums.dart';

/// Timeline节点（步骤或检查点）
class TimelineNode {
  final String id;
  final TimelineNodeType type;
  final String? resourceId;
  final String action;
  final String? description;
  final ParallelLevel? parallelLevel;
  final int durationSeconds;
  final DateTime startAt;
  final DateTime endAt;
  final String? reason;                   // checkpoint专用：阻塞原因
  final String? recipeId;
  final String? stepId;
  bool isCompleted;
  bool isActive;

  TimelineNode({
    required this.id,
    required this.type,
    this.resourceId,
    required this.action,
    this.description,
    this.parallelLevel,
    required this.durationSeconds,
    required this.startAt,
    required this.endAt,
    this.reason,
    this.recipeId,
    this.stepId,
    this.isCompleted = false,
    this.isActive = false,
  });

  bool get isCheckpoint => type == TimelineNodeType.checkpoint;
  bool get isStep => type == TimelineNodeType.step;
  
  /// 判断是否为烹饪步骤（需要加热的步骤，自动倒计时）
  /// 使用灶具、炒锅、炖锅、蒸锅、烤箱 = 烹饪步骤
  bool get isCookingStep {
    if (isCheckpoint) return false;
    if (resourceId == null) return false;
    // 根据resourceId前缀判断资源类型
    final id = resourceId!.toLowerCase();
    return id.startsWith('stove') || 
           id.startsWith('wok') || 
           id.startsWith('stew') || 
           id.startsWith('steamer') || 
           id.startsWith('oven');
  }
  
  /// 判断是否为准备步骤（切菜、洗菜等，需要手动确认）
  /// 使用案板或无资源 = 准备步骤
  bool get isPrepStep {
    if (isCheckpoint) return false;
    if (resourceId == null) return true; // 无资源默认为准备步骤
    final id = resourceId!.toLowerCase();
    return id.startsWith('cutting');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'resource_id': resourceId,
      'action': action,
      'description': description,
      'parallel_level': parallelLevel?.value,
      'duration_seconds': durationSeconds,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'reason': reason,
      'recipe_id': recipeId,
      'step_id': stepId,
    };
  }

  factory TimelineNode.fromJson(Map<String, dynamic> json) {
    return TimelineNode(
      id: json['id'],
      type: TimelineNodeType.values.firstWhere((e) => e.name == json['type']),
      resourceId: json['resource_id'],
      action: json['action'],
      description: json['description'],
      parallelLevel: json['parallel_level'] != null 
          ? ParallelLevel.values[json['parallel_level']]
          : null,
      durationSeconds: json['duration_seconds'],
      startAt: DateTime.parse(json['start_at']),
      endAt: DateTime.parse(json['end_at']),
      reason: json['reason'],
      recipeId: json['recipe_id'],
      stepId: json['step_id'],
    );
  }
}

/// 计划指标
class PlanMetrics {
  final int totalDurationSeconds;         // 总时长（含清洗buffer）
  final int activeCookingSeconds;         // 实际烹饪时间
  final int cleaningBufferSeconds;        // 清洗预留时间
  final int savedSeconds;                 // 通过并行节省的时间

  PlanMetrics({
    required this.totalDurationSeconds,
    required this.activeCookingSeconds,
    required this.cleaningBufferSeconds,
    this.savedSeconds = 0,
  });

  String get totalDurationFormatted {
    final minutes = totalDurationSeconds ~/ 60;
    final seconds = totalDurationSeconds % 60;
    return seconds > 0 ? '$minutes分$seconds秒' : '$minutes分钟';
  }

  Map<String, dynamic> toJson() {
    return {
      'total_duration_seconds': totalDurationSeconds,
      'active_cooking_seconds': activeCookingSeconds,
      'cleaning_buffer_seconds': cleaningBufferSeconds,
      'saved_seconds': savedSeconds,
    };
  }

  factory PlanMetrics.fromJson(Map<String, dynamic> json) {
    return PlanMetrics(
      totalDurationSeconds: json['total_duration_seconds'],
      activeCookingSeconds: json['active_cooking_seconds'],
      cleaningBufferSeconds: json['cleaning_buffer_seconds'],
      savedSeconds: json['saved_seconds'] ?? 0,
    );
  }
}

/// 烹饪计划
class CookingPlan {
  final String planId;
  final String status;                    // done, degraded, error
  final String? degradationReason;        // 降级原因
  final PlanMetrics metrics;
  final List<TimelineNode> timeline;
  final List<String> recipeIds;
  final List<String> warnings;
  final DateTime createdAt;

  CookingPlan({
    required this.planId,
    required this.status,
    this.degradationReason,
    required this.metrics,
    required this.timeline,
    required this.recipeIds,
    this.warnings = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isDegraded => degradationReason != null;
  
  /// 获取关键路径上的节点
  List<TimelineNode> get criticalPath {
    // 简化实现：返回最长持续时间链路上的节点
    return timeline.where((n) => n.isStep).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'plan_id': planId,
      'status': status,
      'degradation_reason': degradationReason,
      'metrics': metrics.toJson(),
      'timeline': timeline.map((e) => e.toJson()).toList(),
      'recipe_ids': recipeIds,
      'warnings': warnings,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CookingPlan.fromJson(Map<String, dynamic> json) {
    return CookingPlan(
      planId: json['plan_id'],
      status: json['status'],
      degradationReason: json['degradation_reason'],
      metrics: PlanMetrics.fromJson(json['metrics']),
      timeline: (json['timeline'] as List)
          .map((e) => TimelineNode.fromJson(e))
          .toList(),
      recipeIds: List<String>.from(json['recipe_ids']),
      warnings: List<String>.from(json['warnings'] ?? []),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}
