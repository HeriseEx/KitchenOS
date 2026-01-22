# KitchenOS 智能厨房管理系统 - 最佳实践实施指南 V2（清洗机制修订）

> 范围：Phase 1 MVP + 清洗/Checkpoint 机制
> 

---

## 1. 目标

指导调度引擎、前端执行页与可观测性实现，使“资源复用 + 清洗阻塞”在算法、UI 与计时逻辑上保持一致。

---

## 2. 核心调度引擎（修订）

### 2.1 资源状态机（新增）

推荐实现为显式状态机：

```
Free → Occupied → Dirty/Blocked → Free

```

- **Free**：可被调度使用
- **Occupied**：当前有 Step 正在占用
- **Dirty/Blocked**：上一个 Step `requires_cleaning_after = true`，必须清洗后才能复用

**状态转换规则**：

1. Step 开始 → 相关资源从 Free → Occupied
2. Step 结束：
    - 若 `requires_cleaning_after = false` → Occupied → Free
    - 若 `requires_cleaning_after = true` → Occupied → **Dirty/Blocked**
3. 用户调用 `/resource/reset` → Dirty/Blocked → Free

### 2.2 Cleaning Checkpoint 插入规则

在同一资源的连续复用 A → B 场景下：

- 若 A.requires_cleaning_after = true，则必须在 A 与 B 之间插入 **Checkpoint** 节点。
- Checkpoint：
    - 不分配真实烹饪时间
    - 作为 DAG 中的**阻塞依赖节点**
    - 绑定单一 resource_id

### 2.3 时间模型（双口径）

- **计划态（Planning Time）**：
    - 每个 Checkpoint 计入固定 buffer（默认 60s），用于预估“开饭时间”。
- **执行态（Execution Time）**：
    - **Active Cooking Time**：仅累加 `type = step` 的持续时间。
    - **Elapsed Time**：包含 Active Cooking Time + 用户清洗等待 + 其他停顿。
    - Checkpoint **不增加** Active Cooking Time，但会拉长 Elapsed Time。

---

## 3. 调度可解释性

在返回的 Timeline 中：

- 明确区分 `step` 与 `checkpoint`
- 每个 Checkpoint 建议携带 `reason = "requires_cleaning_after"`
- 建议提供资源占用视图，帮助用户理解“为何被阻塞”。

---

## 4. 前端执行页落地（UI-06）

### 4.1 状态可视化

- 资源状态三色区分：
    - Free（可用）
    - Occupied（进行中）
    - **Dirty/Blocked（待清洗）**

### 4.2 阻塞交互

当资源进入 Dirty/Blocked：

- 相关步骤卡片变灰并锁定
- 显示文案：“请先清洗该资源”
- 提供按钮 **“我已洗好”** → 调用 `/resource/reset`

### 4.3 计时器行为（容错说明）

- 进入 Dirty/Blocked 时：
    - **暂停 Active Cooking Timer**
    - 继续累计 **Elapsed Time**
- 用户点击“我已洗好”后：
    - 资源状态 → Free
    - 恢复 Active Cooking Timer
    - 后续 Step 可继续倒计时

---

## 5. 可观测性与监控

建议采集：

- Checkpoint 插入次数/计划
- 用户清洗等待时长分布
- 每个资源的 Dirty/Blocked 频率
- 实际 Elapsed Time vs 预估 Planning Time 的偏差

---

## 6. 调度优化建议（降低清洗频率）

在可行范围内：

- 优先将 **不致脏（requires_cleaning_after = false）** 的步骤连续安排。
- 若存在多种可替代资源，优先选择“当前更干净”的资源。
- 对于高频致脏操作（如切生肉），尽量集中执行，减少切换次数。