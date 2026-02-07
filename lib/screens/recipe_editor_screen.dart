import 'package:flutter/material.dart' hide Step;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';

enum EditorMode { create, edit, derive }

class RecipeEditorScreen extends StatefulWidget {
  final Recipe? recipe;
  final EditorMode mode;

  const RecipeEditorScreen({
    super.key,
    this.recipe,
    this.mode = EditorMode.create,
  });

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _servingsController;
  late TextEditingController _estimatedMinutesController;
  
  String _difficulty = '简单';
  List<Ingredient> _ingredients = [];
  List<Step> _steps = [];
  List<String> _tags = [];

  final List<String> _difficultyOptions = ['简单', '中等', '困难'];

  @override
  void initState() {
    super.initState();
    _initializeFromRecipe();
  }

  void _initializeFromRecipe() {
    final recipe = widget.recipe;
    if (recipe != null) {
      _nameController = TextEditingController(
        text: widget.mode == EditorMode.derive ? '${recipe.name} (副本)' : recipe.name,
      );
      _descriptionController = TextEditingController(text: recipe.description ?? '');
      _servingsController = TextEditingController(text: recipe.servings.toString());
      _estimatedMinutesController = TextEditingController(text: recipe.estimatedMinutes.toString());
      _difficulty = recipe.difficulty ?? '简单';
      _ingredients = recipe.ingredients.map((i) => Ingredient(
        id: widget.mode == EditorMode.derive ? _uuid.v4() : i.id,
        name: i.name,
        quantity: i.quantity,
        unit: i.unit,
        isPrepRequired: i.isPrepRequired,
      )).toList();
      _steps = recipe.steps.map((s) => s.copyWith(
        id: widget.mode == EditorMode.derive ? _uuid.v4() : s.id,
      )).toList();
      _tags = List.from(recipe.tags);
    } else {
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _servingsController = TextEditingController(text: '2');
      _estimatedMinutesController = TextEditingController(text: '30');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _servingsController.dispose();
    _estimatedMinutesController.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.mode) {
      case EditorMode.create:
        return '新建菜谱';
      case EditorMode.edit:
        return '编辑菜谱';
      case EditorMode.derive:
        return '派生菜谱';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.paste_rounded),
            tooltip: '导入 JSON',
            onPressed: _importJson,
          ),
          TextButton.icon(
            onPressed: _saveRecipe,
            icon: const Icon(Icons.check),
            label: const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildIngredientsSection(),
            const SizedBox(height: 24),
            _buildStepsSection(),
            const SizedBox(height: 24),
            _buildTagsSection(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _SectionCard(
      title: '基本信息',
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '菜谱名称 *',
              hintText: '例如：红烧肉',
            ),
            validator: (v) => v == null || v.isEmpty ? '请输入菜谱名称' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: '描述',
              hintText: '简单介绍这道菜',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _servingsController,
                  decoration: const InputDecoration(
                    labelText: '份量（人）',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return '必填';
                    if (int.tryParse(v) == null) return '请输入数字';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _estimatedMinutesController,
                  decoration: const InputDecoration(
                    labelText: '预计时间（分钟）',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return '必填';
                    if (int.tryParse(v) == null) return '请输入数字';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _difficulty,
            decoration: const InputDecoration(labelText: '难度'),
            items: _difficultyOptions.map((d) => DropdownMenuItem(
              value: d,
              child: Text(d),
            )).toList(),
            onChanged: (v) => setState(() => _difficulty = v ?? '简单'),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    return _SectionCard(
      title: '食材清单',
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        onPressed: _addIngredient,
        color: Theme.of(context).primaryColor,
      ),
      child: _ingredients.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.shopping_basket_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text('暂无食材，点击右上角添加', style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              ),
            )
          : ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ingredients.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _ingredients.removeAt(oldIndex);
                  _ingredients.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final ingredient = _ingredients[index];
                return _IngredientTile(
                  key: ValueKey(ingredient.id),
                  ingredient: ingredient,
                  onEdit: () => _editIngredient(index),
                  onDelete: () => setState(() => _ingredients.removeAt(index)),
                );
              },
            ),
    );
  }

  Widget _buildStepsSection() {
    return _SectionCard(
      title: '烹饪步骤',
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        onPressed: _addStep,
        color: Theme.of(context).primaryColor,
      ),
      child: _steps.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.format_list_numbered, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text('暂无步骤，点击右上角添加', style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              ),
            )
          : ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _steps.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _steps.removeAt(oldIndex);
                  _steps.insert(newIndex, item);
                  _updateStepIndexes();
                });
              },
              itemBuilder: (context, index) {
                final step = _steps[index];
                return _StepTile(
                  key: ValueKey(step.id),
                  step: step,
                  index: index,
                  onEdit: () => _editStep(index),
                  onDelete: () {
                    setState(() {
                      _steps.removeAt(index);
                      _updateStepIndexes();
                    });
                  },
                );
              },
            ),
    );
  }

  Widget _buildTagsSection() {
    return _SectionCard(
      title: '标签',
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        onPressed: _addTag,
        color: Theme.of(context).primaryColor,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _tags.isEmpty
            ? [Text('暂无标签', style: TextStyle(color: Colors.grey[500]))]
            : _tags.map((tag) => Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => setState(() => _tags.remove(tag)),
              )).toList(),
      ),
    );
  }

  void _addIngredient() async {
    final result = await showDialog<Ingredient>(
      context: context,
      builder: (ctx) => _IngredientDialog(),
    );
    if (result != null) {
      setState(() => _ingredients.add(result));
    }
  }

  void _editIngredient(int index) async {
    final result = await showDialog<Ingredient>(
      context: context,
      builder: (ctx) => _IngredientDialog(ingredient: _ingredients[index]),
    );
    if (result != null) {
      setState(() => _ingredients[index] = result);
    }
  }

  void _addStep() async {
    final recipeId = widget.recipe?.id ?? _uuid.v4();
    final result = await showDialog<Step>(
      context: context,
      builder: (ctx) => _StepDialog(recipeId: recipeId, orderIndex: _steps.length),
    );
    if (result != null) {
      setState(() => _steps.add(result));
    }
  }

  void _editStep(int index) async {
    final result = await showDialog<Step>(
      context: context,
      builder: (ctx) => _StepDialog(step: _steps[index], recipeId: _steps[index].recipeId, orderIndex: index),
    );
    if (result != null) {
      setState(() => _steps[index] = result);
    }
  }

  void _updateStepIndexes() {
    for (int i = 0; i < _steps.length; i++) {
      _steps[i] = _steps[i].copyWith(orderIndex: i);
    }
  }

  void _addTag() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加标签'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '输入标签名'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('添加'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && !_tags.contains(result)) {
      setState(() => _tags.add(result));
    }
  }

  void _importJson() async {
    final importedRecipe = await showDialog<Recipe>(
      context: context,
      builder: (ctx) => const PasteJsonDialog(),
    );

    if (importedRecipe != null) {
      setState(() {
        _nameController.text = importedRecipe.name;
        _descriptionController.text = importedRecipe.description ?? '';
        _servingsController.text = importedRecipe.servings.toString();
        _estimatedMinutesController.text = importedRecipe.estimatedMinutes.toString();
        _difficulty = importedRecipe.difficulty ?? '简单';
        _ingredients = List.from(importedRecipe.ingredients);
        _steps = List.from(importedRecipe.steps);
        _tags = List.from(importedRecipe.tags);
        _updateStepIndexes();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导入成功')),
      );
    }
  }

  void _saveRecipe() {
    if (!_formKey.currentState!.validate()) return;
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少添加一个食材')),
      );
      return;
    }
    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少添加一个步骤')),
      );
      return;
    }

    final recipeId = widget.mode == EditorMode.edit 
        ? widget.recipe!.id 
        : _uuid.v4();

    final recipe = Recipe(
      id: recipeId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      servings: int.parse(_servingsController.text),
      estimatedMinutes: int.parse(_estimatedMinutesController.text),
      ingredients: _ingredients,
      steps: _steps.map<Step>((Step s) => s.copyWith(recipeId: recipeId)).toList(),
      tags: _tags,
      difficulty: _difficulty,
    );

    final provider = context.read<AppProvider>();
    if (widget.mode == EditorMode.edit) {
      provider.updateRecipe(recipe);
    } else {
      provider.addRecipe(recipe);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.mode == EditorMode.edit ? '更新' : '创建'}成功')),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _IngredientTile extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _IngredientTile({
    super.key,
    required this.ingredient,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.drag_handle, color: Colors.grey),
      title: Text(ingredient.name),
      subtitle: Text('${ingredient.quantity}${ingredient.unit}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
          IconButton(icon: Icon(Icons.delete, size: 20, color: Colors.red[300]), onPressed: onDelete),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final Step step;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StepTile({
    super.key,
    required this.step,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.drag_handle, color: Colors.grey),
          const SizedBox(width: 8),
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
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
      title: Text(step.action, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(AppUtils.formatDurationChinese(step.durationSeconds)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
          IconButton(icon: Icon(Icons.delete, size: 20, color: Colors.red[300]), onPressed: onDelete),
        ],
      ),
    );
  }
}

