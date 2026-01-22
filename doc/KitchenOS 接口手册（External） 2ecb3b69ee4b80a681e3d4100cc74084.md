# KitchenOS 接口手册（External）

---

## 1. POST /plan/generate

**用途**：根据菜谱与可用装备生成烹饪计划。

### Request

```json
{
  "recipe_ids": ["uuid"],
  "available_resources": ["uuid"]
}

```

### Response 200

```json
{
  "plan_id": "uuid",
  "status": "done",
  "degradation_reason": null,
  "metrics": {
    "total_duration_seconds": 1800,
    "active_cooking_seconds": 1600,
    "cleaning_buffer_seconds": 200
  },
  "timeline": [
    {
      "id": "uuid_step_1",
      "type": "step",
      "resource_id": "res_wok_1",
      "action": "滑炒鸡蛋",  // 新增：用于 UI 展示
      "description": "大火快炒至凝固即可盛出", // 新增：简要指导
      "parallel_level": 0, // 新增：0=专注, 1=并行, 2=后台
      "duration_seconds": 120, // 计划耗时
      "start_at": "2026-01-18T10:00:00Z",
      "end_at": "2026-01-18T10:02:00Z"
    },
    {
      "id": "uuid_chk_1",
      "type": "checkpoint",
      "resource_id": "res_wok_1",
      "action": "清洗炒锅", // 新增：前端直接显示这个标题
      "description": "前序步骤导致锅具变脏，需清洗后复用",
      "reason": "requires_cleaning_after",
      "duration_seconds": 60, // 新增：预估的 Buffer 时间，用于画甘特图宽度
      "start_at": "2026-01-18T10:02:00Z", // 紧接上一步结束
      "end_at": "2026-01-18T10:03:00Z"   // 下一步以此为开始
    },
    {
      "id": "uuid_step_2",
      "type": "step",
      "resource_id": "res_wok_1",
      "action": "爆炒肉丝",
      "start_at": "2026-01-18T10:03:00Z", // 紧接 Checkpoint 结束
      "end_at": "..."
      // ...
    }
  ]
}

```

**Timeline 节点类型**：

- `step`：普通倒计时任务
- `checkpoint`：非时间敏感的阻塞任务，仅用于阻断与可视化

### Response 409

```json
{
  "code": "RESOURCE_INSUFFICIENT",
  "message": "资源不足，计划已退化为串行执行"
}

```

---

## 2. GET /user/kitchen_profile

**用途**：获取用户厨房配置。

```json
{
  "user_id": "uuid",
  "resources": [
    {
      "id": "uuid",
      "type": "wok",
      "heat_level": "high",
      "capacity_liters": 3.0,
      "max_temp_celsius": null,
      "is_meat_safe": true,
      "state": "Free | Occupied | Dirty"
    }
  ]
}

```

---

## 3. PUT /user/kitchen_profile

**用途**：整量更新用户厨房配置。

```json
{
  "resources": ["uuid"]
}

```

**Response 200**：OK

---

## 4. POST /resource/reset（新增）

**用途**：前端上报“用户已完成清洗”，将资源从 Dirty/Blocked → Free。

```json
{
  "resource_id": "uuid"
}

```

**Response 200**：OK