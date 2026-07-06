<#
.SYNOPSIS
    Windows 11 設定精靈 - 模組 04:AI 功能 (AI Features)

.DESCRIPTION
    停用 Windows 內建 AI 功能 (Recall、Windows Copilot、Click to Do 等)。
    提問模式:選項式 (統一模型)。

    模組本體僅負責載入知識庫並呼叫引擎,不內嵌資料;所有設定項與選項設計
    由 Data\kb_03_AI.psd1 提供。

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
$ModuleId    = "03_AI"
$ModuleMode  = "individual"
$ModuleTitle = Get-Text "cat_03"   # AI 功能

# ============================================================
#  載入知識庫 (設定項資料)
#  (Import-PowerShellDataFile 規定檔案最外層須為 Hashtable,
#   所以陣列包在 Items 鍵底下,讀取後要多一步 $kb.Items 取出)
# ============================================================
$kbFile = Join-Path $Global:DataPath "kb_03_AI.psd1"
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
