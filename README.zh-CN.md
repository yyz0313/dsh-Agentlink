# dsh-Agentlink（ZCode 适配版）

![dsh-Agentlink cover](assets/dsh-agentlink-cover.webp)

[![CI](https://github.com/hootandy321/dsh-Agentlink/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/hootandy321/dsh-Agentlink/actions/workflows/ci.yml) [![GitHub Stars](https://img.shields.io/github/stars/hootandy321/dsh-Agentlink?style=flat-square&logo=github)](https://github.com/hootandy321/dsh-Agentlink/stargazers) [![License: MIT](https://img.shields.io/github/license/hootandy321/dsh-Agentlink?style=flat-square)](LICENSE) [![Node.js 22+](https://img.shields.io/badge/Node.js-22%2B-339933?style=flat-square&logo=nodedotjs&logoColor=white)](https://nodejs.org/) [![DSH plugin](https://img.shields.io/badge/DSH-plugin-4B6BFB?style=flat-square)](https://www.deepseek.com/harness/en/)

**English** | **简体中文**

> **⚠️ 重要声明：本仓库是 [hootandy321/dsh-Agentlink](https://github.com/hootandy321/dsh-Agentlink) 的二次开发版本。**
> 原项目面向 Codex，本仓库在保留全部原有功能的基础上，额外适配了 **ZCode** 插件体系，使其可以在 ZCode 环境中无缝使用。
>
> 本仓库的 `main` 分支始终与上游保持同步。当原作者更新时，会通过 GitHub Action 自动合并。

dsh-Agentlink 是一个 **connect-only 模式的 MCP 桥接器**。它让 AI 编程工具（如 ZCode）可以将编码任务委托给本地运行的 **DeepSeek Harness (DSH) Web Host**，然后在调用方中保持监督、追问、审批和取消。

## 与原版的关系

| 项目 | 链接 | 说明 |
|------|------|------|
| 原版（面向 Codex） | https://github.com/hootandy321/dsh-Agentlink | 官方原版，维护最新功能 |
| **本仓库（ZCode 适配）** | https://github.com/yyz0313/dsh-Agentlink | 本仓库，含 ZCode 插件 + 自动同步 |

两条分支并行维护，功能完全兼容。本仓库的提交只涉及 ZCode 适配和功能性增强（如 `sessionId` 参数），不会修改上游原有逻辑。

## 新增内容（与原版相比）

| 路径 | 说明 |
|------|------|
| `.zcode-plugin/plugin.json` | ZCode 插件 manifest，含 MCP 服务器配置、用户可配置的 DSH Host URL 和 agent preset |
| `skills/dsh-collab/SKILL.md` | ZCode 专用协作技能，包含完整的工具调用指南、工作流和安全规则 |
| `scripts/install.ps1` | ZCode 一键安装脚本，自动检测环境并写入 ZCode 配置 |
| `.github/workflows/sync-upstream.yml` | 自动同步上游更新的工作流，每 6 小时检查一次 |
| `src/bridge-service.ts` | 新增 `sessionId` 参数支持复用已有会话（见下方功能说明） |

## 自动同步机制

本仓库配置了 GitHub Action：
- **每 6 小时**自动检查上游 `hootandy321/dsh-Agentlink` 是否有新提交
- 有新更新时**自动合并**到本仓库 `main` 分支
- 合并冲突时会在 Actions 日志中告警，需手动解决
- 我们的 ZCode 适配文件（`.zcode-plugin/`、`skills/`、`scripts/`）始终保留，不受上游影响

手动同步命令：
```bash
git fetch upstream main
git merge upstream/main --no-edit
npm run build
```

## 功能特性

- **连接即走，不启动/不守护 DSH** — 你负责运行 DSH Web Host，bridge 只负责通信
- **会话持久化** — DSH session 在 bridge 退出后仍可在 DSH Web UI 中查看和继续
- **沙箱隔离** — DSH Code Mode 提供完整的文件系统沙箱，bridge 不会绕过
- **人工审批** — 每次写入操作都需要你通过 `dsh_resolve_approval` 手动放行
- **多轮协作** — 可以用 `dsh_followup` 追加任务，用 `dsh_cancel` 精准取消
- **会话复用** — `dsh_delegate` 支持传入 `sessionId`，复用已有 DSH 会话（二开新增功能）

## 安装步骤

### 前置条件

- Node.js 22+
- ZCode CLI（最新版）
- DSH Web Host（在后台运行，默认端口 3080）

### 方式一：自动安装（推荐）

在项目目录运行安装脚本：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

脚本会自动检测 Node.js、DSH Host、编译 bridge，然后写入 ZCode 配置。

### 方式二：手动安装

```powershell
# 1. 确保 DSH Web Host 在运行
#    另开终端： dsh web --profile web --port 3080

# 2. 安装依赖并编译
npm install
npm run build

# 3. 将以下内容添加到 ZCode 配置文件
#    路径：~/.zcode/cli/config.json
#    或双击运行 scripts/install.ps1
```

### ZCode 配置

在 `~/.zcode/cli/config.json` 中添加：

```json
{
  "mcp": {
    "servers": {
      "dsh_agentlink": {
        "command": "C:\\Users\\你\\.workbuddy\\binaries\\node\\versions\\22.22.2\\node.exe",
        "args": ["C:\\Users\\你\\.zcode\\workspace\\default\\dsh-Agentlink\\dist\\index.js"],
        "cwd": "${ZCODE_PROJECT_DIR}",
        "env": {
          "DSH_HOST_URL": "http://127.0.0.1:3080",
          "DSH_BRIDGE_AGENT_PRESET": "code"
        }
      }
    }
  }
}
```

### 验证安装

```powershell
# 检查 bridge 连接状态
node dist/doctor.js

# 应输出：{"ok": true, "compatibility": "compatible-untested", ...}
```

## 使用方式

在 ZCode 中，MCP 工具会以 `mcp__dsh_agentlink__<工具名>` 的形式暴露。常用流程：

### 1. 检查 Host 状态

```
mcp__dsh_agentlink__dsh_host_status
```

### 2. 委托编码任务

```
mcp__dsh_agentlink__dsh_delegate
参数：
  prompt: "实现一个用户登录模块，包含 JWT 验证"
  cwd: "/path/to/your/project"
  workspaceMode: "exclusive-write"  # 或 "read-only"
  sessionId: "可选 - 复用已有会话 ID"
```

返回 `taskId` 和 `rootSessionId`，记录下来。

### 3. 等待并查看进度

```
mcp__dsh_agentlink__dsh_wait  # 最多等 30 秒
mcp__dsh_agentlink__dsh_tail  # 查看最新进展（带 cursor）
```

### 4. 追问或指导

```
mcp__dsh_agentlink__dsh_followup
参数：
  taskId: "xxx"
  mode: "queue"        # 当前 turn 结束后追加任务
  # 或
  mode: "steer"        # 注入当前 turn 的下一步指导
  content: "注意处理边界情况"
```

### 5. 回答提问 / 审批写入

当 DSH 需要审批时，从 `dsh_status` 或 `dsh_tail` 中获取 `pendingInteractions`：

```
mcp__dsh_agentlink__dsh_answer_question
参数：taskId, requestId, answers

mcp__dsh_agentlink__dsh_resolve_approval
参数：taskId, requestId, outcome: "allow_once" | "reject"
```

**⚠️ 安全规则：bridge 永远不会自动允许审批，必须由你手动确认。**

### 6. 取消 / 释放工作区

```
mcp__dsh_agentlink__dsh_cancel(scope="turn")    # 只取消当前 turn，保留队列
mcp__dsh_agentlink__dsh_cancel(scope="queue")   # 取消整个队列
mcp__dsh_agentlink__dsh_release_workspace       # 释放工作区锁（不关闭 DSH session）
```

## DSH 技能文件

本仓库提供 ZCode 专用技能，包含完整的使用指南：

```
skills/dsh-collab/SKILL.md    # ZCode 协作技能（工具名、工作流、安全规则）
```

在 ZCode 中使用 `/dsh-collab` 即可加载该技能。

## 已知限制

- **不自动启动 DSH Host** — 你需要自己运行 `dsh web`
- **Host 重启会丢失状态** — active turn、pending interaction、queue 都会丢失
- **不支持 exactly-once** — delivery 是 at-least-once + 确定性去重
- **仅 connect-only** — bridge 不管理 Host 进程生命周期
- **审批永不自动放行** — 这是安全设计，不是 bug

## 许可证

本项目基于 [MIT 许可证](LICENSE) 开源，与上游保持一致。

Alpha 说明：DSH 仍处于 developer preview，本项目是独立社区项目，不代表 DeepSeek 或 OpenAI 官方背书。升级或并发运行 bridge 前请阅读[已知问题](KNOWN_ISSUES.md)。
