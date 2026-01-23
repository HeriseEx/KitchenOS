# KitchenOS 产品需求文档（PRD）-Phase 1 MVP（完善版）

> 状态：Draft（Revised）
> 
> 
> **范围**：Phase 1 MVP
> 
> **最后更新**：2026-01-18
> 

---

## 1. 产品愿景

KitchenOS 旨在为家庭与半专业厨房提供**智能烹饪计划生成与执行辅助系统**，在充分考虑**菜谱依赖、厨房装备与人类注意力**的前提下，自动生成可执行、可解释、可并行的烹饪计划，并在执行过程中支持容错与重排。

### 1.1 核心价值

- **节省时间**：通过并行调度缩短总烹饪时长
- **降低心智负担**：提供清晰的时间轴与关键路径提示
- **贴合真实厨房**：以用户真实装备作为一级输入

---

## 2. MVP 范围

**包含**：

- 菜谱建模（Steps + Dependencies）
- CPM 关键路径调度
- 资源冲突与注意力冲突消解
- Mise en Place（Prep Phase）
- 厨房装备配置（UI-00）
- 计划级可用装备确认（UI-05a）
- 基础 API：/plan/generate、/user/kitchen_profile

**不包含（Phase 2）**：

- IoT 传感器接入
- 自动识别厨具
- 多用户协作

---

## 3. 核心调度模型

### 3.1 Step 定义（修订）

```
S = (d, deps, R, p, cleaning)
where:
  d    = duration（秒）
  deps = 依赖集合
  R    = 所需资源类型
  p    = parallel_level ∈ {0,1,2}
  cleaning = requires_cleaning_after (Boolean)

```

### 3.2 求解流程（修订） 求解流程

**Phase 1：CPM 关键路径** → **Phase 2：资源/注意力冲突消解（最多 10 次迭代）Phase 2 新增逻辑：**
1.检测：若 Step A 与 Step B 连续复用同一资源，且 A.requires_cleaning_after = true。
2.插入：在 A 与 B 之间插入 Cleaning Checkpoint 节点。

- 节点类型：type = checkpoint
- 绑定资源：resource_id = A.resource_id
- 阻塞性质：B 必须等待 Checkpoint 解锁后方可开始（ES_B >= End_Checkpoint）。
时间估算规则（双口径）：
- 计划生成时（预估开饭时间）：每个 Checkpoint 按固定 buffer（默认 60s）计入总时长，用于计算 Timeline。
- 执行时（烹饪倒计时）：Checkpoint 不计入 Active Cooking Time（烹饪倒计时暂停），仅计入 Elapsed Time（总流逝时间）。

---

## 4. Mise en Place（Prep Phase）

触发条件：`is_prep_required = true` 或组件制作时长 > 180s。
输出：`prep_tasks` 与 `prep_outputs`；主流程中以“使用已备好的组件”替代原步骤。

---

## 5. 数据模型（核心）

- **recipes**：菜谱元数据
- **steps**：步骤（含 resource_id、parallel_level、**requires_cleaning_after**）
- **dependencies**：DAG 依赖
- **resources**：能力化厨具实体
- **kitchen_resources**：用户厨房资产
- **plan_available_resources**：计划级资源白名单

---

## 6. API（MVP）

### POST /plan/generate

```json
{
  "recipe_ids": ["uuid"],
  "available_resources": ["uuid"]
}

```

**Timeline 结构说明（修订）**：

- 节点类型需支持：`step`（倒计时任务）与 **`checkpoint`（非时间敏感阻塞任务）**。
json
{
"recipe_ids": ["uuid"],
"available_resources": ["uuid"]
}

```
关键返回字段：`plan_id`、`status`、`degradation_reason?`

### GET /user/kitchen_profile
返回用户厨房资源列表。

### PUT /user/kitchen_profile
整量更新用户厨房配置。

### POST /resource/reset（新增）
**用途**：前端上报“用户已完成清洗”，将资源从 Dirty/Blocked → Free。
```json
{
  "resource_id": "uuid"
}

