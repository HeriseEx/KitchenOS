# KitchenOS 白皮书 v1.0

> 版本：1.0
> 
> 
> **范围**：Phase 1 MVP + 清洗/Checkpoint 机制
> 
> **目标读者**：产品、技术、运营、合作方、投资方
> 

---

## 摘要（Executive Summary）

KitchenOS 是一套面向家庭与半专业厨房的**智能烹饪操作系统**。它将烹饪视为一类可建模、可调度、可优化的复杂任务，通过形式化建模、关键路径分析、资源感知调度与人类注意力建模，生成**可执行、可解释、可并行**的烹饪计划，并在执行过程中提供容错、重排与协作能力。

区别于传统菜谱或计时器类 App，KitchenOS 的核心价值在于：**把“厨房”当作一台计算机来管理**，其中灶具、锅具、案板等是资源，烹饪步骤是任务，清洗与等待是阻塞，用户是执行器。

---

## 1. 问题背景

### 1.1 传统烹饪的系统性问题

现实厨房存在三类核心瓶颈：

1. **时间碎片化**：多个菜并行时难以规划最优顺序。
2. **资源冲突**：锅、灶、案板数量有限，频繁切换导致效率下降。
3. **认知负担**：用户需要同时记忆多个计时、顺序与依赖。

现有菜谱类 App 主要提供“步骤列表 + 计时器”，并未解决上述系统性问题。

### 1.2 设计目标

KitchenOS 旨在：

- 自动生成**最优（或近似最优）**烹饪计划
- 明确展示关键路径与并行机会
- 以用户**真实厨房装备**作为一级输入
- 明确建模**清洗与等待**带来的阻塞
- 在执行阶段提供实时容错与重排

---

## 2. 产品愿景

KitchenOS 希望成为：

> 家庭厨房的“操作系统”
> 

核心能力包括：

- 菜谱结构化建模
- 资源感知调度
- Cleaning Checkpoint 机制
- 执行态容错与可观测性
- 可扩展 API 生态

---

## 3. 系统架构概览

KitchenOS 采用分层架构：

### 3.1 前端层（Client）

- **UI-00**：厨房配置向导
- **UI-05**：调度预览（甘特图）
- **UI-05a**：可用装备确认
- **UI-06**：烹饪执行页（含清洗交互）

### 3.2 应用层（Backend）

- 计划生成服务 `/plan/generate`
- 用户厨房配置服务 `/user/kitchen_profile`
- 资源状态服务 `/resource/reset`

### 3.3 调度引擎层

- DAG 建模
- CPM 关键路径计算
- 资源冲突消解
- Cleaning Checkpoint 插入
- 计划退化（资源不足时串行化）

### 3.4 数据层

- Recipes（菜谱）
- Steps（步骤，含 requires_cleaning_after）
- Resources（厨具能力模型）
- Kitchen Profile（用户装备）

---

## 4. 核心技术模型

### 4.1 Step 形式化定义

每个烹饪步骤建模为：

```
S = (d, deps, R, p, dirty)

```

其中：

- d：持续时间
- deps：依赖集合
- R：占用资源
- p：并行等级
- dirty：是否导致资源变脏

### 4.2 Cleaning Checkpoint

若步骤 A 与 B 连续复用同一资源，且 A.dirty = true，则自动插入 **Checkpoint**：

- 作为 DAG 中的阻塞节点
- 绑定具体资源
- 不计入烹饪倒计时，但影响执行顺序

### 4.3 时间模型（双口径）

- **Planning Time**：Checkpoint 按固定 buffer（默认 60s）计入开饭时间预估
- **Execution Time**：仅 Step 计入 Active Cooking Time，Checkpoint 仅影响 Elapsed Time

### 4.4 资源状态机

```
Free → Occupied → Dirty/Blocked → Free

```

由 `/resource/reset` 触发复位。

---

## 5. 用户体验设计

### 5.1 首次配置

用户通过 **UI-00** 输入：

- 灶具数量与火力
- 锅具类型与数量
- 案板数量
- 是否有烤箱

### 5.2 计划预览

UI-05 提供：

- 甘特图时间轴
- 关键路径高亮
- Cleaning Checkpoint 可视化（灰色条）

### 5.3 执行阶段

UI-06 支持：

- 资源状态可视化（Free/Occupied/Dirty）
- 清洗阻塞时锁定后续步骤
- “我已洗好”一键解锁
- 自动暂停/恢复倒计时

---

## 6. API 与生态

### 6.1 关键接口

- **POST /plan/generate**：生成烹饪计划（含 step + checkpoint）
- **GET/PUT /user/kitchen_profile**：管理厨房配置
- **POST /resource/reset**：清洗完成信号

### 6.2 扩展方向

- IoT 厨具接入
- 多用户协作
- 自动识别厨具
- 个性化调度策略

---

## 7. 风险与对策

| 风险 | 对策 |
| --- | --- |
| 资源建模不准确 | 能力模型可扩展、持续迭代 |
| 清洗频率过高 | 优先连续安排不致脏步骤 |
| 调度超时 | 异步队列 + 超时回退 |
| 冷启动延迟 | Cloud Run 最小实例配置 |

---

## 8. 路线图

- **Phase 1（MVP）**：核心调度 + 清洗机制 + 基础 UI
- **Phase 2**：IoT 接入 + 自动识别
- **Phase 3**：多用户协作 + 智能推荐

---

## 结语

KitchenOS 重新定义了“做饭”的数字化方式：从静态菜谱走向**动态、资源感知、可执行的烹饪操作系统**。

[KitchenOS 智能厨房管理系统 - 最佳实践实施指南 V1.0](KitchenOS%20%E6%99%BA%E8%83%BD%E5%8E%A8%E6%88%BF%E7%AE%A1%E7%90%86%E7%B3%BB%E7%BB%9F%20-%20%E6%9C%80%E4%BD%B3%E5%AE%9E%E8%B7%B5%E5%AE%9E%E6%96%BD%E6%8C%87%E5%8D%97%20V1%200%202ebb3b69ee4b80cea7a9f4360c9f104e.md)

[KitchenOS 产品需求文档 (PRD) - Phase 1 MVP_old](KitchenOS%20%E4%BA%A7%E5%93%81%E9%9C%80%E6%B1%82%E6%96%87%E6%A1%A3%20(PRD)%20-%20Phase%201%20MVP_old%202ecb3b69ee4b8040bc70d89d9030adcb.md)

[Kitchen OS](Kitchen%20OS%202ecb3b69ee4b808481c2e1b0371b43ab.md)