<#
.SYNOPSIS
    Windows 11 設定精靈 - 模組 14:預裝軟體 (Preinstalled Apps)

.DESCRIPTION
    與其他類不同:動態掃描實機安裝的 Appx,逐一顯示移除建議並詢問是否移除。
    流程:
      1. Get-AppxPackage 掃出目前使用者所有 App。
      2. 依 kb_14 對照表分三層:
         - SystemCritical → 隱藏 (杜絕誤刪系統元件)
         - KnownApps      → 顯示中文名 + 移除建議
         - 其餘           → 顯示原始名 + 標「未收錄,自行判斷」,預設保留
      3. 逐一詢問移除 (Remove-AppxPackage,只移除目前使用者)。
      4. 移除清單記錄於設定檔;移除的 App 多數可日後從 Microsoft Store 重裝。

    掃描邏輯為本模組專屬 (其他類用不到),不污染通用引擎;僅複用引擎的
    Get-Text / Write-Log / Read-Choice / ProfileName 等輔助。

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

$ModuleId    = "13_PreinstalledApps"
$ModuleTitle = Get-Text "cat_13"   # 預裝軟體

# ============================================================
#  載入對照表知識庫
# ============================================================
$kbFile = Join-Path $Global:DataPath "kb_13_PreinstalledApps.psd1"
if (-not (Test-Path $kbFile)) {
    Write-Host ""
    Write-Host ("  " + (Get-Text "err_kb_notfound") + $kbFile) -ForegroundColor Red
    return
}
$kb             = Import-PowerShellDataFile -Path $kbFile
$systemCritical = @($kb.SystemCritical)   # 黑名單字串陣列
$knownApps      = @($kb.KnownApps)         # 對照表
$win32Excluded  = @($kb.Win32Excluded)     # Win32 排除清單 (Edge 系列等)

# ============================================================
#  輔助函式 (本模組專屬)
# ============================================================

# 判斷某 App Name 是否命中黑名單 (含子字串,不分大小寫)
function Test-IsSystemCritical {
    param([string]$AppName)
    foreach ($pat in $systemCritical) {
        if ($AppName -like "*$pat*") { return $true }
    }
    return $false
}

# 依 App Name 找對照表項目 (子字串比對);找不到回 $null
function Get-KnownAppInfo {
    param([string]$AppName)
    foreach ($info in $knownApps) {
        if ($AppName -like "*$($info.Match)*") { return $info }
    }
    return $null
}

# 讀取套件在開始選單顯示的正常名稱 (從 AppxManifest 的 DisplayName)。
# 讀不到或為佔位字串則回空字串。用於判斷是否為可辨識的一般 App。
function Get-AppFriendlyName {
    param($AppPackage)
    try {
        $manifest = Get-AppxPackageManifest -Package $AppPackage.PackageFullName -ErrorAction Stop
        $dn = $manifest.Package.Properties.DisplayName
        # DisplayName 可能是資源字串 (ms-resource:...),那種取不到真名 → 視為無效
        if ([string]::IsNullOrWhiteSpace($dn) -or $dn -like "ms-resource:*") { return "" }
        return $dn
    }
    catch { return "" }
}

# 判斷「未收錄」的套件是否為可辨識的一般 App (白名單特徵)。
# 只有看起來像正常 App 的才顯示,GUID 命名/無正常顯示名/系統元件模式一律隱藏。
function Test-IsRecognizableApp {
    param($AppPackage)
    $name = $AppPackage.Name

    # 1. GUID 命名 (如 1527c705-839a-...) → 系統元件,隱藏
    if ($name -match '^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-') { return $false }

    # 2. 常見系統元件名稱模式 → 隱藏 (通則,不需窮舉黑名單)
    $sysPatterns = @(
        "OOBE", "CaptivePortal", "PinningConfirmation", "PrintDialog", "PrintQueue",
        "immersivecontrolpanel", "BioEnrollment", "ParentalControls", "AssignedAccess",
        "SecureAssessment", "AsyncTextService", "Apprep", "XGpuEject", "UndockedDevKit",
        "Client.FileExp", "Client.OOBE", "Client.Photon", "Client.CBS", "Client.Core",
        "CallingShellApp", "CapturePicker", "NarratorQuickStart", "PeopleExperienceHost",
        "Wallet", "AAD.Broker", "CloudExperienceHost", "CredDialog", "Win32WebViewHost"
    )
    foreach ($p in $sysPatterns) {
        if ($name -like "*$p*") { return $false }
    }

    # 3. 亂碼型名稱 (MicrosoftWindows.數字.縮寫,如 .57242383.Tasbar) → 系統元件,隱藏
    if ($name -match '^MicrosoftWindows\.\d+\.') { return $false }

    # 4. 必須讀得到正常顯示名,才算可辨識的一般 App
    $friendly = Get-AppFriendlyName -AppPackage $AppPackage
    if ([string]::IsNullOrWhiteSpace($friendly)) { return $false }

    return $true
}

