# KitchenOS Recipe Function Call API

## 概述

本文档定义了菜谱新增和派生的 JSON 配置结构，可用于 Function Call 集成。

---

## 1. 创建/更新菜谱

### Function: `createRecipe` / `updateRecipe`

#### 请求参数

```json
{
  "name": "createRecipe",
  "description": "创建或更新一个菜谱",
  "parameters": {
    "type": "object",
    "properties": {
      "id": {
        "type": "string",
        "description": "菜谱唯一ID（更新时必填，创建时可选，系统自动生成UUID）"
      },
      "name": {
        "type": "string",
        "description": "菜谱名称"
      },
      "description": {
        "type": "string",
        "description": "菜谱描述"
      },
      "servings": {
        "type": "integer",
        "description": "份量（人数）",
        "default": 2
      },
      "estimated_minutes": {
        "type": "integer",
        "description": "预计烹饪时间（分钟）"
      },
      "difficulty": {
        "type": "string",
        "enum": ["简单", "中等", "困难"],
        "description": "难度等级"
      },
      "tags": {
        "type": "array",
        "items": { "type": "string" },
        "description": "标签列表"
      },
      "ingredients": {
        "type": "array",
        "description": "食材列表",
        "items": {
          "$ref": "#/definitions/Ingredient"
        }
      },
      "steps": {
        "type": "array",
        "description": "烹饪步骤列表",
        "items": {
          "$ref": "#/definitions/Step"
        }
      }
    },
    "required": ["name", "estimated_minutes", "ingredients", "steps"]
  }
}
```

---

## 2. 数据结构定义

### Ingredient（食材）

```json
{
  "type": "object",
  "properties": {
    "id": {
      "type": "string",
      "description": "食材唯一ID"
    },
    "name": {
      "type": "string",
      "description": "食材名称"
    },
    "quantity": {
      "type": "number",
      "description": "数量"
    },
    "unit": {
      "type": "string",
      "description": "单位（克、毫升、个、勺等）"
    },
    "is_prep_required": {
      "type": "boolean",
      "description": "是否需要预处理",
      "default": false
    }
  },
  "required": ["id", "name", "quantity", "unit"]
}
```

### Step（烹饪步骤）

```json
{
  "type": "object",
  "properties": {
    "id": {
      "type": "string",
      "description": "步骤唯一ID"
    },
    "recipe_id": {
      "type": "string",
      "description": "所属菜谱ID"
    },
    "action": {
      "type": "string",
      "description": "步骤动作（如：热锅下油）"
    },
    "description": {
      "type": "string",
      "description": "详细说明"
    },
    "duration_seconds": {
      "type": "integer",
      "description": "持续时间（秒）"
    },
    "dependencies": {
      "type": "array",
      "items": { "type": "string" },
      "description": "依赖的步骤ID列表"
    },
    "resource_type": {
      "type": "string",
      "enum": ["stove", "wok", "stewPot", "steamer", "cuttingBoard", "oven"],
      "description": "所需资源类型"
    },
    "parallel_level": {
      "type": "integer",
      "enum": [0, 1, 2],
      "description": "并行等级：0=需专注，1=可并行，2=后台任务"
    },
    "requires_cleaning_after": {
      "type": "boolean",
      "description": "完成后是否需要清洗",
      "default": false
    },
    "order_index": {
      "type": "integer",
      "description": "步骤顺序索引"
    }
  },
  "required": ["id", "recipe_id", "action", "duration_seconds", "order_index"]
}
```

---

## 3. 派生菜谱

### Function: `deriveRecipe`

派生菜谱会基于现有菜谱创建一个新的副本，并生成新的ID。

```json
{
  "name": "deriveRecipe",
  "description": "基于现有菜谱派生一个新菜谱",
  "parameters": {
    "type": "object",
    "properties": {
      "source_recipe_id": {
        "type": "string",
        "description": "源菜谱ID"
      },
      "new_name": {
        "type": "string",
        "description": "新菜谱名称（默认为'原名称 (副本)'）"
      },
      "modifications": {
        "type": "object",
        "description": "要修改的字段",
        "properties": {
          "description": { "type": "string" },
          "servings": { "type": "integer" },
          "estimated_minutes": { "type": "integer" },
          "difficulty": { "type": "string" },
          "tags": { "type": "array", "items": { "type": "string" } },
          "ingredients": { "type": "array" },
          "steps": { "type": "array" }
        }
      }
    },
    "required": ["source_recipe_id"]
  }
}
```

---

## 4. 删除菜谱

### Function: `deleteRecipe`

