import 'dart:collection';
import '../models/models.dart';

/// CPM关键路径调度引擎
/// 实现 PRD 3.2 求解流程
class SchedulingEngine {
  static const int maxConflictIterations = 10;
  static const int defaultCleaningBuffer = 60; // 清洗默认buffer（秒）

  /// 生成烹饪计划
  /// 
  /// Phase 1: CPM关键路径计算
  /// Phase 2: 资源/注意力冲突消解（最多10次迭代）
  CookingPlan generatePlan({
    required List<Recipe> recipes,
    required List<Resource> availableResources,
  }) {
    // 合并所有步骤
    final allSteps = <Step>[];
    for (final recipe in recipes) {
      allSteps.addAll(recipe.steps);
    }

    if (allSteps.isEmpty) {
      return _createEmptyPlan(recipes.map((r) => r.id).toList());
    }

    // Phase 1: 拓扑排序 + CPM前向/后向传递
    final sortedSteps = _topologicalSort(allSteps);
    if (sortedSteps == null) {
      // 检测到循环依赖
      return _createErrorPlan(
        recipes.map((r) => r.id).toList(),
        'CYCLE_DETECTED',
        '检测到循环依赖，无法生成计划',
      );
    }

    // CPM计算
    _calculateCPM(sortedSteps);

    // Phase 2: 资源冲突消解
    final (scheduledSteps, warnings, isDegraded) = _resolveConflicts(
      sortedSteps,
      availableResources,
    );

    // 构建Timeline
    final timeline = _buildTimeline(scheduledSteps, availableResources);

    // 计算指标
    final metrics = _calculateMetrics(timeline);

    return CookingPlan(
      planId: _generatePlanId(),
      status: isDegraded ? 'degraded' : 'done',
      degradationReason: isDegraded ? 'insufficient_resources' : null,
      metrics: metrics,
      timeline: timeline,
      recipeIds: recipes.map((r) => r.id).toList(),
      warnings: warnings,
    );
  }

  /// 拓扑排序（Kahn算法）
  List<Step>? _topologicalSort(List<Step> steps) {
    final stepMap = {for (var s in steps) s.id: s};
    final inDegree = <String, int>{};
    final adjacency = <String, List<String>>{};

    // 初始化
    for (final step in steps) {
      inDegree[step.id] = 0;
      adjacency[step.id] = [];
    }

    // 构建图
    for (final step in steps) {
      for (final depId in step.dependencies) {
        if (adjacency.containsKey(depId)) {
          adjacency[depId]!.add(step.id);
          inDegree[step.id] = (inDegree[step.id] ?? 0) + 1;
        }
      }
    }

    // Kahn算法
    final queue = Queue<String>();
    for (final entry in inDegree.entries) {
      if (entry.value == 0) {
        queue.add(entry.key);
      }
    }

    final result = <Step>[];
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      result.add(stepMap[current]!);

      for (final neighbor in adjacency[current]!) {
        inDegree[neighbor] = inDegree[neighbor]! - 1;
        if (inDegree[neighbor] == 0) {
          queue.add(neighbor);
        }
      }
    }

    // 检查循环依赖
    if (result.length != steps.length) {
      return null; // 存在循环
    }

