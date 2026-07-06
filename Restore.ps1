<#
.SYNOPSIS
    Windows 11 設定精靈 - 還原工具 (Restore Tool)

.DESCRIPTION
    救回先前被「刪除登錄檔值」操作移除的項目。
    流程:列出 Restore 資料夾內的還原檔 → 選擇 → 逐項寫回登錄檔 → 驗證。

    安全原則:若某個值「目前已存在」,自動略過不覆蓋 (只補回缺少的值),
    避免蓋掉使用者後來自行設定的內容。

.NOTES
    作者:dincht55 (DCT)   授權:MIT
    用法:於專案根目錄執行 powershell -ExecutionPolicy Bypass -File .\Restore.ps1
#>

# ============================================================
#  載入共用引擎
# ============================================================
$standalone = $false
if (-not $Global:CommonLoaded) {
    . (Join-Path $PSScriptRoot "Common.ps1")
    $standalone = $true
}
if ($standalone) {
    Select-Language   # 單獨執行:讓使用者選語言 (共用函式)
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ("  " + (Get-Text "restore_title")) -ForegroundColor Cyan
Write-Host ("  " + (Get-Text "restore_subtitle")) -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan

# ============================================================
#  列出可用還原檔 (依時間新到舊)
# ============================================================
$files = @(Get-ChildItem -Path $Global:RestorePath -Filter "*_restore_*.json" -ErrorAction SilentlyContinue |
           Sort-Object LastWriteTime -Descending)

if ($files.Count -eq 0) {
    Write-Host ""
    Write-Host ("  " + (Get-Text "restore_no_files")) -ForegroundColor Yellow
    return
}

Write-Host ""
Write-Host ("  " + (Get-Text "restore_available") + ":") -ForegroundColor White
for ($i = 0; $i -lt $files.Count; $i++) {
    Write-Host ("  [" + ($i + 1) + "] " + $files[$i].Name) -ForegroundColor Gray
}
Write-Host "  [Q] " -NoNewline -ForegroundColor Gray
Write-Host (Get-Text "hint_q") -ForegroundColor Gray
Write-Host "────────────────────────────────────" -ForegroundColor DarkCyan

# ============================================================
#  選擇還原檔 (輸入編號或 Q)
# ============================================================
$selected = $null
while ($true) {
    Write-Host ("  " + (Get-Text "restore_select") + " > ") -NoNewline -ForegroundColor White
    $inp = (Read-Host).Trim()

    if ($inp.ToUpper() -eq "Q") { return }

    $num = 0
    if ([int]::TryParse($inp, [ref]$num) -and $num -ge 1 -and $num -le $files.Count) {
        $selected = $files[$num - 1]
        break
    }
    Write-Host ("  " + (Get-Text "restore_invalid")) -ForegroundColor Red
}

# ============================================================
#  讀取還原檔內容
# ============================================================
try {
    $data = Get-Content -Path $selected.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
}
catch {
    Write-Host ("  讀取還原檔失敗:" + $_.Exception.Message) -ForegroundColor Red
    return
}

$deleted = @($data.deleted)
if ($deleted.Count -eq 0) {
    Write-Host ("  此還原檔內沒有可還原的項目。") -ForegroundColor Yellow
    return
}

# ============================================================
#  顯示將還原的項目 + 確認
# ============================================================
Write-Host ""
Write-Host ("  " + (Get-Text "restore_will_title") + ":") -ForegroundColor White
foreach ($d in $deleted) {
    Write-Host ("    - " + $d.Path + "\" + $d.Name) -ForegroundColor Gray
}
Write-Host ""
Write-Host ("  " + (Get-Text "restore_will_note")) -ForegroundColor Yellow
Write-Host "────────────────────────────────────" -ForegroundColor DarkCyan

$c = Read-Choice -ValidKeys @("Y", "N") -Labels @{
    Y = (Get-Text "restore_confirm_yes")
    N = (Get-Text "restore_confirm_no")
}
if ($c -eq "N") {
    Write-Host ("  " + (Get-Text "restore_cancelled")) -ForegroundColor DarkYellow
    return
}

# ============================================================
#  執行還原 (已存在則略過,不覆蓋)
# ============================================================
$restored = @(); $skipped = @(); $failed = @()

foreach ($d in $deleted) {
    # 檢查該值是否已存在
    $exists = $false
    if (Test-Path $d.Path) {
        $p = Get-ItemProperty -Path $d.Path -Name $d.Name -ErrorAction SilentlyContinue
        if ($p -and ($p.PSObject.Properties.Name -contains $d.Name)) { $exists = $true }
    }

    if ($exists) {
        # 已存在 → 略過,不覆蓋 (保護使用者現有設定)
        $skipped += ($d.Path + "\" + $d.Name)
        continue
    }

    # 不存在 → 寫回原值
    try {
        if (-not (Test-Path $d.Path)) {
            New-Item -Path $d.Path -Force -ErrorAction Stop | Out-Null
        }
        Set-ItemProperty -Path $d.Path -Name $d.Name -Value $d.Value -Type $d.Type -Force -ErrorAction Stop

        # 讀回驗證
        $chk = Get-ItemProperty -Path $d.Path -Name $d.Name -ErrorAction SilentlyContinue
        if ($chk -and ($chk.PSObject.Properties.Name -contains $d.Name)) {
            $restored += ($d.Path + "\" + $d.Name)
        }
        else {
            $failed += ($d.Path + "\" + $d.Name)
        }
    }
    catch {
        $failed += ($d.Path + "\" + $d.Name)
    }
}

# ============================================================
#  還原結果摘要
# ============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ("  " + (Get-Text "restore_summary_title")) -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-SummaryLine -Label (Get-Text "restore_res_restored") -Names $restored -Color Green      -Symbol "[v]"
Write-SummaryLine -Label (Get-Text "restore_res_skipped")  -Names $skipped  -Color DarkYellow -Symbol "[-]"
Write-SummaryLine -Label (Get-Text "restore_res_failed")   -Names $failed   -Color Red        -Symbol "[x]"
Write-Host ""
Write-Host ("  " + (Get-Text "restore_finished")) -ForegroundColor Green
