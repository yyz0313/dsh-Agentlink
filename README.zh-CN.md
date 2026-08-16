# dsh-Agentlink（ZCode 适配版）

![dsh-Agentlink cover](assets/dsh-agentlink-cover.webp)

[![CI](https://github.com/hootandy321/dsh-Agentlink/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/hootandy321/dsh-Agentlink/actions/workflows/ci.yml) [![GitHub Stars](https://img.shields.io/github/stars/hootandy321/dsh-Agentlink?style=flat-square&logo=github)](https://github.com/hootandy321/dsh-Agentlink/stargazers) [![License: MIT](https://img.shields.io/github/license/hootandy321/dsh-Agentlink?style=flat-square)](LICENSE) [![Node.js 22+](https://img.shields.io/badge/Node.js-22%2B-339933?style=flat-square&logo=nodedotjs&logoColor=white)](https://nodejs.org/) [![DSH plugin](https://img.shields.io/badge/DSH-plugin-4B6BFB?style=flat-square)](https://www.deepseek.com/harness/en/)

**English** | **简体中文**

> **⚠️ 重要声明：本仓库是 [hootandy321/dsh-Agentlink](https://github.com/hootandy321/dsh-Agentlink) 的二次开发版本。**
> 原项目面向 Codex，本仓库在保留全部原有功能的基础上，额外适配了 **ZCode** 插件体系，使其可以在 ZCode 环境中无缝使用。
>
> 本仓库的 `main` 分支始终与上游保持同步。当原作者更新时，会通过 GitHub Action 自动合并。
>
> 如果你是 Codex 用户，请直接前往 [原作者仓库](https://github.com/hootandy321/dsh-Agentlink)。

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

---

## 下面是原项目的完整文档（面向所有调用方通用）

> 原项目文档由 [hootandy321](https://github.com/hootandy321/dsh-Agentlink) 编写，此处完整保留。ZCode 用户在完成上方安装后，以下内容同样适用。

dsh-Agentlink 是一个让你直接在原本的 AI 工作工具里调用 DeepSeek Harness（DSH）协作的插件。你的主 agent 可以把实现、调研、调试和长日志整理等任务交给 DSH，再在原有工作流中观察、继续或取消对应会话。

## 安装（Codex 用户）

> Codex 用户请直接访问 [原作者仓库](https://github.com/hootandy321/dsh-Agentlink) 获取最新版安装指南。

安装前先准备环境：只需要 **Node.js 22+** 和可以正常运行的 **DSH CLI**。先在 DSH 中配置一次你希望使用的模型，之后 dsh-Agentlink 会自动使用当前路由。

### 手动安装

1. 检查环境。当前经过测试的 DSH CLI 目标是 `0.1.0-rc.6`。

   ```bash
   node --version
   dsh --version
   ```

2. 在独立终端启动官方 DSH Web Host。

   ```bash
   dsh web
   ```

3. 克隆仓库、安装依赖并运行配置向导。

   ```bash
   git clone https://github.com/hootandy321/dsh-Agentlink.git
   cd dsh-Agentlink
   npm install
   npm run setup
   ```

   向导只会询问 Host 地址和 DSH agent preset，随后备份 Codex 配置，并以 `approval_mode = "prompt"` 安装 MCP 入口。它不会启动 DSH，也不会替你重启 Codex。

   无交互使用默认值时运行 `npm run setup -- --yes`。需要更新已有配置时，请先检查原配置，再运行 `npm run setup -- --replace`。配置工具会识别旧版 `dsh_collab`，并且只在得到这次明确的替换授权后迁移为 `dsh_agentlink`。

4. 重启 Codex，然后验证连接。

   ```bash
   npm run doctor
   ```

通过 `/mcp` 或 Codex 设置确认 `dsh_agentlink` 已连接。doctor 还会以只读方式报告 `DSH_BRIDGE_HOME` 下的 fail-closed 锁位置，且从不清理它们，因此即使存在锁也能安全运行。需要完全手动编辑 TOML 或查看全部环境变量时，请阅读[手动 Codex MCP 配置](docs/manual-configuration.zh-CN.md)。

当前源码补丁会阻止新的 projection/chunk 洪峰继续扩大 coordination ledger，但不会自动压缩已有的 5 MB 以上 ledger。请保留旧 bridge home 备查；新的委派可以选择独立的 `DSH_BRIDGE_HOME`。对话真源始终是 DSH `session.history`，不是 bridge ledger。保守恢复边界见[已知问题](KNOWN_ISSUES.md)。

dsh-Agentlink 是安装在调用方一侧的插件，不是 DSH Cordis bundle；请不要使用 `dsh plugin --profile ... add ...` 安装。

## 为什么需要 dsh-Agentlink？

### 利用 DSH 的 Harness 能力

DSH 为复杂任务提供持久 session、工具调用、subagent 和人工监督等能力。dsh-Agentlink 让调用方能够与这套独立 harness 讨论并协作，同时不离开你原本的工作入口。

![Codex 与 DeepSeek Harness 协作](assets/codex-dsh-collaboration.webp)

*主 agent 继续负责规划、讨论和总控，DSH 负责执行 harness、会话与 worker。*

### 不只是再增加一个原生 subagent

原生 subagent 仍属于调用方自己的 agent tree。dsh-Agentlink 接入的是一套由用户配置的独立 harness：会话可以在 DSH Web 持续查看，使用 DSH 自己的 worker 与模型路由，并由调用方观察、继续或取消。

![dsh-Agentlink 与原生 subagent 对比](assets/dsh-vs-native-subagents.webp)

*主 agent 专注判断和验收，DSH 使用你配置的模型承担更大规模的执行工作。*

### 省时间、也省成本

- **省时间。** 把实现、检索、资料提取和长日志整理等执行型任务交给你在 DSH 中配置的高速模型，例如 DeepSeek V4 路由，主 agent 可以继续规划和验收。
- **省成本。** 把大量执行 token 路由到成本更低的 DeepSeek 模型，可以减少对昂贵主模型的消耗。

实际速度和费用取决于模型、服务商、部署方式、网络与任务本身。完成安装后，你仍然可以像平常一样使用你的 AI 工具，只在适合交给 DSH 执行时直接让它发起委派即可。

## 如何使用

启动 `dsh web` 并让工具重新加载 MCP 配置后，直接用自然语言告诉你的主 agent，例如：

> 使用 dsh-Agentlink，把当前仓库里的这个实现任务委派给 DSH。保持会话在 DSH Web 可见，向我报告进度，任何 approval 都先询问我。

之后你的 agent 可以委派任务、观察事件、继续同一会话、与你一起回答 DSH 的问题，或取消任务。打开 `http://127.0.0.1:3080`，即可在 DSH Web 查看并操作同一个 session。

## MCP 工具

- `dsh_host_status` — 读取 connect-only Host 状态与 capabilities
- `dsh_delegate` — 创建 root session 并排队初始 prompt；默认 detached（`waitSeconds=0`）
- `dsh_followup` — 以显式 `mode="queue"|"steer"` 继续同一个 root session；默认 `queue`
- `dsh_continue` — `dsh_followup` 的兼容别名
- `dsh_status` — 返回 availability、execution、lineage、queue、pending interaction、final message 和 cursors
- `dsh_tail` — 使用 bridge task cursor 读取有界事件摘要
- `dsh_wait` — 最多等待 30 秒，直到出现 durable event、状态变化、pending interaction 或 terminal 状态
- `dsh_observe` — `dsh_wait` 的兼容别名；bridge cursor 取代原始 per-session seq cursor
- `dsh_cancel` — `scope="turn"|"queue"`
- `dsh_list` — 列出 task mapping，并附带当前派生状态
- `dsh_answer_question` — 通过 pending question rpcId 提交类型化答案
- `dsh_resolve_approval` — 对 pending approval rpcId 提交 `allow_once|reject`
- `dsh_release_workspace` — 显式释放持久化 workspace claim，但不关闭 DSH session

正常委派没有 model 参数。目标模型只在安装或调整 DSH 时配置。每次 delegate 都会读取 `session.models.current` 并信任 Host 返回的 `routable`；bridge 不会修改模型，也不会根据 catalog group 自行推导 routability。

`dsh_wait` 只观察 bridge 的持久化状态。assistant delta/chunk 帧和顶层 `session/projection` snapshot 会被跳过，因此不会 bump task revision，也不会唤醒 waiter；turn 结束后的完整 final message 仍可通过 status/tail 观察。

## 后续方向

以下内容是计划方向，不代表已经实现或 release 承诺。

1. **Claude 与其他入口** — 探索 Claude Code、Claude Desktop MCP、Workbuddy 等调用方接入同一个官方 DSH Web Host。
2. **Agent 调用与信息传输** — 优化 prompt 组织、上下文打包、输出摘要和压缩策略，同时确保问题、审批、错误和最终答案可靠传输。
3. **更多集成** — 待 Codex bridge 与兼容性约定稳定后继续扩展。

## 更多文档

- [架构与安全模型](docs/architecture.zh-CN.md) — 身份、状态、恢复、审批、取消与工作区协作
- [验证指南](docs/validation.md) — 兼容性检查与人工验收流程
- [已知问题](KNOWN_ISSUES.md) — 当前升级与并发运行限制
- [贡献指南](CONTRIBUTING.md)与[安全说明](SECURITY.md)

## 许可证

[MIT](LICENSE)

Alpha 说明：DSH 仍处于 developer preview，本项目是独立社区项目，不代表 DeepSeek 或 OpenAI 官方背书。`0.1.0-alpha.1` 包含一个共享账本并发问题；修复已进入源码、尚待发布。升级或并发运行 bridge 前请阅读[已知问题](KNOWN_ISSUES.md)。

---

## ZCode 适配说明

> **注意**：本仓库是 [hootandy321/dsh-Agentlink](https://github.com/hootandy321/dsh-Agentlink) 的二次开发版本。
> 原项目面向 Codex，本仓库添加了 ZCode 插件支持。

### 新增内容

| 路径 | 说明 |
|------|------|
| `.zcode-plugin/plugin.json` | ZCode 插件 manifest，含 MCP 服务器配置 |
| `skills/dsh-collab/SKILL.md` | ZCode 专用协作技能 |
| `scripts/install.ps1` | ZCode 一键安装脚本 |
| `.github/workflows/sync-upstream.yml` | 自动同步上游机制 |
| `.github/workflows/auto-fork-adapt.yml` | 全自动 fork → PR → 同步工作流 |

### 自动同步机制

本仓库配置了 GitHub Action，每 6 小时自动检查并合并上游更新：
```bash
# 手动同步
git fetch upstream main
git merge upstream/main --no-edit
npm run build
```

### 使用 ZCode

请参考 [QUICK_START.ps1](QUICK_START.ps1) 或进入 Actions 页面运行工作流程。
