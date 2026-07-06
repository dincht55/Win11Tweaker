<#
.SYNOPSIS
    Windows 11 設定精靈 - 共用函式庫 (Common Engine)

.DESCRIPTION
    提供所有模組共用的核心功能:
    - 語言載入 (Language Loading)
    - 日誌系統 (Logging)
    - 錯誤處理 (Error Handling)
    - 寫入驗證 (Verification)
    - 版本偵測 (Version / Support Detection)
    - 提問引擎 (Interactive Prompt - 逐題 / 分組)
    - 斷點續傳 (Resume / Progress)
    - 設定檔匯出 / 載入 (Config Export / Import)

.NOTES
    專案:Windows 11 設定精靈
    作者:dincht55 (DCT)
    授權:MIT
    設計原則:易讀易改、執行效率高、多語言/多版本相容
#>

# ============================================================
#  全域變數與路徑
# ============================================================

# 專案根目錄 = Common.ps1 自己所在的資料夾
# 用 $MyInvocation.MyCommand.Path 抓「本檔 (Common.ps1) 的真實路徑」,
# 不受呼叫端影響:不論單獨執行模組或由 Main.ps1 點載入,都正確指向專案根目錄。
$Global:CommonFile = $MyInvocation.MyCommand.Path
if (-not $Global:CommonFile) { $Global:CommonFile = $PSCommandPath }
$Global:RootPath = Split-Path -Parent $Global:CommonFile

$Global:ModulesPath  = Join-Path $Global:RootPath "Modules"
$Global:DataPath     = Join-Path $Global:RootPath "Data"
$Global:LangPath     = Join-Path $Global:RootPath "Lang"
$Global:ConfigPath   = Join-Path $Global:RootPath "Config"
$Global:ProgressPath = Join-Path $Global:RootPath "Progress"
$Global:ReportsPath  = Join-Path $Global:RootPath "Reports"
$Global:RestorePath  = Join-Path $Global:RootPath "Restore"   # 刪除登錄檔值的還原備份

# 確保必要目錄存在
foreach ($p in @($Global:ConfigPath, $Global:ProgressPath, $Global:ReportsPath, $Global:RestorePath)) {
    if (-not (Test-Path $p)) {
        New-Item -Path $p -ItemType Directory -Force | Out-Null
    }
}

# 語言字典 (載入後填入)
$Global:Lang = @{}

# 目前設定檔識別名稱 (使用者輸入)
$Global:ProfileName = ""

# 目前執行的日誌檔路徑
$Global:CurrentLogFile = ""

# 目前系統資訊 (啟動時偵測一次)
$Global:SystemInfo = $null

# 需要重開機的旗標
$Global:RebootRequired = $false


# ============================================================
#  語言載入 (Language)
# ============================================================

<#
.SYNOPSIS
    載入指定語言檔,填入 $Global:Lang 字典。
.PARAMETER LangCode
    語言代碼:zh-TW / en / ja
#>
function Import-Language {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("zh-TW", "en")]
        [string]$LangCode
    )

    $langFile = Join-Path $Global:LangPath "lang_$LangCode.psd1"

    if (-not (Test-Path $langFile)) {
        Write-Host "[警告] 找不到語言檔:$langFile,改用繁體中文。" -ForegroundColor Yellow
        $langFile = Join-Path $Global:LangPath "lang_zh-TW.psd1"
        $LangCode = "zh-TW"
    }

    try {
        $Global:Lang = Import-PowerShellDataFile -Path $langFile
        $Global:Lang["_code"] = $LangCode
        $Global:CurrentLang = $LangCode   # 供 Get-Field 判斷選用哪個語言欄位
        return $true
    }
    catch {
        Write-Host "[錯誤] 語言檔載入失敗:$($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

<#
.SYNOPSIS
    語言選擇 (共用):讓使用者選繁中/英文並載入對應語言檔。
    Main / Reset / Restore 等進入點共用此函式,確保語言選擇邏輯單一來源。
.NOTES
    先載入預設繁中,確保 Read-Choice 內部訊息 (輸入錯誤提示) 有內容。
    選項標題與各語言選項刻意用「自己的語言」呈現,方便使用者辨識。
#>
function Select-Language {
    Import-Language "zh-TW" | Out-Null   # 先載入預設繁中,確保提示有內容
    Write-Host ""
    Write-Host "  ══════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "   Language / 語言" -ForegroundColor Cyan
    Write-Host "  ══════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  [1] 繁體中文 (台灣)" -ForegroundColor White
    Write-Host "  [2] English" -ForegroundColor White
    switch (Read-Choice -ValidKeys @("1", "2") -DefaultKey "1") {
        "1" { Import-Language "zh-TW" | Out-Null }
        "2" { Import-Language "en"    | Out-Null }
    }
}

<#
.SYNOPSIS
    依當前語言,從 kb 物件取對應語言的文字欄位 (雙語欄位機制)。
    繁中用 <Base>Zh、英文用 <Base>En;缺英文欄位則 fallback 中文。
.PARAMETER Obj
    含雙語欄位的 hashtable (如 kb 的 Item / Choice)
.PARAMETER Base
    欄位基底名 (如 "Name" → NameZh/NameEn;"Desc"、"Notes"、"Label")
.OUTPUTS
    字串 (對應語言的文字);兩者皆無回空字串
#>
function Get-Field {
    param(
        [Parameter(Mandatory)]$Obj,
        [Parameter(Mandatory)][string]$Base
    )
    $isEn  = ($Global:CurrentLang -eq "en")
    $isDict = ($Obj -is [System.Collections.IDictionary])
    $zhKey = "${Base}Zh"
    $enKey = "${Base}En"

    if ($isEn) {
        # 英文:優先 En 欄位,缺則 fallback 中文
        if ($isDict) {
            if ($Obj.Contains($enKey) -and $Obj[$enKey]) { return $Obj[$enKey] }
            if ($Obj.Contains($zhKey)) { return $Obj[$zhKey] }
        }
        else {
            if ($Obj.PSObject.Properties[$enKey] -and $Obj.$enKey) { return $Obj.$enKey }
            if ($Obj.PSObject.Properties[$zhKey]) { return $Obj.$zhKey }
        }
    }
    else {
        if ($isDict) { if ($Obj.Contains($zhKey)) { return $Obj[$zhKey] } }
        else         { if ($Obj.PSObject.Properties[$zhKey]) { return $Obj.$zhKey } }
    }
    # 特例:Label 這類單一欄位 (無 Zh 後綴) 的相容處理
    if ($isDict) { if ($Obj.Contains($Base)) { return $Obj[$Base] } }
    else         { if ($Obj.PSObject.Properties[$Base]) { return $Obj.$Base } }
    return ""
}

<#
.SYNOPSIS
    取得語言字串。找不到 key 時回傳 key 本身(方便除錯)。
.PARAMETER Key
    語言字典的鍵值
.PARAMETER Args
    格式化參數 (對應字串內的 {0} {1} ...)
#>
function Get-Text {
    param(
        [Parameter(Mandatory)]
        [string]$Key,
        [object[]]$Args = @()
    )

    if ($Global:Lang.ContainsKey($Key)) {
        $text = $Global:Lang[$Key]
        if ($Args.Count -gt 0) {
            return ($text -f $Args)
        }
        return $text
    }
    # 找不到就回傳 key,方便發現缺翻譯
    return "[$Key]"
}


# ============================================================
#  系統資訊偵測 (System Info)
# ============================================================

<#
.SYNOPSIS
    偵測目前 Windows 版本資訊,存入 $Global:SystemInfo。
    只在啟動時呼叫一次。
#>
function Initialize-SystemInfo {
    $os = Get-CimInstance Win32_OperatingSystem
    $cv = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue

    $Global:SystemInfo = [PSCustomObject]@{
        Caption      = $os.Caption                        # 例:Microsoft Windows 11 Pro
        Version      = $os.Version                        # 例:10.0.26200
        BuildNumber  = [int]$os.BuildNumber               # 例:26200
        DisplayVer   = $cv.DisplayVersion                 # 例:25H2
        UBR          = $cv.UBR                            # Update Build Revision
        Edition      = $cv.EditionID                      # 例:Professional
        Is64Bit      = [Environment]::Is64BitOperatingSystem
    }

    return $Global:SystemInfo
}

<#
.SYNOPSIS
    判斷目前系統 Build 是否符合最低需求。
.PARAMETER MinBuild
    最低 Build 號 (例:26100 表示需要 24H2 以上)。0 表示不限。
#>
function Test-BuildSupported {
    param([int]$MinBuild = 0)

    if ($MinBuild -le 0) { return $true }
    return ($Global:SystemInfo.BuildNumber -ge $MinBuild)
}

<#
.SYNOPSIS
    判斷目前 Windows 版本 (Edition) 是否符合白名單。
.PARAMETER EditionOnly
    允許的 EditionID 陣列 (例:@("Enterprise","Education","ServerStandard"))。
    空陣列或 $null 視為不限。
.NOTES
    常見 EditionID:
      Core                     = Windows 11 Home
      Professional             = Windows 11 Pro
      ProfessionalWorkstation  = Windows 11 Pro for Workstations
      ProfessionalEducation    = Windows 11 Pro Education
      Enterprise               = Windows 11 Enterprise
      EnterpriseS              = Windows 11 Enterprise LTSC
      Education                = Windows 11 Education
      ServerStandard / ServerDatacenter (Windows Server 系列)
    以 $Global:SystemInfo.Edition 對照白名單,精確字串比對。
#>
function Test-EditionSupported {
    param([string[]]$EditionOnly = @())

    if (-not $EditionOnly -or $EditionOnly.Count -eq 0) { return $true }
    return ($Global:SystemInfo.Edition -in $EditionOnly)
}


# ============================================================
#  日誌系統 (Logging)
# ============================================================

<#
.SYNOPSIS
    開始一個新的執行日誌,建立日誌檔。
.PARAMETER Scope
    執行範圍名稱 (例:All / 01_Privacy)
#>
function Start-ExecutionLog {
    param([string]$Scope = "All")

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $fileName  = "Execution_${Scope}_${timestamp}.log"
    $Global:CurrentLogFile = Join-Path $Global:ReportsPath $fileName

    $header = @(
        "========================================",
        "  Windows 11 設定精靈 - 執行日誌",
        "========================================",
        "開始時間 : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "執行範圍 : $Scope",
        "設定檔名 : $Global:ProfileName",
        "系統版本 : $($Global:SystemInfo.Caption) $($Global:SystemInfo.DisplayVer) (Build $($Global:SystemInfo.BuildNumber).$($Global:SystemInfo.UBR))",
        "========================================",
        ""
    )
    $header | Out-File -FilePath $Global:CurrentLogFile -Encoding UTF8

    return $Global:CurrentLogFile
}

<#
.SYNOPSIS
    寫一行日誌 (同時可選擇是否顯示於畫面)。
.PARAMETER Message
    訊息內容
.PARAMETER Level
    層級:INFO / OK / SKIP / FAIL / WARN / UNSUPPORT
.PARAMETER Module
    模組名稱
.PARAMETER Item
    項目名稱
#>
function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet("INFO", "OK", "SKIP", "FAIL", "WARN", "UNSUPPORT")]
        [string]$Level = "INFO",
        [string]$Module = "",
        [string]$Item = ""
    )

    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # 組合日誌行
    $prefix = "[$time]"
    if ($Module) { $prefix += " [$Module]" }
    if ($Item)   { $prefix += " [$Item]" }

    $symbol = switch ($Level) {
        "OK"        { "OK  " }
        "SKIP"      { "SKIP" }
        "FAIL"      { "FAIL" }
        "WARN"      { "WARN" }
        "UNSUPPORT" { "N/A " }
        default     { "INFO" }
    }

    $line = "$prefix [$symbol] $Message"

    # 寫入檔案
    if ($Global:CurrentLogFile) {
        Add-Content -Path $Global:CurrentLogFile -Value $line -Encoding UTF8
    }
}


