# dsh-Agentlink (ZCode Adaptation)

![dsh-Agentlink cover](assets/dsh-agentlink-cover.webp)

[![CI](https://github.com/hootandy321/dsh-Agentlink/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/hootandy321/dsh-Agentlink/actions/workflows/ci.yml) [![GitHub Stars](https://img.shields.io/github/stars/hootandy321/dsh-Agentlink?style=flat-square&logo=github)](https://github.com/hootandy321/dsh-Agentlink/stargazers) [![License: MIT](https://img.shields.io/github/license/hootandy321/dsh-Agentlink?style=flat-square)](LICENSE) [![Node.js 22+](https://img.shields.io/badge/Node.js-22%2B-339933?style=flat-square&logo=nodedotjs&logoColor=white)](https://nodejs.org/) [![DSH plugin](https://img.shields.io/badge/DSH-plugin-4B6BFB?style=flat-square)](https://www.deepseek.com/harness/en/)

**English** | [简体中文](README.zh-CN.md)

> **Important: This repository is a second-development fork of [hootandy321/dsh-Agentlink](https://github.com/hootandy321/dsh-Agentlink).**
> The original targets Codex; this fork adds **ZCode** plugin support on top of all original functionality.
>
> The `main` branch stays in sync with upstream automatically. When the upstream author pushes updates, they are merged in automatically via GitHub Actions.

dsh-Agentlink is a **connect-only MCP bridge** that lets AI coding tools (like ZCode) delegate implementation tasks to a locally running **DeepSeek Harness (DSH) Web Host**, then observe, continue, approve, or cancel those sessions from the calling agent.

## Relationship with the Original

| Project | Link | Description |
|---------|------|-------------|
| Original (Codex) | https://github.com/hootandy321/dsh-Agentlink | Official upstream, maintained by original author |
| **This fork (ZCode)** | https://github.com/yyz0313/dsh-Agentlink | This repository — ZCode plugin + auto-sync |

Both branches are maintained in parallel with full compatibility. Our commits only touch ZCode adaptation and functional enhancements (e.g., `sessionId` parameter), without modifying upstream logic.

## What We Added (Beyond the Original)

| Path | Description |
|------|-------------|
| `.zcode-plugin/plugin.json` | ZCode plugin manifest — MCP server config, user-configurable DSH Host URL and agent preset |
| `skills/dsh-collab/SKILL.md` | ZCode collaboration skill — full tool reference, workflow, and safety rules |
| `scripts/install.ps1` | One-click ZCode MCP registration script with environment detection |
| `.github/workflows/sync-upstream.yml` | Auto-sync GitHub Action — checks upstream every 6 hours |
| `src/bridge-service.ts` | New `sessionId` parameter to reuse existing DSH sessions |

## Auto-Sync Mechanism

A GitHub Action runs every 6 hours:
- Checks if `hootandy321/dsh-Agentlink` has new commits
- Automatically merges into this repo's `main`
- Logs conflicts in Actions for manual resolution
- Our ZCode files (`.zcode-plugin/`, `skills/`, `scripts/`) are never overwritten

Manual sync:
```bash
git fetch upstream main
git merge upstream/main --no-edit
npm run build
```

## Features

- **Connect-only, no process management** — you run DSH Web Host; the bridge just communicates
- **Persistent sessions** — DSH sessions remain visible and controllable in DSH Web after the bridge disconnects
- **Sandbox isolation** — DSH Code Mode provides full filesystem sandbox; the bridge cannot bypass it
- **Human approval required** — every write operation must be manually approved via `dsh_resolve_approval`
- **Multi-turn collaboration** — use `dsh_followup` to append tasks, `dsh_cancel` to selectively stop
- **Session reuse** — `dsh_delegate` accepts an optional `sessionId` to continue an existing DSH conversation (new in this fork)

## Installation

### Prerequisites

- Node.js 22+
- ZCode CLI (latest)
- DSH Web Host running in the background (default port 3080)

### Option 1: Auto-install (Recommended)

Run the install script in the project directory:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

The script auto-detects Node.js, DSH Host, compiles the bridge, and writes the ZCode config.

### Option 2: Manual Install

```powershell
# 1. Ensure DSH Web Host is running (in another terminal):
#    dsh web --profile web --port 3080

# 2. Install dependencies and build
npm install
npm run build

# 3. Add the MCP config to ~/.zcode/cli/config.json
#    (or just double-click scripts/install.ps1)
```

### ZCode Configuration

Add to `~/.zcode/cli/config.json`:

```json
{
  "mcp": {
    "servers": {
      "dsh_agentlink": {
        "command": "C:\\Users\\you\\.workbuddy\\binaries\\node\\versions\\22.22.2\\node.exe",
        "args": ["C:\\Users\\you\\.zcode\\workspace\\default\\dsh-Agentlink\\dist\\index.js"],
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

### Verify Installation

```powershell
# Check bridge connection status
node dist/doctor.js

# Should output: {"ok": true, "compatibility": "compatible-untested", ...}
```

## Usage

In ZCode, MCP tools are exposed as `mcp__dsh_agentlink__<tool_name>`. Common workflow:

### 1. Check Host Status

```
mcp__dsh_agentlink__dsh_host_status
```

### 2. Delegate a Task

```
mcp__dsh_agentlink__dsh_delegate
Parameters:
  prompt: "Implement a user login module with JWT auth"
  cwd: "/path/to/your/project"
  workspaceMode: "exclusive-write"  # or "read-only"
  sessionId: "optional - reuse existing session ID"
```

Note the returned `taskId` and `rootSessionId`.

### 3. Wait and Monitor

```
mcp__dsh_agentlink__dsh_wait  # wait up to 30 seconds
mcp__dsh_agentlink__dsh_tail  # read latest progress (with cursor)
```

### 4. Follow Up

```
mcp__dsh_agentlink__dsh_followup
Parameters:
  taskId: "xxx"
  mode: "queue"        # append after current turn finishes
  # or
  mode: "steer"        # inject guidance into the active turn
  content: "Handle edge cases carefully"
```

### 5. Answer Questions / Approve Writes

When DSH needs approval, get `pendingInteractions` from `dsh_status` or `dsh_tail`:

```
mcp__dsh_agentlink__dsh_answer_question
Parameters: taskId, requestId, answers

mcp__dsh_agentlink__dsh_resolve_approval
Parameters: taskId, requestId, outcome: "allow_once" | "reject"
```

**Security rule: the bridge never auto-approves. Every write must be manually confirmed by you.**

### 6. Cancel / Release Workspace

```
mcp__dsh_agentlink__dsh_cancel(scope="turn")    # cancel only active turn, keep queue
mcp__dsh_agentlink__dsh_cancel(scope="queue")   # cancel entire queue
mcp__dsh_agentlink__dsh_release_workspace       # release workspace lock (does not close DSH session)
```

## ZCode Skill

This repo provides a ZCode-specific skill with the full usage guide:

```
skills/dsh-collab/SKILL.md    # ZCode collaboration skill (tool names, workflow, safety rules)
```

Use `/dsh-collab` in ZCode to load the skill.

## Known Limitations

- **Does not auto-start DSH Host** — you must run `dsh web` yourself
- **Host restart loses state** — active turns, pending interactions, and queue are lost
- **At-least-once delivery** — not exactly-once; deduplication is deterministic per-session
- **Connect-only** — the bridge does not manage Host process lifecycle
- **Approvals are never auto-granted** — this is a security design, not a bug

## License

This project is open-sourced under the [MIT License](LICENSE), same as upstream.

Alpha note: DSH is still in developer preview and this community project is independent of DeepSeek and OpenAI. Read [Known issues](KNOWN_ISSUES.md) before upgrading or running concurrent bridge processes.
