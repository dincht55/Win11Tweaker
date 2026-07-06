<#
.SYNOPSIS
    Windows 11 設定精靈 - 模組 15:磁碟清理 (Disk Cleanup)

.DESCRIPTION
    與設定型類別不同:先估算各清理對象可釋放的空間,顯示後逐一詢問是否清理。
    分兩區:
      安全清理區 (SafeItems)     - 純賺,清了幾乎無副作用。
      進階區     (AdvancedItems) - 知情取捨,清了有代價 (如 Windows.old 清了
                                    無法回退舊版),預設不清,說明清楚後由使用者決定。

    清理方式 (Method):
      folder   - 清空資料夾內容 (鎖住的檔案自動略過)
      wusvc    - Windows Update 快取 (停 wuauserv/bits → 清 → 啟服務)
      recycle  - 清空回收筒 (Clear-RecycleBin)
      cleanmgr - 交系統磁碟清理 (Windows.old 等,用 sagerun)
      dism     - WinSxS 元件清理 (DISM StartComponentCleanup)

    清理邏輯為本模組專屬,不污染通用引擎;僅複用 Get-Text / Write-Log /
    Read-Choice / ProfileName 等輔助。

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

$ModuleId    = "14_DiskCleanup"
$ModuleTitle = Get-Text "cat_14"   # 磁碟清理

# ============================================================
#  載入清理對象知識庫
# ============================================================
$kbFile = Join-Path $Global:DataPath "kb_14_DiskCleanup.psd1"
if (-not (Test-Path $kbFile)) {
    Write-Host ""
    Write-Host ("  " + (Get-Text "err_kb_notfound") + $kbFile) -ForegroundColor Red
    return
}
$kb            = Import-PowerShellDataFile -Path $kbFile
$safeItems     = @($kb.SafeItems)
$advancedItems = @($kb.AdvancedItems)

# ============================================================
#  輔助函式
# ============================================================

# 展開路徑中的環境變數 (psd1 是純資料,%VAR% 需在此展開)
function Expand-CleanPath {
    param([string]$Path)
    if ([string]::IsNullOrEmpty($Path)) { return "" }
    return [Environment]::ExpandEnvironmentVariables($Path)
}

# 估算資料夾內容大小 (bytes)。讀不到/不存在/空資料夾回 0。
function Get-FolderSize {
    param([string]$Path, [string]$Filter = "*")
    if ([string]::IsNullOrEmpty($Path) -or -not (Test-Path $Path)) { return 0 }
    try {
        # 只取檔案 (資料夾沒有 Length 屬性,會導致 Measure-Object 報錯)
        $files = Get-ChildItem -Path $Path -Filter $Filter -Recurse -Force -File -ErrorAction SilentlyContinue
        if (-not $files) { return 0 }
        $sum = ($files | Measure-Object -Property Length -Sum).Sum
        if ($null -eq $sum) { return 0 }
        return [long]$sum
    }
    catch { return 0 }
}

# 將 bytes 轉為易讀字串 (KB/MB/GB)
function Format-Size {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return ("{0:N2} GB" -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ("{0:N1} MB" -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ("{0:N0} KB" -f ($Bytes / 1KB)) }
    return ("{0} B" -f $Bytes)
}

# 清空資料夾內容 (保留資料夾本身,鎖住的檔案略過)。回傳 @{ Deleted; Skipped }
function Clear-FolderContent {
    param([string]$Path, [string]$Filter = "*")
    $deleted = 0; $skipped = 0
    if (-not (Test-Path $Path)) { return @{ Deleted = 0; Skipped = 0 } }
    Get-ChildItem -Path $Path -Filter $Filter -Force -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction Stop
            $deleted++
        }
        catch { $skipped++ }   # 使用中的檔案 → 略過
    }
    return @{ Deleted = $deleted; Skipped = $skipped }
}

