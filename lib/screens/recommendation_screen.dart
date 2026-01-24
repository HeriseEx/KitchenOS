import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/utils.dart';

class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日推荐'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final allRecipes = provider.recipes;
          
          // Categorize recipes
          final breakfastRecipes = allRecipes.where((r) => 
            r.tags.contains('早餐')
          ).toList();

          final lunchRecipes = allRecipes.where((r) => 
            !r.tags.contains('早餐') && 
            (r.tags.contains('下饭菜') || r.tags.contains('硬菜') || r.tags.contains('川菜'))
          ).toList();

          final dinnerRecipes = allRecipes.where((r) => 
            !r.tags.contains('早餐') && 
            (r.tags.contains('清淡') || r.tags.contains('素菜') || r.tags.contains('蒸菜') || r.tags.contains('健康'))
          ).toList();
          
          // Fallback: If dinner/lunch lists are empty, loosely distribute
          // For demo purposes, we can allow overlap or just simple filtering above is fine.
          
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '今日食谱',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '为您精心搭配的一日三餐',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _buildSectionHeader(context, '早餐', '美好的一天从这里开始', Icons.wb_sunny_outlined),
              _buildRecipeList(context, breakfastRecipes),

              _buildSectionHeader(context, '午餐', '能量满满，工作更有劲', Icons.restaurant),
              _buildRecipeList(context, lunchRecipes),

              _buildSectionHeader(context, '晚餐', '清淡饮食，健康生活', Icons.nightlight_round),
              _buildRecipeList(context, dinnerRecipes),
                
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.luxuryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                ),
                child: const Icon(Icons.star, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeList(BuildContext context, List<Recipe> recipes) {
    if (recipes.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text('暂无推荐', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final recipe = recipes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RecommendationCard(recipe: recipe),
            );
          },
          childCount: recipes.length,
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Recipe recipe;

  const _RecommendationCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
           Navigator.pushNamed(
            context,
            '/ingredient-confirm',
            arguments: [recipe.id],
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  size: 32,
                  color: Theme.of(context).primaryColor,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.description ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _SmallTag(icon: Icons.access_time, text: '${recipe.estimatedMinutes}m'),
                        const SizedBox(width: 8),
                        _SmallTag(icon: Icons.local_fire_department, text: recipe.difficulty ?? '一般'),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallTag({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey[500]),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(color: Colors.grey[600], fontSize: 11),
        ),
      ],
    );
  }
}