# ============================================================
#  斷點續傳 (Progress / Resume)
# ============================================================

<#
.SYNOPSIS
    取得進度檔路徑。
#>
function Get-ProgressFile {
    return (Join-Path $Global:ProgressPath "Progress.json")
}

<#
.SYNOPSIS
    儲存目前進度 (每答一題即時呼叫)。
.PARAMETER Data
    進度資料 (hashtable)
#>
function Save-Progress {
    # 用 IDictionary 同時接受一般 hashtable 與有序字典 (ordered),
    # 避免有序字典被強制轉型為 hashtable 而失去欄位順序。
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Data)

    $file = Get-ProgressFile
    $Data["last_update"] = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

    try {
        $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $file -Encoding UTF8
        return $true
    }
    catch {
        Write-Log -Message "進度儲存失敗:$($_.Exception.Message)" -Level FAIL
        return $false
    }
}

<#
.SYNOPSIS
    讀取進度檔。無檔案回傳 $null。
#>
function Read-Progress {
    $file = Get-ProgressFile
    if (-not (Test-Path $file)) { return $null }

    try {
        $json = Get-Content -Path $file -Raw -Encoding UTF8
        return ($json | ConvertFrom-Json)
    }
    catch {
        return $null
    }
}

<#
.SYNOPSIS
    清除進度檔 (完成或使用者選擇重新開始時)。會先備份。
#>
function Clear-Progress {
    $file = Get-ProgressFile
    if (Test-Path $file) {
        $backup = Join-Path $Global:ProgressPath "Progress_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        Move-Item -Path $file -Destination $backup -Force -ErrorAction SilentlyContinue
    }
}


# ============================================================
#  寫入與驗證 (Apply & Verify)
# ============================================================

<#
.SYNOPSIS
    讀取一個登錄檔值;路徑或值不存在時回傳 $null (不丟例外)。
    供「判斷目前狀態」比對用。
.OUTPUTS
    值本身 (型別依登錄檔),或 $null (不存在)
#>
function Get-RegistryValueOrNull {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name
    )
    if (-not (Test-Path $Path)) { return $null }
    $prop = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
    if ($null -eq $prop -or -not ($prop.PSObject.Properties.Name -contains $Name)) { return $null }
    return $prop.$Name
}

<#
.SYNOPSIS
    套用一個登錄檔設定,並讀回驗證。
.PARAMETER Path
    登錄檔路徑 (如 HKLM:\SOFTWARE\...)
.PARAMETER Name
    值名稱
.PARAMETER Value
    要寫入的值
.PARAMETER Type
    值型別:DWord / String / QWord / Binary
.OUTPUTS
    hashtable: @{ Success=$true/$false; Message="..." }
#>
function Set-RegistryValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [ValidateSet("DWord", "String", "QWord", "Binary", "ExpandString")]
        [string]$Type = "DWord"
    )

    try {
        # 路徑不存在則建立
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
        }

        # 寫入
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop

        # 讀回驗證
        $readback = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name
        if ($readback -eq $Value) {
            return @{ Success = $true; Message = "驗證成功 (值=$readback)" }
        }
        else {
            return @{ Success = $false; Message = "驗證不符 (期望=$Value 實際=$readback)" }
        }
    }
    catch {
        return @{ Success = $false; Message = $_.Exception.Message }
    }
}

<#
.SYNOPSIS
    刪除一個登錄檔值 (非修改值),刪除前先讀取原值供還原。
    用於「停止開機自啟」等需移除 Run 項目的情境。
.PARAMETER Path
    登錄檔路徑
.PARAMETER Name
    要刪除的值名稱
.OUTPUTS
    hashtable: @{ Success; Message; Backup }
      Backup = @{ Path; Name; Value; Type }  (供還原;若值本不存在則為 $null)
#>
function Remove-RegistryValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name
    )

    # 路徑不存在 → 視為已達成 (沒有東西可刪)
    if (-not (Test-Path $Path)) {
        return @{ Success = $true; Message = "路徑不存在,無需刪除"; Backup = $null }
    }

    # 值不存在 → 視為已達成
    $prop = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
    if ($null -eq $prop -or -not ($prop.PSObject.Properties.Name -contains $Name)) {
        return @{ Success = $true; Message = "值不存在,無需刪除"; Backup = $null }
    }

    # 讀取現值與型別 (供還原重建)
    $value = $prop.$Name
    try {
        $kind = (Get-Item -Path $Path).GetValueKind($Name).ToString()  # DWord / String / ...
    } catch {
        $kind = "String"
    }

    try {
        Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction Stop

        # 驗證已刪除
        $check = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        if ($null -eq $check -or -not ($check.PSObject.Properties.Name -contains $Name)) {
            return @{
                Success = $true
                Message = "已刪除 (已備份可還原)"
                Backup  = @{ Path = $Path; Name = $Name; Value = $value; Type = $kind }
            }
        }
        else {
            return @{ Success = $false; Message = "刪除後仍存在"; Backup = $null }
        }
    }
    catch {
        return @{ Success = $false; Message = $_.Exception.Message; Backup = $null }
    }
}

<#
.SYNOPSIS
    以登錄檔方式停用/啟用服務 (改 Start 值,重開後生效)。
    比 Stop-Service 更能對付受保護服務。
.PARAMETER ServiceName
    服務名稱 (英文識別碼,如 DiagTrack)
.PARAMETER StartType
    4=停用 / 3=手動 / 2=自動
#>
function Set-ServiceStartType {
    param(
        [Parameter(Mandatory)][string]$ServiceName,
        [ValidateSet(2, 3, 4)]
        [int]$StartType = 4
    )

    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName"

    # 先確認服務存在 (登錄檔機碼存在即可)
    if (-not (Test-Path $regPath)) {
        return @{ Success = $false; Message = "服務不存在於此系統"; Unsupported = $true }
    }

    # StartType 數字 → Set-Service 啟動類型字串
    $stMap = @{ 2 = "Automatic"; 3 = "Manual"; 4 = "Disabled" }
    $stName = $stMap[$StartType]

    try {
        # 走服務控制管理員 (SCM) 設定,可修改直接寫登錄檔會被 ACL 拒絕的受保護服務
        # (如 TrkWks)。Set-Service 是 PowerShell 內建、走正規通道,權限與相容性最佳。
        Set-Service -Name $ServiceName -StartupType $stName -ErrorAction Stop

        # 讀回登錄檔 Start 值驗證 (SCM 設定後會反映在此)
        $readback = (Get-ItemProperty -Path $regPath -Name "Start" -ErrorAction SilentlyContinue).Start
        if ($null -eq $readback) {
            # 讀不到值但 Set-Service 未拋錯,視為成功 (少數服務讀回受限)
            return @{ Success = $true; Message = "已設定 ($stName,重開後生效)" }
        }
        if ($readback -eq $StartType) {
            return @{ Success = $true; Message = "驗證成功 (Start=$readback,重開後生效)" }
        }
        return @{ Success = $false; Message = "驗證不符 (期望=$StartType 實際=$readback)" }
    }
    catch {
        return @{ Success = $false; Message = $_.Exception.Message }
    }
}

<#
.SYNOPSIS
    停用排程工作。
.PARAMETER TaskPath
    排程路徑 (如 \Microsoft\Windows\Maps\)
.PARAMETER TaskName
    排程名稱 (可選,不給則停用整個路徑下所有)
#>
function Set-ScheduledTaskState {
    <#
    .SYNOPSIS
        設定排程工作的啟用狀態 (支援雙向:停用或啟用)。
    .PARAMETER TaskPath
        排程路徑 (如 \Microsoft\Windows\Application Experience\)
    .PARAMETER TaskName
        排程名稱 (可選,不給則整個路徑下所有)
    .PARAMETER Enable
        $true=啟用、$false=停用
    .OUTPUTS
        hashtable: @{ Success; Message; Unsupported }
    #>
    param(
        [Parameter(Mandatory)][string]$TaskPath,
        [string]$TaskName = "",
        [bool]$Enable = $false
    )
    try {
        if ($TaskName) {
            $tasks = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction Stop
        }
        else {
            $tasks = Get-ScheduledTask -TaskPath $TaskPath -ErrorAction Stop
        }
        if (-not $tasks) {
            return @{ Success = $false; Message = "找不到排程"; Unsupported = $true }
        }

        $failCount = 0
        foreach ($t in $tasks) {
            try {
                if ($Enable) { Enable-ScheduledTask  -InputObject $t -ErrorAction Stop | Out-Null }
                else         { Disable-ScheduledTask -InputObject $t -ErrorAction Stop | Out-Null }
            }
            catch { $failCount++ }
        }

        $act = if ($Enable) { "啟用" } else { "停用" }
        if ($failCount -eq 0) {
            return @{ Success = $true; Message = "已${act} $($tasks.Count) 個排程" }
        }
        return @{ Success = $false; Message = "$failCount 個排程${act}失敗 (可能受系統保護)" }
    }
    catch {
        return @{ Success = $false; Message = $_.Exception.Message; Unsupported = $true }
    }
}

function Disable-ScheduledTaskSafe {
    # 保留舊名 (相容既有呼叫),內部轉呼叫 Set-ScheduledTaskState 停用。
    param(
        [Parameter(Mandatory)][string]$TaskPath,
        [string]$TaskName = ""
    )
    return Set-ScheduledTaskState -TaskPath $TaskPath -TaskName $TaskName -Enable $false
}

<#
.SYNOPSIS
    移除 AppX 預裝應用程式。
.PARAMETER PackageName
    套件名稱 (英文,如 Microsoft.BingSearch)
#>
function Remove-AppxSafe {
    param([Parameter(Mandatory)][string]$PackageName)

    try {
        $pkg = Get-AppxPackage -Name $PackageName -ErrorAction SilentlyContinue
        if (-not $pkg) {
            return @{ Success = $false; Message = "此系統未安裝此 App"; Unsupported = $true }
        }

        $pkg | Remove-AppxPackage -ErrorAction Stop

        # 驗證
        $check = Get-AppxPackage -Name $PackageName -ErrorAction SilentlyContinue
        if (-not $check) {
            return @{ Success = $true; Message = "已移除" }
        }
        else {
            return @{ Success = $false; Message = "移除後仍存在 (可能為系統元件)" }
        }
    }
    catch {
        return @{ Success = $false; Message = $_.Exception.Message }
    }
}


# ============================================================
#  按鍵讀取 (Read-Choice)
# ============================================================

<#
.SYNOPSIS
    讀取使用者按鍵,限定有效鍵,顯示統一提示列。
.PARAMETER ValidKeys
    有效按鍵陣列
