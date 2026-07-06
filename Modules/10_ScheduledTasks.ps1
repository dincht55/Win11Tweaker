<#
.SYNOPSIS
    Windows 11 設定精靈 - 模組 11:排程工作 (Scheduled Tasks)

.DESCRIPTION
    遙測/資料收集類背景排程的停用管理。
    提問模式:選項式、逐題 (individual) —— 排程停用與否因人而異,逐一決定。
    每項三選項:停用 / 啟用 / 維持 (雙向可逆),Enter 跟隨建議。
    設定項由 Data\kb_10_ScheduledTasks.psd1 提供。

.NOTES
    作者:dincht55 (DCT)   授權:MIT
#>

# ============================================================
#  載入共用引擎 (支援單獨執行本模組)
# ============================================================
$standalone = $false
if (-not $Global:CommonLoaded) {
    . (Join-Path (Split-Path -Parent $PSScriptRoot) "Common.ps1")
    $standalone = $true
}
if ($standalone) {
    Import-Language "zh-TW" | Out-Null
    Initialize-SystemInfo   | Out-Null
    Initialize-ProfileName  | Out-Null
}

# ============================================================
#  模組資訊
# ============================================================
$ModuleId    = "10_ScheduledTasks"
$ModuleMode  = "individual"
$ModuleTitle = Get-Text "cat_10"   # 排程工作

# ============================================================
#  載入知識庫
# ============================================================
$kbFile = Join-Path $Global:DataPath "kb_10_ScheduledTasks.psd1"
if (-not (Test-Path $kbFile)) {
    Write-Host ""
    Write-Host ("  " + (Get-Text "err_kb_notfound") + $kbFile) -ForegroundColor Red
    return
}
$kb    = Import-PowerShellDataFile -Path $kbFile
$Items = $kb.Items

# ============================================================
#  類別說明
# ============================================================
Write-Host ""
Write-Host ("  ── " + (Get-Text "about_title") + " ──") -ForegroundColor DarkCyan
Write-Host ("  " + (Get-Text "about_10_1")) -ForegroundColor Gray
Write-Host ("  " + (Get-Text "about_10_2")) -ForegroundColor Gray
Write-Host ("  " + (Get-Text "about_10_3")) -ForegroundColor Gray

# ============================================================
#  執行:呼叫 Common 的通用流程引擎
# ============================================================
Invoke-Category -ModuleId $ModuleId -ModuleTitle $ModuleTitle -Items $Items -Mode $ModuleMode
