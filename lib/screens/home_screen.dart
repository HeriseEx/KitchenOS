import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/utils.dart';
import '../widgets/responsive_layout.dart';

/// 主页 - 菜谱列表 (iOS 17 Inspired Responsive Redesign)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine screen size classes
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;
    final isTablet = width > 600 && width <= 900;

    return Scaffold(
      extendBodyBehindAppBar: true, // Allow content to scroll behind blur
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (provider.recipes.isEmpty) {
            return const Center(child: Text('暂无菜谱'));
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // iOS Style Large Title Header with Glassmorphism
              SliverAppBar(
                expandedHeight: 100.0,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                elevation: 0,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
                      title: Text(
                        'KitchenOS',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.titleLarge?.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      centerTitle: false, // iOS titles are left-aligned when large
                    ),
                  ),
                ),
                actions: [
                  _GlassActionButton(
                    icon: Icons.calendar_today_outlined,
                    onTap: () => Navigator.pushNamed(context, '/recommendation'),
                    tooltip: '每日推荐',
                  ),
                  const SizedBox(width: 8),
                  _GlassActionButton(
                    icon: Icons.settings_outlined,
                    onTap: () => Navigator.pushNamed(context, '/setup'),
                    tooltip: '设置',
                  ),
                  const SizedBox(width: 16),
                ],
              ),

              // Responsive Content Area
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? (width - 900) / 2 : 16, // Max width constraint
                  vertical: 16,
                ),
                sliver: isDesktop || isTablet
                    ? SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 3 : 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.85, // Taller cards for desktop
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final recipe = provider.recipes[index];
                            return _RecipeCard(recipe: recipe, isGrid: true);
                          },
                          childCount: provider.recipes.length,
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final recipe = provider.recipes[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _RecipeCard(recipe: recipe, isGrid: false),
                            );
                          },
                          childCount: provider.recipes.length,
                        ),
                      ),
              ),
              
              // Bottom padding for FAB
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: AppTheme.luxuryGradient,
          boxShadow: AppTheme.glowShadow,
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showRecipeSelector(context),
          elevation: 0,
          highlightElevation: 0,
          backgroundColor: Colors.transparent,
          icon: const Icon(Icons.restaurant_menu, color: Colors.white),
          label: const Text('开始烹饪', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
      ),
    );
  }

  void _showRecipeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _RecipeSelectorSheet(),
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _GlassActionButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black87, size: 22),
        onPressed: onTap,
        tooltip: tooltip,
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool isGrid;

  const _RecipeCard({required this.recipe, required this.isGrid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showRecipeDetail(context),
          borderRadius: BorderRadius.circular(24),
          child: isGrid ? _buildGridContent(context) : _buildListContent(context),
        ),
      ),
    );
  }

  Widget _buildListContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.05),
                  Theme.of(context).primaryColor.withOpacity(0.02)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.restaurant,
              size: 32,
              color: Theme.of(context).primaryColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  recipe.description ?? '暂无描述',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _InfoBadge(icon: Icons.schedule, text: '${recipe.estimatedMinutes}分钟'),
                    const SizedBox(width: 12),
                    _InfoBadge(icon: Icons.person_outline, text: '${recipe.servings}人'),
                    if (recipe.difficulty != null) ...[
                      const SizedBox(width: 12),
                      _DifficultyBadge(difficulty: recipe.difficulty!),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[300]),
        ],
      ),
    );
  }

  Widget _buildGridContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.08),
                      Theme.of(context).primaryColor.withOpacity(0.03)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ]
                ),
                child: Icon(
                  Icons.restaurant,
                  size: 48,
                  color: Theme.of(context).primaryColor.withOpacity(0.8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            recipe.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            recipe.description ?? '',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoBadge(icon: Icons.schedule, text: '${recipe.estimatedMinutes}m'),
              if (recipe.difficulty != null)
                _DifficultyBadge(difficulty: recipe.difficulty!),
            ],
          ),
        ],
      ),
    );
  }

  void _showRecipeDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BlurModal(
        child: _RecipeDetailSheet(recipe: recipe),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String difficulty;

  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (difficulty) {
      case '简单':
        color = Colors.green;
        break;
      case '中等':
        color = Colors.orange;
        break;
      case '困难':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _BlurModal extends StatelessWidget {
  final Widget child;

  const _BlurModal({required this.child});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ]
              ),
              child: child is _ScrollableWidget 
                ? (child as _ScrollableWidget).copyWithController(scrollController)
                : child,
            ),
          ),
        );
      },
    );
  }
}

