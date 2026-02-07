/// KitchenOS 数据模型
/// 基于 PRD Phase 1 MVP 定义

// 资源类型枚举
enum ResourceType {
  stove,      // 灶具
  wok,        // 炒锅
  stewPot,    // 炖锅
  steamer,    // 蒸锅
  cuttingBoard, // 案板
  oven,       // 烤箱
}

// 火力等级
enum HeatLevel {
  high,
  medium,
  low,
}

// 资源状态
enum ResourceState {
  free,       // 可用
  occupied,   // 占用中
  dirty,      // 待清洗/阻塞
}

// 并行等级
enum ParallelLevel {
  focused,    // 0 - 需要专注
  parallel,   // 1 - 可并行
  background, // 2 - 后台任务
}

// Timeline节点类型
enum TimelineNodeType {
  step,       // 普通倒计时任务
  checkpoint, // 非时间敏感的阻塞任务（清洗）
}

extension ResourceTypeExtension on ResourceType {
  String get displayName {
    switch (this) {
      case ResourceType.stove:
        return '灶具';
      case ResourceType.wok:
        return '炒锅';
      case ResourceType.stewPot:
        return '炖锅';
      case ResourceType.steamer:
        return '蒸锅';
      case ResourceType.cuttingBoard:
        return '案板';
      case ResourceType.oven:
        return '烤箱';
    }
  }

  String get icon {
    switch (this) {
      case ResourceType.stove:
        return '🔥';
      case ResourceType.wok:
        return '🍳';
      case ResourceType.stewPot:
        return '🍲';
      case ResourceType.steamer:
        return '♨️';
      case ResourceType.cuttingBoard:
        return '🔪';
      case ResourceType.oven:
        return '🍞';
    }
  }
}

extension HeatLevelExtension on HeatLevel {
  String get displayName {
    switch (this) {
      case HeatLevel.high:
        return '大火';
      case HeatLevel.medium:
        return '中火';
      case HeatLevel.low:
        return '小火';
    }
  }
}

extension ResourceStateExtension on ResourceState {
  String get displayName {
    switch (this) {
      case ResourceState.free:
        return '可用';
      case ResourceState.occupied:
        return '使用中';
      case ResourceState.dirty:
        return '待清洗';
    }
  }
}

extension ParallelLevelExtension on ParallelLevel {
  String get displayName {
    switch (this) {
      case ParallelLevel.focused:
        return '需专注';
      case ParallelLevel.parallel:
        return '可并行';
      case ParallelLevel.background:
        return '后台';
    }
  }

  int get value {
    switch (this) {
      case ParallelLevel.focused:
        return 0;
      case ParallelLevel.parallel:
        return 1;
      case ParallelLevel.background:
        return 2;
    }
  }
}