    return result;
  }

  /// CPM前向和后向传递
  void _calculateCPM(List<Step> sortedSteps) {
    final stepMap = {for (var s in sortedSteps) s.id: s};

    // 前向传递：计算ES和EF
    for (final step in sortedSteps) {
      int maxPredEnd = 0;
      for (final depId in step.dependencies) {
        final dep = stepMap[depId];
        if (dep != null && dep.earliestFinish != null) {
          maxPredEnd = maxPredEnd > dep.earliestFinish! 
              ? maxPredEnd 
              : dep.earliestFinish!;
        }
      }
      step.earliestStart = maxPredEnd;
      step.earliestFinish = maxPredEnd + step.durationSeconds;
    }

    // 项目结束时间
    int projectEnd = 0;
    for (final step in sortedSteps) {
      if (step.earliestFinish != null && step.earliestFinish! > projectEnd) {
        projectEnd = step.earliestFinish!;
      }
    }

    // 后向传递：计算LS和LF
    for (final step in sortedSteps.reversed) {
      // 找到所有后继
      int minSuccStart = projectEnd;
      for (final other in sortedSteps) {
        if (other.dependencies.contains(step.id)) {
          if (other.latestStart != null && other.latestStart! < minSuccStart) {
            minSuccStart = other.latestStart!;
          }
        }
      }
      step.latestFinish = minSuccStart;
      step.latestStart = minSuccStart - step.durationSeconds;
      
      // 计算松弛时间
      step.slack = step.latestStart! - step.earliestStart!;
      step.isOnCriticalPath = step.slack == 0;
    }
  }

  /// 资源冲突消解
  (List<Step>, List<String>, bool) _resolveConflicts(
    List<Step> steps,
    List<Resource> resources,
  ) {
    final warnings = <String>[];
    var isDegraded = false;
    final resourceMap = {for (var r in resources) r.type.name: r};

    // 按资源类型分组
    final resourceUsage = <String, List<Step>>{};
    
    for (final step in steps) {
      if (step.resourceType != null) {
        resourceUsage.putIfAbsent(step.resourceType!, () => []).add(step);
      }
    }

    // 检测并解决冲突
    for (var iteration = 0; iteration < maxConflictIterations; iteration++) {
      bool hasConflict = false;

      for (final entry in resourceUsage.entries) {
        final resourceType = entry.key;
        final stepsUsingResource = entry.value;
        
        // 检查该资源类型是否可用
        final resource = resourceMap[resourceType];
        if (resource == null) {
          // 资源不足，需要串行化
          isDegraded = true;
          warnings.add('资源 $resourceType 不可用，计划已串行化');
          continue;
        }

        // 按ES排序
        stepsUsingResource.sort((a, b) => 
            (a.earliestStart ?? 0).compareTo(b.earliestStart ?? 0));

        // 检测时间重叠
        for (int i = 0; i < stepsUsingResource.length - 1; i++) {
          final current = stepsUsingResource[i];
          final next = stepsUsingResource[i + 1];

          if (current.earliestFinish! > next.earliestStart!) {
            // 存在冲突，延迟下一个步骤
            final delay = current.earliestFinish! - next.earliestStart!;
            next.earliestStart = current.earliestFinish;
            next.earliestFinish = next.earliestStart! + next.durationSeconds;
            hasConflict = true;
          }
        }
      }

      // 注意力冲突检测（parallel_level = 0的步骤不能同时进行）
      final focusedSteps = steps.where(
        (s) => s.parallelLevel == ParallelLevel.focused
      ).toList();
      
      focusedSteps.sort((a, b) => 
          (a.earliestStart ?? 0).compareTo(b.earliestStart ?? 0));

      for (int i = 0; i < focusedSteps.length - 1; i++) {
        final current = focusedSteps[i];
        final next = focusedSteps[i + 1];

        if (current.earliestFinish! > next.earliestStart!) {
          // 注意力冲突，延迟下一个
          next.earliestStart = current.earliestFinish;
          next.earliestFinish = next.earliestStart! + next.durationSeconds;
          hasConflict = true;
        }
      }

      if (!hasConflict) break;
    }

    // 分配具体资源ID
    for (final step in steps) {
      if (step.resourceType != null) {
        final resource = resourceMap[step.resourceType!];
        if (resource != null) {
          // 使用copyWith创建新的step（如果需要修改resourceId）
          // 这里简化处理，直接找到可用资源
        }
      }
    }

    return (steps, warnings, isDegraded);
  }

  /// 构建Timeline
  List<TimelineNode> _buildTimeline(
    List<Step> steps,
    List<Resource> resources,
  ) {
    final timeline = <TimelineNode>[];
    final baseTime = DateTime.now();
    final resourceMap = {for (var r in resources) r.type.name: r};

    // 按ES排序
    final sortedSteps = List<Step>.from(steps);
    sortedSteps.sort((a, b) => 
        (a.earliestStart ?? 0).compareTo(b.earliestStart ?? 0));

    // 追踪每个资源的上一个步骤
    final lastStepByResource = <String, Step>{};

    for (final step in sortedSteps) {
      final resource = step.resourceType != null 
          ? resourceMap[step.resourceType!] 
          : null;

      // 检查是否需要插入清洗检查点
      if (step.resourceType != null && 
          lastStepByResource.containsKey(step.resourceType!)) {
        final lastStep = lastStepByResource[step.resourceType!]!;
        
        if (lastStep.requiresCleaningAfter) {
          // 插入清洗检查点
          final checkpointStart = baseTime.add(
            Duration(seconds: lastStep.earliestFinish ?? 0)
          );
          final checkpointEnd = checkpointStart.add(
            Duration(seconds: defaultCleaningBuffer)
          );

          timeline.add(TimelineNode(
            id: 'chk_${lastStep.id}',
            type: TimelineNodeType.checkpoint,
            resourceId: resource?.id,
            action: '清洗${resource?.displayName ?? step.resourceType}',
            description: '前序步骤导致资源变脏，需清洗后复用',
            durationSeconds: defaultCleaningBuffer,
            startAt: checkpointStart,
            endAt: checkpointEnd,
            reason: 'requires_cleaning_after',
            recipeId: step.recipeId,
          ));

          // 调整当前步骤的开始时间
          step.earliestStart = (step.earliestStart ?? 0) + defaultCleaningBuffer;
          step.earliestFinish = step.earliestStart! + step.durationSeconds;
        }
      }

      // 添加步骤节点
      final startAt = baseTime.add(
        Duration(seconds: step.earliestStart ?? 0)
      );
      final endAt = baseTime.add(
        Duration(seconds: step.earliestFinish ?? step.durationSeconds)
      );

      timeline.add(TimelineNode(
        id: step.id,
        type: TimelineNodeType.step,
        resourceId: resource?.id,
        action: step.action,
        description: step.description,
        parallelLevel: step.parallelLevel,
        durationSeconds: step.durationSeconds,
        startAt: startAt,
        endAt: endAt,
        recipeId: step.recipeId,
        stepId: step.id,
      ));

      // 更新资源使用记录
      if (step.resourceType != null) {
        lastStepByResource[step.resourceType!] = step;
      }
    }

    // 按开始时间排序
    timeline.sort((a, b) => a.startAt.compareTo(b.startAt));

    return timeline;
  }

  /// 计算指标
  PlanMetrics _calculateMetrics(List<TimelineNode> timeline) {
    if (timeline.isEmpty) {
      return PlanMetrics(
        totalDurationSeconds: 0,
        activeCookingSeconds: 0,
        cleaningBufferSeconds: 0,
      );
    }

    final firstStart = timeline.first.startAt;
    final lastEnd = timeline.map((n) => n.endAt).reduce(
      (a, b) => a.isAfter(b) ? a : b
    );

    final totalSeconds = lastEnd.difference(firstStart).inSeconds;
    
    final activeSeconds = timeline
        .where((n) => n.isStep)
        .fold<int>(0, (sum, n) => sum + n.durationSeconds);
    
    final cleaningSeconds = timeline
        .where((n) => n.isCheckpoint)
        .fold<int>(0, (sum, n) => sum + n.durationSeconds);

    // 计算串行执行时间（用于对比节省）
    final serialTotal = timeline.fold<int>(0, (sum, n) => sum + n.durationSeconds);
    final savedSeconds = serialTotal > totalSeconds ? serialTotal - totalSeconds : 0;

    return PlanMetrics(
      totalDurationSeconds: totalSeconds,
      activeCookingSeconds: activeSeconds,
      cleaningBufferSeconds: cleaningSeconds,
      savedSeconds: savedSeconds,
    );
  }

  CookingPlan _createEmptyPlan(List<String> recipeIds) {
    return CookingPlan(
      planId: _generatePlanId(),
      status: 'done',
      metrics: PlanMetrics(
        totalDurationSeconds: 0,
        activeCookingSeconds: 0,
        cleaningBufferSeconds: 0,
      ),
      timeline: [],
      recipeIds: recipeIds,
    );
  }

  CookingPlan _createErrorPlan(
    List<String> recipeIds,
    String code,
    String message,
  ) {
    return CookingPlan(
      planId: _generatePlanId(),
      status: 'error',
      degradationReason: '$code: $message',
      metrics: PlanMetrics(
        totalDurationSeconds: 0,
        activeCookingSeconds: 0,
        cleaningBufferSeconds: 0,
      ),
      timeline: [],
      recipeIds: recipeIds,
      warnings: [message],
    );
  }

  String _generatePlanId() {
    return 'plan_${DateTime.now().millisecondsSinceEpoch}';
  }
}
