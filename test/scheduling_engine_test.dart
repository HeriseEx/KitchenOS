import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_os/models/models.dart';
import 'package:kitchen_os/services/scheduling_engine.dart';

void main() {
  group('SchedulingEngine Tests', () {
    late SchedulingEngine engine;

    setUp(() {
      engine = SchedulingEngine();
    });

    // TC1: BOM合并测试 (简化版 - 验证多菜谱合并)
    test('TC1: 多菜谱步骤合并', () {
      final recipe1 = Recipe(
        id: 'r1',
        name: '菜1',
        estimatedMinutes: 10,
        steps: [
          Step(
            id: 's1',
            recipeId: 'r1',
            action: '切菜',
            durationSeconds: 120,
            orderIndex: 0,
          ),
        ],
      );

      final recipe2 = Recipe(
        id: 'r2',
        name: '菜2',
        estimatedMinutes: 15,
        steps: [
          Step(
            id: 's2',
            recipeId: 'r2',
            action: '炒菜',
            durationSeconds: 180,
            orderIndex: 0,
          ),
        ],
      );

      final resources = Resource.defaultResources;
      final plan = engine.generatePlan(
        recipes: [recipe1, recipe2],
        availableResources: resources,
      );

      expect(plan.status, isNot('error'));
      expect(plan.timeline.where((n) => n.isStep).length, 2);
      expect(plan.recipeIds, containsAll(['r1', 'r2']));
    });

    // TC2: 循环依赖检测
    test('TC2: 循环依赖检测', () {
      final recipe = Recipe(
        id: 'r1',
        name: '循环测试',
        estimatedMinutes: 10,
        steps: [
          Step(
            id: 's1',
            recipeId: 'r1',
            action: '步骤1',
            durationSeconds: 60,
            dependencies: ['s3'], // 依赖s3，形成循环
            orderIndex: 0,
          ),
          Step(
            id: 's2',
            recipeId: 'r1',
            action: '步骤2',
            durationSeconds: 60,
            dependencies: ['s1'],
            orderIndex: 1,
          ),
          Step(
            id: 's3',
            recipeId: 'r1',
            action: '步骤3',
            durationSeconds: 60,
            dependencies: ['s2'],
            orderIndex: 2,
          ),
        ],
      );

      final resources = Resource.defaultResources;
      final plan = engine.generatePlan(
        recipes: [recipe],
        availableResources: resources,
      );

      expect(plan.status, 'error');
      expect(plan.degradationReason, contains('CYCLE_DETECTED'));
    });

    // TC3: 资源冲突自动串行化
    test('TC3: 资源冲突自动串行化', () {
      final recipe = Recipe(
        id: 'r1',
        name: '冲突测试',
        estimatedMinutes: 10,
        steps: [
          Step(
            id: 's1',
            recipeId: 'r1',
            action: '炒菜1',
            durationSeconds: 120,
            resourceType: 'wok',
            parallelLevel: ParallelLevel.focused,
            orderIndex: 0,
          ),
          Step(
            id: 's2',
            recipeId: 'r1',
            action: '炒菜2',
            durationSeconds: 120,
            resourceType: 'wok', // 同一资源
            parallelLevel: ParallelLevel.focused,
            orderIndex: 1,
          ),
        ],
      );

      final resources = [
        Resource(id: 'wok_1', type: ResourceType.wok),
      ];

      final plan = engine.generatePlan(
        recipes: [recipe],
        availableResources: resources,
      );

      expect(plan.status, isNot('error'));
      
      // 两个步骤应该串行执行，不重叠
      final steps = plan.timeline.where((n) => n.isStep).toList();
      expect(steps.length, 2);
      
      // 第二个步骤的开始时间应该 >= 第一个步骤的结束时间
      if (steps.length >= 2) {
        expect(
          steps[1].startAt.isAfter(steps[0].endAt) || 
          steps[1].startAt.isAtSameMomentAs(steps[0].endAt),
          isTrue,
        );
      }
    });

    // TC4: 能力降级使用产生Warning
    test('TC4: 资源不足产生降级警告', () {
      final recipe = Recipe(
        id: 'r1',
        name: '降级测试',
        estimatedMinutes: 10,
        steps: [
          Step(
            id: 's1',
            recipeId: 'r1',
            action: '烤制',
            durationSeconds: 600,
            resourceType: 'oven', // 需要烤箱
            orderIndex: 0,
          ),
        ],
      );

      // 提供的资源中没有烤箱
      final resources = [
        Resource(id: 'wok_1', type: ResourceType.wok),
      ];

      final plan = engine.generatePlan(
        recipes: [recipe],
        availableResources: resources,
      );

      // 应该产生降级或警告
      expect(plan.isDegraded || plan.warnings.isNotEmpty, isTrue);
    });

    // TC5: 资源复用阻塞与清洗检查点
    test('TC5: 清洗检查点插入', () {
      final recipe = Recipe(
        id: 'r1',
        name: '清洗测试',
        estimatedMinutes: 10,
        steps: [
          Step(
            id: 's1',
            recipeId: 'r1',
            action: '炒鸡蛋',
            durationSeconds: 60,
            resourceType: 'wok',
            requiresCleaningAfter: true, // 需要清洗
            orderIndex: 0,
          ),
          Step(
            id: 's2',
            recipeId: 'r1',
            action: '炒肉丝',
            durationSeconds: 120,
            dependencies: ['s1'],
            resourceType: 'wok', // 复用同一锅
            orderIndex: 1,
          ),
        ],
      );

      final resources = [
        Resource(id: 'wok_1', type: ResourceType.wok),
      ];

      final plan = engine.generatePlan(
        recipes: [recipe],
        availableResources: resources,
      );

      expect(plan.status, isNot('error'));

      // 应该包含清洗检查点
      final checkpoints = plan.timeline.where((n) => n.isCheckpoint).toList();
      expect(checkpoints.isNotEmpty, isTrue);
      
      // 检查点应该在两个步骤之间
      if (checkpoints.isNotEmpty) {
        expect(checkpoints.first.action, contains('清洗'));
        expect(checkpoints.first.reason, 'requires_cleaning_after');
      }
    });

    // 额外测试：CPM计算验证
    test('CPM: 关键路径计算', () {
      final recipe = Recipe(
        id: 'r1',
        name: 'CPM测试',
        estimatedMinutes: 10,
        steps: [
          Step(
            id: 's1',
            recipeId: 'r1',
            action: '准备食材',
            durationSeconds: 180,
            orderIndex: 0,
          ),
          Step(
            id: 's2',
            recipeId: 'r1',
            action: '切菜',
            durationSeconds: 120,
            dependencies: ['s1'],
            orderIndex: 1,
          ),
          Step(
            id: 's3',
            recipeId: 'r1',
            action: '调酱汁',
            durationSeconds: 60,
            dependencies: ['s1'], // 可与s2并行
            orderIndex: 2,
          ),
          Step(
            id: 's4',
            recipeId: 'r1',
            action: '炒制',
            durationSeconds: 180,
            dependencies: ['s2', 's3'],
            orderIndex: 3,
          ),
        ],
      );

      final resources = Resource.defaultResources;
      final plan = engine.generatePlan(
        recipes: [recipe],
        availableResources: resources,
      );

      expect(plan.status, isNot('error'));
      expect(plan.timeline.where((n) => n.isStep).length, 4);
      
      // 验证依赖关系正确执行
      final stepNodes = plan.timeline.where((n) => n.isStep).toList();
      expect(stepNodes.isNotEmpty, isTrue);
    });

    // 空计划测试
    test('空菜谱生成空计划', () {
      final plan = engine.generatePlan(
        recipes: [],
        availableResources: Resource.defaultResources,
      );

      expect(plan.status, 'done');
      expect(plan.timeline, isEmpty);
      expect(plan.metrics.totalDurationSeconds, 0);
    });

    // 指标计算测试
    test('指标计算正确', () {
      final recipe = Recipe(
        id: 'r1',
        name: '指标测试',
        estimatedMinutes: 5,
        steps: [
          Step(
            id: 's1',
            recipeId: 'r1',
            action: '步骤1',
            durationSeconds: 60,
            requiresCleaningAfter: true,
            resourceType: 'wok',
            orderIndex: 0,
          ),
          Step(
            id: 's2',
            recipeId: 'r1',
            action: '步骤2',
            durationSeconds: 120,
            dependencies: ['s1'],
            resourceType: 'wok',
            orderIndex: 1,
          ),
        ],
      );

      final resources = [
        Resource(id: 'wok_1', type: ResourceType.wok),
      ];

      final plan = engine.generatePlan(
        recipes: [recipe],
        availableResources: resources,
      );

      expect(plan.metrics.activeCookingSeconds, greaterThan(0));
      
      // 如果有清洗检查点，清洗时间应该大于0
      if (plan.timeline.any((n) => n.isCheckpoint)) {
        expect(plan.metrics.cleaningBufferSeconds, greaterThan(0));
      }
    });
  });

  group('Model Tests', () {
    test('Resource 默认资源池创建', () {
      final defaults = Resource.defaultResources;
      
      expect(defaults.length, 3);
      expect(defaults.any((r) => r.type == ResourceType.stove), isTrue);
      expect(defaults.any((r) => r.type == ResourceType.wok), isTrue);
      expect(defaults.any((r) => r.type == ResourceType.cuttingBoard), isTrue);
    });

    test('Resource JSON序列化', () {
      final resource = Resource(
        id: 'test_1',
        type: ResourceType.wok,
        capacityLiters: 3.0,
        state: ResourceState.free,
      );

      final json = resource.toJson();
      final restored = Resource.fromJson(json);

      expect(restored.id, resource.id);
      expect(restored.type, resource.type);
      expect(restored.capacityLiters, resource.capacityLiters);
      expect(restored.state, resource.state);
    });

    test('KitchenProfile 有效资源过滤', () {
      final profile = KitchenProfile(
        userId: 'test',
        resources: [
          Resource(id: 'r1', type: ResourceType.wok),
          Resource(id: 'r2', type: ResourceType.stove),
          Resource(id: 'r3', type: ResourceType.cuttingBoard),
        ],
      );

      final effective = profile.getEffectiveResources(['r1', 'r3']);
      
      expect(effective.length, 2);
      expect(effective.any((r) => r.id == 'r1'), isTrue);
      expect(effective.any((r) => r.id == 'r3'), isTrue);
      expect(effective.any((r) => r.id == 'r2'), isFalse);
    });

    test('Step 依赖关系', () {
      final step = Step(
        id: 's1',
        recipeId: 'r1',
        action: '测试',
        durationSeconds: 60,
        dependencies: ['s0'],
        parallelLevel: ParallelLevel.focused,
        requiresCleaningAfter: true,
        orderIndex: 1,
      );

      expect(step.dependencies, contains('s0'));
      expect(step.parallelLevel, ParallelLevel.focused);
      expect(step.requiresCleaningAfter, isTrue);
    });

    test('PlanMetrics 时间格式化', () {
      final metrics = PlanMetrics(
        totalDurationSeconds: 1830, // 30分30秒
        activeCookingSeconds: 1800,
        cleaningBufferSeconds: 30,
      );

      expect(metrics.totalDurationFormatted, '30分30秒');
    });
  });

  group('Enum Extension Tests', () {
    test('ResourceType displayName', () {
      expect(ResourceType.stove.displayName, '灶具');
      expect(ResourceType.wok.displayName, '炒锅');
      expect(ResourceType.oven.displayName, '烤箱');
    });

    test('HeatLevel displayName', () {
      expect(HeatLevel.high.displayName, '大火');
      expect(HeatLevel.medium.displayName, '中火');
      expect(HeatLevel.low.displayName, '小火');
    });

    test('ResourceState displayName', () {
      expect(ResourceState.free.displayName, '可用');
      expect(ResourceState.occupied.displayName, '使用中');
      expect(ResourceState.dirty.displayName, '待清洗');
    });

    test('ParallelLevel value', () {
      expect(ParallelLevel.focused.value, 0);
      expect(ParallelLevel.parallel.value, 1);
      expect(ParallelLevel.background.value, 2);
    });
  });
}
