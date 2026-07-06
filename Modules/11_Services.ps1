<#
.SYNOPSIS
    Windows 11 設定精靈 - 模組 12:不必要服務 (Services)

.DESCRIPTION
    動態掃描架構 (同 14 預裝軟體)。Get-CimInstance 掃出實機所有服務,逐一顯示
    並詢問啟動類型。服務因人而異,一問一設定,絕不整組套用。

    三層處理:
      1. Essential (必要服務黑名單) → 隱藏,杜絕誤停核心服務
      2. KnownServices (對照表)      → 顯示中文名 + 建議 + 說明
      3. 其餘                        → 顯示服務顯示名 + 系統描述,預設維持

    每服務四選項:停用(4) / 手動(3) / 自動(2) / 維持。多數建議「手動」
    (需要時仍能被觸發啟動,比停用安全)。設定寫入登錄檔 Start 值,重開機生效。

    掃描邏輯為本模組專屬,不污染通用引擎;複用 Set-ServiceStartType / Read-Choice
    / Get-Text / Write-Log 等輔助。

.NOTES
    作者:dincht55 (DCT)   授權:MIT
#>

# ============================================================
#  載入共用引擎
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

$ModuleId    = "11_Services"
$ModuleTitle = Get-Text "cat_11"   # 不必要服務

# ============================================================
#  載入知識庫
# ============================================================
$kbFile = Join-Path $Global:DataPath "kb_11_Services.psd1"
if (-not (Test-Path $kbFile)) {
    Write-Host ""
    Write-Host ("  " + (Get-Text "err_kb_notfound") + $kbFile) -ForegroundColor Red
    return
}
$kb            = Import-PowerShellDataFile -Path $kbFile
$essential     = @($kb.Essential)        # 必要服務黑名單
$knownServices = @($kb.KnownServices)     # 對照表

# 啟動類型數字 → 中文
$startTypeZh = @{ 2 = (Get-Text "sv_state_auto"); 3 = (Get-Text "sv_state_manual"); 4 = (Get-Text "sv_state_disable") }
# Win32_Service.StartMode 字串 → 數字
$startModeToNum = @{ "Auto" = 2; "Manual" = 3; "Disabled" = 4; "Boot" = 0; "System" = 1 }

# ============================================================
#  輔助函式
# ============================================================

# 是否為必要服務 (黑名單精確比對,不分大小寫)
function Test-IsEssentialService {
    param([string]$Name)
    foreach ($e in $essential) {
        if ($Name -ieq $e) { return $true }
    }
    return $false
}

# 依服務名找對照表 (精確比對,不分大小寫);找不到回 $null
function Get-KnownServiceInfo {
    param([string]$Name)
    foreach ($info in $knownServices) {
        if ($Name -ieq $info.Match) { return $info }
    }
    return $null
}

# ============================================================
#  類別說明
# ============================================================
Write-Host ""
Write-Host "  ══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   $ModuleTitle" -ForegroundColor Cyan
Write-Host "  ══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host ("  " + (Get-Text "sv_intro_1")) -ForegroundColor Gray
Write-Host ("  " + (Get-Text "sv_intro_2")) -ForegroundColor Gray
Write-Host ("  " + (Get-Text "sv_intro_3")) -ForegroundColor DarkGray
Write-Host ""
Write-Host ("  " + (Get-Text "sv_scanning")) -ForegroundColor Gray

# ============================================================
#  掃描並分類
# ============================================================
$allSvc = @(Get-CimInstance -ClassName Win32_Service -ErrorAction SilentlyContinue)

