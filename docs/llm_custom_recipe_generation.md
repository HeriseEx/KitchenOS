# KitchenOS LLM 自定义菜谱生成指南

本文档定义了 LLM (Large Language Model) 通过 Function Call 生成自定义菜谱的 JSON 规范。此规范专为 LLM 生成优化，使用索引引用依赖关系，简化了 ID 生成过程。

## 核心 Function 定义

### Function: `create_recipe`

**描述**: 创建一个新的自定义菜谱，包含详细的食材和烹饪步骤调度信息。

### JSON Schema

```json
{
  "name": "create_recipe",
  "description": "创建一个新的自定义菜谱，包含详细的食材和烹饪步骤调度信息。",
  "parameters": {
    "type": "object",
    "properties": {
      "name": {
        "type": "string",
        "description": "菜品名称，如：番茄炒蛋"
      },
      "description": {
        "type": "string",
        "description": "菜品的简短介绍或风味描述"
      },
      "servings": {
        "type": "integer",
        "description": "适用人数/份量",
        "default": 2
      },
      "estimated_minutes": {
        "type": "integer",
        "description": "预计总耗时（分钟）"
      },
      "difficulty": {
        "type": "string",
        "description": "难度等级",
        "enum": ["easy", "medium", "hard"]
      },
      "tags": {
        "type": "array",
        "description": "菜品标签，如：中餐, 快手菜, 辣",
        "items": {
          "type": "string"
        }
      },
      "ingredients": {
        "type": "array",
        "description": "所需食材清单",
        "items": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string",
              "description": "食材名称，如：鸡蛋"
            },
            "quantity": {
              "type": "number",
              "description": "数量"
            },
            "unit": {
              "type": "string",
              "description": "单位，如：个, g, ml, 勺"
            },
            "is_prep_required": {
              "type": "boolean",
              "description": "是否需要预处理（洗/切等）",
              "default": false
            }
          },
          "required": ["name", "quantity", "unit"]
        }
      },
      "steps": {
        "type": "array",
        "description": "烹饪步骤列表，支持并行与依赖关系",
        "items": {
          "type": "object",
          "properties": {
            "action": {
              "type": "string",
              "description": "步骤简述（动词开头），如：打散鸡蛋"
            },
            "description": {
              "type": "string",
              "description": "详细操作说明，如：将鸡蛋打入碗中，加少许盐搅拌均匀"
            },
            "duration_seconds": {
              "type": "integer",
              "description": "预计耗时（秒）"
            },
            "resource_type": {
              "type": "string",
              "description": "所需厨房资源类型",
              "enum": [
                "stove",        // 灶具
                "wok",          // 炒锅
                "stewPot",      // 炖锅
                "steamer",      // 蒸锅
                "cuttingBoard", // 案板
                "oven"          // 烤箱
              ]
            },
            "parallel_level": {
              "type": "integer",
              "description": "并行能力等级：0=需专注(切菜/翻炒), 1=可并行(煮水/预热), 2=后台(炖煮/烤制)",
              "enum": [0, 1, 2],
              "default": 0
            },
            "is_prep_required": {
              "type": "boolean",
              "description": "是否属于备菜阶段",
              "default": false
            },
            "requires_cleaning_after": {
              "type": "boolean",
              "description": "步骤结束后是否必须清洗设备才能进行下一步",
              "default": false
            },
            "dependency_indices": {
              "type": "array",
              "description": "依赖的前置步骤索引列表（对应 steps 数组的下标），用于构建执行DAG图",
              "items": {
                "type": "integer"
              }
            }
          },
          "required": ["action", "duration_seconds"]
        }
      }
    },
    "required": ["name", "estimated_minutes", "ingredients", "steps"]
  }
}
```

## 关键字段详解

### 1. `steps` (步骤与调度核心)
这是 KitchenOS 的核心，用于生成并行的烹饪时间轴。

*   **`parallel_level` (并行等级)**:
    *   `0 (Focused)`: **需专注**。人手必须被占用，无法同时做其他事（如：切肉、爆炒）。
    *   `1 (Parallel)`: **可并行**。需要人偶尔照看，但可以插空做别的事（如：等待水开、小火慢煎）。
    *   `2 (Background)`: **后台任务**。完全不需要人手，只需定时器（如：烤箱烤制、炖锅慢炖30分钟）。
*   **`dependency_indices` (依赖索引)**:
    *   通过引用数组下标来定义顺序。
    *   例如：步骤3是“炒鸡蛋”，步骤1是“打蛋”，步骤2是“切葱花”。步骤3的依赖就是 `[1, 2]`（即依赖步骤1和步骤2完成后才能开始）。

### 2. `resource_type` (资源类型)
对应代码中的 `ResourceType` 枚举，用于资源分配检查。

| 值 | 说明 |
|---|---|
| `stove` | 灶头（火源） |
| `wok` | 炒锅 |
| `stewPot` | 炖锅 |
| `steamer` | 蒸锅 |
| `cuttingBoard` | 案板 |
| `oven` | 烤箱 |

## 示例数据 (JSON)

以下是一个“西红柿炒鸡蛋”的生成示例：

```json
{
  "name": "西红柿炒鸡蛋",
  "description": "国民经典家常菜，酸甜可口",
  "servings": 2,
  "estimated_minutes": 10,
  "difficulty": "easy",
  "tags": ["家常菜", "快手"],
  "ingredients": [
    { "name": "鸡蛋", "quantity": 3, "unit": "个", "is_prep_required": true },
    { "name": "西红柿", "quantity": 2, "unit": "个", "is_prep_required": true },
    { "name": "葱", "quantity": 1, "unit": "根", "is_prep_required": true }
  ],
  "steps": [
    {
      "action": "洗切西红柿",
      "description": "西红柿洗净切块",
      "duration_seconds": 60,
      "resource_type": "cuttingBoard",
      "parallel_level": 0,
      "is_prep_required": true,
      "dependency_indices": []
    },
    {
      "action": "打鸡蛋",
      "description": "鸡蛋打入碗中搅散",
      "duration_seconds": 60,
      "resource_type": "cuttingBoard",
      "parallel_level": 0,
      "is_prep_required": true,
      "dependency_indices": []
    },
    {
      "action": "炒鸡蛋",
      "description": "热锅凉油，倒入蛋液滑熟盛出",
      "duration_seconds": 120,
      "resource_type": "wok",
      "parallel_level": 0,
      "dependency_indices": [1],
      "requires_cleaning_after": false
    },
    {
      "action": "炒西红柿",
      "description": "锅中留底油，放入西红柿炒出汁",
      "duration_seconds": 180,
      "resource_type": "wok",
      "parallel_level": 0,
      "dependency_indices": [0, 2]
    },
    {
      "action": "混合调味",
      "description": "倒入鸡蛋，加盐糖调味，撒葱花出锅",
      "duration_seconds": 60,
      "resource_type": "wok",
      "parallel_level": 0,
      "dependency_indices": [3]
    }
  ]
}
```
