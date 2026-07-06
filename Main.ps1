<#
.SYNOPSIS
    Windows 11 設定精靈 (Win11Tweaker) - 主控流程 Main.ps1

.DESCRIPTION
    模組化互動式 Windows 11 優化工具的進入點。
    負責:載入引擎 → 選語言 → 初始化系統資訊/設定檔名 → 主選單 → 依模式執行 14 類。

    兩種模式:
      完整模式 - 14 類依序全跑 (逐題,Enter 跟隨建議)
      自訂模式 - 自選模組執行,執行後回自訂選單可繼續挑,Q 返回主選單

    啟動方式 (繞過 PowerShell 執行原則):
      powershell -ExecutionPolicy Bypass -File .\Main.ps1

.NOTES
    專案:dincht55/Win11Tweaker   授權:MIT
#>

# ============================================================
#  載入共用引擎
# ============================================================
$Global:CommonLoaded = $false
. (Join-Path $PSScriptRoot "Common.ps1")

# ============================================================
#  14 類模組清單 (依執行順序;檔名去掉 .ps1 與 kb 對應)
#  Id = 模組檔名主體;TitleKey = 語言鍵
# ============================================================
$Modules = @(
    @{ Num = 1;  File = "01_Privacy";           TitleKey = "cat_01" }
    @{ Num = 2;  File = "02_AppPermissions";    TitleKey = "cat_02" }
    @{ Num = 3;  File = "03_AI";                TitleKey = "cat_03" }
    @{ Num = 4;  File = "04_AppBehavior";       TitleKey = "cat_04" }
    @{ Num = 5;  File = "05_Personalize";       TitleKey = "cat_05" }
    @{ Num = 6;  File = "06_Network";           TitleKey = "cat_06" }
    @{ Num = 7;  File = "07_Hardware";          TitleKey = "cat_07" }
    @{ Num = 8;  File = "08_VisualPerformance"; TitleKey = "cat_08" }
    @{ Num = 9;  File = "09_Security";          TitleKey = "cat_09" }
    @{ Num = 10; File = "10_ScheduledTasks";    TitleKey = "cat_10" }
    @{ Num = 11; File = "11_Services";          TitleKey = "cat_11" }
    @{ Num = 12; File = "12_SystemBehavior";    TitleKey = "cat_12" }
    @{ Num = 13; File = "13_PreinstalledApps";  TitleKey = "cat_13" }
    @{ Num = 14; File = "14_DiskCleanup";       TitleKey = "cat_14" }
)

# ============================================================
#  執行單一模組 (點載入;引擎已載入,模組不會重載)
# ============================================================
function Invoke-Module {
    param([Parameter(Mandatory)][hashtable]$Mod)
    $path = Join-Path $Global:ModulesPath ($Mod.File + ".ps1")
    if (-not (Test-Path $path)) {
        Write-Host ((Get-Text "main_err_notfound") + $path) -ForegroundColor Red
        return
    }
    try {
        . $path
    }
    catch {
        Write-Host ((Get-Text "main_err_failed") + $_.Exception.Message) -ForegroundColor Red
        Write-Log -Message ("模組執行失敗:" + $_.Exception.Message) -Level FAIL -Module $Mod.File
    }
}

# ============================================================
#  完整模式:14 類依序全跑
# ============================================================
function Start-FullMode {
    Write-Host ""
    Write-Host "  ══════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ("   " + (Get-Text "main_full_title")) -ForegroundColor Cyan
    Write-Host "  ══════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ("  " + (Get-Text "main_full_hint")) -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host ("  " + (Get-Text "main_full_start")) -ForegroundColor Gray
    $go = Read-Choice -ValidKeys @("1", "Q") -Labels @{ "1" = (Get-Text "main_btn_start") } -DefaultKey "1"
    if ($go -eq "Q") { return }

    foreach ($mod in $Modules) {
        $title = Get-Text $mod.TitleKey
        Write-Host ""
        Write-Host ("  ▶ [{0}/14] {1}" -f $mod.Num, $title) -ForegroundColor Yellow
        Invoke-Module -Mod $mod
    }

    Write-Host ""
    Write-Host "  ══════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ("   " + (Get-Text "main_full_done")) -ForegroundColor Green
    Write-Host "  ══════════════════════════════════════════════" -ForegroundColor Green
}

