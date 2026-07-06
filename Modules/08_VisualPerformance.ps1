<#
.SYNOPSIS
    Windows 11 設定精靈 - 模組 09:視覺與效能 (Visual & Performance)

.DESCRIPTION
    分組型 (group)。視覺效果代價一致、通常一起調,適合整組套用。
    每個群組提供:效能優先 / 外觀優先 / 展開個別調整 / 維持。
    整組套用用 VisualFXSetting (Windows 官方一鍵開關);展開個別項用獨立鍵。
    設定項由 Data\kb_08_VisualPerformance.psd1 提供,呼叫 Common 的 Show-Group 引擎。

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

$ModuleId    = "08_VisualPerformance"
$ModuleTitle = Get-Text "cat_08"   # 視覺與效能

# ============================================================
#  載入知識庫
# ============================================================
$kbFile = Join-Path $Global:DataPath "kb_08_VisualPerformance.psd1"
if (-not (Test-Path $kbFile)) {
    Write-Host ""
    Write-Host ("  " + (Get-Text "err_kb_notfound") + $kbFile) -ForegroundColor Red
    return
}
$kb     = Import-PowerShellDataFile -Path $kbFile
$groups = @($kb.Groups)

# ============================================================
#  標題與類別說明
# ============================================================
Write-Host ""
Write-Host "  ══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   $ModuleTitle" -ForegroundColor Cyan
Write-Host "  ══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host ("  " + (Get-Text "about_08_1")) -ForegroundColor Gray
Write-Host ("  " + (Get-Text "about_08_2")) -ForegroundColor Gray

# ============================================================
#  逐群組呼叫 Show-Group 引擎
# ============================================================
$totalApplied = 0
$allResults   = @()
for ($g = 0; $g -lt $groups.Count; $g++) {
    $r = Show-Group -Group $groups[$g] -GroupIndex ($g + 1) -GroupTotal $groups.Count `
                    -ModuleId $ModuleId -ModuleTitle $ModuleTitle
    if ($r.Quit) { Write-Host ("  " + (Get-Text "vfx_ended")) -ForegroundColor Gray; break }
    $totalApplied += $r.Applied
    $allResults   += $r.Results
}

# ============================================================
#  摘要
# ============================================================
Write-Host ""
Write-Host "  ========================================" -ForegroundColor Cyan
Write-Host ("    " + (Get-Text "exec_summary") + " - " + $ModuleTitle) -ForegroundColor Cyan
Write-Host "  ========================================" -ForegroundColor Cyan
Write-Host ("  " + (Get-Text "vfx_applied") + " : " + $totalApplied) -ForegroundColor Green
foreach ($r in $allResults) { Write-Host ("    [v] {0}" -f $r) -ForegroundColor Green }
if ($totalApplied -gt 0) {
    Write-Host ""
    Write-Host ("  " + (Get-Text "vfx_remind_1")) -ForegroundColor DarkCyan
    Write-Host ("  " + (Get-Text "vfx_remind_2")) -ForegroundColor DarkCyan
    Write-Host ("  " + (Get-Text "vfx_remind_3")) -ForegroundColor DarkGray
}