# ============================================================
#  類別說明
# ============================================================
Write-Host ""
Write-Host "  ══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   $ModuleTitle" -ForegroundColor Cyan
Write-Host "  ══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host ("  " + (Get-Text "pa_scanning")) -ForegroundColor Gray

# ============================================================
#  掃描並分類
# ============================================================
# 只掃目前使用者、非系統框架的主要 App (NonRemovable 為系統標記者也略過)
$allApps = @(Get-AppxPackage | Where-Object { -not $_.IsFramework })

$candidates = @()   # 要顯示給使用者的項目 (已排除系統關鍵)
foreach ($app in $allApps) {
    if (Test-IsSystemCritical -AppName $app.Name) { continue }   # 系統關鍵 → 隱藏

    $info = Get-KnownAppInfo -AppName $app.Name
    if ($info) {
        $candidates += [pscustomobject]@{
            Type            = "appx"
            PackageFullName = $app.PackageFullName
            DisplayName     = $info.NameZh
            DisplayNameEn   = if ($info.ContainsKey("NameEn")) { $info.NameEn } else { $info.NameZh }
            RawName         = $app.Name
            UninstallString = ""
            Recommend       = $info.Recommend      # remove / keep
            Note            = $info.Note
            NoteEn          = if ($info.ContainsKey("NoteEn")) { $info.NoteEn } else { $info.Note }
            Known           = $true
        }
    }
    else {
        # 未收錄:先過濾,只有可辨識的一般 App 才顯示 (GUID/系統元件隱藏)
        if (-not (Test-IsRecognizableApp -AppPackage $app)) { continue }

        # 用套件真正的顯示名 (讀得到才會通過上面的過濾)
        $friendly = Get-AppFriendlyName -AppPackage $app
        $candidates += [pscustomobject]@{
            Type            = "appx"
            PackageFullName = $app.PackageFullName
            DisplayName     = $friendly
            DisplayNameEn   = $friendly
            RawName         = $app.Name
            UninstallString = ""
            Recommend       = "keep"
            Note            = (Get-Text "pa_unknown_appx")
            NoteEn          = (Get-Text "pa_unknown_appx")
            Known           = $false
        }
    }
}

# ------------------------------------------------------------
#  掃描 Win32 傳統程式 (登錄檔 Uninstall 鍵)
#  Edge、Office、OEM 工具、第三方軟體等非 Appx 程式都在這裡。
#  移除方式:執行程式自己的 UninstallString (原生移除精靈)。
# ------------------------------------------------------------
$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
$seenNames = @{}   # 去重 (同程式可能在多路徑出現)
foreach ($path in $uninstallPaths) {
    $entries = @(Get-ItemProperty -Path $path -ErrorAction SilentlyContinue)
    foreach ($e in $entries) {
        $dn = $e.DisplayName
        # 過濾:須有顯示名、須有移除指令、排除系統修補與更新
        if ([string]::IsNullOrWhiteSpace($dn)) { continue }
        if ([string]::IsNullOrWhiteSpace($e.UninstallString)) { continue }
        if ($e.SystemComponent -eq 1) { continue }                    # 系統元件
        if ($null -ne $e.ParentKeyName) { continue }                  # 更新修補的子項
        if ($dn -match 'KB\d{6,}') { continue }                       # 安全更新 (KBxxxxxx)
        if ($dn -match '(?i)(update for|hotfix|安全性更新|修補程式)') { continue }
        # 受系統保護/相依過深、實際移不掉的程式 (Edge 系列) → 跳過,不給假選項
        $excluded = $false
        foreach ($ex in $win32Excluded) {
            if ($dn -like "*$ex*") { $excluded = $true; break }
        }
        if ($excluded) { continue }
        if ($seenNames.ContainsKey($dn)) { continue }
        $seenNames[$dn] = $true

        # Win32 一律歸「未收錄、建議保留」(不代大眾判斷第三方程式該不該移)
        $candidates += [pscustomobject]@{
            Type            = "win32"
            PackageFullName = ""
            DisplayName     = $dn
            DisplayNameEn   = $dn
            RawName         = $dn
            UninstallString = $e.UninstallString
            Recommend       = "keep"
            Note            = (Get-Text "pa_win32_note")
            NoteEn          = (Get-Text "pa_win32_note")
            Known           = $false
        }
    }
}

# 排序:建議移除的排前面 (known+remove) → 已知保留 → 未知/Win32
# 用 @() 強制為陣列 (Sort-Object 回單一元素時會變成非陣列,導致 .Count 為空)
$candidates = @($candidates | Sort-Object `
    @{ Expression = { if ($_.Recommend -eq "remove") { 0 } else { 1 } } }, `
    @{ Expression = { if ($_.Known) { 0 } else { 1 } } }, `
    @{ Expression = { if ($_.Type -eq "appx") { 0 } else { 1 } } }, `
    @{ Expression = { $_.DisplayName } })