class _IngredientDialog extends StatefulWidget {
  final Ingredient? ingredient;

  const _IngredientDialog({this.ingredient});

  @override
  State<_IngredientDialog> createState() => _IngredientDialogState();
}

class _IngredientDialogState extends State<_IngredientDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  bool _isPrepRequired = false;

  @override
  void initState() {
    super.initState();
    final i = widget.ingredient;
    _nameController = TextEditingController(text: i?.name ?? '');
    _quantityController = TextEditingController(text: i?.quantity.toString() ?? '');
    _unitController = TextEditingController(text: i?.unit ?? '克');
    _isPrepRequired = i?.isPrepRequired ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.ingredient == null ? '添加食材' : '编辑食材'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '食材名称 *'),
                validator: (v) => v == null || v.isEmpty ? '必填' : null,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: '数量 *'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return '必填';
                        if (double.tryParse(v) == null) return '数字';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(labelText: '单位'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('需要预处理'),
                value: _isPrepRequired,
                onChanged: (v) => setState(() => _isPrepRequired = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final ingredient = Ingredient(
              id: widget.ingredient?.id ?? const Uuid().v4(),
              name: _nameController.text.trim(),
              quantity: double.parse(_quantityController.text),
              unit: _unitController.text.trim().isEmpty ? '份' : _unitController.text.trim(),
              isPrepRequired: _isPrepRequired,
            );
            Navigator.pop(context, ingredient);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class _StepDialog extends StatefulWidget {
  final Step? step;
  final String recipeId;
  final int orderIndex;

  const _StepDialog({this.step, required this.recipeId, required this.orderIndex});

  @override
  State<_StepDialog> createState() => _StepDialogState();
}

class _StepDialogState extends State<_StepDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _actionController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  String? _resourceType;
  ParallelLevel _parallelLevel = ParallelLevel.focused;
  bool _requiresCleaningAfter = false;

  final List<String> _resourceTypes = ['stove', 'wok', 'stewPot', 'steamer', 'cuttingBoard', 'oven'];
  final Map<String, String> _resourceTypeNames = {
    'stove': '灶具',
    'wok': '炒锅',
    'stewPot': '炖锅',
    'steamer': '蒸锅',
    'cuttingBoard': '案板',
    'oven': '烤箱',
  };

  @override
  void initState() {
    super.initState();
    final s = widget.step;
    _actionController = TextEditingController(text: s?.action ?? '');
    _descriptionController = TextEditingController(text: s?.description ?? '');
    _durationController = TextEditingController(text: s != null ? (s.durationSeconds ~/ 60).toString() : '');
    _resourceType = s?.resourceType;
    _parallelLevel = s?.parallelLevel ?? ParallelLevel.focused;
    _requiresCleaningAfter = s?.requiresCleaningAfter ?? false;
  }

  @override
  void dispose() {
    _actionController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.step == null ? '添加步骤' : '编辑步骤'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _actionController,
                decoration: const InputDecoration(labelText: '步骤动作 *', hintText: '例如：热锅下油'),
                validator: (v) => v == null || v.isEmpty ? '必填' : null,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: '详细说明'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: '持续时间（分钟）*'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return '必填';
                  if (int.tryParse(v) == null) return '请输入数字';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _resourceType,
                decoration: const InputDecoration(labelText: '所需资源'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('无')),
                  ..._resourceTypes.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(_resourceTypeNames[t] ?? t),
                  )),
                ],
                onChanged: (v) => setState(() => _resourceType = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ParallelLevel>(
                value: _parallelLevel,
                decoration: const InputDecoration(labelText: '并行等级'),
                items: ParallelLevel.values.map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(p.displayName),
                )).toList(),
                onChanged: (v) => setState(() => _parallelLevel = v ?? ParallelLevel.focused),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('完成后需清洗'),
                value: _requiresCleaningAfter,
                onChanged: (v) => setState(() => _requiresCleaningAfter = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final step = Step(
              id: widget.step?.id ?? const Uuid().v4(),
              recipeId: widget.recipeId,
              action: _actionController.text.trim(),
              description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
              durationSeconds: int.parse(_durationController.text) * 60,
              resourceType: _resourceType,
              parallelLevel: _parallelLevel,
              requiresCleaningAfter: _requiresCleaningAfter,
              orderIndex: widget.orderIndex,
            );
            Navigator.pop(context, step);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
