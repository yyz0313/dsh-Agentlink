# ================================================
#  DSH-Agentlink ZCode 适配 快速开始脚本
# ================================================

param(
    [switch]$SetupPat = $false,
    [switch]$RunWorkflow = $false,
    [switch]$ShowWorkflows = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DSH-Agentlink ZCode 适配快速开始" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

echo @'
✅ 已完成（本地文件）：
   - ZCode 插件文件 (.zcode-plugin/plugin.json)
   - 协作技能 (skills/dsh-collab/SKILL.md)
   - 安装脚本 (scripts/install.ps1)
   - 自动同步工作流程 (.github/workflows/sync-upstream.yml)
   - Release 工作流程 (.github/workflows/release.yml)
   - 全自动 fork 工作流程 (.github/workflows/auto-fork-adapt.yml)

📁 本地配置说明：
   - GH_TOKEN_CONFIG.md （PAT Token 配置说明）
   
'@

echo @'
🔧 下一步操作：

1. 添加 PAT Token 到 GitHub Secrets：
   进入：https://github.com/yyz0313/dsh-Agentlink/settings/secrets/actions
   添加 Secret：
   - 名称：PAT_TOKEN
   - 值：您的个人访问令牌 (需勾选 public_repo 权限)

2. 触发自动化工作流程：
   进入：https://github.com/yyz0313/dsh-Agentlink/actions
   选择 "Auto Fork & Adapt PR" 工作流程
   点击 "Run workflow"
   填写参数：
   - upstream_repo: hootandy321/dsh-Agentlink
   - target_branch: zcode-adaptation  
   - version: 0.1.0

3. 工作流会自动：
   ✨ Fork 原仓库 → 修改代码 → 创建 PR → 待合并 → 自动同步

'@

Write-Host "按任意键打开 GitHub Secrets 页面..." -ForegroundColor Yellow
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null

Start-Process "https://github.com/yyz0313/dsh-Agentlink/settings/secrets/actions"