$appxCount  = @($candidates | Where-Object { $_.Type -eq "appx" }).Count
$win32Count = @($candidates | Where-Object { $_.Type -eq "win32" }).Count
Write-Host ("  " + (Get-Text "pa_scan_done" -Args @($candidates.Count, $appxCount, $win32Count))) -ForegroundColor Gray
Write-Host ""

# ============================================================
#  逐一詢問移除
#  - 預設動作跟隨建議 (直接按 Enter = 照建議做),降低反直覺
#  - 支援 [P] 上一步 (回退並撤銷該項先前記錄的決定)
#  - 每項決定記錄於 $decisions,方便回退時修正
# ============================================================
$decisions = @{}   # index -> "removed"/"kept"/"failed" (供回退時撤銷)

$i = 0
while ($i -lt $candidates.Count) {
    $item = $candidates[$i]
    $isRemoveRec = ($item.Recommend -eq "remove")
    $recZh = if ($isRemoveRec) { (Get-Text "pa_rec_remove") } else { (Get-Text "pa_rec_keep") }
    $typeZh = if ($item.Type -eq "win32") { (Get-Text "pa_type_win32") } elseif (-not $item.Known) { (Get-Text "pa_type_appx_unknown") } else { (Get-Text "pa_type_appx") }
    $tag = " [$typeZh]"

    Write-Host "  ────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ("  [{0}/{1}] {2}{3}" -f ($i + 1), $candidates.Count, (Get-Field -Obj $item -Base "DisplayName"), $tag) -ForegroundColor White
    Write-Host ("        " + (Get-Field -Obj $item -Base "Note")) -ForegroundColor Gray

    # 兩選項數字選單:[1]移除 [2]保留。建議項標「(建議)」並上綠色,Enter 跟隨建議。
    # 預設鍵:建議移除→1、建議保留→2
    $defKey    = if ($isRemoveRec) { "1" } else { "2" }
    $rmMark    = if ($isRemoveRec) { (Get-Text "pa_mark_rec") } else { "" }
    $keepMark  = if ($isRemoveRec) { "" } else { (Get-Text "pa_mark_rec") }
    $rmColor   = if ($isRemoveRec) { "Green" } else { "White" }
    $keepColor = if ($isRemoveRec) { "White" } else { "Green" }
    Write-Host ("        [1] " + (Get-Text "pa_btn_remove") + $rmMark)   -ForegroundColor $rmColor
    Write-Host ("        [2] " + (Get-Text "pa_btn_keep") + $keepMark) -ForegroundColor $keepColor

    $validKeys = if ($i -gt 0) { @("1", "2", "P", "Q") } else { @("1", "2", "Q") }
    $labels    = @{ "1" = (Get-Text "pa_btn_remove"); "2" = (Get-Text "pa_btn_keep"); P = (Get-Text "grp_btn_prev"); Q = (Get-Text "grp_btn_end") }

    $choice = Read-Choice -ValidKeys $validKeys -Labels $labels -DefaultKey $defKey

    if ($choice -eq "Q") {
        Write-Host ("  " + (Get-Text "pa_ended")) -ForegroundColor Gray
        break
    }
    elseif ($choice -eq "P") {
        # 上一步:撤銷上一項的決定記錄 (注意:已移除的無法復原,僅撤銷清單記錄並提醒)
        $prev = $i - 1
        if ($decisions.ContainsKey($prev)) {
            $prevItem = $candidates[$prev]
            switch ($decisions[$prev]) {
                "removed" {
                    $removedList = @($removedList | Where-Object { $_ -ne (Get-Field -Obj $prevItem -Base "DisplayName") })
                    Write-Host ("  " + (Get-Text "pa_prev_removed" -Args @((Get-Field -Obj $prevItem -Base "DisplayName")))) -ForegroundColor Yellow
                }
                "kept"   { $keptList   = @($keptList   | Where-Object { $_ -ne (Get-Field -Obj $prevItem -Base "DisplayName") }) }
                "failed" { $failedList = @($failedList | Where-Object { $_ -ne (Get-Field -Obj $prevItem -Base "DisplayName") }) }
            }
            $decisions.Remove($prev)
        }
        $i = $prev
        continue
    }
    elseif ($choice -eq "1") {
        if ($item.Type -eq "appx") {
            # Appx:直接移除 (乾淨、當前使用者)
            try {
                Get-AppxPackage -Name $item.RawName -ErrorAction Stop |
                    Remove-AppxPackage -ErrorAction Stop
                $removedList += (Get-Field -Obj $item -Base "DisplayName")
                $decisions[$i] = "removed"
                Write-Host ("        " + (Get-Text "pa_removed_ok" -Args @((Get-Field -Obj $item -Base "DisplayName")))) -ForegroundColor Green
                Write-Log -Message ("已移除 (Appx):" + $item.RawName) -Level OK -Module $ModuleId -Item (Get-Field -Obj $item -Base "DisplayName")
            }
            catch {
                $failedList += (Get-Field -Obj $item -Base "DisplayName")
                $decisions[$i] = "failed"
                Write-Host ("        " + (Get-Text "pa_remove_failed") + $_.Exception.Message) -ForegroundColor Red
                Write-Log -Message ("移除失敗:" + $_.Exception.Message) -Level FAIL -Module $ModuleId -Item (Get-Field -Obj $item -Base "DisplayName")
            }
        }
        else {
            # Win32:執行程式自己的解除安裝精靈 (UninstallString)。
            # 使用者需在跳出的精靈中手動完成;我們只負責啟動它。
            Write-Host ("        " + (Get-Text "pa_uninstall_wizard")) -ForegroundColor Yellow
            try {
                # UninstallString 常見形式:"C:\...\uninst.exe" 或 MsiExec.exe /X{GUID}
                # 用 cmd /c 啟動最通用,能處理帶引號與參數的字串。
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $item.UninstallString -Wait -ErrorAction Stop
                $removedList += (Get-Field -Obj $item -Base "DisplayName")
                $decisions[$i] = "removed"
                Write-Host ("        " + (Get-Text "pa_uninstall_started" -Args @((Get-Field -Obj $item -Base "DisplayName")))) -ForegroundColor Green
                Write-Log -Message ("已啟動 Win32 解除安裝:" + (Get-Field -Obj $item -Base "DisplayName")) -Level OK -Module $ModuleId -Item (Get-Field -Obj $item -Base "DisplayName")
            }
            catch {
                $failedList += (Get-Field -Obj $item -Base "DisplayName")
                $decisions[$i] = "failed"
                Write-Host ("        " + (Get-Text "pa_uninstall_failed") + $_.Exception.Message) -ForegroundColor Red
                Write-Log -Message ("Win32 解除安裝失敗:" + $_.Exception.Message) -Level FAIL -Module $ModuleId -Item (Get-Field -Obj $item -Base "DisplayName")
            }
        }
    }
    elseif ($choice -eq "2") {
        # 2 = 保留
        $keptList += (Get-Field -Obj $item -Base "DisplayName")
        $decisions[$i] = "kept"
    }
    $i++
}

