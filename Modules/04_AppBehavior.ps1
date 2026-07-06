<#
.SYNOPSIS
    Windows 11 設定精靈 - 模組 05:應用程式行為 (App Behavior)

.DESCRIPTION
    調整內建應用程式的功能行為 (OneDrive/Edge/Teams 自啟、Edge 各項功能、
    自動播放、Game Bar 等)。提問模式:選項式 (統一模型,雙選以 1/2 呈現)。

    本模組為「知識庫 + 選項式引擎 + 刪除還原」三者整合的範本模組:
      - 設定項資料改放獨立知識庫檔 (Data\kb_04_AppBehavior.psd1),
        模組本身只負責載入與呼叫引擎,不再內嵌資料。
      - 提問使用 Show-ChoiceQuestion (Common.ps1),全專案統一選項式模型,
        每題為「問題 + 選項清單 + 建議」,以 1~5 數字選擇。
      - 含「刪除開機自啟項目」的設定 (RegDel),套用前會由引擎額外
        跳出確認並自動備份,行為與其他類別已驗證的機制完全一致。

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
$ModuleId    = "04_AppBehavior"
$ModuleMode  = "individual"
$ModuleTitle = Get-Text "cat_04"   # 應用程式行為

# ============================================================
#  載入知識庫 (設定項資料)
#  知識庫檔內每筆項目已是 Choices 格式,可直接當 $Items 餵給引擎,
#  不需任何欄位轉換。新增/調整設定只需改知識庫檔,不用動這支模組。
#  (Import-PowerShellDataFile 規定檔案最外層須為 Hashtable,
#   所以陣列包在 Items 鍵底下,讀取後要多一步 $kb.Items 取出)
# ============================================================
$kbFile = Join-Path $Global:DataPath "kb_04_AppBehavior.psd1"
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
