<#
.SYNOPSIS
    Windows 11 設定精靈 - 模組 10:安全性 (Security)

.DESCRIPTION
    核心安全設定:記憶體完整性 HVCI、UAC 等級、SmartScreen。提問模式:選項式。
    模組本體僅載入知識庫並呼叫引擎;設定項由 Data\kb_09_Security.psd1 提供。

    本類項目經嚴格篩選,只收「使用者應知情自選」且有實際調整價值的項目。
    各項說明皆清楚寫出安全取捨,協助使用者理解後正確設定。

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
$ModuleId    = "09_Security"
$ModuleMode  = "individual"
$ModuleTitle = Get-Text "cat_09"   # 安全性

# ============================================================
#  載入知識庫
# ============================================================
$kbFile = Join-Path $Global:DataPath "kb_09_Security.psd1"
if (-not (Test-Path $kbFile)) {
    Write-Host ""
    Write-Host ("  " + (Get-Text "err_kb_notfound") + $kbFile) -ForegroundColor Red
    return
}
$kb    = Import-PowerShellDataFile -Path $kbFile
$Items = $kb.Items

# ============================================================
#  類別說明 (安全類項目需使用者知情理解)
# ============================================================
Write-Host ""
Write-Host ("  ── " + (Get-Text "about_title") + " ──") -ForegroundColor DarkCyan
Write-Host ("  " + (Get-Text "about_09_1")) -ForegroundColor Gray
Write-Host ("  " + (Get-Text "about_09_2")) -ForegroundColor Gray

# ============================================================
#  執行:呼叫 Common 的通用流程引擎
# ============================================================
Invoke-Category -ModuleId $ModuleId -ModuleTitle $ModuleTitle -Items $Items -Mode $ModuleMode
