import 'step.dart';

/// 食材模型
class Ingredient {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final bool isPrepRequired;

  Ingredient({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.isPrepRequired = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'is_prep_required': isPrepRequired,
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'].toDouble(),
      unit: json['unit'],
      isPrepRequired: json['is_prep_required'] ?? false,
    );
  }
}

/// 菜谱模型
/// 对应 PRD 中的 recipes 表
class Recipe {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int servings;                     // 份量
  final int estimatedMinutes;             // 预估时间（分钟）
  final List<Ingredient> ingredients;     // 食材列表
  final List<Step> steps;                 // 步骤列表
  final List<String> tags;                // 标签
  final String? difficulty;               // 难度

  Recipe({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.servings = 2,
    required this.estimatedMinutes,
    this.ingredients = const [],
    this.steps = const [],
    this.tags = const [],
    this.difficulty,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'servings': servings,
      'estimated_minutes': estimatedMinutes,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'steps': steps.map((e) => e.toJson()).toList(),
      'tags': tags,
      'difficulty': difficulty,
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['image_url'],
      servings: json['servings'] ?? 2,
      estimatedMinutes: json['estimated_minutes'],
      ingredients: (json['ingredients'] as List?)
          ?.map((e) => Ingredient.fromJson(e))
          .toList() ?? [],
      steps: (json['steps'] as List?)
          ?.map((e) => Step.fromJson(e))
          .toList() ?? [],
      tags: List<String>.from(json['tags'] ?? []),
      difficulty: json['difficulty'],
    );
  }
}
