<#
.SYNOPSIS
    Windows 11 設定精靈 - 模組 02:App 權限管理 (App Permissions)

.DESCRIPTION
    動態掃描型。掃描 CapabilityAccessManager\ConsentStore 下各權限的當前狀態,
    逐一顯示並詢問是否關閉。只管 Windows 商店 (UWP) 應用程式,與第三方
    (Win32) 桌面程式無關。

    因權限預設全為開啟,選單簡化為兩項:關閉 (Deny) / 維持開啟 (Allow)。
    依需求關閉才是修改的原因,有需要的自然保持開啟。

    現況讀取:HKCU 的 ConsentStore Value (對應設定 UI 的實際開關)。
    寫入:HKCU\...\ConsentStore\{權限}\Value = Allow / Deny。

    掃描邏輯為本模組專屬,不污染通用引擎;複用 Read-Choice / Get-Text / Write-Log。

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

$ModuleId    = "02_AppPermissions"
$ModuleTitle = Get-Text "cat_02"   # App 權限管理

# ============================================================
#  載入對照表
# ============================================================
$kbFile = Join-Path $Global:DataPath "kb_02_AppPermissions.psd1"
if (-not (Test-Path $kbFile)) {
    Write-Host ""
    Write-Host ("  " + (Get-Text "err_kb_notfound") + $kbFile) -ForegroundColor Red
    return
}
$kb    = Import-PowerShellDataFile -Path $kbFile
$perms = @($kb.Perms)

# 對照表轉為 hash,方便用資料夾名快速查中文
$permMap = @{}
foreach ($p in $perms) { $permMap[$p.Key] = $p }

$consentHKCU = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore"
$consentHKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore"

# ============================================================
#  類別說明
# ============================================================
Write-Host ""
Write-Host "  ══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   $ModuleTitle" -ForegroundColor Cyan
Write-Host "  ══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host ("  " + (Get-Text "ap_intro_1")) -ForegroundColor Gray
Write-Host ("  " + (Get-Text "ap_intro_2")) -ForegroundColor Gray
Write-Host ""
Write-Host ("  " + (Get-Text "ap_scanning")) -ForegroundColor Gray

# ============================================================
#  掃描:HKLM + HKCU 兩層合併去重,取得完整權限清單
# ============================================================
function Get-ConsentKeys {
    param([string]$Base)
    if (-not (Test-Path $Base)) { return @() }
    return @(Get-ChildItem -Path $Base -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PSChildName)
}
# 讀某層某權限的 Value (讀不到回 $null)
function Get-ConsentValue {
    param([string]$Base, [string]$Key)
    $p = Join-Path $Base $Key
    if (-not (Test-Path $p)) { return $null }
    return (Get-ItemProperty -Path $p -Name "Value" -ErrorAction SilentlyContinue).Value
}

$hkcuKeys = Get-ConsentKeys -Base $consentHKCU
$hklmKeys = Get-ConsentKeys -Base $consentHKLM
$allKeys  = @($hkcuKeys + $hklmKeys | Sort-Object -Unique)

if ($allKeys.Count -eq 0) {
    Write-Host ("  " + (Get-Text "ap_no_data")) -ForegroundColor Yellow
    return
}

$candidates = @()
foreach ($key in $allKeys) {
    # 現況:HKCU 優先,沒有才看 HKLM;都沒有視為 Allow (預設開)
    $cur = Get-ConsentValue -Base $consentHKCU -Key $key
    if ([string]::IsNullOrEmpty($cur)) { $cur = Get-ConsentValue -Base $consentHKLM -Key $key }
    if ([string]::IsNullOrEmpty($cur)) { $cur = "Allow" }

    $info = $permMap[$key]
    if ($info) {
        $nameZh = $info.NameZh
        $descZh = $info.DescZh
        $nameEn = if ($info.ContainsKey("NameEn")) { $info.NameEn } else { $info.NameZh }
        $descEn = if ($info.ContainsKey("DescEn")) { $info.DescEn } else { $info.DescZh }
        $rec    = if ($info.Recommend) { $info.Recommend } else { "open" }
        $known  = $true
    }
    else {
        $nameZh = $key   # 未收錄:顯示原始資料夾名
        $descZh = (Get-Text "ap_unknown_perm")
        $nameEn = $key
        $descEn = (Get-Text "ap_unknown_perm")
        $rec    = "open"  # 未收錄預設建議開啟 (保守)
        $known  = $false
    }

    $candidates += [pscustomobject]@{
        Key       = $key
        NameZh    = $nameZh
        NameEn    = $nameEn
        DescZh    = $descZh
        DescEn    = $descEn
        CurVal    = $cur       # Allow / Deny / Prompt
        Recommend = $rec       # open / close
        Known     = $known
    }
}

# 排序:已收錄的排前 (有中文名) → 未收錄的排後 → 同組依中文名
$candidates = @($candidates | Sort-Object `
    @{ Expression = { if ($_.Known) { 0 } else { 1 } } }, `
    @{ Expression = { $_.NameZh } })

Write-Host ("  " + (Get-Text "ap_scan_done" -Args @($candidates.Count))) -ForegroundColor Gray
Write-Host ""

# ============================================================
#  逐一詢問 (三選項:關閉 / 開啟 / 維持,Enter 跟隨建議)
# ============================================================
# 寫入 HKCU 的 ConsentStore Value (Allow/Deny),無資料夾自動建立
function Set-PermValue {
    param([string]$Key, [string]$Value)
    $target = Join-Path $consentHKCU $Key
    if (-not (Test-Path $target)) {
        New-Item -Path $target -Force -ErrorAction Stop | Out-Null
    }
    Set-ItemProperty -Path $target -Name "Value" -Value $Value -Type String -Force -ErrorAction Stop
}