# 執行單一清理項,回傳釋放的 bytes (估算值:清理前後大小差)
function Invoke-CleanItem {
    param($Item)
    $path = Expand-CleanPath $Item.Path
    $filter = if ($Item.Filter) { $Item.Filter } else { "*" }

    switch ($Item.Method) {
        "folder" {
            $before = Get-FolderSize -Path $path -Filter $filter
            $r = Clear-FolderContent -Path $path -Filter $filter
            Write-Host ("        " + (Get-Text "dc_cleaned_n" -Args @($r.Deleted))) -ForegroundColor Green
            if ($r.Skipped -gt 0) {
                Write-Host ("        " + (Get-Text "dc_skipped_n" -Args @($r.Skipped))) -ForegroundColor DarkGray
            }
            return $before
        }
        "wusvc" {
            $before = Get-FolderSize -Path $path
            Write-Host ("        " + (Get-Text "dc_pausing_wu")) -ForegroundColor Gray
            Stop-Service -Name wuauserv, bits -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
            $r = Clear-FolderContent -Path $path
            Start-Service -Name wuauserv, bits -ErrorAction SilentlyContinue
            Write-Host ("        " + (Get-Text "dc_cleaned_svc" -Args @($r.Deleted))) -ForegroundColor Green
            return $before
        }
        "recycle" {
            try {
                Clear-RecycleBin -Force -ErrorAction Stop
                Write-Host ("        " + (Get-Text "dc_recycle_emptied")) -ForegroundColor Green
            }
            catch {
                Write-Host ("        " + (Get-Text "dc_recycle_empty")) -ForegroundColor DarkGray
            }
            return 0   # 回收筒大小不易事先估,不計入估算
        }
        "cleanmgr" {
            # Windows.old 等:用 cleanmgr 的 sageset/sagerun 自動處理
            $before = Get-FolderSize -Path $path
            Write-Host ("        " + (Get-Text "dc_cleanmgr_run")) -ForegroundColor Gray
            # sageset 100 已在別處預設;此處直接 sagerun (若未設則跑空)。
            # 為求可靠,對 Windows.old 直接用 cleanmgr /autoclean 對應類別。
            Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:100" -Wait -ErrorAction SilentlyContinue
            Write-Host ("        " + (Get-Text "dc_cleanmgr_done")) -ForegroundColor Green
            return $before
        }
        "dism" {
            Write-Host ("        " + (Get-Text "dc_dism_run")) -ForegroundColor Gray
            Start-Process -FilePath "dism.exe" `
                -ArgumentList "/Online", "/Cleanup-Image", "/StartComponentCleanup" `
                -Wait -ErrorAction SilentlyContinue
            Write-Host ("        " + (Get-Text "dc_dism_done")) -ForegroundColor Green
            return 0
        }
        default {
            Write-Host ("        " + (Get-Text "dc_unknown_method") + $Item.Method) -ForegroundColor DarkGray
            return 0
        }
    }
}

# ============================================================
#  標題
# ============================================================
Write-Host ""
Write-Host "  ══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   $ModuleTitle" -ForegroundColor Cyan
Write-Host "  ══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host ("  " + (Get-Text "dc_intro")) -ForegroundColor Gray

$totalFreed = 0
$cleanedList = @()