$candidates = @()
foreach ($svc in $allSvc) {
    $name = $svc.Name

    # 過濾 1:必要服務黑名單 → 隱藏
    if (Test-IsEssentialService -Name $name) { continue }

    # 過濾 2:非「使用者可管理」的服務類型 → 隱藏
    # Boot/System 層級 (StartMode Boot/System) 是核心驅動類,不該給一般使用者動。
    if ($svc.StartMode -eq "Boot" -or $svc.StartMode -eq "System") { continue }

    $curNum = if ($startModeToNum.ContainsKey($svc.StartMode)) { $startModeToNum[$svc.StartMode] } else { 3 }

    $info = Get-KnownServiceInfo -Name $name
    if (-not $info) { continue }   # 白名單:未收錄的服務一律不顯示 (服務停錯後果嚴重)

    $candidates += [pscustomobject]@{
        Name        = $name
        DisplayName   = $info.NameZh
        DisplayNameEn = if ($info.ContainsKey("NameEn")) { $info.NameEn } else { $info.NameZh }
        Recommend   = $info.Recommend      # disable/manual/auto/keep
        Note        = $info.Note
        NoteEn      = if ($info.ContainsKey("NoteEn")) { $info.NoteEn } else { $info.Note }
        CurNum      = $curNum
        Known       = $true
    }
}

# 排序:依建議動作分組 (可調整的排前) → 同組依名稱
$recOrder = @{ "disable" = 0; "manual" = 1; "auto" = 2; "keep" = 3 }
$candidates = @($candidates | Sort-Object `
    @{ Expression = { if ($recOrder.ContainsKey($_.Recommend)) { $recOrder[$_.Recommend] } else { 9 } } }, `
    @{ Expression = { $_.DisplayName } })

Write-Host ("  " + (Get-Text "sv_scan_done" -Args @($candidates.Count))) -ForegroundColor Gray
Write-Host ""

