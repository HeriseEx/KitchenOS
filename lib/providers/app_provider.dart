import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'sample_data.dart';

/// 应用状态管理
class AppProvider extends ChangeNotifier {
  final ApiService _api;
  
  // 状态
  KitchenProfile? _kitchenProfile;
  List<Recipe> _recipes = [];
  CookingPlan? _currentPlan;
  List<CookingPlan> _planHistory = [];
  bool _isLoading = false;
  String? _error;
  
  // 执行状态
  int _currentStepIndex = 0;
  bool _isExecuting = false;
  int _elapsedSeconds = 0;
  int _activeCookingSeconds = 0;

  AppProvider(this._api);

  // Getters
  KitchenProfile? get kitchenProfile => _kitchenProfile;
  List<Recipe> get recipes => _recipes;
  CookingPlan? get currentPlan => _currentPlan;
  List<CookingPlan> get planHistory => _planHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConfigured => _kitchenProfile?.isConfigured ?? false;
  
  int get currentStepIndex => _currentStepIndex;
  bool get isExecuting => _isExecuting;
  int get elapsedSeconds => _elapsedSeconds;
  int get activeCookingSeconds => _activeCookingSeconds;

  TimelineNode? get currentNode {
    if (_currentPlan == null || 
        _currentStepIndex >= _currentPlan!.timeline.length) {
      return null;
    }
    return _currentPlan!.timeline[_currentStepIndex];
  }

  /// 初始化
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _kitchenProfile = await _api.getKitchenProfile();
      _recipes = await _api.getRecipes();
      _planHistory = await _api.getPlans();

      // 如果没有菜谱，或者菜谱数量过少（旧缓存），加载示例数据
      if (_recipes.isEmpty || _recipes.length < 7) {
        _recipes = SampleData.getSampleRecipes();
        await _api.saveRecipes(_recipes);
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 保存厨房配置
  Future<void> saveKitchenProfile(KitchenProfile profile) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.updateKitchenProfile(profile);
      _kitchenProfile = profile;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 生成烹饪计划
  Future<CookingPlan?> generatePlan({
    required List<String> recipeIds,
    List<String>? availableResourceIds,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentPlan = await _api.generatePlan(
        recipeIds: recipeIds,
        availableResourceIds: availableResourceIds,
      );
      _planHistory = await _api.getPlans();
      _currentStepIndex = 0;
      _isExecuting = false;
      _elapsedSeconds = 0;
      _activeCookingSeconds = 0;
      return _currentPlan;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 开始执行计划
  void startExecution() {
    _isExecuting = true;
    _currentStepIndex = 0;
    _elapsedSeconds = 0;
    _activeCookingSeconds = 0;
    
    if (_currentPlan != null && _currentPlan!.timeline.isNotEmpty) {
      _currentPlan!.timeline[0].isActive = true;
    }
    
    notifyListeners();
  }

  /// 完成当前步骤
  void completeCurrentStep() {
    if (_currentPlan == null) return;

    final timeline = _currentPlan!.timeline;
    if (_currentStepIndex < timeline.length) {
      timeline[_currentStepIndex].isCompleted = true;
      timeline[_currentStepIndex].isActive = false;
      
      // 如果当前步骤需要清洗，更新资源状态
      final currentNode = timeline[_currentStepIndex];
      if (currentNode.isStep) {
        _activeCookingSeconds += currentNode.durationSeconds;
      }

      _currentStepIndex++;

      if (_currentStepIndex < timeline.length) {
        timeline[_currentStepIndex].isActive = true;
      } else {
        _isExecuting = false;
      }
    }

    notifyListeners();
  }

  /// 重置资源（清洗完成）
  Future<void> resetResource(String resourceId) async {
    try {
      await _api.resetResource(resourceId);
      
      // 更新本地状态
      if (_kitchenProfile != null) {
        final updatedResources = _kitchenProfile!.resources.map((r) {
          if (r.id == resourceId) {
            return r.copyWith(state: ResourceState.free);
          }
          return r;
        }).toList();
        
        _kitchenProfile = _kitchenProfile!.copyWith(
          resources: updatedResources,
        );
      }

      // 如果当前是checkpoint，自动完成
      if (currentNode?.isCheckpoint == true) {
        completeCurrentStep();
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 更新计时器
  void updateTimers(int elapsed) {
    _elapsedSeconds = elapsed;
    notifyListeners();
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 设置当前计划
  void setCurrentPlan(CookingPlan plan) {
    _currentPlan = plan;
    _currentStepIndex = 0;
    _isExecuting = false;
    notifyListeners();
  }
}
