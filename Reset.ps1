<#
.SYNOPSIS
    Windows 11 設定精靈 - 重置工具 (Reset Tool)

.DESCRIPTION
    清除設定精靈執行後產生的所有檔案,讓精靈回到初始 (剛下載) 狀態:
      - Config\   匯出的設定檔 (*.json)
      - Progress\ 斷點續傳記錄 (*.json)
      - Reports\  執行日誌 (*.log)
      - Restore\  刪除登錄檔值的還原備份 (*.json)

    安全設計:
      1. 先掃描並列出所有將被清除的檔案 (數量 + 容量),不會盲刪。
      2. 明確警告:清除 Restore 備份後,先前「刪除類設定」將無法再還原。
      3. 需使用者輸入大寫 YES 才實際執行 (雙重確認)。
      4. 保留結構檔 (.gitkeep) 與說明文件 (README.md),不破壞專案目錄結構。

.NOTES
    作者:dincht55 (DCT)   授權:MIT
    用法:於專案根目錄執行 powershell -ExecutionPolicy Bypass -File .\Reset.ps1
#>

# ============================================================
#  載入共用引擎
# ============================================================
$standalone = $false
if (-not $Global:CommonLoaded) {
    . (Join-Path $PSScriptRoot "Common.ps1")
    $standalone = $true
}

# ------------------------------------------------------------
#  語言選擇 (共用函式;單獨執行時才問)
# ------------------------------------------------------------
if ($standalone) {
    Select-Language
}

# ------------------------------------------------------------
#  位元組格式化 (本工具自足,不依賴模組專屬函式)
# ------------------------------------------------------------
function Format-FileSize {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return ("{0:N2} GB" -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ("{0:N1} MB" -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ("{0:N0} KB" -f ($Bytes / 1KB)) }
    return ("{0} B" -f $Bytes)
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ("  " + (Get-Text "reset_title"))    -ForegroundColor Cyan
Write-Host ("  " + (Get-Text "reset_subtitle")) -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan

# ============================================================
#  掃描各目錄可清除的檔案
#  資料驅動:每個目錄一筆定義 (顯示名鍵 + 路徑 + 檔案篩選),易增易改
# ============================================================
$targets = @(
    @{ LabelKey = "reset_cat_config";   Path = $Global:ConfigPath;   Filter = "*.json" }
    @{ LabelKey = "reset_cat_progress"; Path = $Global:ProgressPath; Filter = "*.json" }
    @{ LabelKey = "reset_cat_reports";  Path = $Global:ReportsPath;  Filter = "*.log"  }
    @{ LabelKey = "reset_cat_restore";  Path = $Global:RestorePath;  Filter = "*.json" }
)

# 收集待刪清單 (只抓實體檔案,天然排除 .gitkeep 與 README.md,因副檔名不符)
$toDelete  = @()
$totalSize = 0
Write-Host ""
Write-Host ("  " + (Get-Text "reset_scanning")) -ForegroundColor Gray
Write-Host ""

foreach ($t in $targets) {
    $files = @()
    if (Test-Path $t.Path) {
        $files = @(Get-ChildItem -Path $t.Path -Filter $t.Filter -File -ErrorAction SilentlyContinue)
    }
    $size = ($files | Measure-Object -Property Length -Sum).Sum
    if (-not $size) { $size = 0 }
    $totalSize += $size
    $toDelete  += $files

    $label = Get-Text $t.LabelKey
    if ($files.Count -gt 0) {
        $line = Get-Text "reset_count_unit" -Args @($files.Count, (Format-FileSize $size))
        Write-Host ("  [{0}] {1}" -f $label, $line) -ForegroundColor White
    }
    else {
        Write-Host ("  [{0}] -" -f $label) -ForegroundColor DarkGray
    }
}

# ------------------------------------------------------------
#  無檔案 → 已是初始狀態,直接結束
# ------------------------------------------------------------
if ($toDelete.Count -eq 0) {
    Write-Host ""
    Write-Host ("  " + (Get-Text "reset_nothing")) -ForegroundColor Green
    Write-Host ""
    return
}

# ============================================================
#  顯示總計 + 警告 + 雙重確認
# ============================================================
Write-Host ""
Write-Host ("  " + (Get-Text "reset_total" -Args @($toDelete.Count, (Format-FileSize $totalSize)))) -ForegroundColor Cyan
Write-Host ""
Write-Host ("  " + (Get-Text "reset_warn_title")) -ForegroundColor Yellow
Write-Host ("  " + (Get-Text "reset_warn_restore")) -ForegroundColor Yellow
Write-Host ("  " + (Get-Text "reset_warn_irreversible")) -ForegroundColor Yellow
Write-Host ("  " + (Get-Text "reset_keep_note")) -ForegroundColor DarkGray
Write-Host ""

# 需輸入大寫 YES 才執行 (不用 Read-Choice,刻意要求完整字串,避免誤觸)
Write-Host ("  " + (Get-Text "reset_confirm_prompt")) -ForegroundColor Yellow -NoNewline
Write-Host " " -NoNewline
$answer = Read-Host

if ($answer -cne "YES") {
    Write-Host ""
    Write-Host ("  " + (Get-Text "reset_cancelled")) -ForegroundColor Gray
    Write-Host ""
    return
}

# ============================================================
#  執行清除
# ============================================================
Write-Host ""
Write-Host ("  " + (Get-Text "reset_running")) -ForegroundColor Gray

$deleted = 0
$failed  = 0
foreach ($f in $toDelete) {
    try {
        Remove-Item -Path $f.FullName -Force -ErrorAction Stop
        $deleted++
    }
    catch {
        $failed++
    }
}

Write-Host ""
if ($failed -eq 0) {
    Write-Host ("  " + (Get-Text "reset_done" -Args @($deleted))) -ForegroundColor Green
}
else {
    Write-Host ("  " + (Get-Text "reset_done" -Args @($deleted))) -ForegroundColor Green
    Write-Host ("  " + (Get-Text "reset_failed_some" -Args @($failed))) -ForegroundColor Yellow
}
Write-Host ""