# ============================================================
#  逐一詢問 (四選項:停用/手動/自動/維持,預設跟隨建議)
# ============================================================
$results   = @()   # 真正變更 (原≠新)
$unchanged = @()   # 已是建議設定 (原=新,雖執行但值未變)
$protected = @()   # 受系統保護,需特殊權限,已略過
$failed    = @()   # 其他原因設定失敗
$i = 0
while ($i -lt $candidates.Count) {
    $item = $candidates[$i]
    $curZh = if ($startTypeZh.ContainsKey($item.CurNum)) { $startTypeZh[$item.CurNum] } else { (Get-Text "sv_state_manual") }

    # 建議 → 預設鍵對應
    $recKey = switch ($item.Recommend) {
        "disable" { "1" }
        "manual"  { "2" }
        "auto"    { "3" }
        default   { "4" }   # keep
    }
    $recZh = switch ($item.Recommend) {
        "disable" { (Get-Text "sv_rec_disable") }
        "manual"  { (Get-Text "sv_rec_manual") }
        "auto"    { (Get-Text "sv_rec_auto") }
        default   { "建議維持現狀" }
    }
    Write-Host "  ────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ("  [{0}/{1}] {2}" -f ($i + 1), $candidates.Count, (Get-Field -Obj $item -Base "DisplayName")) -ForegroundColor White
    Write-Host ("        " + (Get-Text "sv_svcname") + ":" + $item.Name + "  " + (Get-Text "sv_current") + ":" + $curZh) -ForegroundColor DarkGray
    Write-Host ("        " + (Get-Field -Obj $item -Base "Note")) -ForegroundColor Gray
    Write-Host ("        → " + $recZh + " " + (Get-Text "sv_enter_hint")) -ForegroundColor DarkCyan

    $validKeys = if ($i -gt 0) { @("1", "2", "3", "4", "P", "Q") } else { @("1", "2", "3", "4", "Q") }
    $labels = @{ "1" = (Get-Text "sv_btn_disable"); "2" = (Get-Text "sv_btn_manual"); "3" = (Get-Text "sv_btn_auto"); "4" = (Get-Text "sv_btn_keep"); P = (Get-Text "grp_btn_prev"); Q = (Get-Text "grp_btn_end") }
    $choice = Read-Choice -ValidKeys $validKeys -Labels $labels -DefaultKey $recKey

    if ($choice -eq "Q") { Write-Host ("  " + (Get-Text "sv_ended")) -ForegroundColor Gray; break }
    if ($choice -eq "P") { if ($i -gt 0) { $i-- }; continue }

    if ($choice -eq "4") {
        # 維持現狀,不動作
        $i++
        continue
    }

    # 1/2/3 → 對應 StartType 4/3/2
    $targetNum = switch ($choice) { "1" { 4 } "2" { 3 } "3" { 2 } }
    $res = Set-ServiceStartType -ServiceName $item.Name -StartType $targetNum
    if ($res.Success) {
        $oldZh = if ($startTypeZh.ContainsKey($item.CurNum)) { $startTypeZh[$item.CurNum] } else { (Get-Text "sv_state_manual") }
        $newZh = $startTypeZh[$targetNum]
        if ($item.CurNum -eq $targetNum) {
            # 原本就是此設定,值未變 → 歸「已是此設定」
            Write-Host ("        " + (Get-Text "sv_already" -Args @($newZh))) -ForegroundColor DarkGray
            $unchanged += ("{0} ({1})" -f (Get-Field -Obj $item -Base "DisplayName"), $newZh)
        }
        else {
            Write-Host ("        " + (Get-Text "sv_set_ok" -Args @($newZh, $oldZh))) -ForegroundColor Green
            $results += ("{0}:{1} → {2}" -f (Get-Field -Obj $item -Base "DisplayName"), $oldZh, $newZh)
            Write-Log -Message ("服務 {0}:{1} → {2}" -f $item.Name, $oldZh, $newZh) -Level OK -Module $ModuleId -Item (Get-Field -Obj $item -Base "DisplayName")
        }
    }
    elseif ($res.Unsupported) {
        Write-Host ("        " + (Get-Text "sv_not_exist")) -ForegroundColor DarkGray
    }
    else {
        # 判斷是否為「存取被拒」類 (微軟對部分服務設了專屬保護,只允許
        # TrustedInstaller 修改,連系統管理員都不行)。這類優雅略過,不強行提權。
        if ($res.Message -match "(?i)(access is denied|access denied|存取被拒|拒絕存取)") {
            Write-Host ("        " + (Get-Text "sv_protected")) -ForegroundColor Yellow
            $protected += (Get-Field -Obj $item -Base "DisplayName")
            Write-Log -Message ("服務受保護略過:" + $item.Name) -Level WARN -Module $ModuleId -Item (Get-Field -Obj $item -Base "DisplayName")
        }
        else {
            Write-Host ("        " + (Get-Text "sv_set_failed") + $res.Message) -ForegroundColor Red
            $failed += ("{0} ({1})" -f (Get-Field -Obj $item -Base "DisplayName"), $res.Message)
            Write-Log -Message ("服務設定失敗:" + $res.Message) -Level FAIL -Module $ModuleId -Item (Get-Field -Obj $item -Base "DisplayName")
        }
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
Write-Host ("  " + (Get-Text "sv_sum_changed") + " : " + $results.Count) -ForegroundColor Green
foreach ($r in $results) { Write-Host ("    [v] {0}" -f $r) -ForegroundColor Green }
if ($unchanged.Count -gt 0) {
    Write-Host ("  " + (Get-Text "sv_sum_unchanged") + " : " + $unchanged.Count) -ForegroundColor Gray
    foreach ($u in $unchanged) { Write-Host ("    [-] {0}" -f $u) -ForegroundColor DarkGray }
}
if ($protected.Count -gt 0) {
    Write-Host ("  " + (Get-Text "sv_sum_protected") + " : " + $protected.Count) -ForegroundColor Yellow
    foreach ($p in $protected) { Write-Host ("    [!] {0}" -f $p) -ForegroundColor Yellow }
    Write-Host ("    " + (Get-Text "sv_sum_protected_note")) -ForegroundColor DarkGray
}
if ($failed.Count -gt 0) {
    Write-Host ("  " + (Get-Text "sv_sum_failed") + " : " + $failed.Count) -ForegroundColor Red
    foreach ($f in $failed) { Write-Host ("    [x] {0}" -f $f) -ForegroundColor Red }
}
if ($results.Count -gt 0) {
    Write-Host ""
    Write-Host ("  " + (Get-Text "sv_remind_1")) -ForegroundColor DarkCyan
    Write-Host ("  " + (Get-Text "sv_remind_2")) -ForegroundColor DarkGray
}
