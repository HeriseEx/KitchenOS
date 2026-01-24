import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/responsive_layout.dart';
import '../utils/utils.dart';

/// UI-00: 厨房配置向导
/// 首次引导用户配置厨房装备
class KitchenSetupScreen extends StatefulWidget {
  final bool isInitialSetup;

  const KitchenSetupScreen({
    super.key,
    this.isInitialSetup = true,
  });

  @override
  State<KitchenSetupScreen> createState() => _KitchenSetupScreenState();
}

class _KitchenSetupScreenState extends State<KitchenSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 配置状态
  int _stoveCount = 1;
  HeatLevel _stoveHeatLevel = HeatLevel.high;
  int _wokCount = 1;
  int _stewPotCount = 0;
  int _steamerCount = 0;
  int _cuttingBoardCount = 1;
  bool _hasOven = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('厨房配置'),
        actions: [
          if (widget.isInitialSetup)
            TextButton(
              onPressed: _skipSetup,
              child: const Text('跳过'),
            ),
        ],
      ),
      body: ResponsiveLayout(
        mobileBody: Column(
          children: [
            // 进度指示器
            Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / 5,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(AppTheme.accentColor),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildWelcomePage(),
                  _buildStovePage(),
                  _buildPotPage(),
                  _buildCuttingBoardPage(),
                  _buildOvenPage(),
                ],
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.kitchen,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 24),
          const Text(
            '让我们了解您的厨房',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '通过配置您的厨房装备，KitchenOS 可以为您生成更优化的烹饪计划，'
            '充分利用并行烹饪来节省时间。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          _buildValueCard(
            icon: Icons.timer,
            title: '节省时间',
            description: '通过并行调度缩短总烹饪时长',
          ),
          const SizedBox(height: 12),
          _buildValueCard(
            icon: Icons.psychology,
            title: '降低心智负担',
            description: '清晰的时间轴与关键路径提示',
          ),
          const SizedBox(height: 12),
          _buildValueCard(
            icon: Icons.home,
            title: '贴合真实厨房',
            description: '基于您的实际装备生成计划',
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }

  Widget _buildStovePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '灶具配置',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '您有几个灶眼？',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildCountSelector(
            label: '灶眼数量',
            value: _stoveCount,
            min: 1,
            max: 6,
            onChanged: (v) => setState(() => _stoveCount = v),
          ),
          const SizedBox(height: 24),
          const Text(
            '最大火力',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          _buildHeatLevelSelector(),
        ],
      ),
    );
  }

  Widget _buildHeatLevelSelector() {
    return Row(
      children: HeatLevel.values.map((level) {
        final isSelected = _stoveHeatLevel == level;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(level.displayName),
              selected: isSelected,
              onSelected: (_) => setState(() => _stoveHeatLevel = level),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPotPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '锅具配置',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '您有哪些锅具？',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildCountSelector(
              label: '炒锅',
              icon: Icons.soup_kitchen,
              value: _wokCount,
              min: 0,
              max: 4,
              onChanged: (v) => setState(() => _wokCount = v),
            ),
            const SizedBox(height: 16),
            _buildCountSelector(
              label: '炖锅',
              icon: Icons.rice_bowl,
              value: _stewPotCount,
              min: 0,
              max: 4,
              onChanged: (v) => setState(() => _stewPotCount = v),
            ),
            const SizedBox(height: 16),
            _buildCountSelector(
              label: '蒸锅',
              icon: Icons.local_fire_department,
              value: _steamerCount,
              min: 0,
              max: 4,
              onChanged: (v) => setState(() => _steamerCount = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCuttingBoardPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '案板配置',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '您有几块案板？',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildCountSelector(
            label: '案板数量',
            icon: Icons.content_cut,
            value: _cuttingBoardCount,
            min: 1,
            max: 4,
            onChanged: (v) => setState(() => _cuttingBoardCount = v),
          ),
          const SizedBox(height: 24),
          const Card(
            color: Color(0xFFFFF3E0),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '建议生熟分开，至少准备2块案板',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOvenPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '烤箱配置',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '您有烤箱吗？',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('我有烤箱'),
            subtitle: const Text('烤箱可以并行执行烘烤任务'),
            value: _hasOven,
            onChanged: (v) => setState(() => _hasOven = v),
          ),
          const Spacer(),
          Card(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '配置摘要',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text('灶眼: $_stoveCount 个 (${_stoveHeatLevel.displayName})'),
                  Text('炒锅: $_wokCount 个'),
                  Text('炖锅: $_stewPotCount 个'),
                  Text('蒸锅: $_steamerCount 个'),
                  Text('案板: $_cuttingBoardCount 块'),
                  Text('烤箱: ${_hasOven ? "有" : "无"}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountSelector({
    required String label,
    IconData? icon,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 28),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: Icon(Icons.remove_circle_outline, color: value > min ? AppTheme.primaryColor : Colors.grey[300]),
        ),
        Container(
          width: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: Icon(Icons.add_circle_outline, color: value < max ? AppTheme.primaryColor : Colors.grey[300]),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: _previousPage,
              child: const Text('上一步'),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: _currentPage < 4 ? _nextPage : _saveConfiguration,
            child: Text(_currentPage < 4 ? '下一步' : '完成配置'),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _skipSetup() {
    final provider = context.read<AppProvider>();
    provider.saveKitchenProfile(
      KitchenProfile.defaultProfile('default'),
    );
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _saveConfiguration() {
    final resources = <Resource>[];

    // 添加灶具
    for (int i = 0; i < _stoveCount; i++) {
      resources.add(Resource(
        id: 'stove_${i + 1}',
        type: ResourceType.stove,
        heatLevel: _stoveHeatLevel,
        name: '灶眼${i + 1}',
      ));
    }

    // 添加炒锅
    for (int i = 0; i < _wokCount; i++) {
      resources.add(Resource(
        id: 'wok_${i + 1}',
        type: ResourceType.wok,
        capacityLiters: 3.0,
        name: '炒锅${i + 1}',
      ));
    }

    // 添加炖锅
    for (int i = 0; i < _stewPotCount; i++) {
      resources.add(Resource(
        id: 'stew_pot_${i + 1}',
        type: ResourceType.stewPot,
        capacityLiters: 4.0,
        name: '炖锅${i + 1}',
      ));
    }

    // 添加蒸锅
    for (int i = 0; i < _steamerCount; i++) {
      resources.add(Resource(
        id: 'steamer_${i + 1}',
        type: ResourceType.steamer,
        name: '蒸锅${i + 1}',
      ));
    }

    // 添加案板
    for (int i = 0; i < _cuttingBoardCount; i++) {
      resources.add(Resource(
        id: 'cutting_board_${i + 1}',
        type: ResourceType.cuttingBoard,
        isMeatSafe: i == 0, // 第一块案板可处理生肉
        name: i == 0 ? '生肉案板' : '蔬菜案板',
      ));
    }

    // 添加烤箱
    if (_hasOven) {
      resources.add(Resource(
        id: 'oven_1',
        type: ResourceType.oven,
        maxTempCelsius: 230,
        name: '烤箱',
      ));
    }

    final profile = KitchenProfile(
      userId: 'default',
      resources: resources,
      isConfigured: true,
      lastUpdated: DateTime.now(),
    );

    final provider = context.read<AppProvider>();
    provider.saveKitchenProfile(profile);

    Navigator.of(context).pushReplacementNamed('/home');
  }
}