$closed  = @()   # 已關閉
$opened  = @()   # 已開啟
$nochange = @()  # 已是目標狀態,未變更
$i = 0
while ($i -lt $candidates.Count) {
    $item = $candidates[$i]
    $curZh = switch ($item.CurVal) {
        "Allow"  { (Get-Text "ap_state_on") }
        "Deny"   { (Get-Text "ap_state_off") }
        "Prompt" { (Get-Text "ap_state_prompt") }
        default  { $item.CurVal }
    }
    $tag = if ($item.Known) { "" } else { (Get-Text "ap_tag_unknown") }

    # 建議 → 預設鍵 (1=關閉、2=開啟) 與提示文字
    $recIsClose = ($item.Recommend -eq "close")
    $defKey = if ($recIsClose) { "1" } else { "2" }
    $recHint = if ($recIsClose) { (Get-Text "ap_rec_close") }
               else            { (Get-Text "ap_rec_open") }

    Write-Host "  ────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ("  [{0}/{1}] {2}{3}" -f ($i + 1), $candidates.Count, (Get-Field -Obj $item -Base "Name"), $tag) -ForegroundColor White
    Write-Host ("        {0}" -f (Get-Field -Obj $item -Base "Desc")) -ForegroundColor Gray
    Write-Host ("        " + (Get-Text "ap_current") + ":" + $curZh) -ForegroundColor DarkGray
    Write-Host ("        {0}" -f $recHint) -ForegroundColor $(if ($recIsClose) { "Yellow" } else { "DarkCyan" })

    # 1=關閉 / 2=開啟 / 3=維持 / P=上一步 / Q=結束。Enter 跟隨建議
    $validKeys = if ($i -gt 0) { @("1", "2", "3", "P", "Q") } else { @("1", "2", "3", "Q") }
    $labels = @{ "1" = (Get-Text "ap_btn_close"); "2" = (Get-Text "ap_btn_open"); "3" = (Get-Text "ap_btn_keep"); P = (Get-Text "grp_btn_prev"); Q = (Get-Text "grp_btn_end") }
    $choice = Read-Choice -ValidKeys $validKeys -Labels $labels -DefaultKey $defKey

    if ($choice -eq "Q") { Write-Host ("  " + (Get-Text "ap_ended")) -ForegroundColor Gray; break }
    if ($choice -eq "P") { if ($i -gt 0) { $i-- }; continue }
    if ($choice -eq "3") { $i++; continue }   # 維持

    # 目標值:1→Deny(關)、2→Allow(開)
    $targetVal = if ($choice -eq "1") { "Deny" } else { "Allow" }

    # 已是目標狀態則不動作
    if ($item.CurVal -eq $targetVal) {
        $stateZh = if ($targetVal -eq "Deny") { (Get-Text "ap_state_off") } else { (Get-Text "ap_state_on") }
        Write-Host ("        " + (Get-Text "ap_already" -Args @($stateZh))) -ForegroundColor DarkGray
        $nochange += ((Get-Field -Obj $item -Base "Name") + " (" + (Get-Text "ap_already_short" -Args @($stateZh)) + ")")
        $i++
        continue
    }
    try {
        Set-PermValue -Key $item.Key -Value $targetVal
        if ($targetVal -eq "Deny") {
            Write-Host ("        " + (Get-Text "ap_closed_ok")) -ForegroundColor Green
            $closed += ((Get-Field -Obj $item -Base "Name") + ":" + $curZh + " → " + (Get-Text "ap_sum_to_close"))
        }
        else {
            Write-Host ("        " + (Get-Text "ap_opened_ok")) -ForegroundColor Green
            $opened += ((Get-Field -Obj $item -Base "Name") + ":" + $curZh + " → " + (Get-Text "ap_sum_to_open"))
        }
        Write-Log -Message ("權限 {0} → {1}" -f $item.Key, $targetVal) -Level OK -Module $ModuleId -Item (Get-Field -Obj $item -Base "Name")
    }
    catch {
        Write-Host ("        " + (Get-Text "ap_set_failed") + $_.Exception.Message) -ForegroundColor Red
        Write-Log -Message ("權限設定失敗:" + $_.Exception.Message) -Level FAIL -Module $ModuleId -Item (Get-Field -Obj $item -Base "Name")
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
Write-Host ("  " + (Get-Text "ap_sum_closed") + " : " + $closed.Count) -ForegroundColor Green
foreach ($c in $closed) { Write-Host ("    [v] {0}" -f $c) -ForegroundColor Green }
Write-Host ("  " + (Get-Text "ap_sum_opened") + " : " + $opened.Count) -ForegroundColor Green
foreach ($o in $opened) { Write-Host ("    [v] {0}" -f $o) -ForegroundColor Green }
if ($nochange.Count -gt 0) {
    Write-Host ("  " + (Get-Text "ap_sum_nochange") + " : " + $nochange.Count) -ForegroundColor Gray
    foreach ($n in $nochange) { Write-Host ("    [-] {0}" -f $n) -ForegroundColor DarkGray }
}
if ($closed.Count -gt 0 -or $opened.Count -gt 0) {
    Write-Host ""
    Write-Host ("  " + (Get-Text "ap_remind_1")) -ForegroundColor DarkCyan
    Write-Host ("  " + (Get-Text "ap_remind_2")) -ForegroundColor DarkGray
}
