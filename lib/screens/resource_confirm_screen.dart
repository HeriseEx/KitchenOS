import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/responsive_layout.dart';
import '../utils/utils.dart';

/// UI-05a: 可用装备确认界面
/// 在生成计划前让用户确认本次可用的资源
class ResourceConfirmScreen extends StatefulWidget {
  final List<String> recipeIds;

  const ResourceConfirmScreen({
    super.key,
    required this.recipeIds,
  });

  @override
  State<ResourceConfirmScreen> createState() => _ResourceConfirmScreenState();
}

class _ResourceConfirmScreenState extends State<ResourceConfirmScreen> {
  late Set<String> _selectedResourceIds;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    // 默认全选所有资源
    _selectedResourceIds = provider.kitchenProfile?.resources
        .map((r) => r.id)
        .toSet() ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final resources = provider.kitchenProfile?.resources ?? [];
    
    // 按类型分组
    final groupedResources = <ResourceType, List<Resource>>{};
    for (final resource in resources) {
      groupedResources.putIfAbsent(resource.type, () => []).add(resource);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('确认可用装备'),
      ),
      body: ResponsiveLayout(
        mobileBody: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: Colors.blue.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '请确认本次烹饪可用的厨房装备。'
                              '取消勾选不可用的装备，系统会据此调整烹饪计划。',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...groupedResources.entries.map((entry) => _buildResourceGroup(
                    entry.key,
                    entry.value,
                  )),
                  const SizedBox(height: 16),
                  if (_hasInsufficientResources())
                    Card(
                      color: Colors.orange.shade50,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '资源不足可能导致计划串行化，烹饪时间可能延长',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('返回'),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _generatePlan,
              icon: const Icon(Icons.play_arrow),
              label: const Text('生成烹饪计划'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceGroup(ResourceType type, List<Resource> resources) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(
                type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                type.displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _toggleGroupSelection(resources),
                child: Text(
                  _isGroupFullySelected(resources) ? '取消全选' : '全选',
                ),
              ),
            ],
          ),
        ),
        ...resources.map((resource) => _buildResourceTile(resource)),
        const Divider(),
      ],
    );
  }

  Widget _buildResourceTile(Resource resource) {
    final isSelected = _selectedResourceIds.contains(resource.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isSelected ? Colors.white : Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppTheme.accentColor.withOpacity(0.5) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => _toggleResource(resource.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
               Icon(
                _getResourceIcon(resource.type),
                color: isSelected ? AppTheme.accentColor : Colors.grey,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.black : Colors.grey,
                      ),
                    ),
                    if (_buildResourceSubtitle(resource) != null) ...[
                      const SizedBox(height: 4),
                      _buildResourceSubtitle(resource)!,
                    ],
                  ],
                ),
              ),
              Switch.adaptive(
                value: isSelected, 
                onChanged: (_) => _toggleResource(resource.id),
                activeColor: AppTheme.accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildResourceSubtitle(Resource resource) {
    final details = <String>[];
    
    if (resource.heatLevel != null) {
      details.add(resource.heatLevel!.displayName);
    }
    if (resource.capacityLiters != null) {
      details.add('${resource.capacityLiters}L');
    }
    if (resource.maxTempCelsius != null) {
      details.add('最高${resource.maxTempCelsius}°C');
    }
    if (resource.isMeatSafe == true) {
      details.add('可处理生肉');
    }
    
    if (details.isEmpty) return null;
    
    return Text(details.join(' · '));
  }

  IconData _getResourceIcon(ResourceType type) {
    switch (type) {
      case ResourceType.stove:
        return Icons.local_fire_department;
      case ResourceType.wok:
        return Icons.soup_kitchen;
      case ResourceType.stewPot:
        return Icons.rice_bowl;
      case ResourceType.steamer:
        return Icons.cloud;
      case ResourceType.cuttingBoard:
        return Icons.content_cut;
      case ResourceType.oven:
        return Icons.microwave;
    }
  }

  void _toggleResource(String id) {
    setState(() {
      if (_selectedResourceIds.contains(id)) {
        _selectedResourceIds.remove(id);
      } else {
        _selectedResourceIds.add(id);
      }
    });
  }

  void _toggleGroupSelection(List<Resource> resources) {
    setState(() {
      if (_isGroupFullySelected(resources)) {
        for (final r in resources) {
          _selectedResourceIds.remove(r.id);
        }
      } else {
        for (final r in resources) {
          _selectedResourceIds.add(r.id);
        }
      }
    });
  }

  bool _isGroupFullySelected(List<Resource> resources) {
    return resources.every((r) => _selectedResourceIds.contains(r.id));
  }

  bool _hasInsufficientResources() {
    // 简化检查：至少需要一个灶具和一个炒锅
    final provider = context.read<AppProvider>();
    final resources = provider.kitchenProfile?.resources ?? [];
    
    final selectedResources = resources
        .where((r) => _selectedResourceIds.contains(r.id))
        .toList();
    
    final hasStove = selectedResources.any((r) => r.type == ResourceType.stove);
    final hasWok = selectedResources.any((r) => r.type == ResourceType.wok);
    
    return !hasStove || !hasWok;
  }

  Future<void> _generatePlan() async {
    setState(() => _isLoading = true);

    try {
      final provider = context.read<AppProvider>();
      final plan = await provider.generatePlan(
        recipeIds: widget.recipeIds,
        availableResourceIds: _selectedResourceIds.toList(),
      );

      if (plan != null && mounted) {
        Navigator.pushReplacementNamed(context, '/preview');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