// Mixin interface for widgets that need the scroll controller from DraggableScrollableSheet
abstract class _ScrollableWidget {
  Widget copyWithController(ScrollController controller);
}

class _RecipeDetailSheet extends StatelessWidget implements _ScrollableWidget {
  final Recipe recipe;
  final ScrollController? scrollController;

  const _RecipeDetailSheet({
    required this.recipe,
    this.scrollController,
  });

  @override
  Widget copyWithController(ScrollController controller) {
    return _RecipeDetailSheet(recipe: recipe, scrollController: controller);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          recipe.name,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          recipe.description ?? '',
          style: TextStyle(color: Colors.grey[600], fontSize: 17, height: 1.5),
        ),
        const SizedBox(height: 32),
        const Text(
          '食材清单',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: recipe.ingredients.asMap().entries.map((entry) {
              final isLast = entry.key == recipe.ingredients.length - 1;
              return Container(
                decoration: BoxDecoration(
                  border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey[100]!)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.value.name, style: const TextStyle(fontSize: 16)),
                    Text(
                      '${entry.value.quantity}${entry.value.unit}', 
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          '烹饪步骤',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...recipe.steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.action,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      if (step.description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            step.description!,
                            style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.4),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          AppUtils.formatDurationChinese(step.durationSeconds),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => _startCooking(context),
            child: const Text('开始烹饪'),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _startCooking(BuildContext context) {
    Navigator.pop(context);
    Navigator.pushNamed(
      context,
      '/ingredient-confirm',
      arguments: [recipe.id],
    );
  }
}

/// 菜谱选择器（多选）
class _RecipeSelectorSheet extends StatefulWidget {
  const _RecipeSelectorSheet();

  @override
  State<_RecipeSelectorSheet> createState() => _RecipeSelectorSheetState();
}

class _RecipeSelectorSheetState extends State<_RecipeSelectorSheet> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return _BlurModal(
      child: _SelectorContent(
        recipes: provider.recipes,
        selectedIds: _selectedIds,
        onToggle: _toggleSelection,
        onConfirm: _confirmSelection,
      ),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _confirmSelection() {
    Navigator.pop(context);
    Navigator.pushNamed(
      context,
      '/ingredient-confirm',
      arguments: _selectedIds.toList(),
    );
  }
}

class _SelectorContent extends StatelessWidget implements _ScrollableWidget {
  final List<Recipe> recipes;
  final Set<String> selectedIds;
  final Function(String) onToggle;
  final VoidCallback onConfirm;
  final ScrollController? scrollController;

  const _SelectorContent({
    required this.recipes,
    required this.selectedIds,
    required this.onToggle,
    required this.onConfirm,
    this.scrollController,
  });

  @override
  Widget copyWithController(ScrollController controller) {
    return _SelectorContent(
      recipes: recipes,
      selectedIds: selectedIds,
      onToggle: onToggle,
      onConfirm: onConfirm,
      scrollController: controller,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '选择烹饪菜谱',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '选择多道菜系统将自动统筹',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              final isSelected = selectedIds.contains(recipe.id);
              
              return GestureDetector(
                onTap: () => onToggle(recipe.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
                        ),
                        child: isSelected 
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: isSelected ? Theme.of(context).primaryColor : Colors.black,
                              ),
                            ),
                            Text(
                              '${recipe.estimatedMinutes}分钟 · ${recipe.servings}人份',
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Text(
                  '已选 ${selectedIds.length} 道',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: selectedIds.isEmpty ? null : onConfirm,
                  child: const Text('下一步'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
