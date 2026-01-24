import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/voice_command_service.dart';
import '../utils/utils.dart';
import '../widgets/responsive_layout.dart';

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
  
  // 语音控制服务
  final VoiceCommandService _voiceService = VoiceCommandService();
  bool _voiceEnabled = true; // 默认开启语音控制

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initVoiceControl();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _voiceService.dispose();
    super.dispose();
  }
  
  /// 初始化语音控制
  Future<void> _initVoiceControl() async {
    final success = await _voiceService.initialize();
    _voiceService.onCommandRecognized = _handleVoiceCommand;
    
    // 默认开启时自动开始监听
    if (success && _voiceEnabled) {
      _voiceService.setEnabled(true);
      if (mounted) setState(() {});
    } else if (!success && mounted) {
      // 初始化失败时更新UI状态
      setState(() {
        _voiceEnabled = false;
      });
    }
  }
  
  /// 处理语音命令
  void _handleVoiceCommand(VoiceCommand command) {
    final provider = context.read<AppProvider>();
    
    switch (command) {
      case VoiceCommand.nextStep:
      case VoiceCommand.complete:
        _completeCurrentStep(provider);
        // 播放反馈音或振动
        break;
      case VoiceCommand.pause:
        if (!_isPaused) {
          setState(() => _isPaused = true);
        }
        break;
      case VoiceCommand.resume:
        if (_isPaused) {
          setState(() => _isPaused = false);
        }
        break;
      case VoiceCommand.unknown:
        break;
    }
  }
  
  /// 切换语音控制
  void _toggleVoiceControl() {
    setState(() {
      _voiceEnabled = !_voiceEnabled;
      _voiceService.setEnabled(_voiceEnabled);
    });
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
          // 语音控制按钮
          _VoiceControlButton(
            isEnabled: _voiceEnabled,
            isListening: _voiceService.isListening,
            isAvailable: _voiceService.isAvailable,
            onToggle: _toggleVoiceControl,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: () => setState(() => _isPaused = !_isPaused),
            tooltip: _isPaused ? '继续' : '暂停',
          ),
        ],
      ),
      body: Column(
        children: [
          // 语音状态提示条
          if (_voiceEnabled)
            _VoiceStatusBar(
              isListening: _voiceService.isListening,
              lastWords: _voiceService.lastWords,
              statusMessage: _voiceService.statusMessage,
              errorDetail: _voiceService.errorDetail,
            ),
          Expanded(
            child: ResponsiveLayout(
              mobileBody: _buildMobileLayout(context, provider, plan, currentNode),
              desktopBody: _buildDesktopLayout(context, provider, plan, currentNode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, AppProvider provider, CookingPlan plan, TimelineNode currentNode) {
    return Column(
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
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AppProvider provider, CookingPlan plan, TimelineNode currentNode) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: (provider.currentStepIndex + 1) / plan.timeline.length,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Main Task & Timer
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _TimeStatsBar(
                        elapsedSeconds: provider.elapsedSeconds,
                        activeCookingSeconds: provider.activeCookingSeconds,
                        totalSeconds: plan.metrics.totalDurationSeconds,
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: _CurrentStepCard(
                              node: currentNode,
                              elapsed: _currentStepElapsed,
                              isPaused: _isPaused,
                              onComplete: () => _completeCurrentStep(provider),
                              onCleaningComplete: currentNode.isCheckpoint
                                  ? () => _handleCleaningComplete(provider, currentNode)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // Right Column: Context Info
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                       Expanded(
                         child: SingleChildScrollView(
                           child: Column(
                             children: [
                               Card(
                                 child: Padding(
                                   padding: const EdgeInsets.all(16),
                                   child: _ResourceStatusSection(
                                     resources: provider.kitchenProfile?.resources ?? [],
                                     onResetResource: (id) => provider.resetResource(id),
                                   ),
                                 ),
                               ),
                               const SizedBox(height: 24),
                               Card(
                                 child: Padding(
                                   padding: const EdgeInsets.all(16),
                                   child: _UpcomingStepsSection(
                                     timeline: plan.timeline,
                                     currentIndex: provider.currentStepIndex,
                                   ),
                                 ),
                               ),
                             ],
                           ),
                         ),
                       ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
      elevation: 0,
      shadowColor: Colors.transparent,
      color: isCheckpoint ? Colors.orange.shade50 : Theme.of(context).cardTheme.color,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: isCheckpoint 
            ? BorderSide(color: Colors.orange.withOpacity(0.3), width: 1)
            : BorderSide(color: Colors.black.withOpacity(0.03), width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: isCheckpoint ? null : LinearGradient(
             colors: [Colors.white, Colors.grey.shade50],
             begin: Alignment.topLeft,
             end: Alignment.bottomRight,
          ),
          boxShadow: isCheckpoint ? null : AppTheme.softShadow,
        ),
        padding: const EdgeInsets.all(32),
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
            
            // 计时器 - 只对烹饪步骤显示倒计时
            if (!isCheckpoint) ...[
              // 烹饪步骤：显示倒计时环
              if (node.isCookingStep) ...[
                _buildTimerRing(context, progress, remaining, isPaused),
                const SizedBox(height: 32),
              ] else ...[
                // 准备步骤：不显示倒计时，显示手动确认提示
                _buildPrepStepIndicator(context),
                const SizedBox(height: 32),
              ],
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

  /// 构建烹饪计时器环（使用 CustomPaint 实现渐变效果）
  Widget _buildTimerRing(BuildContext context, double progress, int remaining, bool isPaused) {
    final isUrgent = remaining <= 10;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // 外圈阴影光晕
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isUrgent ? Colors.red : AppTheme.accentColor).withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        // 背景环
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade200, width: 2),
          ),
        ),
        // 进度环 (使用 CustomPaint 实现渐变)
        SizedBox(
          width: 220,
          height: 220,
          child: CustomPaint(
            painter: _GradientCircularProgressPainter(
              progress: progress.clamp(0.0, 1.0),
              strokeWidth: 14,
              gradient: isUrgent 
                  ? const LinearGradient(colors: [Colors.red, Colors.orange])
                  : AppTheme.luxuryGradient,
            ),
          ),
        ),
        // 内圈玻璃效果
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        // 时间显示
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppUtils.formatDuration(remaining),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: isUrgent ? Colors.red : const Color(0xFF1C1C1E),
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '剩余时间',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isPaused)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pause, size: 14, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      '已暂停',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// 构建准备步骤指示器（手动确认，无倒计时）
  Widget _buildPrepStepIndicator(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.cyan.shade50,
          ],
        ),
        border: Border.all(color: Colors.blue.withOpacity(0.2), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_outlined,
            size: 48,
            color: Colors.blue.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            '手动操作',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '完成后点击下方按钮',
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

/// 渐变环形进度条画笔
class _GradientCircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Gradient gradient;

  _GradientCircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // 创建渐变着色器
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 从顶部开始绘制 (-90度 = -π/2)
    const startAngle = -3.14159265359 / 2;
    final sweepAngle = 2 * 3.14159265359 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GradientCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
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

/// 语音控制按钮
class _VoiceControlButton extends StatelessWidget {
  final bool isEnabled;
  final bool isListening;
  final bool isAvailable;
  final VoidCallback onToggle;

  const _VoiceControlButton({
    required this.isEnabled,
    required this.isListening,
    required this.isAvailable,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isEnabled 
            ? const LinearGradient(colors: [Color(0xFF34C759), Color(0xFF30D158)])
            : null,
        color: isEnabled ? null : Colors.grey.shade200,
        boxShadow: isEnabled ? [
          BoxShadow(
            color: const Color(0xFF34C759).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  size: 18,
                  color: isEnabled ? Colors.white : Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  isEnabled ? '语音开' : '语音',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? Colors.white : Colors.grey.shade600,
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

/// 语音状态提示条
class _VoiceStatusBar extends StatelessWidget {
  final bool isListening;
  final String lastWords;
  final String statusMessage;
  final String errorDetail;

  const _VoiceStatusBar({
    required this.isListening,
    required this.lastWords,
    required this.statusMessage,
    this.errorDetail = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isListening 
              ? [const Color(0xFF34C759).withOpacity(0.1), const Color(0xFF30D158).withOpacity(0.05)]
              : [Colors.grey.shade100, Colors.grey.shade50],
        ),
        border: Border(
          bottom: BorderSide(
            color: isListening ? const Color(0xFF34C759).withOpacity(0.3) : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          // 状态指示器
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isListening ? const Color(0xFF34C759) : Colors.grey,
              boxShadow: isListening ? [
                BoxShadow(
                  color: const Color(0xFF34C759).withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ] : null,
            ),
          ),
          const SizedBox(width: 12),
          // 状态信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isListening ? '正在聆听...' : statusMessage,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isListening ? const Color(0xFF34C759) : Colors.grey.shade600,
                  ),
                ),
                if (errorDetail.isNotEmpty && !isListening)
                  Text(
                    errorDetail,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else if (lastWords.isNotEmpty)
                  Text(
                    '识别: $lastWords',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // 支持的命令提示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '说 "下一步" 或 "完成"',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
