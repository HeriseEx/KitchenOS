import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'scheduling_engine.dart';

/// 本地存储服务
/// MVP阶段使用SharedPreferences，后续可替换为真实后端
class StorageService {
  static const String _kitchenProfileKey = 'kitchen_profile';
  static const String _recipesKey = 'recipes';
  static const String _plansKey = 'plans';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ===== Kitchen Profile =====

  Future<KitchenProfile> getKitchenProfile(String userId) async {
    final data = _prefs?.getString(_kitchenProfileKey);
    if (data != null) {
      return KitchenProfile.fromJson(jsonDecode(data));
    }
    return KitchenProfile.defaultProfile(userId);
  }

  Future<void> saveKitchenProfile(KitchenProfile profile) async {
    await _prefs?.setString(_kitchenProfileKey, jsonEncode(profile.toJson()));
  }

  // ===== Recipes =====

  Future<List<Recipe>> getRecipes() async {
    final data = _prefs?.getString(_recipesKey);
    if (data != null) {
      final list = jsonDecode(data) as List;
      return list.map((e) => Recipe.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> saveRecipes(List<Recipe> recipes) async {
    await _prefs?.setString(
      _recipesKey,
      jsonEncode(recipes.map((e) => e.toJson()).toList()),
    );
  }

  // ===== Plans =====

  Future<List<CookingPlan>> getPlans() async {
    final data = _prefs?.getString(_plansKey);
    if (data != null) {
      final list = jsonDecode(data) as List;
      return list.map((e) => CookingPlan.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> savePlan(CookingPlan plan) async {
    final plans = await getPlans();
    plans.insert(0, plan);
    // 只保留最近20个计划
    final toSave = plans.take(20).toList();
    await _prefs?.setString(
      _plansKey,
      jsonEncode(toSave.map((e) => e.toJson()).toList()),
    );
  }
}

/// API服务层
/// 对应 PRD 中的 API 定义
class ApiService {
  final StorageService _storage;
  final SchedulingEngine _scheduler;

  ApiService(this._storage) : _scheduler = SchedulingEngine();

  /// POST /plan/generate
  /// 生成烹饪计划
  Future<CookingPlan> generatePlan({
    required List<String> recipeIds,
    List<String>? availableResourceIds,
  }) async {
    // 获取菜谱
    final allRecipes = await _storage.getRecipes();
    final recipes = allRecipes.where((r) => recipeIds.contains(r.id)).toList();

    if (recipes.isEmpty) {
      throw Exception('未找到指定菜谱');
    }

    // 获取可用资源
    final profile = await _storage.getKitchenProfile('default');
    final effectiveResources = profile.getEffectiveResources(availableResourceIds);

    // 生成计划
    final plan = _scheduler.generatePlan(
      recipes: recipes,
      availableResources: effectiveResources,
    );

    // 保存计划
    await _storage.savePlan(plan);

    return plan;
  }

  /// GET /user/kitchen_profile
  Future<KitchenProfile> getKitchenProfile() async {
    return _storage.getKitchenProfile('default');
  }

  /// PUT /user/kitchen_profile
  Future<void> updateKitchenProfile(KitchenProfile profile) async {
    await _storage.saveKitchenProfile(profile);
  }

  /// POST /resource/reset
  /// 重置资源状态（清洗完成）
  Future<void> resetResource(String resourceId) async {
    final profile = await _storage.getKitchenProfile('default');
    final updatedResources = profile.resources.map((r) {
      if (r.id == resourceId) {
        return r.copyWith(state: ResourceState.free);
      }
      return r;
    }).toList();

    await _storage.saveKitchenProfile(profile.copyWith(
      resources: updatedResources,
      lastUpdated: DateTime.now(),
    ));
  }

  /// 获取所有菜谱
  Future<List<Recipe>> getRecipes() async {
    return _storage.getRecipes();
  }

  /// 获取菜谱详情
  Future<Recipe?> getRecipe(String id) async {
    final recipes = await _storage.getRecipes();
    return recipes.where((r) => r.id == id).firstOrNull;
  }

  /// 保存菜谱
  Future<void> saveRecipes(List<Recipe> recipes) async {
    await _storage.saveRecipes(recipes);
  }

  /// 获取历史计划
  Future<List<CookingPlan>> getPlans() async {
    return _storage.getPlans();
  }
}