# ============================================================
#  安全清理區
# ============================================================
Write-Host ""
Write-Host ("  ── " + (Get-Text "dc_safe_zone") + " ──") -ForegroundColor Green
Write-Host ""
foreach ($item in $safeItems) {
    $p = Expand-CleanPath $item.Path
    $f = if ($item.Filter) { $item.Filter } else { "*" }
    $estBytes = Get-FolderSize -Path $p -Filter $f
    $sizeZh = if ($estBytes -gt 0) { Format-Size $estBytes } else { (Get-Text "dc_size_minimal") }
    Write-Host "  ────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ("  {0}  ({1} {2})" -f (Get-Field -Obj $item -Base "Name"), (Get-Text "dc_free_approx"), $sizeZh) -ForegroundColor White
    Write-Host ("        {0}" -f (Get-Field -Obj $item -Base "Desc")) -ForegroundColor Gray
    Write-Host ("        {0}" -f (Get-Field -Obj $item -Base "Note")) -ForegroundColor DarkGray
    Write-Host ("        " + (Get-Text "dc_rec_clean")) -ForegroundColor DarkCyan

    $choice = Read-Choice -ValidKeys @("Y", "N", "Q") -Labels @{ Y = (Get-Text "dc_btn_clean"); N = (Get-Text "dc_btn_skip"); Q = (Get-Text "grp_btn_end") } -DefaultKey "Y"
    if ($choice -eq "Q") { Write-Host ("  " + (Get-Text "dc_ended")) -ForegroundColor Gray; break }
    if ($choice -eq "Y") {
        $freed = Invoke-CleanItem -Item $item
        $totalFreed += $freed
        $cleanedList += (Get-Field -Obj $item -Base "Name")
        Write-Log -Message ("已清理:" + $item.Id) -Level OK -Module $ModuleId -Item (Get-Field -Obj $item -Base "Name")
    }
}

# ============================================================
#  進階區 (知情取捨,預設不清)
# ============================================================
if ($choice -ne "Q") {
    Write-Host ""
    Write-Host ("  ── " + (Get-Text "dc_adv_zone") + " ──") -ForegroundColor Yellow
    Write-Host ""
    foreach ($item in $advancedItems) {
        $p = Expand-CleanPath $item.Path
        $estBytes = Get-FolderSize -Path $p
        $sizeZh = if ($estBytes -gt 0) { Format-Size $estBytes } else { (Get-Text "dc_size_varies") }
        Write-Host "  ────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host ("  {0}  ({1} {2})" -f (Get-Field -Obj $item -Base "Name"), (Get-Text "dc_free_approx"), $sizeZh) -ForegroundColor White
        Write-Host ("        {0}" -f (Get-Field -Obj $item -Base "Desc")) -ForegroundColor Gray
        Write-Host ("        {0}" -f (Get-Field -Obj $item -Base "Note")) -ForegroundColor Yellow
        Write-Host ("        " + (Get-Text "dc_rec_noclean")) -ForegroundColor DarkCyan

        $choice = Read-Choice -ValidKeys @("Y", "N", "Q") -Labels @{ Y = (Get-Text "dc_btn_clean"); N = (Get-Text "dc_btn_skip"); Q = (Get-Text "grp_btn_end") } -DefaultKey "N"
        if ($choice -eq "Q") { Write-Host ("  " + (Get-Text "dc_ended")) -ForegroundColor Gray; break }
        if ($choice -eq "Y") {
            $freed = Invoke-CleanItem -Item $item
            $totalFreed += $freed
            $cleanedList += (Get-Field -Obj $item -Base "Name")
            Write-Log -Message ("已清理 (進階):" + $item.Id) -Level OK -Module $ModuleId -Item (Get-Field -Obj $item -Base "Name")
        }
    }
}

# ============================================================
#  摘要
# ============================================================
Write-Host ""
Write-Host "  ========================================" -ForegroundColor Cyan
Write-Host ("    " + (Get-Text "exec_summary") + " - " + $ModuleTitle) -ForegroundColor Cyan
Write-Host "  ========================================" -ForegroundColor Cyan
Write-Host ("  " + (Get-Text "dc_summary_cleaned") + " : " + $cleanedList.Count) -ForegroundColor Green
foreach ($n in $cleanedList) { Write-Host ("    [v] {0}" -f $n) -ForegroundColor Green }
if ($totalFreed -gt 0) {
    Write-Host ("  " + (Get-Text "dc_summary_freed") + " " + (Format-Size $totalFreed)) -ForegroundColor Cyan
    Write-Host ("  " + (Get-Text "dc_summary_note")) -ForegroundColor DarkGray
}
