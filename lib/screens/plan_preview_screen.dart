import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/responsive_layout.dart';
import '../utils/utils.dart';

/// UI-05: 调度预览界面
/// 展示生成的烹饪计划，包括甘特图和关键路径
class PlanPreviewScreen extends StatelessWidget {
  const PlanPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final plan = provider.currentPlan;

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('烹饪计划')),
        body: const Center(child: Text('暂无计划')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('烹饪计划'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Navigator.pop(context),
            tooltip: '重新生成',
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobileBody: _buildMobileLayout(context, provider, plan),
        desktopBody: _buildDesktopLayout(context, provider, plan),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: () {
            provider.startExecution();
            Navigator.pushReplacementNamed(context, '/cooking');
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('开始烹饪'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, AppProvider provider, CookingPlan plan) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 计划摘要卡片
        _PlanSummaryCard(plan: plan),
        const SizedBox(height: 16),
        
        // 降级警告
        if (plan.isDegraded) _DegradationWarning(plan: plan),
        if (plan.warnings.isNotEmpty) _WarningsCard(warnings: plan.warnings),
        
        // 时间节省卡片
        if (plan.metrics.savedSeconds > 0) 
          _TimeSavedCard(savedSeconds: plan.metrics.savedSeconds),
        
        const SizedBox(height: 16),
        
        // 甘特图
        const Text(
          '时间轴',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _GanttChart(timeline: plan.timeline),
        
        const SizedBox(height: 24),
        
        // 步骤列表
        const Text(
          '步骤详情',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...plan.timeline.asMap().entries.map((entry) => 
          _TimelineNodeCard(
            index: entry.key,
            node: entry.value,
            isLast: entry.key == plan.timeline.length - 1,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AppProvider provider, CookingPlan plan) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Analysis & Chart
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PlanSummaryCard(plan: plan),
                  const SizedBox(height: 16),
                  
                  if (plan.isDegraded) _DegradationWarning(plan: plan),
                  if (plan.warnings.isNotEmpty) _WarningsCard(warnings: plan.warnings),
                  
                  if (plan.metrics.savedSeconds > 0) 
                    _TimeSavedCard(savedSeconds: plan.metrics.savedSeconds),
                  
                  const SizedBox(height: 24),
                  
                  const Text(
                    '时间轴',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _GanttChart(timeline: plan.timeline),
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),
          // Right: Steps List
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '步骤详情',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: plan.timeline.length,
                    itemBuilder: (context, index) {
                      return _TimelineNodeCard(
                        index: index,
                        node: plan.timeline[index],
                        isLast: index == plan.timeline.length - 1,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 计划摘要卡片
class _PlanSummaryCard extends StatelessWidget {
  final CookingPlan plan;

  const _PlanSummaryCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.timer,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '预计用时 ${plan.metrics.totalDurationFormatted}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MetricItem(
                  icon: Icons.restaurant,
                  label: '烹饪时间',
                  value: AppUtils.formatDurationChinese(
                    plan.metrics.activeCookingSeconds,
                  ),
                ),
                _MetricItem(
                  icon: Icons.cleaning_services,
                  label: '清洗预留',
                  value: AppUtils.formatDurationChinese(
                    plan.metrics.cleaningBufferSeconds,
                  ),
                ),
                _MetricItem(
                  icon: Icons.format_list_numbered,
                  label: '总步骤',
                  value: '${plan.timeline.where((n) => n.isStep).length}步',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

/// 降级警告
class _DegradationWarning extends StatelessWidget {
  final CookingPlan plan;

  const _DegradationWarning({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '计划已降级',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  Text(
                    plan.degradationReason ?? '资源不足，部分步骤已串行化',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 警告卡片
class _WarningsCard extends StatelessWidget {
  final List<String> warnings;

  const _WarningsCard({required this.warnings});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.yellow.shade50,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  '注意事项',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...warnings.map((w) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('• $w', style: TextStyle(color: Colors.amber[800])),
            )),
          ],
        ),
      ),
    );
  }
}

/// 时间节省卡片
class _TimeSavedCard extends StatelessWidget {
  final int savedSeconds;

  const _TimeSavedCard({required this.savedSeconds});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.shade50,
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.speed, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '并行优化',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    '通过并行烹饪，预计节省 ${AppUtils.formatDurationChinese(savedSeconds)}',
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 简化甘特图
class _GanttChart extends StatelessWidget {
  final List<TimelineNode> timeline;

  const _GanttChart({required this.timeline});

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return const SizedBox.shrink();
    }

    final firstStart = timeline.first.startAt;
    final lastEnd = timeline.map((n) => n.endAt).reduce(
      (a, b) => a.isAfter(b) ? a : b,
    );
    final totalSeconds = lastEnd.difference(firstStart).inSeconds;

    if (totalSeconds == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间刻度
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('0:00', style: TextStyle(fontSize: 12)),
                Text(
                  AppUtils.formatDuration(totalSeconds),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 甘特条
            ...timeline.map((node) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _GanttBar(
                node: node,
                firstStart: firstStart,
                totalSeconds: totalSeconds,
              ),
            )),
            const SizedBox(height: 12),
            // 图例
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(color: Colors.green, label: '烹饪步骤'),
                SizedBox(width: 16),
                _LegendItem(color: Colors.grey, label: '清洗检查点'),
                SizedBox(width: 16),
                _LegendItem(color: Colors.pink, label: '关键路径'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GanttBar extends StatelessWidget {
  final TimelineNode node;
  final DateTime firstStart;
  final int totalSeconds;

  const _GanttBar({
    required this.node,
    required this.firstStart,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final startOffset = node.startAt.difference(firstStart).inSeconds;
    final duration = node.durationSeconds;
    
    final startFraction = startOffset / totalSeconds;
    final widthFraction = duration / totalSeconds;

    Color barColor;
    if (node.isCheckpoint) {
      barColor = AppTheme.checkpointColor;
    } else if (node.parallelLevel == ParallelLevel.focused) {
      barColor = AppTheme.criticalPathColor;
    } else {
      barColor = AppTheme.freeResourceColor;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        return SizedBox(
          height: 32,
          child: Stack(
            children: [
              Positioned(
                left: totalWidth * startFraction,
                width: (totalWidth * widthFraction).clamp(4, totalWidth),
                top: 4,
                bottom: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    gradient: node.isCheckpoint ? null : AppTheme.luxuryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: barColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    node.action,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

/// 时间线节点卡片
class _TimelineNodeCard extends StatelessWidget {
  final int index;
  final TimelineNode node;
  final bool isLast;

  const _TimelineNodeCard({
    required this.index,
    required this.node,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isCheckpoint = node.isCheckpoint;
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间线
          SizedBox(
            width: 40,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isCheckpoint 
                      ? Colors.grey 
                      : Theme.of(context).primaryColor,
                  child: isCheckpoint
                      ? const Icon(Icons.cleaning_services, 
                          size: 16, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey[300],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 卡片内容
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isCheckpoint ? Colors.grey.shade100 : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            node.action,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCheckpoint 
                                ? Colors.grey 
                                : Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            AppUtils.formatDuration(node.durationSeconds),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (node.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        node.description!,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (node.resourceId != null) ...[
                          Icon(Icons.kitchen, 
                            size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            node.resourceId!,
                            style: TextStyle(
                              fontSize: 12, 
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (node.parallelLevel != null) ...[
                          Icon(
                            node.parallelLevel == ParallelLevel.focused
                                ? Icons.center_focus_strong
                                : Icons.compare_arrows,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            node.parallelLevel!.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
