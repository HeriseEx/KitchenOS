# 已知问题 (Known Issues)

## Android Chrome 语音识别无法启动 (Web Speech API)

**状态**: 🔴 挂起 / 疑难杂症 (Pending / Won't Fix for now)
**受影响平台**: Android (Chrome, Edge 等基于 Chromium 的浏览器)
**特定设备**: 小米/Redmi (HyperOS/MIUI) 及其他国产 Android 定制系统

### 问题描述
在 Android Chrome 浏览器中，尝试启动语音识别 (`SpeechRecognition.start()`) 时，即使用户已经明确授予了网站麦克风权限，并且 HTTPS 环境配置正确，API 依然立即抛出 `not-allowed` 错误。

- **错误信息**: `Raw error: not-allowed`
- **Safari (iOS)**: ✅ 正常工作
- **Desktop Chrome**: ✅ 正常工作

### 排查过程记录
我们已经尝试了以下修复方案，但问题依旧存在：
1.  **HTTPS 强制跳转**: 确认部署在 HTTPS 环境下，并配置了 HSTS。
2.  **权限查询 API**: 使用 `navigator.permissions.query({name: 'microphone'})` 查询，显示状态为 `granted` 或 `prompt`，但在调用 `start()` 时依然失败。
3.  **系统级权限**:
    - 确认 Android 系统设置中，**浏览器应用 (Chrome)** 拥有麦克风权限。
    - 确认 Android 系统设置中，**Google App (Google)** 拥有麦克风权限（Android Web Speech API 依赖 Google App 提供服务）。
    - 确认 HyperOS/MIUI 的“显示在其他应用上层”权限。
4.  **交互策略**:
    - 禁用了移动端的 `continuous` 模式。
    - 确保 `start()` 调用是由用户点击事件直接触发的（User Gesture Policy）。
    - 尝试了 `getUserMedia` 预热（后取消，因可能导致资源占用冲突）。

### 推测原因
该问题被标记为“疑难杂症”，可能由以下深层原因导致：

1.  **Google 服务阉割/限制**: 国内行货手机（如小米 HyperOS）虽然内置了 Google 框架，但 Google App 的语音识别服务可能被系统层级限制，或者无法连接 Google 服务器进行在线识别，导致立即失败。
2.  **音频焦点冲突 (Audio Focus)**: Android 系统可能认为浏览器未获得音频焦点，或者被其他后台进程（如语音唤醒助手）占用。
3.  **权限策略头 (Permissions-Policy)**: 即使 HTTPS 正常，某些新版 Android Chrome 可能严格要求服务器响应头包含 `Permissions-Policy: microphone=(self)`。
4.  **Web Speech API 实现碎片化**: Android WebView 或 Chrome 的实现极度依赖底层 Google 语音服务，该服务在国内网络环境或特定 ROM 下极其不稳定。

### 建议替代方案 (未来考虑)
如果未来需要彻底解决此问题，建议放弃浏览器原生的 `Web Speech API`，改用以下方案：
1.  **Audio Worklet + WebSocket**: 使用 `getUserMedia` 录制原始音频流，通过 WebSocket 发送到后端（如 OpenAI Whisper, Google Cloud Speech-to-Text, 阿里云等）进行实时识别。这是目前兼容性最好的方案。
2.  **WASM 离线识别**: 集成 Whisper.cpp 的 WASM 版本到前端，实现纯离线识别（文件体积较大，加载慢）。

---
*记录时间: 2026-01-24*
