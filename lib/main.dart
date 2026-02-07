import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/models.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';
import 'services/services.dart';
import 'utils/utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化存储服务
  final storageService = StorageService();
  await storageService.init();
  
  // 创建API服务
  final apiService = ApiService(storageService);
  
  runApp(KitchenOSApp(apiService: apiService));
}

class KitchenOSApp extends StatelessWidget {
  final ApiService apiService;

  const KitchenOSApp({
    super.key,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(apiService)..init(),
      child: MaterialApp(
        title: 'KitchenOS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const _InitialScreen(),
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/home':
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
      case '/setup':
        return MaterialPageRoute(
          builder: (_) => const KitchenSetupScreen(isInitialSetup: false),
        );
      case '/recommendation':
        return MaterialPageRoute(
          builder: (_) => const RecommendationScreen(),
        );
      case '/ingredient-confirm':
        final recipeIds = settings.arguments as List<String>? ?? [];
        return MaterialPageRoute(
          builder: (_) => IngredientConfirmScreen(recipeIds: recipeIds),
        );
      case '/resource-confirm':
        final recipeIds = settings.arguments as List<String>? ?? [];
        return MaterialPageRoute(
          builder: (_) => ResourceConfirmScreen(recipeIds: recipeIds),
        );
      case '/preview':
        return MaterialPageRoute(
          builder: (_) => const PlanPreviewScreen(),
        );
      case '/cooking':
        return MaterialPageRoute(
          builder: (_) => const CookingExecutionScreen(),
        );
      case '/recipe-editor':
        final args = settings.arguments as Map<String, dynamic>?;
        final recipe = args?['recipe'] as Recipe?;
        final modeStr = args?['mode'] as String? ?? 'create';
        EditorMode mode;
        switch (modeStr) {
          case 'edit':
            mode = EditorMode.edit;
            break;
          case 'derive':
            mode = EditorMode.derive;
            break;
          default:
            mode = EditorMode.create;
        }
        return MaterialPageRoute(
          builder: (_) => RecipeEditorScreen(recipe: recipe, mode: mode),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
    }
  }
}

/// 初始界面 - 根据配置状态决定显示内容
class _InitialScreen extends StatelessWidget {
  const _InitialScreen();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在加载...'),
                ],
              ),
            ),
          );
        }

        if (provider.error != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('加载失败: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.init(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          );
        }

        // 如果未配置厨房，显示配置向导
        if (!provider.isConfigured) {
          return const KitchenSetupScreen(isInitialSetup: true);
        }

        // 已配置，显示首页
        return const HomeScreen();
      },
    );
  }
}
