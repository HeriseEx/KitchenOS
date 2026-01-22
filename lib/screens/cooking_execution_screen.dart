import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/utils.dart';

/// UI-06: 烹饪执行页
/// 实时显示当前步骤，支持计时和资源状态管理
class CookingExecutionScreen extends StatefulWidget {
  const CookingExecutionScreen({super.key});

  @override
  State<CookingExecutionScreen> createState() => _CookingExecutionScreenState();
}

class _CookingExecutionScreenState extends State<CookingExecutionScreen> {
  Timer? _timer;
  int _currentStepElapsed = 0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _currentStepElapsed++;
        });
        
        final provider = context.read<AppProvider>();
        provider.updateTimers(provider.elapsedSeconds + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final plan = provider.currentPlan;
    final currentNode = provider.currentNode;

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('烹饪中')),
        body: const Center(child: Text('暂无计划')),
      );
    }

    // 检查是否完成
    if (currentNode == null || !provider.isExecuting) {
      return _CookingCompleteScreen(plan: plan, provider: provider);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('步骤 ${provider.currentStepIndex + 1}/${plan.timeline.length}'),
        actions: [
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: () => setState(() => _isPaused = !_isPaused),
            tooltip: _isPaused ? '继续' : '暂停',
          ),
        ],
      ),
      body: Column(
        children: [
          // 进度条
          LinearProgressIndicator(
            value: (provider.currentStepIndex + 1) / plan.timeline.length,
          ),
          
          // 时间统计
          _TimeStatsBar(
            elapsedSeconds: provider.elapsedSeconds,
            activeCookingSeconds: provider.activeCookingSeconds,
            totalSeconds: plan.metrics.totalDurationSeconds,
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 当前步骤卡片
                  _CurrentStepCard(
                    node: currentNode,
                    elapsed: _currentStepElapsed,
                    isPaused: _isPaused,
                    onComplete: () => _completeCurrentStep(provider),
                    onCleaningComplete: currentNode.isCheckpoint
                        ? () => _handleCleaningComplete(provider, currentNode)
                        : null,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 资源状态
                  _ResourceStatusSection(
                    resources: provider.kitchenProfile?.resources ?? [],
                    onResetResource: (id) => provider.resetResource(id),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 即将到来的步骤
                  _UpcomingStepsSection(
                    timeline: plan.timeline,
                    currentIndex: provider.currentStepIndex,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _completeCurrentStep(AppProvider provider) {
    setState(() => _currentStepElapsed = 0);
    provider.completeCurrentStep();
  }

  void _handleCleaningComplete(AppProvider provider, TimelineNode node) {
    if (node.resourceId != null) {
      provider.resetResource(node.resourceId!);
    }
    setState(() => _currentStepElapsed = 0);
  }
}

/// 时间统计栏
class _TimeStatsBar extends StatelessWidget {
  final int elapsedSeconds;
  final int activeCookingSeconds;
  final int totalSeconds;

  const _TimeStatsBar({
    required this.elapsedSeconds,
    required this.activeCookingSeconds,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TimeStatItem(
            label: '已用时',
            value: AppUtils.formatDuration(elapsedSeconds),
            icon: Icons.timer,
          ),
          _TimeStatItem(
            label: '烹饪时间',
            value: AppUtils.formatDuration(activeCookingSeconds),
            icon: Icons.restaurant,
          ),
          _TimeStatItem(
            label: '预计剩余',
            value: AppUtils.formatDuration(
              (totalSeconds - elapsedSeconds).clamp(0, totalSeconds),
            ),
            icon: Icons.hourglass_empty,
          ),
        ],
      ),
    );
  }
}

class _TimeStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TimeStatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

/// 当前步骤卡片
class _CurrentStepCard extends StatelessWidget {
  final TimelineNode node;
  final int elapsed;
  final bool isPaused;
  final VoidCallback onComplete;
  final VoidCallback? onCleaningComplete;

  const _CurrentStepCard({
    required this.node,
    required this.elapsed,
    required this.isPaused,
    required this.onComplete,
    this.onCleaningComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isCheckpoint = node.isCheckpoint;
    final remaining = (node.durationSeconds - elapsed).clamp(0, node.durationSeconds);
    final progress = elapsed / node.durationSeconds;

    return Card(
      elevation: 4,
      color: isCheckpoint ? Colors.orange.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 类型标签
            if (isCheckpoint)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '清洗检查点',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            
            const SizedBox(height: 12),
            
            // 步骤名称
            Text(
              node.action,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // 描述
            if (node.description != null)
              Text(
                node.description!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            
            const SizedBox(height: 24),
            
            // 计时器
            if (!isCheckpoint) ...[
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: progress.clamp(0, 1),
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[200],
                      color: remaining <= 10 
                          ? Colors.red 
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        AppUtils.formatDuration(remaining),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: remaining <= 10 ? Colors.red : null,
                        ),
                      ),
                      if (isPaused)
                        const Text(
                          '已暂停',
                          style: TextStyle(color: Colors.orange),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            
            // 资源信息
            if (node.resourceId != null)
              Chip(
                avatar: const Icon(Icons.kitchen, size: 18),
                label: Text('使用: ${node.resourceId}'),
              ),
            
            const SizedBox(height: 16),
            
            // 操作按钮
            if (isCheckpoint)
              ElevatedButton.icon(
                onPressed: onCleaningComplete,
                icon: const Icon(Icons.check),
                label: const Text('我已洗好'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: onComplete,
                icon: const Icon(Icons.check),
                label: const Text('完成此步骤'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 资源状态区域
class _ResourceStatusSection extends StatelessWidget {
  final List<Resource> resources;
  final ValueChanged<String> onResetResource;

  const _ResourceStatusSection({
    required this.resources,
    required this.onResetResource,
  });

  @override
  Widget build(BuildContext context) {
    if (resources.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '资源状态',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: resources.map((resource) {
            return _ResourceChip(
              resource: resource,
              onReset: resource.state == ResourceState.dirty
                  ? () => onResetResource(resource.id)
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ResourceChip extends StatelessWidget {
  final Resource resource;
  final VoidCallback? onReset;

  const _ResourceChip({
    required this.resource,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    IconData stateIcon;
    
    switch (resource.state) {
      case ResourceState.free:
        chipColor = AppTheme.freeResourceColor;
        stateIcon = Icons.check_circle;
        break;
      case ResourceState.occupied:
        chipColor = AppTheme.occupiedResourceColor;
        stateIcon = Icons.play_circle;
        break;
      case ResourceState.dirty:
        chipColor = AppTheme.dirtyResourceColor;
        stateIcon = Icons.warning;
        break;
    }

    return ActionChip(
      avatar: Icon(stateIcon, color: chipColor, size: 18),
      label: Text(resource.displayName),
      backgroundColor: chipColor.withOpacity(0.1),
      onPressed: onReset,
    );
  }
}

/// 即将到来的步骤
class _UpcomingStepsSection extends StatelessWidget {
  final List<TimelineNode> timeline;
  final int currentIndex;

  const _UpcomingStepsSection({
    required this.timeline,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final upcomingSteps = timeline.skip(currentIndex + 1).take(3).toList();
    
    if (upcomingSteps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '接下来',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...upcomingSteps.asMap().entries.map((entry) {
          final index = entry.key;
          final node = entry.value;
          final opacity = 1.0 - (index * 0.2);
          
          return Opacity(
            opacity: opacity,
            child: Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: node.isCheckpoint 
                      ? Colors.grey 
                      : Theme.of(context).primaryColor.withOpacity(0.7),
                  child: node.isCheckpoint
                      ? const Icon(Icons.cleaning_services, 
                          size: 14, color: Colors.white)
                      : Text(
                          '${currentIndex + index + 2}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                ),
                title: Text(node.action),
                trailing: Text(
                  AppUtils.formatDuration(node.durationSeconds),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// 烹饪完成页面
class _CookingCompleteScreen extends StatelessWidget {
  final CookingPlan plan;
  final AppProvider provider;

  const _CookingCompleteScreen({
    required this.plan,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.celebration,
                  size: 80,
                  color: Colors.amber,
                ),
                const SizedBox(height: 24),
                const Text(
                  '烹饪完成！',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '总用时 ${AppUtils.formatDurationChinese(provider.elapsedSeconds)}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  '实际烹饪 ${AppUtils.formatDurationChinese(provider.activeCookingSeconds)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('返回首页'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
