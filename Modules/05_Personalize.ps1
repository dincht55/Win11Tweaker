<#
.SYNOPSIS
    Windows 11 設定精靈 - 模組 06:個人化習慣 (Personalization)

.DESCRIPTION
    調整使用習慣偏好:檔案總管顯示、右鍵選單、主題、工作列、開始選單、
    桌面圖示,以及習慣層級的隱私/安全小項。提問模式:選項式 (統一模型)。

    模組本體僅負責載入知識庫並呼叫引擎,不內嵌資料;所有設定項與選項設計
    由 Data\kb_05_Personalize.psd1 提供。

    註:部分項目 (工作列、主題、桌面圖示、右鍵選單) 需登出重新登入或重啟
        檔案總管後才會在畫面上生效;設定本身套用當下即已寫入。

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
$ModuleId    = "05_Personalize"
$ModuleMode  = "individual"
$ModuleTitle = Get-Text "cat_05"   # 個人化習慣

# ============================================================
#  載入知識庫 (設定項資料)
#  (Import-PowerShellDataFile 規定檔案最外層須為 Hashtable,
#   所以陣列包在 Items 鍵底下,讀取後要多一步 $kb.Items 取出)
# ============================================================
$kbFile = Join-Path $Global:DataPath "kb_05_Personalize.psd1"
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
