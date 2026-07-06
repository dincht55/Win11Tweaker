<#
.SYNOPSIS
    Windows 11 設定精靈 - 模組 13:系統行為 (System Behavior)

.DESCRIPTION
    效能/回應 (遊戲背景錄製、視覺效果、背景 App) 與系統雜項 (剪貼簿歷程、
    系統廣告與建議)。提問模式:選項式。設定項由 Data\kb_12_SystemBehavior.psd1 提供。

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
$ModuleId    = "12_SystemBehavior"
$ModuleMode  = "individual"
$ModuleTitle = Get-Text "cat_12"   # 系統行為

# ============================================================
#  載入知識庫
# ============================================================
$kbFile = Join-Path $Global:DataPath "kb_12_SystemBehavior.psd1"
if (-not (Test-Path $kbFile)) {
    Write-Host ""
    Write-Host ("  " + (Get-Text "err_kb_notfound") + $kbFile) -ForegroundColor Red
    return
}
$kb    = Import-PowerShellDataFile -Path $kbFile
$Items = $kb.Items

# ============================================================
#  執行:呼叫 Common 的通用流程引擎
# ============================================================
Invoke-Category -ModuleId $ModuleId -ModuleTitle $ModuleTitle -Items $Items -Mode $ModuleMode