# ============================================================
#  摘要
# ============================================================
Write-Host ""
Write-Host "  ========================================" -ForegroundColor Cyan
Write-Host ("    " + (Get-Text "exec_summary") + " - " + $ModuleTitle) -ForegroundColor Cyan
Write-Host "  ========================================" -ForegroundColor Cyan
Write-Host ("  " + (Get-Text "pa_sum_removed") + " : " + $removedList.Count) -ForegroundColor Green
foreach ($n in $removedList) { Write-Host ("    [v] {0}" -f $n) -ForegroundColor Green }
Write-Host ("  " + (Get-Text "pa_sum_kept") + " : " + $keptList.Count) -ForegroundColor Gray
Write-Host ("  " + (Get-Text "pa_sum_failed") + " : " + $failedList.Count) -ForegroundColor $(if ($failedList.Count) { "Red" } else { "Gray" })
foreach ($n in $failedList) { Write-Host ("    [x] {0}" -f $n) -ForegroundColor Red }

if ($removedList.Count -gt 0) {
    Write-Host ""
    Write-Host ("  " + (Get-Text "pa_remind")) -ForegroundColor DarkCyan
}

# ============================================================
#  匯出設定檔 (記錄移除清單)
# ============================================================
$profileData = [ordered]@{
    Profile   = $Global:ProfileName
    Module    = $ModuleId
    Timestamp = (Get-Date -Format "yyyyMMdd_HHmmss")
    Removed   = $removedList
    Kept      = $keptList
    Failed    = $failedList
}
$outDir  = Join-Path $Global:ConfigPath ""
if (-not (Test-Path $outDir)) { New-Item -Path $outDir -ItemType Directory -Force | Out-Null }
$outName = "{0}_{1}_{2}.json" -f $Global:ProfileName, $ModuleId, $profileData.Timestamp
$outPath = Join-Path $Global:ConfigPath $outName
$profileData | ConvertTo-Json -Depth 5 | Out-File -FilePath $outPath -Encoding UTF8
Write-Host ""
Write-Host ("  " + (Get-Text "pa_config_exported")) -ForegroundColor Gray
Write-Host ("    {0}" -f $outPath) -ForegroundColor Gray
