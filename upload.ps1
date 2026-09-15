$ErrorActionPreference = "Stop"
$Repo = "jun-dui-wen-zhi-bank"
$Owner = "XML-SS"
$Branch = "main"
$Root = $PSScriptRoot
$token = gh auth token
$headers = @{
    Authorization = "Bearer $token"
    Accept = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

function Get-FileSha($path) {
    $url = "https://api.github.com/repos/$Owner/$Repo/contents/${path}?ref=$Branch"
    try {
        $r = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
        return $r.sha
    } catch {
        return $null
    }
}

function Upload-File($relPath, $absPath) {
    if (-not (Test-Path $absPath)) {
        Write-Host "SKIP missing $relPath"
        return
    }
    $bytes = [System.IO.File]::ReadAllBytes($absPath)
    $b64 = [Convert]::ToBase64String($bytes)
    $sha = Get-FileSha $relPath
    $body = @{
        message = "add $relPath"
        content = $b64
        branch  = $Branch
    }
    if ($sha) { $body.sha = $sha }
    $json = $body | ConvertTo-Json -Depth 5
    $url = "https://api.github.com/repos/$Owner/$Repo/contents/$relPath"
    $r = Invoke-RestMethod -Uri $url -Headers $headers -Method Put -Body $json -ContentType "application/json"
    Write-Host "OK  $relPath"
}

# init: empty repo needs first commit via README
try {
    Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/branches/$Branch" -Headers $headers | Out-Null
    Write-Host "Branch $Branch exists"
} catch {
    Write-Host "Creating initial commit..."
    $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("# jun-dui-wen-zhi-bank`n"))
    $body = @{ message = "init"; content = $b64; branch = $Branch } | ConvertTo-Json
    Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/contents/README.md" -Headers $headers -Method Put -Body $body -ContentType "application/json" | Out-Null
}

Upload-File "README.md" (Join-Path $Root "README.md")
Start-Sleep -Milliseconds 500
Upload-File ".gitignore" (Join-Path $Root ".gitignore")
Start-Sleep -Milliseconds 500
Upload-File "push.ps1" (Join-Path $Root "push.ps1")
Start-Sleep -Milliseconds 500
Upload-File "upload.ps1" (Join-Path $Root "upload.ps1")
Start-Sleep -Milliseconds 500
Upload-File "scripts/build_bank.py" (Join-Path $Root "scripts\build_bank.py")
Start-Sleep -Milliseconds 500
Upload-File "docs/做题技巧总结.md" (Join-Path $Root "docs\做题技巧总结.md")
Start-Sleep -Milliseconds 500
Upload-File "web/index.html" (Join-Path $Root "web\index.html")

Write-Host ""
Write-Host "Done: https://github.com/$Owner/$Repo"