#>
function Read-Choice {
    param(
        [string[]]$ValidKeys = @("Y", "N", "S", "P", "Q"),
        # 可選:自訂各鍵的提示文字,如 @{ Y = "使用預設"; N = "自訂" }
        # 未指定的鍵會沿用預設語言鍵 (hint_y / hint_n ...)
        [hashtable]$Labels = @{},
        # 可選:預設鍵。指定後,直接按 Enter (空輸入) 即回傳此鍵。
        [string]$DefaultKey = ""
    )

    # 組合提示列
    $hints = @()
    foreach ($k in $ValidKeys) {
        if ($Labels.ContainsKey($k)) {
            # 呼叫端提供的自訂文字優先
            $label = $Labels[$k]
        }
        else {
            $label = switch ($k) {
                "Y" { Get-Text "hint_y" }
                "N" { Get-Text "hint_n" }
                "S" { Get-Text "hint_s" }
                "P" { Get-Text "hint_p" }
                "Q" { Get-Text "hint_q" }
                "E" { Get-Text "hint_e" }
                default {
                    # 數字鍵 (選項式提問的 1~14 等):不加標籤,提示列只顯示 [1] [2] ...
                    # 完整標籤已在上方選項清單列出,提示列重複只會過長。
                    if ($k -match '^\d+$') { "" }
                    else { $k }
                }
            }
        }
        $hints += "[$k]$label"
    }
    # 若有預設鍵,在提示列末端標示 (直接 Enter 採用)
    $defHint = ""
    if (-not [string]::IsNullOrEmpty($DefaultKey)) {
        $defHint = "(Enter=$DefaultKey) "
    }
    $promptLine = ($hints -join " ") + " " + $defHint + "> "

    while ($true) {
        Write-Host $promptLine -NoNewline -ForegroundColor White
        $userInput = (Read-Host).Trim().ToUpper()

        # 空輸入:有預設鍵則採用,否則重問
        if ([string]::IsNullOrEmpty($userInput)) {
            if (-not [string]::IsNullOrEmpty($DefaultKey)) { return $DefaultKey.ToUpper() }
            continue
        }

        # 完整輸入比對 (支援雙位數如 "10"~"14";字母鍵取單字元相容)
        if ($ValidKeys -contains $userInput) {
            return $userInput
        }
        # 字母鍵向後相容:單字元比對 (如使用者多打字 "Yes" → "Y")
        $key = $userInput.Substring(0, 1)
        if (($userInput.Length -eq 1 -or $key -notmatch '\d') -and ($ValidKeys -contains $key)) {
            return $key
        }
        Write-Host ("  " + (Get-Text "invalid_key")) -ForegroundColor Red
    }
}


# ============================================================
#  提問引擎 - 選項式模式 (Interactive Prompt - Choice, 統一模型)
#  全專案統一題型:每題為「問題 + 選項清單 + 建議」,雙選只是「兩個
#  選項」的特例,不特別區分,一律用 1~5 數字選擇 (S/P/Q 為控制鍵)。
# ============================================================

<#
.SYNOPSIS
    判斷設定項目前落在哪個選項 (供提問時顯示「目前狀態」)。
    逐一比對每個「有定義登錄檔寫入 (Reg)」的選項:該選項所列的所有
    鍵值都與系統目前實際值吻合時,即為目前狀態,回傳其 Label。
    多鍵選項需「全部鍵」都吻合才算。None/RegDel/Value/Custom 選項不
    參與比對 (無固定可讀狀態);全部不吻合則回傳 $null (未設定/系統預設)。
.OUTPUTS
    字串 (目前狀態選項的 Label) 或 $null (未設定)
#>
function Get-CurrentChoiceState {
    param([Parameter(Mandatory)][hashtable]$Item)

    foreach ($ch in $Item.Choices) {
        # 值寫入型選項:所有鍵值都與系統目前值吻合 → 目前狀態
        if ($ch.ContainsKey("Reg")) {
            $allMatch = $true
            foreach ($r in $ch.Reg) {
                $actual = Get-RegistryValueOrNull -Path $r.Path -Name $r.Name
                # 以字串比較,吸收 DWord(int) 與 String 型別差異
                if ($null -eq $actual -or ([string]$actual -ne [string]$r.Value)) {
                    $allMatch = $false
                    break
                }
            }
            if ($allMatch) { return (Get-Field -Obj $ch -Base "Label") }
        }
        # 排程型選項:比對排程實際的啟用/停用狀態
        elseif ($ch.ContainsKey("Task")) {
            $state = Get-TaskChoiceState -Task $ch.Task
            if ($null -ne $state) {
                # 選項要求 Enable=$true 且排程確為啟用 → 吻合;反之亦然
                $wantEnable = $true
                foreach ($t in @($ch.Task)) {
                    if ($t.ContainsKey("Enable")) { $wantEnable = [bool]$t.Enable }
                }
                if ($state -eq $wantEnable) { return (Get-Field -Obj $ch -Base "Label") }
            }
        }
        # 服務型選項:比對服務啟動類型
        elseif ($ch.ContainsKey("Svc")) {
            if (Test-SvcChoiceState -Svc $ch.Svc) { return (Get-Field -Obj $ch -Base "Label") }
        }
        # 具名特殊動作選項:用對應的狀態偵測 (只讀不寫)
        elseif ($ch.ContainsKey("Special")) {
            if (Test-SpecialState -Name $ch.Special) { return (Get-Field -Obj $ch -Base "Label") }
        }
        # None / RegDel 選項不參與比對 (無固定可讀狀態)
    }
    return $null
}

function Get-TaskChoiceState {
    <#
    .SYNOPSIS
        讀取排程選項對應排程的啟用狀態。
    .OUTPUTS
        [bool] $true=啟用、$false=停用;讀不到 (排程不存在) 回 $null
    #>
    param([Parameter(Mandatory)]$Task)
    $allEnabled = $true; $found = $false
    foreach ($t in @($Task)) {
        try {
            $tn = if ($t.ContainsKey("Name")) { $t.Name } else { "" }
            $obj = if ($tn) { Get-ScheduledTask -TaskPath $t.Path -TaskName $tn -ErrorAction Stop }
                   else     { Get-ScheduledTask -TaskPath $t.Path -ErrorAction Stop }
            if ($obj) {
                $found = $true
                # State: Ready/Running=啟用、Disabled=停用
                foreach ($o in @($obj)) {
                    if ($o.State -eq "Disabled") { $allEnabled = $false }
                }
            }
        }
        catch { }
    }
    if (-not $found) { return $null }
    return $allEnabled
}