```json
{
  "name": "deleteRecipe",
  "description": "删除指定菜谱",
  "parameters": {
    "type": "object",
    "properties": {
      "recipe_id": {
        "type": "string",
        "description": "要删除的菜谱ID"
      }
    },
    "required": ["recipe_id"]
  }
}
```

---

## 5. 完整示例

### 创建菜谱请求示例

```json
{
  "name": "红烧肉",
  "description": "经典家常红烧肉，肥而不腻",
  "servings": 4,
  "estimated_minutes": 90,
  "difficulty": "中等",
  "tags": ["家常菜", "肉类", "下饭菜"],
  "ingredients": [
    {
      "id": "ing_001",
      "name": "五花肉",
      "quantity": 500,
      "unit": "克",
      "is_prep_required": true
    },
    {
      "id": "ing_002",
      "name": "生姜",
      "quantity": 20,
      "unit": "克",
      "is_prep_required": false
    },
    {
      "id": "ing_003",
      "name": "料酒",
      "quantity": 30,
      "unit": "毫升",
      "is_prep_required": false
    },
    {
      "id": "ing_004",
      "name": "生抽",
      "quantity": 30,
      "unit": "毫升",
      "is_prep_required": false
    },
    {
      "id": "ing_005",
      "name": "老抽",
      "quantity": 15,
      "unit": "毫升",
      "is_prep_required": false
    },
    {
      "id": "ing_006",
      "name": "冰糖",
      "quantity": 30,
      "unit": "克",
      "is_prep_required": false
    }
  ],
  "steps": [
    {
      "id": "step_001",
      "recipe_id": "recipe_hongshaorou",
      "action": "五花肉切块焯水",
      "description": "五花肉切成3cm见方的块，冷水下锅焯水去血沫",
      "duration_seconds": 300,
      "dependencies": [],
      "resource_type": "stewPot",
      "parallel_level": 0,
      "requires_cleaning_after": true,
      "order_index": 0
    },
    {
      "id": "step_002",
      "recipe_id": "recipe_hongshaorou",
      "action": "炒糖色",
      "description": "锅中放少许油，小火炒化冰糖至枣红色",
      "duration_seconds": 180,
      "dependencies": ["step_001"],
      "resource_type": "wok",
      "parallel_level": 0,
      "requires_cleaning_after": false,
      "order_index": 1
    },
    {
      "id": "step_003",
      "recipe_id": "recipe_hongshaorou",
      "action": "翻炒上色",
      "description": "放入焯好的五花肉翻炒均匀，使肉块裹上糖色",
      "duration_seconds": 180,
      "dependencies": ["step_002"],
      "resource_type": "wok",
      "parallel_level": 0,
      "requires_cleaning_after": false,
      "order_index": 2
    },
    {
      "id": "step_004",
      "recipe_id": "recipe_hongshaorou",
      "action": "调味",
      "description": "加入姜片、料酒、生抽、老抽翻炒均匀",
      "duration_seconds": 120,
      "dependencies": ["step_003"],
      "resource_type": "wok",
      "parallel_level": 0,
      "requires_cleaning_after": false,
      "order_index": 3
    },
    {
      "id": "step_005",
      "recipe_id": "recipe_hongshaorou",
      "action": "炖煮",
      "description": "加入没过肉的热水，大火烧开后转小火炖1小时",
      "duration_seconds": 3600,
      "dependencies": ["step_004"],
      "resource_type": "stewPot",
      "parallel_level": 2,
      "requires_cleaning_after": false,
      "order_index": 4
    },
    {
      "id": "step_006",
      "recipe_id": "recipe_hongshaorou",
      "action": "收汁",
      "description": "大火收汁至浓稠，汤汁裹满肉块即可",
      "duration_seconds": 300,
      "dependencies": ["step_005"],
      "resource_type": "wok",
      "parallel_level": 0,
      "requires_cleaning_after": true,
      "order_index": 5
    }
  ]
}
```

---

## 6. 资源类型说明

| 资源类型 | 英文标识 | 说明 |
|---------|---------|------|
| 灶具 | stove | 加热设备 |
| 炒锅 | wok | 用于翻炒 |
| 炖锅 | stewPot | 用于炖煮 |
| 蒸锅 | steamer | 用于蒸制 |
| 案板 | cuttingBoard | 用于切配 |
| 烤箱 | oven | 用于烘烤 |

## 7. 并行等级说明

| 等级 | 值 | 说明 |
|-----|---|------|
| 需专注 | 0 | 需要全程关注，不可并行 |
| 可并行 | 1 | 可以与其他任务同时进行 |
| 后台任务 | 2 | 可以在后台运行（如炖煮） |
