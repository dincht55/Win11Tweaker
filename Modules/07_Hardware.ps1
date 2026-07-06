<#
.SYNOPSIS
    Windows 11 設定精靈 - 模組 08:硬體與電源 (Hardware & Power)

.DESCRIPTION
    電源計畫、快速啟動、裝置中繼資料等硬體/電源設定。提問模式:選項式。
    模組本體僅載入知識庫並呼叫引擎;設定項由 Data\kb_07_Hardware.psd1 提供。

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
$ModuleId    = "07_Hardware"
$ModuleMode  = "individual"
$ModuleTitle = Get-Text "cat_07"   # 硬體/裝置

# ============================================================
#  載入知識庫
# ============================================================
$kbFile = Join-Path $Global:DataPath "kb_07_Hardware.psd1"
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
