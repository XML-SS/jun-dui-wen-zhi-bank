# 一键创建 GitHub 仓库并推送
# 用法: .\push.ps1
# 依赖: gh (GitHub CLI，已登录)

$ErrorActionPreference = "Stop"
$RepoName = "jun-dui-wen-zhi-bank"
$Desc = "军队文职公共科目刷题宝 - 1100+题库，离线可用，随机抽卷"
$Root = $PSScriptRoot

Set-Location $Root

# 1. 若未初始化则 git init
if (-not (Test-Path ".git")) {
    git init
    git branch -M main
}

# 2. 写 .gitignore（避免把临时文件推上去）
@"
.DS_Store
Thumbs.db
*.log
__pycache__/
.venv/
"@ | Set-Content -Encoding utf8 .gitignore

# 3. 若仓库不存在则创建（私有可改 --private）
$exists = gh repo view $RepoName --json name 2>$null
if (-not $?) {
    Write-Host "Creating repo $RepoName ..."
    gh repo create $RepoName --public --description $Desc --source . --remote origin --push
} else {
    Write-Host "Repo exists, pushing..."
    git remote get-url origin 2>$null
    if (-not $?) {
        gh repo create $RepoName --public --source . --remote origin
    }
    git add -A
    $msg = "update: " + (Get-Date -Format "yyyy-MM-dd HH:mm")
    git commit -m $msg 2>$null
    git push -u origin main
}

Write-Host "Done. URL: https://github.com/$(gh api user --jq .login)/$RepoName"