function Test-SvcChoiceState {
    <#
    .SYNOPSIS
        判斷服務選項是否為目前狀態 (比對啟動類型)。
    .OUTPUTS
        [bool]
    #>
    param([Parameter(Mandatory)]$Svc)
    foreach ($s in @($Svc)) {
        $want = if ($s.ContainsKey("StartType")) { [int]$s.StartType } else { 4 }
        try {
            $reg = Get-ItemProperty -Path ("HKLM:\SYSTEM\CurrentControlSet\Services\" + $s.Name) -Name "Start" -ErrorAction Stop
            # Start: 2=自動、3=手動、4=停用
            if ([int]$reg.Start -ne $want) { return $false }
        }
        catch { return $false }
    }
    return $true
}

<#
.SYNOPSIS
    顯示「選項式」設定項並取得使用者選擇。
.PARAMETER Item
    設定項物件 (hashtable),需含:
      NameZh    - 項目名稱 (繁中)
      DescZh    - 說明 (繁中)
      Choices   - 選項陣列,每筆:
                    Id       (必要) 選項識別碼,跨版本移植穩定 (如 "disable_all")
                    Label    (必要) 顯示文字
                    Value / Reg / RegDel / None (擇一) 動作定義
                    MinBuild   (可選) 選項自己的最低 Build 門檻,不符會被過濾
                    EditionOnly(可選) 只在指定 EditionID 出現的選項白名單
                    Note       (可選) 顯示在選項後方的短提示,如版本差異警語
      Recommend - 建議選項的 Id (字串);向後相容:若為數字,視為 1-based 編號
      MinBuild  - (可選) 整個項目的最低 Build,不符則自動跳過
      Notes     - (可選) 顯示於選項清單下方的詳細備註
.PARAMETER Index
    目前題號
.PARAMETER Total
    本類總題數
.PARAMETER ModuleTitle
    類別標題
.OUTPUTS
    字串:選中的選項 Id / "S" / "P" / "Q" / "UNSUPPORT"
    (向後相容:若選項無 Id,回傳過濾後的顯示編號 "1".."5")
#>
function Show-ChoiceQuestion {
    param(
        [Parameter(Mandatory)][hashtable]$Item,
        [int]$Index,
        [int]$Total,
        [string]$ModuleTitle
    )

    # ---- 項目層級版本檢查 (整題 skip) ----
    $minBuild = if ($Item.ContainsKey("MinBuild")) { [int]$Item.MinBuild } else { 0 }
    if (-not (Test-BuildSupported -MinBuild $minBuild)) {
        Write-Host ""
        Write-Host ("  [{0}/{1}] {2}" -f $Index, $Total, (Get-Field -Obj $Item -Base "Name")) -ForegroundColor DarkGray
        Write-Host ("  → " + (Get-Text "unsupported_skip")) -ForegroundColor DarkGray
        return "UNSUPPORT"
    }

    # ---- 選項層級過濾 (依 MinBuild / EditionOnly) ----
    # 建立可用選項清單,每筆記錄「顯示編號 → 原始 Choice」的映射
    $available = @()
    foreach ($ch in $Item.Choices) {
        $chMinBuild = if ($ch.ContainsKey("MinBuild"))    { [int]$ch.MinBuild }    else { 0 }
        $chEdition  = if ($ch.ContainsKey("EditionOnly")) { @($ch.EditionOnly) }   else { @() }
        if (-not (Test-BuildSupported     -MinBuild    $chMinBuild)) { continue }
        if (-not (Test-EditionSupported   -EditionOnly $chEdition))  { continue }
        $available += $ch
    }

    # 若所有選項都被過濾掉,視同不支援 (理論上不應發生,通常都會保留「維持現狀」)
    if ($available.Count -eq 0) {
        Write-Host ""
        Write-Host ("  [{0}/{1}] {2}" -f $Index, $Total, (Get-Field -Obj $Item -Base "Name")) -ForegroundColor DarkGray
        Write-Host ("  → " + (Get-Text "unsupported_skip")) -ForegroundColor DarkGray
        return "UNSUPPORT"
    }

    # ---- 決定建議選項在「過濾後」的顯示編號 ----
    # 優先用 Id 字串對應;向後相容:若 Recommend 是數字,視為 1-based 原始編號
    $recDisplayIdx = 0   # 0 表示「無明確建議」,顯示第一個為建議
    if ($Item.ContainsKey("Recommend")) {
        $rec = $Item.Recommend
        if ($rec -is [int] -or ($rec -is [string] -and $rec -match '^\d+$')) {
            # 舊格式:數字編號 → 對應到原始 Choices[rec-1],再看它在 available 的位置
            $origIdx = [int]$rec - 1
            if ($origIdx -ge 0 -and $origIdx -lt $Item.Choices.Count) {
                $origChoice = $Item.Choices[$origIdx]
                for ($k = 0; $k -lt $available.Count; $k++) {
                    if ([object]::ReferenceEquals($available[$k], $origChoice)) { $recDisplayIdx = $k + 1; break }
                }
            }
        }
        else {
            # 新格式:選項 Id 字串
            for ($k = 0; $k -lt $available.Count; $k++) {
                if ($available[$k].ContainsKey("Id") -and $available[$k].Id -eq $rec) { $recDisplayIdx = $k + 1; break }
            }
        }
    }
    # Fallback:找不到建議 → 標第一個可用選項為建議
    if ($recDisplayIdx -eq 0) { $recDisplayIdx = 1 }

    # ---- 顯示提問畫面 ----
    Write-Host ""
    Write-Host "────────────────────────────────────" -ForegroundColor DarkCyan
    Write-Host ("$ModuleTitle          " + (Get-Text "progress") + ":$Index / $Total") -ForegroundColor Cyan
    Write-Host "────────────────────────────────────" -ForegroundColor DarkCyan
    Write-Host ((Get-Text "item") + ":") -NoNewline -ForegroundColor White
    Write-Host (" " + (Get-Field -Obj $Item -Base "Name")) -ForegroundColor White
    Write-Host ""
    Write-Host ((Get-Text "desc") + ":") -ForegroundColor Gray
    Write-Host ("  " + (Get-Field -Obj $Item -Base "Desc")) -ForegroundColor Gray
    Write-Host ""

    # ---- 顯示目前狀態 (讀系統實際值比對出目前落在哪個選項) ----
    # 讓「維持現狀」有意義:使用者看得到目前是什麼狀態。
    # 比對不到任何選項 → 未設定 (系統預設,通常是政策鍵尚未建立)。
    $curState = Get-CurrentChoiceState -Item $Item
    $curText  = if ($curState) { $curState } else { (Get-Text "state_not_set") }
    Write-Host ((Get-Text "current_state") + ":" + $curText) -ForegroundColor Yellow
    Write-Host ""

    # 逐一列出可用選項 (依過濾後順序)
    for ($n = 0; $n -lt $available.Count; $n++) {
        $ch    = $available[$n]
        $tag   = if (($n + 1) -eq $recDisplayIdx) { " (" + (Get-Text "choice_recommended") + ")" } else { "" }
        $color = if (($n + 1) -eq $recDisplayIdx) { "Green" } else { "White" }
        Write-Host ("  [{0}] {1}{2}" -f ($n + 1), (Get-Field -Obj $ch -Base "Label"), $tag) -ForegroundColor $color
        # 選項自帶的 Note (短提示,顯示在該選項的下一行,縮排)
        if ($ch.ContainsKey("Note") -and (Get-Field -Obj $ch -Base "Note")) {
            Write-Host ("      → " + (Get-Field -Obj $ch -Base "Note")) -ForegroundColor DarkGray
        }
    }

    if ($Item.ContainsKey("Notes") -and (Get-Field -Obj $Item -Base "Notes")) {
        Write-Host ""
        Write-Host ((Get-Text "notes") + ":" + (Get-Field -Obj $Item -Base "Notes")) -ForegroundColor Gray
    }
    Write-Host "────────────────────────────────────" -ForegroundColor DarkCyan

    # ---- 動態組成有效按鍵 ----
    # 提示列數字鍵只顯示 [1] [2] [3]...,S/P/Q 沿用預設語言鍵短標籤
    $validKeys = @()
    for ($n = 0; $n -lt $available.Count; $n++) { $validKeys += "$($n + 1)" }
    $validKeys += @("S", "P", "Q")

    # Enter 跟隨建議:預設鍵 = 建議選項的顯示編號
    $choice = Read-Choice -ValidKeys $validKeys -DefaultKey "$recDisplayIdx"

    # ---- 將顯示編號轉回選項 Id (若選項有 Id) ----
    if ($choice -match '^\d+$') {
        $sel = $available[[int]$choice - 1]
        if ($sel.ContainsKey("Id")) {
            return [string]$sel.Id
        }
        # 向後相容:選項沒 Id 就回傳過濾後的顯示編號
        return $choice
    }
    return $choice
}


# ============================================================
#  提問引擎 - 分組模式 (Interactive Prompt - Grouped)
# ============================================================

<#
.SYNOPSIS
    顯示一個設定群組並取得回答 (可展開個別設定)。
.PARAMETER Group
    群組物件 (hashtable),需含:
      Name  - 群組名稱
      Desc  - 群組說明 (含哪些項目)
      Items - 該組內的設定項陣列
.OUTPUTS
    hashtable: @{ Mode="ALL_Y"/"ALL_N"/"EXPAND"/"SKIP"/"QUIT"; }
#>
function Get-PreferenceMask {
    <#
    .SYNOPSIS
        讀取 UserPreferencesMask 為 32-bit 整數。讀不到回預設值。
    .OUTPUTS
        [uint32] 遮罩值 (前 4 bytes 組成的整數)
    #>
    $path = "HKCU:\Control Panel\Desktop"
    try {
        $raw = (Get-ItemProperty -Path $path -Name "UserPreferencesMask" -ErrorAction Stop).UserPreferencesMask
        if ($null -eq $raw -or $raw.Count -lt 4) { return [uint32]0x9E3E0780 }  # 常見預設 (全效果開)
        # 前 4 bytes → little-endian uint32
        return [uint32]($raw[0] -bor ($raw[1] -shl 8) -bor ($raw[2] -shl 16) -bor ($raw[3] -shl 24))
    }
    catch { return [uint32]0x9E3E0780 }
}

function Test-PreferenceMaskBit {
    <#
    .SYNOPSIS
        測試 UserPreferencesMask 某 bit 是否為 1 (該效果是否開啟)。
    .PARAMETER BitMask
        位元遮罩 (如 0x2 = 選單動畫)
    .OUTPUTS
        [bool]
    #>
    param([Parameter(Mandatory)][uint32]$BitMask)
    $mask = Get-PreferenceMask
    return (($mask -band $BitMask) -ne 0)
}

function Set-PreferenceMaskBit {
    <#
    .SYNOPSIS
        設定 UserPreferencesMask 的單一 bit (開或關),不影響其他 bit。
        讀出完整 8-byte 陣列 → 改前 4 bytes 的目標 bit → 寫回。
    .PARAMETER BitMask
        位元遮罩 (如 0x2 = 選單動畫)
    .PARAMETER Enable
        $true=設為 1 (開啟效果)、$false=設為 0 (關閉效果)
    .OUTPUTS
        hashtable: @{ Success; Message }
    #>
    param(
        [Parameter(Mandatory)][uint32]$BitMask,
        [Parameter(Mandatory)][bool]$Enable
    )
    $path = "HKCU:\Control Panel\Desktop"
    try {
        # 讀出完整 byte 陣列 (保留全部,通常 8 bytes)
        $raw = (Get-ItemProperty -Path $path -Name "UserPreferencesMask" -ErrorAction SilentlyContinue).UserPreferencesMask
        if ($null -eq $raw -or $raw.Count -lt 4) {
            # 沒有值 → 用常見預設 8-byte 起始
            $raw = [byte[]](0x9E, 0x3E, 0x07, 0x80, 0x12, 0x00, 0x00, 0x00)
        }
        else {
            $raw = [byte[]]$raw   # 確保可寫
        }

        # 前 4 bytes 組成 uint32,改目標 bit
        $val = [uint32]($raw[0] -bor ($raw[1] -shl 8) -bor ($raw[2] -shl 16) -bor ($raw[3] -shl 24))
        if ($Enable) { $val = $val -bor $BitMask }
        else         { $val = $val -band (-bnot $BitMask) }

        # 寫回前 4 bytes (其餘 bytes 不動)
        $raw[0] = [byte]($val -band 0xFF)
        $raw[1] = [byte](($val -shr 8)  -band 0xFF)
        $raw[2] = [byte](($val -shr 16) -band 0xFF)
        $raw[3] = [byte](($val -shr 24) -band 0xFF)

        Set-ItemProperty -Path $path -Name "UserPreferencesMask" -Value $raw -Type Binary -Force -ErrorAction Stop
        return @{ Success = $true; Message = "遮罩位元已更新 (需登出重登生效)" }
    }
    catch {
        return @{ Success = $false; Message = $_.Exception.Message }
    }
}

function Invoke-ChoiceApply {
    <#
    .SYNOPSIS
        套用單一選項的登錄檔設定 (供分組展開的個別項使用)。
        選項含 Reg 陣列 (同逐題複雜型結構),逐一寫入。
    .OUTPUTS
        hashtable: @{ Success; Message }
    #>
    param([Parameter(Mandatory)][hashtable]$Choice)

    # 遮罩型:選項含 Mask (@{ BitMask=0x2; Enable=$false })
    if ($Choice.ContainsKey("Mask")) {
        $m = $Choice.Mask
        $res = Set-PreferenceMaskBit -BitMask ([uint32]$m.BitMask) -Enable ([bool]$m.Enable)
        return @{ Success = $res.Success; Message = $res.Message }
    }

    if ($Choice.ContainsKey("Reg")) {
        $ok = $true; $msg = ""
        foreach ($r in $Choice.Reg) {
            $res = Set-RegistryValue -Path $r.Path -Name $r.Name -Value $r.Value -Type $r.Type
            if (-not $res.Success) { $ok = $false; $msg = $res.Message }
        }
        return @{ Success = $ok; Message = $msg }
    }
    # 無 Reg (如 None 維持型) → 視為成功不動作
    return @{ Success = $true; Message = "" }
}

function Show-Group {
    <#
    .SYNOPSIS
        分組引擎:呈現一個群組,提供整組套用或展開個別微調。
    .DESCRIPTION
        兩層互動:
          組層級 - [1]方案A [2]方案B [3]展開個別調整 [4]維持
                   方案 A/B 用 GroupKey (如 VisualFXSetting) 一鍵套用整組。
          項層級 - 展開後,各個別項逐一詢問 (每項有獨立 Reg)。

        群組資料結構 (Group):
          Name       群組名
          Desc       說明 (整組包含哪些)
          OptA       @{ Label; Value }  組層級選項 A (如 效能優先 → VisualFXSetting=2)
          OptB       @{ Label; Value }  組層級選項 B (如 外觀優先 → VisualFXSetting=1)
          GroupPath  整組鍵的登錄檔路徑
          GroupName  整組鍵的名稱 (如 VisualFXSetting)
          GroupType  整組鍵的型別 (如 DWord)
          RecommendOpt "A"/"B"  組層級建議 (Enter 預設)
          Items      @( 個別項 )    展開時逐一調,各含 Choices/Recommend (同逐題項結構)
    .OUTPUTS
        hashtable: @{ Applied=<套用數>; Results=@(結果字串) }
    #>
    param(
        [Parameter(Mandatory)][hashtable]$Group,
        [int]$GroupIndex = 1,
        [int]$GroupTotal = 1,
        [string]$ModuleId = "",
        [string]$ModuleTitle = ""
    )

    $results = @()
    $appliedCount = 0

    Write-Host ""
    Write-Host "  ────────────────────────────────────────" -ForegroundColor DarkCyan
    Write-Host ("  {0}  ({1} {2}/{3})" -f (Get-Field -Obj $Group -Base "Name"), (Get-Text "grp_index"), $GroupIndex, $GroupTotal) -ForegroundColor Cyan
    Write-Host "  ────────────────────────────────────────" -ForegroundColor DarkCyan
    Write-Host ("  {0}" -f (Get-Field -Obj $Group -Base "Desc")) -ForegroundColor Gray
    if ($Group.Items) {
        Write-Host ("  " + (Get-Text "grp_item_count" -Args @($Group.Items.Count))) -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host ("  [1] {0}" -f (Get-Field -Obj $Group.OptA -Base "Label")) -ForegroundColor White
    Write-Host ("  [2] {0}" -f (Get-Field -Obj $Group.OptB -Base "Label")) -ForegroundColor White
    Write-Host ("  [3] " + (Get-Text "grp_opt_expand")) -ForegroundColor White
    Write-Host ("  [4] " + (Get-Text "grp_opt_keep")) -ForegroundColor White

    # 組層級建議 → 預設鍵
    $defKey = if ($Group.RecommendOpt -eq "B") { "2" } else { "1" }
    $recLabel = if ($Group.RecommendOpt -eq "B") { (Get-Field -Obj $Group.OptB -Base "Label") } else { (Get-Field -Obj $Group.OptA -Base "Label") }
    Write-Host ("      → " + (Get-Text "grp_suggest") + ":" + $recLabel + " " + (Get-Text "grp_enter_hint")) -ForegroundColor DarkCyan

    $choice = Read-Choice -ValidKeys @("1", "2", "3", "4", "Q") `
                          -Labels @{ "1" = (Get-Field -Obj $Group.OptA -Base "Label"); "2" = (Get-Field -Obj $Group.OptB -Base "Label"); "3" = (Get-Text "grp_btn_expand"); "4" = (Get-Text "grp_btn_keep"); Q = (Get-Text "grp_btn_end") } `
                          -DefaultKey $defKey

    if ($choice -eq "Q") { return @{ Applied = 0; Results = @(); Quit = $true } }
    if ($choice -eq "4") { return @{ Applied = 0; Results = @() } }

    # ── 整組套用 (方案 A 或 B):寫 GroupKey 一鍵 ──
    if ($choice -eq "1" -or $choice -eq "2") {
        $opt = if ($choice -eq "1") { $Group.OptA } else { $Group.OptB }
        try {
            if (-not (Test-Path $Group.GroupPath)) {
                New-Item -Path $Group.GroupPath -Force -ErrorAction Stop | Out-Null
            }
            Set-ItemProperty -Path $Group.GroupPath -Name $Group.GroupName -Value $opt.Value `
                             -Type $Group.GroupType -Force -ErrorAction Stop
            Write-Host ("  [v] " + (Get-Text "grp_applied_all") + ":" + (Get-Field -Obj $opt -Base "Label")) -ForegroundColor Green
            $results += ("{0}:整組 → {1}" -f (Get-Field -Obj $Group -Base "Name"), (Get-Field -Obj $opt -Base "Label"))
            $appliedCount++
            Write-Log -Message ("分組套用 {0}={1}" -f $Group.GroupName, $opt.Value) -Level OK -Module $ModuleId -Item (Get-Field -Obj $Group -Base "Name")
            Update-VisualSettings   # 通知系統套用
        }
        catch {
            Write-Host ("  [x] " + (Get-Text "grp_apply_failed") + ":" + $_.Exception.Message) -ForegroundColor Red
            Write-Log -Message ("分組套用失敗:" + $_.Exception.Message) -Level FAIL -Module $ModuleId -Item (Get-Field -Obj $Group -Base "Name")
        }
        return @{ Applied = $appliedCount; Results = $results }
    }

    # ── 展開個別調整 (choice=3):各個別項逐一詢問 ──
    Write-Host ""
    Write-Host ("  ── " + (Get-Text "grp_expand_title") + " ──") -ForegroundColor DarkCyan

    # 個別設定要生效並顯示在「效能選項」對話框,必須先切到自訂模式
    # (VisualFXSetting=3)。否則在「最佳外觀/效能/讓Windows選擇」模式下,
    # 個別 bit 的變更不會反映在對話框勾選、也可能不生效。
    if ($Group.GroupPath -and $Group.GroupName) {
        try {
            if (-not (Test-Path $Group.GroupPath)) {
                New-Item -Path $Group.GroupPath -Force -ErrorAction Stop | Out-Null
            }
            Set-ItemProperty -Path $Group.GroupPath -Name $Group.GroupName -Value 3 `
                             -Type $Group.GroupType -Force -ErrorAction SilentlyContinue
            Write-Host ("  " + (Get-Text "grp_custom_mode")) -ForegroundColor DarkGray
        }
        catch { }
    }

    $items = @($Group.Items)
    $j = 0
    while ($j -lt $items.Count) {
        $it = $items[$j]
        $applied = Invoke-GroupItem -Item $it -Index ($j + 1) -Total $items.Count -ModuleId $ModuleId
        if ($applied.Quit) { break }
        if ($applied.Back) { if ($j -gt 0) { $j-- }; continue }
        if ($applied.Applied) { $appliedCount++; $results += $applied.Result }
        $j++
    }

    # 通知系統套用視覺設定變更 (廣播,讓部分效果即時生效不必等登出)
    Update-VisualSettings

    return @{ Applied = $appliedCount; Results = $results }
}

function Update-VisualSettings {
    <#
    .SYNOPSIS
        通知系統重新套用視覺/使用者偏好設定。
        用 SystemParametersInfo (SPI_SETUIEFFECTS) 廣播變更,讓部分效果
        不必登出即可生效。失敗不影響 (登出重登仍會套用)。
    #>
    try {
        if (-not ("Win32.SPI" -as [type])) {
            Add-Type -Namespace Win32 -Name SPI -MemberDefinition @"
[System.Runtime.InteropServices.DllImport("user32.dll", SetLastError=true)]
public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
"@ -ErrorAction SilentlyContinue
        }
        # SPI_SETUIEFFECTS = 0x103F;fWinIni: SPIF_UPDATEINIFILE(1)|SPIF_SENDCHANGE(2)=3
        [Win32.SPI]::SystemParametersInfo(0x103F, 0, [IntPtr]::Zero, 3) | Out-Null
    }
    catch { }
}

function Invoke-GroupItem {
    <#
    .SYNOPSIS
        分組展開後,處理單一個別項 (選項式,同逐題項結構)。
    .OUTPUTS
        hashtable: @{ Applied=<bool>; Result=<字串>; Quit; Back }
    #>
    param(
        [Parameter(Mandatory)][hashtable]$Item,
        [int]$Index, [int]$Total, [string]$ModuleId
    )
    $choices = @($Item.Choices)
    # 建議 → 預設鍵 (對應建議選項的序號)
    $defKey = "1"
    for ($k = 0; $k -lt $choices.Count; $k++) {
        if ($choices[$k].Id -eq $Item.Recommend) { $defKey = [string]($k + 1) }
    }

    Write-Host "  ────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ("  [{0}/{1}] {2}" -f $Index, $Total, (Get-Field -Obj $Item -Base "Name")) -ForegroundColor White
    if ((Get-Field -Obj $Item -Base "Desc")) { Write-Host ("        {0}" -f (Get-Field -Obj $Item -Base "Desc")) -ForegroundColor Gray }

    $validKeys = @(); $labels = @{}
    for ($k = 0; $k -lt $choices.Count; $k++) {
        $key = [string]($k + 1)
        $validKeys += $key
        $labels[$key] = (Get-Field -Obj $choices[$k] -Base "Label")
        $isRec = ($choices[$k].Id -eq $Item.Recommend)
        $mark  = if ($isRec) { " (建議)" } else { "" }
        $color = if ($isRec) { "Green" } else { "White" }
        Write-Host ("        [{0}] {1}{2}" -f $key, (Get-Field -Obj $choices[$k] -Base "Label"), $mark) -ForegroundColor $color
    }
    if ($Index -gt 1) { $validKeys += "P"; $labels["P"] = (Get-Text "grp_btn_prev") }
    $validKeys += "Q"; $labels["Q"] = (Get-Text "grp_btn_end")

    $choice = Read-Choice -ValidKeys $validKeys -Labels $labels -DefaultKey $defKey
    if ($choice -eq "Q") { return @{ Quit = $true } }
    if ($choice -eq "P") { return @{ Back = $true } }

    $sel = $choices[[int]$choice - 1]
    if ($sel.None) {
        return @{ Applied = $false }   # 維持現狀
    }
    # 套用前先讀目前狀態 (供摘要顯示「原 → 新」)
    $curLabel = Get-CurrentChoiceState -Item $Item
    if (-not $curLabel) { $curLabel = "未設定" }
    # 套用該選項的 Reg / Mask
    $res = Invoke-ChoiceApply -Choice $sel
    if ($res.Success) {
        Write-Host ("        [v] 已套用:{0}" -f (Get-Field -Obj $sel -Base "Label")) -ForegroundColor Green
        return @{ Applied = $true; Result = ("{0}:{1} → {2}" -f (Get-Field -Obj $Item -Base "Name"), $curLabel, (Get-Field -Obj $sel -Base "Label")) }
    }
    else {
        Write-Host ("        [x] 失敗:{0}" -f $res.Message) -ForegroundColor Red
        return @{ Applied = $false }
    }
}


# ============================================================
#  設定檔匯出 / 載入 (Config Export / Import)
# ============================================================

<#
.SYNOPSIS
    匯出一類的設定檔。
.PARAMETER ModuleId
    模組代號 (如 01_Privacy)
.PARAMETER Answers
    答案字典 @{ 項目key = "applied"/"declined"/"skipped" }
#>
function Export-Config {
    param(
        [Parameter(Mandatory)][string]$ModuleId,
        # 用 IDictionary 接受有序字典,避免被轉型為 hashtable 而失去 settings 順序
        [Parameter(Mandatory)][System.Collections.IDictionary]$Answers
    )

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $safeName  = if ($Global:ProfileName) { $Global:ProfileName } else { "User" }
    $fileName  = "${safeName}_${ModuleId}_${timestamp}.json"
    $filePath  = Join-Path $Global:ConfigPath $fileName

    $config = [ordered]@{
        profile_name = $safeName
        module       = $ModuleId
        timestamp    = $timestamp
        system_build = $Global:SystemInfo.BuildNumber
        settings     = $Answers
    }

    try {
        $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding UTF8
        return @{ Success = $true; Path = $filePath }
    }
    catch {
        return @{ Success = $false; Message = $_.Exception.Message }
    }
}

<#
.SYNOPSIS
    將被刪除的登錄檔值寫入還原檔 (供日後重建)。
.PARAMETER ModuleId
    模組代號
.PARAMETER Backups
    備份清單,每筆 @{ Path; Name; Value; Type }
.OUTPUTS
    hashtable: @{ Success; Path }
#>
function Export-RestoreFile {
    param(
        [Parameter(Mandatory)][string]$ModuleId,
        [Parameter(Mandatory)][array]$Backups
    )

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $safeName  = if ($Global:ProfileName) { $Global:ProfileName } else { "User" }
    $fileName  = "${safeName}_${ModuleId}_restore_${timestamp}.json"
    $filePath  = Join-Path $Global:RestorePath $fileName

    $restore = [ordered]@{
        profile_name = $safeName
        module       = $ModuleId
        timestamp    = $timestamp
        note         = "此檔記錄被刪除的登錄檔值,可用於還原。deleted 內每筆含 Path/Name/Value/Type。"
        deleted      = $Backups
    }

    try {
        $restore | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding UTF8
        return @{ Success = $true; Path = $filePath }
    }
    catch {
        return @{ Success = $false; Message = $_.Exception.Message }
    }
}

<#
.SYNOPSIS
    列出某類可載入的設定檔 (依時間排序,新到舊)。
.PARAMETER ModuleId
    模組代號 (可選,不給則列出全部)
#>
function Get-ConfigFiles {
    param([string]$ModuleId = "")

    $pattern = if ($ModuleId) { "*_${ModuleId}_*.json" } else { "*.json" }
    $files = Get-ChildItem -Path $Global:ConfigPath -Filter $pattern -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime -Descending

    return $files
}

<#
.SYNOPSIS
    載入設定檔內容。
.PARAMETER FilePath
    設定檔完整路徑
#>
function Import-Config {
    param([Parameter(Mandatory)][string]$FilePath)

    if (-not (Test-Path $FilePath)) {
        return $null
    }

    try {
        $json = Get-Content -Path $FilePath -Raw -Encoding UTF8
        return ($json | ConvertFrom-Json)
    }
    catch {
        return $null
    }
}


# ============================================================
#  權限檢查 (Admin Check)
# ============================================================

<#
.SYNOPSIS
    檢查是否以系統管理員身分執行。
#>
function Test-IsAdmin {
    $identity  = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}


# ============================================================
#  設定檔名稱初始化 (Profile Name)
#  預設用「電腦名稱_使用者名稱」自動命名 (可區分不同電腦與使用者),
#  並提示使用者:用預設,或自訂。單獨執行模組與 Main.ps1 共用。
#  若已設定過 ($Global:ProfileName 有值) 則不重複詢問。
# ============================================================
function Initialize-ProfileName {
    if ($Global:ProfileName) { return $Global:ProfileName }

    # 預設名稱 = 電腦名稱_使用者名稱 (用 ${} 包住避免變數名解析錯誤)
    $default = "${env:COMPUTERNAME}_${env:USERNAME}"

    Write-Host ""
    Write-Host "────────────────────────────────────" -ForegroundColor DarkCyan
    Write-Host ("  " + (Get-Text "profile_name_title")) -ForegroundColor Cyan
    Write-Host "────────────────────────────────────" -ForegroundColor DarkCyan
    Write-Host ((Get-Text "profile_name_default") + ":" + $default) -ForegroundColor White
    Write-Host ("  " + (Get-Text "profile_name_default_hint")) -ForegroundColor Gray
    Write-Host ""
    Write-Host ("  [Y] " + (Get-Text "profile_name_use_default")) -ForegroundColor Green
    Write-Host ("  [N] " + (Get-Text "profile_name_custom")) -ForegroundColor DarkYellow
    Write-Host "────────────────────────────────────" -ForegroundColor DarkCyan

    $c = Read-Choice -ValidKeys @("Y", "N") -Labels @{
        Y = (Get-Text "profile_name_use_default")
        N = (Get-Text "profile_name_custom")
    }
    if ($c -eq "Y") {
        $Global:ProfileName = $default
    }
    else {
        Write-Host ""
        Write-Host ("  " + (Get-Text "profile_input_prompt") + " > ") -NoNewline -ForegroundColor White
        $custom = (Read-Host).Trim()
        if ([string]::IsNullOrEmpty($custom)) { $custom = $default }
        # 清理不合法的檔名字元,避免存檔失敗
        $custom = $custom -replace '[\\/:*?"<>|]', '_'
        $Global:ProfileName = $custom
    }

    Write-Host ("  " + (Get-Text "profile_name_set") + $Global:ProfileName) -ForegroundColor Green
    return $Global:ProfileName
}


# ============================================================
#  套用分派 - 選項式 (Apply Dispatcher - Choice)
#  套用「選項式」設定項中,使用者選中的那個選項。依選項攜帶的欄位分派:
#    None   -> 不做任何動作 (使用者選擇維持現狀)
#    Reg    -> 登錄檔寫入,選項自帶完整清單 (複雜型,可多筆)
#    Value  -> 登錄檔寫入,同一位置換數值,Value 由選項帶、
#              Path/Name/Type 由 Item 層級的 RegPath/RegName/RegType 帶 (簡潔型)
#    RegDel -> 登錄檔刪除 (可多筆,回傳 Backups 供還原)
#  回傳統一格式:@{ Success; Message; Backups; Note; NoAction }
# ============================================================

<#
.SYNOPSIS
    依 ChoiceRef 從 Item.Choices 中找出對應選項物件。
    ChoiceRef 可以是選項 Id (新格式,字串) 或原始 1-based 編號 (舊格式,向後相容)。
    找不到回傳 $null。
#>
function Get-ChoiceByRef {
    param(
        [Parameter(Mandatory)][hashtable]$Item,
        [Parameter(Mandatory)][string]$ChoiceRef
    )

    # 新格式:字串 Id
    foreach ($ch in $Item.Choices) {
        if ($ch.ContainsKey("Id") -and $ch.Id -eq $ChoiceRef) { return $ch }
    }
    # 舊格式:純數字,視為 1-based 編號
    if ($ChoiceRef -match '^\d+$') {
        $idx = [int]$ChoiceRef - 1
        if ($idx -ge 0 -and $idx -lt $Item.Choices.Count) { return $Item.Choices[$idx] }
    }
    return $null
}

function Invoke-ApplyChoiceItem {
    param(
        [Parameter(Mandatory)][hashtable]$Item,
        [Parameter(Mandatory)][string]$ChoiceRef
    )

    # 版本門檻:不符則回報不支援 (與 Invoke-ApplyItem 相同邏輯)
    $minBuild = if ($Item.ContainsKey("MinBuild")) { [int]$Item.MinBuild } else { 0 }
    if (-not (Test-BuildSupported -MinBuild $minBuild)) {
        return @{ Success = $false; Unsupported = $true; Message = (Get-Text "unsupported_skip") }
    }

    $selected = Get-ChoiceByRef -Item $Item -ChoiceRef $ChoiceRef
    if ($null -eq $selected) {
        return @{ Success = $false; Message = "找不到選項:$ChoiceRef" }
    }

    # ── 維持現狀,無需動作 ──
    if ($selected.ContainsKey("None") -and $selected.None) {
        return @{ Success = $true; Message = "使用者選擇維持現狀"; NoAction = $true }
    }

    # ── 前提條件檢查 (選項可帶 RequirePath) ──
    # 用於「App 專屬深層設定鍵」情境:某些設定 (如新版 Teams 的 StartupTask)
    # 只有在該 App 已安裝且初始化後,其登錄檔鍵才存在。若鍵不存在,代表 App
    # 未安裝/未初始化,此時憑空建立深層鍵通常無效 (App 之後會覆蓋),故視為
    # 「無需設定」直接回報成功並附註記 (與 RegDel『原本不存在』同一處理模式)。
    if ($selected.ContainsKey("RequirePath") -and -not (Test-Path $selected.RequirePath)) {
        return @{ Success = $true; Message = "前提路徑不存在,無需設定"; Note = (Get-Text "prereq_notfound") }
    }

    # ── 登錄檔寫入:選項自帶完整 Reg 清單 (複雜型) ──
    if ($selected.ContainsKey("Reg")) {
        $ok = $true; $msg = ""
        foreach ($r in $selected.Reg) {
            $res = Set-RegistryValue -Path $r.Path -Name $r.Name -Value $r.Value -Type $r.Type
            if (-not $res.Success) { $ok = $false; $msg = $res.Message }
        }
        return @{ Success = $ok; Message = $msg }
    }

    # ── 登錄檔寫入:同一位置換數值 (簡潔型) ──
    if ($selected.ContainsKey("Value") -and $Item.ContainsKey("RegPath")) {
        $res = Set-RegistryValue -Path $Item.RegPath -Name $Item.RegName -Value $selected.Value -Type $Item.RegType
        return @{ Success = $res.Success; Message = $res.Message }
    }

    # ── 刪除登錄檔值 (會先備份) ──
    if ($selected.ContainsKey("RegDel")) {
        $ok = $true; $msg = ""; $backups = @(); $deletedCount = 0
        foreach ($r in $selected.RegDel) {
            $res = Remove-RegistryValue -Path $r.Path -Name $r.Name
            if (-not $res.Success) { $ok = $false; $msg = $res.Message }
            elseif ($res.Backup)  { $backups += $res.Backup; $deletedCount++ }
        }
        $note = if ($deletedCount -gt 0) { (Get-Text "del_note_deleted") } else { (Get-Text "del_note_notfound") }
        return @{ Success = $ok; Message = $msg; Backups = $backups; Note = $note }
    }

    # ── 服務 (可單筆或多筆) ──
    # 每筆 @{ Name=..; StartType=4 };StartType 預設 4 (停用)。
    # 若所有服務都不存在於此系統,回報不支援 (歸「版本不支援/不適用」)。
    if ($selected.ContainsKey("Svc")) {
        $ok = $true; $msg = ""; $anySupported = $false
        foreach ($s in @($selected.Svc)) {
            $st  = if ($s.ContainsKey("StartType")) { [int]$s.StartType } else { 4 }
            $res = Set-ServiceStartType -ServiceName $s.Name -StartType $st
            if ($res.Success) { $anySupported = $true }
            elseif (-not $res.Unsupported) { $ok = $false; $msg = $res.Message; $anySupported = $true }
        }
        if (-not $anySupported) { return @{ Success = $false; Unsupported = $true; Message = "服務不存在於此系統" } }
        return @{ Success = $ok; Message = $msg }
    }

    # ── 排程 (可單筆或多筆) ──
    # 每筆 @{ Path=..; Name=.. }。若所有排程都不存在,回報不支援。
    if ($selected.ContainsKey("Task")) {
        $ok = $true; $msg = ""; $anySupported = $false
        foreach ($t in @($selected.Task)) {
            $tn  = if ($t.ContainsKey("Name")) { $t.Name } else { "" }
            $en  = if ($t.ContainsKey("Enable")) { [bool]$t.Enable } else { $false }
            $res = Set-ScheduledTaskState -TaskPath $t.Path -TaskName $tn -Enable $en
            if ($res.Success) { $anySupported = $true }
            elseif (-not $res.Unsupported) { $ok = $false; $msg = $res.Message; $anySupported = $true }
        }
        if (-not $anySupported) { return @{ Success = $false; Unsupported = $true; Message = "排程不存在於此系統" } }
        return @{ Success = $ok; Message = $msg }
    }

    # ── 移除預裝 App ──
    # 值為套件名稱字串 (如 "Microsoft.BingSearch")。
    if ($selected.ContainsKey("Appx")) {
        return (Remove-AppxSafe -PackageName $selected.Appx)
    }

    # ── 自訂 scriptblock ──
    # 值為 scriptblock,需回傳 @{ Success; Message }。
    # (註:KB 由 Import-PowerShellDataFile 載入,只能放純資料,不能放 scriptblock;
    #  故 KB 項目請改用下方的 Special 具名特殊動作,Custom 僅供程式碼內建項目使用。)
    if ($selected.ContainsKey("Custom")) {
        try { return (& $selected.Custom) }
        catch { return @{ Success = $false; Message = $_.Exception.Message } }
    }

    # ── 具名特殊動作 (Special) ──
    # 值為字串標記 (純資料,可寫在 KB),對應引擎內建的 Invoke-SpecialAction。
    # 用於「需執行期邏輯」的狀態 (如 OneDrive 啟用需先偵測安裝路徑再重建 Run 鍵)。
    if ($selected.ContainsKey("Special")) {
        return (Invoke-SpecialAction -Name $selected.Special)
    }

    return @{ Success = $false; Message = "此選項未定義套用方式" }
}


# ============================================================
#  具名特殊動作 (Named Special Actions)
#  KB 只能放純資料,無法內嵌 scriptblock;凡是「需要執行期邏輯」才能
#  完成的狀態 (例如 OneDrive 啟用得先偵測安裝路徑),就在 KB 選項寫一個
#  字串標記 (Special = "xxx"),實際邏輯集中寫在這裡,依名稱分派。
# ============================================================

<#
.SYNOPSIS
    執行具名特殊動作,回傳 @{ Success; Message; Unsupported? }。
.PARAMETER Name
    特殊動作名稱 (對應 KB 選項的 Special 欄位)。
#>
function Invoke-SpecialAction {
    param([Parameter(Mandatory)][string]$Name)

    switch ($Name) {
        # OneDrive 啟用開機自啟:偵測 OneDrive.exe 實際安裝位置,用真實路徑
        # 重建 HKCU Run 機碼。三種安裝形態依序偵測;都找不到代表未安裝,
        # 回報不支援 (歸「不適用」,不會誤建指向不存在程式的壞啟動項)。
        "onedrive_enable" {
            $candidates = @()
            if ($env:LOCALAPPDATA)        { $candidates += (Join-Path $env:LOCALAPPDATA        "Microsoft\OneDrive\OneDrive.exe") }
            if ($env:ProgramFiles)        { $candidates += (Join-Path $env:ProgramFiles        "Microsoft OneDrive\OneDrive.exe") }
            if (${env:ProgramFiles(x86)}) { $candidates += (Join-Path ${env:ProgramFiles(x86)} "Microsoft OneDrive\OneDrive.exe") }

            $exe = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
            if (-not $exe) {
                return @{ Success = $false; Unsupported = $true; Message = "OneDrive 未安裝於此系統" }
            }
            # Run 機碼標準值:"完整路徑" /background
            $value = '"' + $exe + '" /background'
            return (Set-RegistryValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -Value $value -Type "String")
        }

        # 古典右鍵選單 - 啟用:建立 InprocServer32 鍵並把 (Default) 設為空字串。
        # 空字串 (非「值未設定」) 才會讓 Explorer 回退到 Win10 完整選單。
        # 用 Set-Item 設定鍵的預設值最可靠。
        "classic_context_classic" {
            $key = "HKCU:\SOFTWARE\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
            try {
                if (-not (Test-Path $key)) { New-Item -Path $key -Force -ErrorAction Stop | Out-Null }
                Set-Item -Path $key -Value "" -ErrorAction Stop
                return @{ Success = $true; Message = "已切換為 Win10 完整右鍵選單 (需重啟檔案總管生效)" }
            }
            catch { return @{ Success = $false; Message = $_.Exception.Message } }
        }

        # 古典右鍵選單 - 還原:刪除整個 {86ca...} CLSID 鍵,回到 Win11 精簡選單。
        # (RegDel 只能刪值不能刪鍵,故此還原走特殊動作。)
        "classic_context_restore" {
            $key = "HKCU:\SOFTWARE\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
            if (-not (Test-Path $key)) {
                return @{ Success = $true; Message = "原本即為 Win11 選單,無需還原" }
            }
            try {
                Remove-Item -Path $key -Recurse -Force -ErrorAction Stop
                return @{ Success = $true; Message = "已還原 Win11 精簡右鍵選單 (需重啟檔案總管生效)" }
            }
            catch { return @{ Success = $false; Message = $_.Exception.Message } }
        }

        # 電源計畫切換 (powercfg /setactive <GUID>)。三個標準計畫共用一段邏輯,
        # 差別只在 GUID;找不到該計畫 (GUID 未安裝) 時回報不支援,不誤設。
        "powerplan_high"     { return (Set-PowerScheme -Guid "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" -Label "高效能") }
        "powerplan_balanced" { return (Set-PowerScheme -Guid "381b4222-f694-41f0-9685-ff5bb260df2e" -Label "平衡") }
        "powerplan_saver"    { return (Set-PowerScheme -Guid "a1841308-3541-4fab-bc81-f71556f20b4a" -Label "省電") }

        # NetBIOS over TCP/IP:設定綁在每個網路介面 (per-interface),需列舉
        # NetBT\Parameters\Interfaces 下所有 Tcpip_{GUID} 子鍵逐一設 NetbiosOptions。
        # 2=停用、0=預設(依 DHCP)。停用可防 NBT-NS poisoning。
        "netbios_disable" { return (Set-NetbiosAllInterfaces -Value 2 -Label "停用") }
        "netbios_default" { return (Set-NetbiosAllInterfaces -Value 0 -Label "還原預設") }

        default {
            return @{ Success = $false; Message = "未知的特殊動作:$Name" }
        }
    }
}

<#
.SYNOPSIS
    對所有網路介面設定 NetBIOS over TCP/IP (NetbiosOptions)。
    設定是 per-interface 的,故列舉 NetBT\Parameters\Interfaces 下所有子鍵逐一寫入。
.PARAMETER Value
    NetbiosOptions 值:2=停用、1=啟用、0=預設(依 DHCP)。
.PARAMETER Label
    動作中文名稱 (供訊息顯示)。
#>
function Set-NetbiosAllInterfaces {
    param(
        [Parameter(Mandatory)][int]$Value,
        [Parameter(Mandatory)][string]$Label
    )
    $base = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces"
    if (-not (Test-Path $base)) {
        return @{ Success = $false; Unsupported = $true; Message = "找不到 NetBT 介面清單" }
    }
    # 只處理 Tcpip_ 開頭的介面子鍵 (每個網路介面一個)
    $ifaces = Get-ChildItem -Path $base -ErrorAction SilentlyContinue |
              Where-Object { $_.PSChildName -like "Tcpip_*" }
    if (-not $ifaces -or $ifaces.Count -eq 0) {
        return @{ Success = $false; Unsupported = $true; Message = "無可設定的網路介面" }
    }
    $done = 0
    foreach ($if in $ifaces) {
        try {
            Set-ItemProperty -Path $if.PSPath -Name "NetbiosOptions" -Value $Value -Type DWord -ErrorAction Stop
            $done++
        }
        catch {
            return @{ Success = $false; Message = "設定介面 $($if.PSChildName) 失敗:$($_.Exception.Message)" }
        }
    }
    return @{ Success = $true; Message = "已對 $done 個網路介面$Label NetBIOS" }
}

<#
.SYNOPSIS
    切換使用中的電源計畫 (powercfg /setactive)。計畫 GUID 不存在時回報不支援。
.PARAMETER Guid
    電源計畫 GUID。
.PARAMETER Label
    計畫中文名稱 (供訊息顯示)。
#>
function Set-PowerScheme {
    param(
        [Parameter(Mandatory)][string]$Guid,
        [Parameter(Mandatory)][string]$Label
    )
    # 先確認此 GUID 存在於系統的電源計畫清單 (powercfg /list)
    $list = (& powercfg /list 2>&1) -join "`n"
    if ($list -notmatch [regex]::Escape($Guid)) {
        return @{ Success = $false; Unsupported = $true; Message = "此系統無『$Label』電源計畫 (GUID 未安裝)" }
    }
    $out = (& powercfg /setactive $Guid 2>&1) -join "`n"
    if ($LASTEXITCODE -eq 0) {
        return @{ Success = $true; Message = "已切換電源計畫為『$Label』" }
    }
    return @{ Success = $false; Message = "切換電源計畫失敗:$out" }
}

<#
.SYNOPSIS
    偵測某具名特殊動作對應的狀態目前是否成立 (供「目前狀態」顯示)。
    與 Invoke-SpecialAction 不同:此處只讀取、不寫入。
.PARAMETER Name
    特殊動作名稱。
.OUTPUTS
    $true = 此狀態目前成立 / $false = 不成立或未知名稱
#>
function Test-SpecialState {
    param([Parameter(Mandatory)][string]$Name)

    switch ($Name) {
        # OneDrive 啟用:HKCU Run 機碼存在 OneDrive 值 → 目前為開機自啟開啟
        "onedrive_enable" {
            return ($null -ne (Get-RegistryValueOrNull -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive"))
        }
        # 古典右鍵啟用:InprocServer32 鍵存在 → 目前為 Win10 完整選單
        "classic_context_classic" {
            return (Test-Path "HKCU:\SOFTWARE\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32")
        }
        # 電源計畫:目前使用中的計畫 GUID 是否等於該選項對應的 GUID
        "powerplan_high"     { return (Test-ActivePowerScheme "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c") }
        "powerplan_balanced" { return (Test-ActivePowerScheme "381b4222-f694-41f0-9685-ff5bb260df2e") }
        "powerplan_saver"    { return (Test-ActivePowerScheme "a1841308-3541-4fab-bc81-f71556f20b4a") }
        # NetBIOS:所有網路介面的 NetbiosOptions 皆為該值,才算目前是此狀態
        "netbios_disable" { return (Test-NetbiosAllInterfaces 2) }
        "netbios_default" { return (Test-NetbiosAllInterfaces 0) }
        default { return $false }
    }
}

<#
.SYNOPSIS
    判斷是否所有網路介面的 NetbiosOptions 都等於指定值。
#>
function Test-NetbiosAllInterfaces {
    param([Parameter(Mandatory)][int]$Value)
    $base = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces"
    if (-not (Test-Path $base)) { return $false }
    $ifaces = Get-ChildItem -Path $base -ErrorAction SilentlyContinue |
              Where-Object { $_.PSChildName -like "Tcpip_*" }
    if (-not $ifaces -or $ifaces.Count -eq 0) { return $false }
    foreach ($if in $ifaces) {
        $cur = Get-RegistryValueOrNull -Path $if.PSPath -Name "NetbiosOptions"
        if ($cur -ne $Value) { return $false }   # 有任一介面不符 → 非此狀態
    }
    return $true
}

<#
.SYNOPSIS
    判斷目前使用中的電源計畫 GUID 是否為指定值 (powercfg /getactivescheme)。
#>
function Test-ActivePowerScheme {
    param([Parameter(Mandatory)][string]$Guid)
    $out = (& powercfg /getactivescheme 2>&1) -join "`n"
    return ($out -match [regex]::Escape($Guid))
}


# ============================================================
#  斷點續傳詢問 (Resume Prompt)
#  偵測到中斷時顯示流程說明,詢問續傳或重來。
#  回傳:$true=續傳 / $false=重新開始
# ============================================================
function Show-ResumePrompt {
    param(
        [Parameter(Mandatory)]$Progress,
        [int]$Total
    )

    $pos = [int]$Progress.current_index + 1

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ("  " + (Get-Text "resume_detected")) -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ("  " + (Get-Text "resume_last_pos") + " : " + (Get-Text "progress") + " $pos / $Total") -ForegroundColor White
    Write-Host ""
    Write-Host ("  " + (Get-Text "resume_flow_title") + ":") -ForegroundColor Cyan
    Write-Host ("   - " + (Get-Text "resume_flow_1")) -ForegroundColor Gray
    Write-Host ("   - " + (Get-Text "resume_flow_2")) -ForegroundColor Gray
    Write-Host ("   - " + (Get-Text "resume_flow_4")) -ForegroundColor Gray
    Write-Host ("   - " + (Get-Text "resume_flow_5")) -ForegroundColor Gray
    Write-Host ""
    Write-Host ("  [Y] " + (Get-Text "resume_choice_y")) -ForegroundColor Green
    Write-Host ("  [N] " + (Get-Text "resume_choice_n")) -ForegroundColor DarkYellow
    Write-Host "────────────────────────────────────" -ForegroundColor DarkCyan

    $c = Read-Choice -ValidKeys @("Y", "N") -Labels @{
        Y = (Get-Text "resume_btn_y")
        N = (Get-Text "resume_btn_n")
    }
    return ($c -eq "Y")
}


# ============================================================
#  分類執行流程 - 通用引擎 (Category Runner)
#  所有模組共用此流程。模組只需提供:ModuleId / ModuleTitle / Items / Mode。
#
#  流程:斷點偵測 → (續傳或重來) → 逐題提問 → 套用 → 驗證 → 摘要 → 匯出
# ============================================================
function Invoke-Category {
    param(
        [Parameter(Mandatory)][string]$ModuleId,
        [Parameter(Mandatory)][string]$ModuleTitle,
        [Parameter(Mandatory)][array]$Items,
        [string]$Mode = "individual"
    )

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ("  " + $ModuleTitle) -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    Start-ExecutionLog -Scope $ModuleId | Out-Null

    # 目前實作 individual(逐題);grouped(分組)於首個分組模組時擴充
    if ($Mode -ne "individual") {
        Write-Host ("  " + (Get-Text "grp_not_impl")) -ForegroundColor Yellow
        Write-Log -Message "分組模式尚未實作" -Level WARN -Module $ModuleId
        return
    }

    # ---- 斷點續傳偵測 ----
    $startIndex = 0
    $answers    = [ordered]@{}
    $prog = Read-Progress
    if ($prog -and $prog.module -eq $ModuleId -and $prog.status -eq "in_progress") {
        if (Show-ResumePrompt -Progress $prog -Total $Items.Count) {
            # 續傳:依 Items 順序重建有序字典 (Progress.json 讀回為物件)
            foreach ($it in $Items) {
                if ($prog.answered.PSObject.Properties.Name -contains $it.Id) {
                    $answers[$it.Id] = $prog.answered.$($it.Id)
                }
            }
            $startIndex = [int]$prog.current_index
            Write-Log -Message "從第 $($startIndex + 1) 題續傳" -Level INFO -Module $ModuleId
        }
        else {
            Clear-Progress   # 重來:備份舊進度
            Write-Log -Message "使用者選擇重新開始" -Level INFO -Module $ModuleId
        }
    }

    # ---- 階段一:逐題提問 ----
    # 所有設定項均為「選項式」(帶 Choices 欄位),以 1~5 數字選擇,S/P/Q 控制。
    $i = $startIndex
    while ($i -lt $Items.Count) {
        $item = $Items[$i]

        $choice = Show-ChoiceQuestion -Item $item -Index ($i + 1) -Total $Items.Count -ModuleTitle $ModuleTitle

        # 回傳值:選項 Id (字串) 或控制鍵 (S/P/Q/UNSUPPORT)。
        # 非控制鍵一律當作「選中的選項 Id」記入。
        if ($choice -notin @("S","P","Q","UNSUPPORT")) {
            $answers[$item.Id] = $choice
            $i++
        }
        else {
            switch ($choice) {
                "S"         { $answers[$item.Id] = "skipped";     $i++ }
                "UNSUPPORT" { $answers[$item.Id] = "unsupported"; $i++ }
                "P" {
                    if ($i -gt 0) { $i-- }
                    else { Write-Host ("  " + (Get-Text "already_first")) -ForegroundColor DarkYellow }
                }
                "Q" {
                    Save-Progress -Data ([ordered]@{
                        module = $ModuleId; status = "in_progress"
                        current_index = $i; total = $Items.Count; answered = $answers
                    }) | Out-Null
                    Write-Log -Message "使用者於第 $($i + 1) 題中斷" -Level WARN -Module $ModuleId
                    Write-Host ""
                    Write-Host ("  " + (Get-Text "interrupted_saved")) -ForegroundColor Yellow
                    return
                }
            }
        }

        # 每答一題即時存進度 (斷點續傳)
        Save-Progress -Data ([ordered]@{
            module = $ModuleId; status = "in_progress"
            current_index = $i; total = $Items.Count; answered = $answers
        }) | Out-Null
    }

    # ---- 階段二~五:套用 → 摘要 → 匯出 ----
    Invoke-CategoryApply -ModuleId $ModuleId -ModuleTitle $ModuleTitle -Items $Items -Answers $answers
}


# ============================================================
#  摘要單行輸出 (Summary Line)
#  顯示「標籤 : 數量」,若有項目則逐一列出名稱。
# ============================================================
function Write-SummaryLine {
    param(
        [Parameter(Mandatory)][string]$Label,
        [array]$Names = @(),
        [string]$Color = "Gray",
        [string]$Symbol = "-"      # 各項目前綴符號 (如 [v] [x] [-] [>] [NA])
    )
    Write-Host ("  " + $Label + " : " + $Names.Count) -ForegroundColor $Color
    foreach ($n in $Names) {
        Write-Host ("    " + $Symbol + " " + $n) -ForegroundColor $Color
    }
}


# ============================================================
#  分類套用 (Category Apply)
#  依答案套用「applied」項目,驗證、記錄、摘要、匯出設定檔。
#  互動流程與「載入設定檔套用」流程共用此函式。
# ============================================================
function Invoke-CategoryApply {
    param(
        [Parameter(Mandatory)][string]$ModuleId,
        [Parameter(Mandatory)][string]$ModuleTitle,
        [Parameter(Mandatory)][array]$Items,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Answers
    )

    # ---- 刪除操作確認 (最後同意才刪除) ----
    # 找出「即將套用且使用者選中的選項本身帶 RegDel」的項目 (依選項 Id 查回)
    $delItems = @()
    foreach ($it in $Items) {
        $ans = [string]$Answers[$it.Id]
        if ($it.ContainsKey("Choices")) {
            $sel = Get-ChoiceByRef -Item $it -ChoiceRef $ans
            if ($sel -and $sel.ContainsKey("RegDel")) { $delItems += $it }
        }
    }
    if ($delItems.Count -gt 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host ("  " + (Get-Text "del_confirm_title")) -ForegroundColor Yellow
        Write-Host "========================================" -ForegroundColor Yellow
        Write-Host ("  " + (Get-Text "del_confirm_desc")) -ForegroundColor White
        foreach ($d in $delItems) {
            Write-Host ("    [!] " + (Get-Field -Obj $d -Base "Name")) -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host ("  " + (Get-Text "del_confirm_note")) -ForegroundColor Gray
        Write-Host "────────────────────────────────────" -ForegroundColor DarkCyan
        $delChoice = Read-Choice -ValidKeys @("Y", "N") -Labels @{
            Y = (Get-Text "del_confirm_yes")
            N = (Get-Text "del_confirm_no")
        }
        if ($delChoice -eq "N") {
            # 使用者不同意刪除,不執行刪除:
            #   舊版項目 → 改回 declined
            #   選項式項目 → 改選同一項目中的 None (維持現狀) 選項;優先用 Id,
            #                若該項目沒有 None 選項可選 (理論上不應發生),退回 declined
            foreach ($d in $delItems) {
                $noneRef = $null
                for ($n = 0; $n -lt $d.Choices.Count; $n++) {
                    if ($d.Choices[$n].ContainsKey("None") -and $d.Choices[$n].None) {
                        $noneRef = if ($d.Choices[$n].ContainsKey("Id")) { [string]$d.Choices[$n].Id } else { "$($n + 1)" }
                        break
                    }
                }
                $Answers[$d.Id] = if ($noneRef) { $noneRef } else { "declined" }
            }
            Write-Host ("  " + (Get-Text "del_skipped")) -ForegroundColor DarkYellow
            Write-Log -Message "使用者略過所有刪除項目" -Level INFO -Module $ModuleId
        }
    }

    # 統計即將套用的項目數 (任何有效選項參照,含「維持現狀」)
    $toApplyCount = 0
    foreach ($it in $Items) {
        $ans = [string]$Answers[$it.Id]
        if (Get-ChoiceByRef -Item $it -ChoiceRef $ans) { $toApplyCount++ }
    }
    Write-Host ""
    Write-Host ("  " + (Get-Text "applying_count" -Args @($toApplyCount))) -ForegroundColor Cyan

    # 套用階段:逐項套用並依結果分類收集項目名稱
    # (套用過程只寫入日誌,不逐項顯示於畫面;完整明細統一在最後摘要呈現,避免重複)
    $okList = @(); $failList = @(); $maintainList = @(); $allBackups = @()
    foreach ($item in $Items) {
        $ans = [string]$Answers[$item.Id]
        $itemLabel = (Get-Field -Obj $item -Base "Name")

        # 所有設定項均為選項式:依選中的選項 Id 套用
        $sel = Get-ChoiceByRef -Item $item -ChoiceRef $ans
        if ($null -eq $sel) { continue }   # 跳過 / 不支援 / 無效參照 → 不套用
        $selectedLabel = (Get-Field -Obj $sel -Base "Label")

        # ---- 「已是此設定」偵測 ----
        # 若「明確偵測到」系統目前狀態就等於使用者選的狀態 → 無需重複寫入,
        # 歸「維持不變」。採保守原則:只有在明確相同時才跳過;偵測不到目前狀態
        # (Get-CurrentChoiceState 回 null) 或狀態不同時,一律照常套用,確保不漏套。
        # 「維持現狀」(None) 選項本身不比對 (它交由 Invoke-ApplyChoiceItem 回 NoAction)。
        if (-not ($sel.ContainsKey("None") -and $sel.None)) {
            $curState = Get-CurrentChoiceState -Item $item
            if ($null -ne $curState -and $curState -eq $selectedLabel) {
                $maintainList += "$itemLabel → $selectedLabel ($(Get-Text 'already_set'))"
                Write-Log -Message "已是此設定,無需套用" -Level OK -Module $ModuleId -Item $itemLabel
                continue
            }
        }

        $res = Invoke-ApplyChoiceItem -Item $item -ChoiceRef $ans

        # 收集刪除操作的備份 (供還原檔)
        if ($res.ContainsKey("Backups") -and $res.Backups.Count -gt 0) {
            $allBackups += $res.Backups
        }

        if ($res.Success) {
            # 名稱附加「→ 選中的選項」,方便從摘要辨識實際選了什麼;
            # 若有註記 (如刪除的「已刪除」/「無需刪除」、前提不符的「未安裝」) 一併附上。
            $suffix = if ($res.ContainsKey("Note") -and $res.Note) { "$selectedLabel ($($res.Note))" } else { $selectedLabel }
            $displayName = "$itemLabel → $suffix"

            # 解析結果為「無動作」(選了維持現狀) → 歸類到「維持不變」而非「成功套用」
            if ($res.ContainsKey("NoAction") -and $res.NoAction) {
                $maintainList += $displayName
            }
            else {
                $okList += $displayName
            }
            Write-Log -Message "套用成功" -Level OK -Module $ModuleId -Item $itemLabel
        }
        elseif ($res.Unsupported) {
            $Answers[$item.Id] = "unsupported"   # 套用時才發現不支援,回填狀態
            Write-Log -Message $res.Message -Level UNSUPPORT -Module $ModuleId -Item $itemLabel
        }
        else {
            $failList += $itemLabel
            Write-Log -Message ("套用失敗:" + $res.Message) -Level FAIL -Module $ModuleId -Item $itemLabel
        }
    }

    # ---- 結果摘要 ----
    # 依最終答案,把各狀態的「項目名稱」收集起來 (供逐一列出明細)
    $declinedList = @(); $skippedList = @(); $unsupList = @()
    foreach ($item in $Items) {
        $itemLabel = (Get-Field -Obj $item -Base "Name")
        switch ($Answers[$item.Id]) {
            "declined"    { $declinedList += $itemLabel }
            "skipped"     { $skippedList  += $itemLabel }
            "unsupported" { $unsupList    += $itemLabel }
        }
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ("  " + (Get-Text "summary_title") + " - " + $ModuleTitle) -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    # 每個狀態:先顯示「標籤 : 數量」,再逐一列出項目 (前綴符號)。
    # 「不套用 (declined)」僅在極少數選項式項目缺 None 選項、又被使用者取消刪除時
    # 退回此狀態才會有內容,故依清單是否為空決定是否顯示,避免無意義的空類別。
    Write-SummaryLine -Label (Get-Text "summary_applied")     -Names $okList        -Color Green      -Symbol "[v]"
    Write-SummaryLine -Label (Get-Text "summary_maintained")  -Names $maintainList  -Color DarkYellow -Symbol "[-]"
    Write-SummaryLine -Label (Get-Text "summary_failed")      -Names $failList      -Color Red        -Symbol "[x]"
    if ($declinedList.Count -gt 0) {
        Write-SummaryLine -Label (Get-Text "summary_declined") -Names $declinedList -Color DarkYellow -Symbol "[-]"
    }
    Write-SummaryLine -Label (Get-Text "summary_skipped")     -Names $skippedList   -Color Gray       -Symbol "[>]"
    Write-SummaryLine -Label (Get-Text "summary_unsupported") -Names $unsupList     -Color DarkGray   -Symbol "[NA]"


    # ---- 匯出設定檔 ----
    $exp = Export-Config -ModuleId $ModuleId -Answers $Answers
    if ($exp.Success) {
        Write-Host ""
        Write-Host ("  " + (Get-Text "summary_export_ok") + ":") -ForegroundColor Green
        Write-Host ("    " + $exp.Path) -ForegroundColor Gray
        Write-Log -Message ("設定檔已匯出:" + $exp.Path) -Level OK -Module $ModuleId
    }

    # ---- 若有刪除操作:寫入還原檔並告知使用者 ----
    if ($allBackups.Count -gt 0) {
        $rst = Export-RestoreFile -ModuleId $ModuleId -Backups $allBackups
        if ($rst.Success) {
            Write-Host ""
            Write-Host ("  " + (Get-Text "restore_file_created") + ":") -ForegroundColor Yellow
            Write-Host ("    " + $rst.Path) -ForegroundColor Gray
            Write-Host ("  " + (Get-Text "restore_file_hint")) -ForegroundColor Gray
            Write-Log -Message ("還原檔已建立:" + $rst.Path) -Level OK -Module $ModuleId
        }
    }

    # ---- 完成:標記 completed 後清除 (備份) ----
    Save-Progress -Data ([ordered]@{
        module = $ModuleId; status = "completed"
        current_index = $Items.Count; total = $Items.Count; answered = $Answers
    }) | Out-Null
    Clear-Progress
    Write-Log -Message "本類執行完畢" -Level INFO -Module $ModuleId
}


# ============================================================
#  結尾:標記模組已載入
# ============================================================
$Global:CommonLoaded = $true
