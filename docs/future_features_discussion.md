# Future Features Discussion / 未来功能讨论

## 1. Persistent Cooking Sessions & Long-Duration Tasks / 持久化烹饪会话与长时间任务

### Feature Description / 功能描述
Implementation of a robust resume functionality for cooking sessions. This feature ensures that users can return to their current step after app interruptions, device restarts, or during long-duration processes (e.g., slow cooking, marinating, or fermentation).
为烹饪会话实现稳健的恢复功能。该功能确保用户在应用中断、设备重启或执行长时间过程（如慢炖、腌制或发酵）后能够返回当前的步骤。

### Technical Implementation / 技术实现
- **Local Storage Logic / 本地存储逻辑**: State persistence using a local database (SQLite/Hive) or encrypted preferences to store current recipe ID, step index, elapsed timer values, and user modifications.
  使用本地数据库（SQLite/Hive）或加密首选项进行状态持久化，以存储当前食谱 ID、步骤索引、已过计时器值和用户修改。
- **Timestamp Diffing / 时间戳差异计算**: On app resume, calculate the time elapsed since the last recorded activity. Automatically adjust timers or notify users if a critical time window has passed.
  在应用恢复时，计算自上次记录活动以来经过的时间。如果超过了关键时间窗口，自动调整计时器或通知用户。
- **Background Notifications / 后台通知**: Integration with system-level alarm managers and push notifications to alert users of step completions or required actions even when the app is in the background.
  与系统级闹钟管理器和推送通知集成，即使应用在后台运行，也能提醒用户步骤完成或需要采取的操作。

### Edge Cases / 边缘情况
- **Multiple Concurrent Recipes / 多个并发食谱**: How to handle UI state when a user is managing two or more active sessions? Requires a "Session Switcher" or dashboard view.
  当用户管理两个或多个活动会话时，如何处理 UI 状态？需要“会话切换器”或仪表板视图。
- **Battery Optimization / 电池优化**: Aggressive OS background process killing (especially on Android) might disrupt timers. Need to investigate foreground services or high-priority alarms.
  激进的操作系统后台进程杀除（特别是 Android）可能会干扰计时器。需要研究前台服务或高优先级闹钟。

---

## 2. Multimedia Step Instruction (Images/Video) / 多媒体步骤说明 (图片/视频)

### Problem Statement / 问题描述
Users frequently request visual aids (images or video) to clarify complex cooking techniques (e.g., "folding in egg whites" or "deboning a chicken"). Text-only instructions can be ambiguous for beginners.
用户经常请求视觉辅助工具（图片或视频）来澄清复杂的烹饪技巧（例如，“拌入蛋白”或“去除鸡骨”）。对于初学者来说，纯文本说明可能含糊不清。

### Constraints / 限制条件
- **Server Costs & Bandwidth / 服务器成本与带宽**: Hosting high-resolution video is expensive. 托管高分辨率视频非常昂贵。
- **Copyright / 版权**: Ensuring all visual content is legally sourced or produced. 确保所有视觉内容均来源于合法渠道或自行制作。
- **Content Production / 内容制作**: High effort required to produce consistent, high-quality video for every recipe step. 为每个食谱步骤制作一致且高质量的视频需要投入大量精力。

### Proposed Solutions / 建议方案

#### A. External Embedding (YouTube/Bilibili) / 外部嵌入 (YouTube/Bilibili)
- **Pros / 优点**: Zero hosting costs, utilizes existing high-quality content. 零托管成本，利用现有的高质量内容。
- **Cons / 缺点**: Subject to third-party ad policies, potential for dead links, lacks a unified UI feel. 受第三方广告政策限制，可能存在死链，缺乏统一的 UI 体验。

#### B. AI Generation / AI 生成
- **Pros / 优点**: Low cost for custom visuals, can generate specific angles or steps on-demand. 定制视觉内容的成本低，可以按需生成特定角度或步骤。
- **Cons / 缺点**: Current AI video/image quality may lack the precision needed for technical cooking steps. 目前 AI 视频/图片质量可能缺乏技术性烹饪步骤所需的精确度。

#### C. Community Uploads / 社区上传
- **Pros / 优点**: Highly scalable, builds user engagement. 高度可扩展，建立用户参与度。
- **Cons / 缺点**: Requires heavy moderation for quality and safety; inconsistent quality. 需要进行严格的质量和安全审核；质量参差不齐。

#### D. Lightweight GIFs / 轻量级 GIF
- **Pros / 优点**: Better than video for bandwidth, loops specific actions clearly, widely compatible. 带宽占用比视频小，能清晰地循环特定动作，兼容性广。
- **Cons / 缺点**: No audio, quality degrades if compressed too much. 无音频，如果压缩过度，质量会下降。

---
*Note: This document is intended for internal product team discussion. / 注意：此文档仅供内部产品团队讨论。*
