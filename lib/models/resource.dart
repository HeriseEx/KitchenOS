import 'enums.dart';

/// 厨房资源模型
/// 对应 PRD 中的 resources 表
class Resource {
  final String id;
  final ResourceType type;
  final HeatLevel? heatLevel;        // 灶具专用
  final double? capacityLiters;      // 锅具容量
  final int? maxTempCelsius;         // 烤箱最高温度
  final bool? isMeatSafe;            // 案板是否可处理生肉
  ResourceState state;
  final String? name;                // 自定义名称

  Resource({
    required this.id,
    required this.type,
    this.heatLevel,
    this.capacityLiters,
    this.maxTempCelsius,
    this.isMeatSafe,
    this.state = ResourceState.free,
    this.name,
  });

  String get displayName => name ?? '${type.displayName} ${id.split('_').last}';

  /// 检查资源是否满足能力要求
  bool meetsRequirements({
    HeatLevel? requiredHeatLevel,
    double? requiredCapacity,
    int? requiredTemp,
    bool? requiresMeatSafe,
  }) {
    // 类型必须匹配
    if (requiredHeatLevel != null && heatLevel != null) {
      // 火力降级：high可以做medium/low的活，但low不能做high的活
      final heatOrder = [HeatLevel.low, HeatLevel.medium, HeatLevel.high];
      if (heatOrder.indexOf(heatLevel!) < heatOrder.indexOf(requiredHeatLevel)) {
        return false;
      }
    }
    
    if (requiredCapacity != null && capacityLiters != null) {
      if (capacityLiters! < requiredCapacity) return false;
    }
    
    if (requiredTemp != null && maxTempCelsius != null) {
      if (maxTempCelsius! < requiredTemp) return false;
    }
    
    if (requiresMeatSafe == true && isMeatSafe != true) {
      return false;
    }
    
    return true;
  }

  Resource copyWith({
    String? id,
    ResourceType? type,
    HeatLevel? heatLevel,
    double? capacityLiters,
    int? maxTempCelsius,
    bool? isMeatSafe,
    ResourceState? state,
    String? name,
  }) {
    return Resource(
      id: id ?? this.id,
      type: type ?? this.type,
      heatLevel: heatLevel ?? this.heatLevel,
      capacityLiters: capacityLiters ?? this.capacityLiters,
      maxTempCelsius: maxTempCelsius ?? this.maxTempCelsius,
      isMeatSafe: isMeatSafe ?? this.isMeatSafe,
      state: state ?? this.state,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'heat_level': heatLevel?.name,
      'capacity_liters': capacityLiters,
      'max_temp_celsius': maxTempCelsius,
      'is_meat_safe': isMeatSafe,
      'state': state.name,
      'name': name,
    };
  }

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'],
      type: ResourceType.values.firstWhere((e) => e.name == json['type']),
      heatLevel: json['heat_level'] != null 
          ? HeatLevel.values.firstWhere((e) => e.name == json['heat_level'])
          : null,
      capacityLiters: json['capacity_liters']?.toDouble(),
      maxTempCelsius: json['max_temp_celsius'],
      isMeatSafe: json['is_meat_safe'],
      state: json['state'] != null 
          ? ResourceState.values.firstWhere((e) => e.name == json['state'])
          : ResourceState.free,
      name: json['name'],
    );
  }

  /// 默认资源池（若用户跳过配置）
  static List<Resource> get defaultResources => [
    Resource(
      id: 'stove_1',
      type: ResourceType.stove,
      heatLevel: HeatLevel.high,
      name: '主灶',
    ),
    Resource(
      id: 'wok_1',
      type: ResourceType.wok,
      capacityLiters: 3.0,
      name: '炒锅',
    ),
    Resource(
      id: 'cutting_board_1',
      type: ResourceType.cuttingBoard,
      isMeatSafe: true,
      name: '案板',
    ),
  ];
}
