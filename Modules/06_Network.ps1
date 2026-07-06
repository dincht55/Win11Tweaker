<#
.SYNOPSIS
    Windows 11 設定精靈 - 模組 07:網路設定 (Network)

.DESCRIPTION
    網路層級的安全/隱私設定。提問模式:選項式 (統一模型)。
    模組本體僅負責載入知識庫並呼叫引擎;設定項由 Data\kb_06_Network.psd1 提供。

    本類項目較少 (目前僅 LLMNR 一項):網路類設定多屬雙面刃,關掉能提升安全
    卻常犧牲連線功能 (如 NCSI 影響公共 Wi-Fi 登入、WPAD 影響 RDP)。在「面對
    大眾、零副作用」的定位下,只收確實安全無虞的項目,寧缺勿濫。

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
$ModuleId    = "06_Network"
$ModuleMode  = "individual"
$ModuleTitle = Get-Text "cat_06"   # 網路設定

# ============================================================
#  載入知識庫 (設定項資料)
# ============================================================
$kbFile = Join-Path $Global:DataPath "kb_06_Network.psd1"
if (-not (Test-Path $kbFile)) {
    Write-Host ""
    Write-Host ("  " + (Get-Text "err_kb_notfound") + $kbFile) -ForegroundColor Red
    return
}
$kb    = Import-PowerShellDataFile -Path $kbFile
$Items = $kb.Items

# ============================================================
#  類別說明 (向使用者說明本類設定的性質)
# ============================================================
Write-Host ""
Write-Host ("  ── " + (Get-Text "about_title") + " ──") -ForegroundColor DarkCyan
Write-Host ("  " + (Get-Text "about_06_1")) -ForegroundColor Gray
Write-Host ("  " + (Get-Text "about_06_2")) -ForegroundColor Gray
Write-Host ("  " + (Get-Text "about_06_3")) -ForegroundColor Gray

# ============================================================
#  執行:呼叫 Common 的通用流程引擎
# ============================================================
Invoke-Category -ModuleId $ModuleId -ModuleTitle $ModuleTitle -Items $Items -Mode $ModuleMode