# ============================================================
#  自訂模式:選號執行,執行後回本選單,Q 返回主選單
# ============================================================
function Start-CustomMode {
    while ($true) {
        Write-Host ""
        Write-Host "  ══════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ("   " + (Get-Text "main_custom_title")) -ForegroundColor Cyan
        Write-Host "  ══════════════════════════════════════════════" -ForegroundColor Cyan
        foreach ($mod in $Modules) {
            $title = Get-Text $mod.TitleKey
            Write-Host ("  [{0,2}] {1}" -f $mod.Num, $title) -ForegroundColor White
        }
        Write-Host "  ────────────────────────────────────────" -ForegroundColor DarkCyan
        Write-Host ("  " + (Get-Text "main_custom_hint")) -ForegroundColor Gray

        $validKeys = @(); foreach ($m in $Modules) { $validKeys += "$($m.Num)" }
        $validKeys += "Q"
        $choice = Read-Choice -ValidKeys $validKeys -Labels @{ Q = (Get-Text "main_btn_backmenu") }

        if ($choice -eq "Q") { return }

        $sel = $Modules | Where-Object { "$($_.Num)" -eq $choice } | Select-Object -First 1
        if ($sel) {
            $title = Get-Text $sel.TitleKey
            Write-Host ""
            Write-Host ("  ▶ " + (Get-Text "main_run_prefix") + $title) -ForegroundColor Yellow
            Invoke-Module -Mod $sel
            Write-Host ""
            Write-Host ("  " + (Get-Text "main_custom_back")) -ForegroundColor DarkCyan
        }
    }
}

# ============================================================
#  語言選擇
# ============================================================
# ============================================================
#  語言選擇改用 Common.ps1 的共用 Select-Language 函式
#  (Main / Reset / Restore 三支共用,單一來源)
# ============================================================

# ============================================================
#  歡迎橫幅 + 執行原則/免責說明
# ============================================================
function Show-Welcome {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host ("  " + (Get-Text "main_welcome_name")) -ForegroundColor Cyan
    Write-Host ("  " + (Get-Text "main_welcome_sub")) -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host ("  " + (Get-Text "main_welcome_1")) -ForegroundColor Gray
    Write-Host ("  " + (Get-Text "main_welcome_2")) -ForegroundColor Gray
    Write-Host ("  " + (Get-Text "main_welcome_3")) -ForegroundColor Gray
    Write-Host ""
    Write-Host ("  " + (Get-Text "main_disclaimer_1")) -ForegroundColor DarkGray
    Write-Host ("  " + (Get-Text "main_disclaimer_2")) -ForegroundColor DarkGray
}

# ============================================================
#  主選單迴圈
# ============================================================
function Start-MainMenu {
    while ($true) {
        Write-Host ""
        Write-Host "  ══════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ("   " + (Get-Text "main_menu_title")) -ForegroundColor Cyan
        Write-Host "  ══════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ("  [1] " + (Get-Text "main_menu_full")) -ForegroundColor White
        Write-Host ("  [2] " + (Get-Text "main_menu_custom")) -ForegroundColor White
        Write-Host ("  [Q] " + (Get-Text "main_menu_quit")) -ForegroundColor White
        Write-Host "  ────────────────────────────────────────" -ForegroundColor DarkCyan

        $choice = Read-Choice -ValidKeys @("1", "2", "Q") -DefaultKey "2"
        switch ($choice) {
            "1" { Start-FullMode }
            "2" { Start-CustomMode }
            "Q" {
                Write-Host ""
                Write-Host ("  " + (Get-Text "main_bye")) -ForegroundColor Cyan
                return
            }
        }
    }
}

# ============================================================
#  進入點
# ============================================================
Select-Language        # 先選語言並載入語言檔,後續 Get-Text 才有內容
Show-Welcome
Initialize-SystemInfo  | Out-Null
Initialize-ProfileName | Out-Null
Start-MainMenu