```

**Response 200**：OK

---

## 7. UI 设计（关键界面）

### **UI-00：厨房配置向导（首次引导）**

**目标**：将厨房装备作为一级输入。

1. 价值说明
2. 灶具配置（数量 + 火力）
3. 锅具配置（炒锅/炖锅/蒸锅/烤箱）
4. 案板配置

若用户跳过，采用保守默认：1 灶 + 1 炒锅 + 1 案板。

### **UI-05：调度预览**

展示：关键路径高亮、并行节省卡片、资源占用图例。
**新增视觉要求**：在甘特图/时间轴中以灰色条或“洗”图标呈现 **Cleaning Checkpoint**，明确为阻塞间隔。

### **UI-05a：可用装备确认（新增）**：可用装备确认（新增）**

在 UI-05 之前弹出：

- 列出当前 `kitchen_profile.resources`
- 用户可勾选本次可用资源
- 若关键资源被取消，显示警告：
    
    > “资源不足可能导致计划串行化”
    > 

### **UI-06：烹饪执行页（新增）**

- 资源状态可视化：Free / Occupied / **Dirty/Blocked**
- 若资源处于 Dirty/Blocked：
    - 关联步骤卡片变灰并锁定
    - 显示文案：“请先清洗该资源”
    - 提供按钮：**“我已洗好”**（触发 `/resource/reset`）

---

## 8. 测试计划（MVP）

- **TC1**：BOM 合并（300g + 200g → 500g）
- **TC2**：循环依赖 → 返回 400 + 环路径
- **TC3**：资源冲突 → 自动串行化
- **TC4**：能力降级使用 → 产生 Warning
- **TC5（新增）**：资源复用阻塞与解锁
    - 场景：A.requires_cleaning_after = true → 插入 Checkpoint → B 被阻塞
    - 预期：用户未点击“我已洗好”前，B 不开始倒计时；调用 `/resource/reset` 后恢复。

---

## **9. 厨房装备配置（NEW）**

### 9.0 Resource Taxonomy（形式化）

```
resource_type ∈ {stove, wok, stew_pot, steamer, cutting_board, oven}

```

**能力维度**：

- stove：`heat_level ∈ {high, medium, low}`
- wok/stew_pot/steamer：`capacity_liters`
- cutting_board：`is_meat_safe`
- oven：`max_temp_celsius`

**匹配规则**：

1. 优先精确匹配类型与能力；
2. 若仅存在能力降级匹配，允许使用但产生 Warning；
3. 若无匹配，返回 `RESOURCE_INSUFFICIENT` 并串行化。

### 9.1 设计定位

- `kitchen_profile` 为调度引擎**一级输入**。
- 可跳过但系统采用保守默认资源池。

### 9.2 默认资源池（若跳过）

```json
{
  "resources": [
    {"id": "stove_1", "type": "stove", "heat_level": "high"},
    {"id": "pan_1", "type": "wok"},
    {"id": "cutting_board_1", "type": "cutting_board"}
  ]
}

```

### 9.3 用户可配置项（首次引导）

- 灶具：数量 + 火力
- 锅具：炒锅/炖锅/蒸锅 数量
- 案板：数量
- 烤箱：有/无

### 9.4 Plan-level Override

扩展 `/plan/generate`：

```json
{
  "recipe_ids": ["r1", "r2"],
  "available_resources": ["stove_1", "pan_1"]
}

```

### 9.5 对调度引擎的影响

- 有效资源池 = `kitchen_profile.resources ∩ available_resources`
- 若不足 → 自动串行化并返回 `degradation_reason: insufficient_resources`。

---

## 10. 路线图（MVP）

- **Sprint 1–2**：DB + 调度引擎 + API
- **Sprint 3**：Flutter 首页 + 甘特图
- **Sprint 4**：联调 + Cloud Run 部署
- **Sprint 5**：容错重排 + 可观测性