# KitchenOS - 智能厨房烹饪计划系统

基于 Phase 1 MVP PRD 实现的智能烹饪计划生成与执行辅助系统。

## 功能特性

### 核心功能
- **CPM关键路径调度**: 自动计算最优烹饪顺序，最大化并行烹饪
- **资源冲突消解**: 自动处理厨具使用冲突，智能串行化
- **注意力冲突消解**: 避免多个需要专注的步骤同时进行
- **清洗检查点**: 自动插入清洗提醒，支持资源状态管理

### UI界面
- **UI-00 厨房配置向导**: 首次使用引导配置厨房装备
- **主页**: 菜谱列表和选择，支持添加自定义菜谱（+按钮）
- **菜谱详情弹窗**: 浮动卡片样式，四周留白，设置菜单支持编辑/派生/删除
- **菜谱编辑器**: 完整的菜谱CRUD功能（创建/编辑/派生）
- **UI-05a 资源确认**: 烹饪前确认可用装备
- **UI-05 计划预览**: 甘特图展示烹饪计划
- **UI-06 烹饪执行**: 实时计时和步骤指导

## 项目结构

```
kitchen_os/
├── lib/
│   ├── main.dart              # 应用入口
│   ├── models/                # 数据模型
│   │   ├── enums.dart         # 枚举定义
│   │   ├── resource.dart      # 厨房资源
│   │   ├── step.dart          # 烹饪步骤
│   │   ├── recipe.dart        # 菜谱
│   │   ├── kitchen_profile.dart # 厨房配置
│   │   ├── cooking_plan.dart  # 烹饪计划
│   │   └── models.dart        # 导出
│   ├── services/              # 服务层
│   │   ├── scheduling_engine.dart # CPM调度引擎
│   │   ├── api_service.dart   # API服务
│   │   └── services.dart      # 导出
│   ├── providers/             # 状态管理
│   │   ├── app_provider.dart  # 应用状态
│   │   ├── sample_data.dart   # 示例数据
│   │   └── providers.dart     # 导出
│   ├── screens/               # UI界面
│   │   ├── kitchen_setup_screen.dart    # 厨房配置
│   │   ├── home_screen.dart             # 主页
│   │   ├── resource_confirm_screen.dart # 资源确认
│   │   ├── plan_preview_screen.dart     # 计划预览
│   │   ├── cooking_execution_screen.dart # 烹饪执行
│   │   ├── recipe_editor_screen.dart    # 菜谱编辑器
│   │   └── screens.dart       # 导出
│   ├── utils/                 # 工具类
│   │   ├── theme.dart         # 主题配置
│   │   └── utils.dart         # 导出
│   └── widgets/               # 通用组件
├── assets/
│   └── data/                  # 静态数据
├── pubspec.yaml               # 项目配置
└── README.md
```

## 数据模型

### Resource (厨房资源)
```dart
resource_type ∈ {stove, wok, stew_pot, steamer, cutting_board, oven}
state ∈ {Free, Occupied, Dirty}
```

### Step (烹饪步骤)
```dart
S = (d, deps, R, p, cleaning)
where:
  d    = duration（秒）
  deps = 依赖集合
  R    = 所需资源类型
  p    = parallel_level ∈ {0,1,2}
  cleaning = requires_cleaning_after (Boolean)
```

## API接口

### POST /plan/generate
生成烹饪计划

```json
{
  "recipe_ids": ["uuid"],
  "available_resources": ["uuid"]
}
```

### GET /user/kitchen_profile
获取用户厨房配置

### PUT /user/kitchen_profile
更新用户厨房配置

### POST /resource/reset
重置资源状态（清洗完成）

## 运行项目

1. 确保已安装 Flutter SDK (>=3.0.0)

2. 获取依赖
```bash
cd kitchen_os
flutter pub get
```

3. 运行应用
```bash
flutter run
```

## 测试用例

- **TC1**: BOM合并（300g + 200g → 500g）
- **TC2**: 循环依赖 → 返回400 + 环路径
- **TC3**: 资源冲突 → 自动串行化
- **TC4**: 能力降级使用 → 产生Warning
- **TC5**: 资源复用阻塞与解锁

## 技术栈

- **Flutter 3.x**: 跨平台UI框架
- **Provider**: 状态管理
- **SharedPreferences**: 本地数据持久化

## 路线图

- [x] Sprint 1-2: DB + 调度引擎 + API
- [x] Sprint 3: Flutter首页 + 甘特图
- [x] 菜谱编辑器: 创建/编辑/派生/删除功能
- [x] Ubuntu开发环境支持
- [ ] Sprint 4: 联调 + Cloud Run部署
- [ ] Sprint 5: 容错重排 + 可观测性
