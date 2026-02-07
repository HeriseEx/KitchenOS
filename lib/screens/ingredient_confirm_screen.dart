import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/responsive_layout.dart';
import '../utils/utils.dart';

/// UI-New: 食材准备确认界面
/// 在选定菜单后，进入制作步骤前，确认食材准备情况
class IngredientConfirmScreen extends StatefulWidget {
  final List<String> recipeIds;

  const IngredientConfirmScreen({
    super.key,
    required this.recipeIds,
  });

  @override
  State<IngredientConfirmScreen> createState() => _IngredientConfirmScreenState();
}

class _IngredientConfirmScreenState extends State<IngredientConfirmScreen> {
  // Map of Ingredient Name -> Boolean (checked)
  final Map<String, bool> _checkedIngredients = {};
  List<AggregatedIngredient> _aggregatedIngredients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIngredients();
    });
  }

  void _loadIngredients() {
    final provider = context.read<AppProvider>();
    final recipes = provider.recipes
        .where((r) => widget.recipeIds.contains(r.id))
        .toList();

    // Aggregate ingredients
    final Map<String, AggregatedIngredient> aggMap = {};

    for (var recipe in recipes) {
      for (var ingredient in recipe.ingredients) {
        // Simple aggregation key: Name + Unit (to avoid mixing grams and pieces if name same)
        // Ideally we should normalize, but for MVP strict match
        final key = '${ingredient.name}_${ingredient.unit}';
        
        if (aggMap.containsKey(key)) {
          aggMap[key]!.quantity += ingredient.quantity;
          aggMap[key]!.sourceRecipes.add(recipe.name);
        } else {
          aggMap[key] = AggregatedIngredient(
            name: ingredient.name,
            quantity: ingredient.quantity,
            unit: ingredient.unit,
            sourceRecipes: {recipe.name},
          );
        }
      }
    }

    setState(() {
      _aggregatedIngredients = aggMap.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('食材准备确认'),
      ),
      body: ResponsiveLayout(
        mobileBody: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.orange.withOpacity(0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '请确认以下食材已准备就绪，勾选确认后即可开始下一步。',
                            style: TextStyle(color: Colors.orange[900]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _aggregatedIngredients.length,
                      itemBuilder: (context, index) {
                        final item = _aggregatedIngredients[index];
                        final isChecked = _checkedIngredients[item.key] ?? false;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: isChecked 
                              ? AppTheme.accentColor.withOpacity(0.05) 
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isChecked 
                                  ? AppTheme.accentColor.withOpacity(0.5) 
                                  : Colors.grey.shade200,
                              width: isChecked ? 1.5 : 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _toggleItem(item.key),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isChecked ? AppTheme.accentColor : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isChecked ? AppTheme.accentColor : Colors.grey.shade300,
                                        width: 2
                                      ),
                                    ),
                                    child: isChecked 
                                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              item.name,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isChecked ? Colors.black : Colors.black87,
                                                decoration: isChecked ? TextDecoration.lineThrough : null,
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${item.quantityStr}${item.unit}',
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.secondary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '用于: ${item.sourceRecipes.join("、")}',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, -4),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: _selectAll,
                            child: Text(_isAllSelected ? '取消全选' : '全选'),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _isAllSelected ? _proceed : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            ),
                            child: const Text('准备好了，下一步'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  bool get _isAllSelected => 
      _aggregatedIngredients.isNotEmpty && 
      _aggregatedIngredients.every((item) => _checkedIngredients[item.key] == true);

  void _toggleItem(String key) {
    setState(() {
      _checkedIngredients[key] = !(_checkedIngredients[key] ?? false);
    });
  }

  void _selectAll() {
    final newValue = !_isAllSelected;
    setState(() {
      for (var item in _aggregatedIngredients) {
        _checkedIngredients[item.key] = newValue;
      }
    });
  }

  void _proceed() {
    Navigator.pushNamed(
      context,
      '/resource-confirm',
      arguments: widget.recipeIds,
    );
  }
}

class AggregatedIngredient {
  final String name;
  double quantity;
  final String unit;
  final Set<String> sourceRecipes;

  AggregatedIngredient({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.sourceRecipes,
  });

  String get key => '${name}_$unit';
  
  String get quantityStr {
    if (quantity == quantity.roundToDouble()) {
      return quantity.round().toString();
    }
    return quantity.toStringAsFixed(1);
  }
}
