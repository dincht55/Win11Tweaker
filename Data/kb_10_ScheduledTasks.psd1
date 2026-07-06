<#
    Windows 11 設定精靈 - 知識庫:第 11 類 排程工作 (Scheduled Tasks)
    ================================================================
    格式:選項式統一模型 (Choices + Recommend),三選項雙向。
    提問模式:逐題 (individual) —— 排程停用與否因人而異,逐一知情決定。

    每個排程三選項:停用 (Disable) / 啟用 (Enable) / 維持 (keep)。
    Enter 跟隨建議 (通用引擎 Show-ChoiceQuestion 已支援)。
    引擎動作:Task = @(@{ Path; Name; Enable=$false/$true }),
    呼叫 Set-ScheduledTaskState;排程不存在時自動標「系統不支援」不報錯。

    收錄以遙測/資料收集/回饋類為主 (多數停用純賺或影響極小);
    錯誤回報與磁碟診斷為知情取捨,保守建議維持。各排程逐一說明由使用者決定。

    Import-PowerShellDataFile 規定檔案最外層須為 Hashtable。
#>

@{
    Items = @(
    @{
        Id      = "task_ceip_consolidator"
        Category = 10
        NameZh  = "客戶經驗改進計畫 (Consolidator)"
        NameEn  = "Customer Experience Improvement Program (Consolidator)"
        DescZh  = "定期收集使用資料回傳微軟以「改進產品」。停用不影響系統功能,純隱私考量。"
        DescEn  = "Periodically collects usage data and sends it to Microsoft to 'improve products'. Disabling doesn't affect system functionality; purely a privacy consideration."
        Choices = @(
            @{ Id = "disable"; Label = "停用"; LabelEn = "Disable"
               Task = @(@{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "Consolidator"; Enable = $false }) }
            @{ Id = "enable"; Label = "啟用"; LabelEn = "Enable"
               Task = @(@{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "Consolidator"; Enable = $true }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        VerifiedDate = "2026-07-05"
        Notes        = "CEIP 純遙測,停用幾乎純賺 (不再回傳使用統計),功能面無影響。建議停用。"
        NotesEn        = "CEIP is pure telemetry; disabling is almost all upside (no more usage statistics reported) with no functional impact. Recommended to disable."
    },
    @{
        Id      = "task_ceip_usb"
        Category = 10
        NameZh  = "客戶經驗改進計畫 (USB 使用資料)"
        NameEn  = "Customer Experience Improvement Program (USB Usage Data)"
        DescZh  = "收集 USB 裝置使用資料回傳微軟。停用不影響 USB 正常使用。"
        DescEn  = "Collects USB device usage data and sends it to Microsoft. Disabling doesn't affect normal USB use."
        Choices = @(
            @{ Id = "disable"; Label = "停用"; LabelEn = "Disable"
               Task = @(@{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "UsbCeip"; Enable = $false }) }
            @{ Id = "enable"; Label = "啟用"; LabelEn = "Enable"
               Task = @(@{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "UsbCeip"; Enable = $true }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        VerifiedDate = "2026-07-05"
        Notes        = "收集 USB 使用統計回傳微軟,停用不影響 USB 裝置運作。建議停用。"
        NotesEn        = "Collects USB usage statistics for Microsoft; disabling doesn't affect USB device operation. Recommended to disable."
    },
    @{
        Id      = "task_ceip_kernel"
        Category = 10
        NameZh  = "客戶經驗改進計畫 (核心遙測)"
        NameEn  = "Customer Experience Improvement Program (Kernel Telemetry)"
        DescZh  = "收集核心層級的使用資料回傳微軟。停用不影響系統運作。"
        DescEn  = "Collects kernel-level usage data and sends it to Microsoft. Disabling doesn't affect system operation."
        Choices = @(
            @{ Id = "disable"; Label = "停用"; LabelEn = "Disable"
               Task = @(@{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "KernelCeipTask"; Enable = $false }) }
            @{ Id = "enable"; Label = "啟用"; LabelEn = "Enable"
               Task = @(@{ Path = "\Microsoft\Windows\Customer Experience Improvement Program\"; Name = "KernelCeipTask"; Enable = $true }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        VerifiedDate = "2026-07-05"
        Notes        = "核心 CEIP 遙測,停用純賺。部分系統可能無此排程 (會自動略過)。建議停用。"
        NotesEn        = "Kernel CEIP telemetry; disabling is pure upside. Some systems may lack this task (skipped automatically). Recommended to disable."
    },
    @{
        Id      = "task_compat_appraiser"
        Category = 10
        NameZh  = "應用程式相容性評估"
        NameEn  = "Application Compatibility Appraiser"
        DescZh  = "掃描已安裝軟體並回傳相容性資料 (CompatTelRunner)。常造成 CPU 尖峰。停用可減少背景負載,但升級前的相容性檢查會減少。"
        DescEn  = "Scans installed software and reports compatibility data (CompatTelRunner). Often causes CPU spikes. Disabling reduces background load but decreases pre-upgrade compatibility checks."
        Choices = @(
            @{ Id = "disable"; Label = "停用"; LabelEn = "Disable"
               Task = @(@{ Path = "\Microsoft\Windows\Application Experience\"; Name = "Microsoft Compatibility Appraiser"; Enable = $false }) }
            @{ Id = "enable"; Label = "啟用"; LabelEn = "Enable"
               Task = @(@{ Path = "\Microsoft\Windows\Application Experience\"; Name = "Microsoft Compatibility Appraiser"; Enable = $true }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        VerifiedDate = "2026-07-05"
        Notes        = "此排程 (CompatTelRunner) 常是背景 CPU 尖峰元凶,收集相容性遙測。停用讓系統更安靜。代價:升級大版本前的相容性評估資料減少 (不影響實際升級)。建議停用。"
        NotesEn        = "This task (CompatTelRunner) is often the culprit behind background CPU spikes, collecting compatibility telemetry. Disabling makes the system quieter. Cost: less compatibility appraisal data before major upgrades (doesn't affect the actual upgrade). Recommended to disable."
    },
    @{
        Id      = "task_programdata"
        Category = 10
        NameZh  = "程式相容性資料更新"
        NameEn  = "Program Compatibility Data Updater"
        DescZh  = "更新應用程式相容性資料庫,與相容性遙測相關。停用可減少背景活動。"
        DescEn  = "Updates the application compatibility database, related to compatibility telemetry. Disabling reduces background activity."
        Choices = @(
            @{ Id = "disable"; Label = "停用"; LabelEn = "Disable"
               Task = @(@{ Path = "\Microsoft\Windows\Application Experience\"; Name = "ProgramDataUpdater"; Enable = $false }) }
            @{ Id = "enable"; Label = "啟用"; LabelEn = "Enable"
               Task = @(@{ Path = "\Microsoft\Windows\Application Experience\"; Name = "ProgramDataUpdater"; Enable = $true }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        VerifiedDate = "2026-07-05"
        Notes        = "與相容性評估同組的資料更新排程,停用可進一步減少相容性遙測。建議停用。"
        NotesEn        = "A data-update task in the same group as the compatibility appraiser; disabling further reduces compatibility telemetry. Recommended to disable."
    },
    @{
        Id      = "task_startupapp"
        Category = 10
        NameZh  = "啟動程式評估"
        NameEn  = "Startup App Evaluation"
        DescZh  = "評估開機啟動程式並回傳相關資料。停用不影響程式正常啟動。"
        DescEn  = "Evaluates startup programs and reports related data. Disabling doesn't affect normal program startup."
        Choices = @(
            @{ Id = "disable"; Label = "停用"; LabelEn = "Disable"
               Task = @(@{ Path = "\Microsoft\Windows\Application Experience\"; Name = "StartupAppTask"; Enable = $false }) }
            @{ Id = "enable"; Label = "啟用"; LabelEn = "Enable"
               Task = @(@{ Path = "\Microsoft\Windows\Application Experience\"; Name = "StartupAppTask"; Enable = $true }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        VerifiedDate = "2026-07-05"
        Notes        = "評估啟動程式的遙測排程,停用不影響程式啟動。建議停用。"
        NotesEn        = "A telemetry task that evaluates startup programs; disabling doesn't affect program startup. Recommended to disable."
    },
    @{
        Id      = "task_autochk_proxy"
        Category = 10
        NameZh  = "Autochk 遙測上傳"
        NameEn  = "Autochk Telemetry Upload"
        DescZh  = "上傳 autochk (開機磁碟檢查) 的 SQM 遙測資料。停用不影響磁碟檢查功能本身。"
        DescEn  = "Uploads SQM telemetry data from autochk (boot disk check). Disabling doesn't affect the disk check function itself."
        Choices = @(
            @{ Id = "disable"; Label = "停用"; LabelEn = "Disable"
               Task = @(@{ Path = "\Microsoft\Windows\Autochk\"; Name = "Proxy"; Enable = $false }) }
            @{ Id = "enable"; Label = "啟用"; LabelEn = "Enable"
               Task = @(@{ Path = "\Microsoft\Windows\Autochk\"; Name = "Proxy"; Enable = $true }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        VerifiedDate = "2026-07-05"
        Notes        = "僅上傳 autochk 的遙測資料,停用不影響開機磁碟檢查功能。建議停用。"
        NotesEn        = "Only uploads autochk telemetry data; disabling doesn't affect the boot disk check function. Recommended to disable."
    },
    @{
        Id      = "task_feedback_dmclient"
        Category = 10
        NameZh  = "Windows 回饋資料上傳"
        NameEn  = "Windows Feedback Data Upload"
        DescZh  = "上傳 Windows 意見回饋 (Feedback) 相關資料。停用減少回傳。"
        DescEn  = "Uploads Windows Feedback-related data. Disabling reduces reporting."
        Choices = @(
            @{ Id = "disable"; Label = "停用"; LabelEn = "Disable"
               Task = @(@{ Path = "\Microsoft\Windows\Feedback\Siuf\"; Name = "DmClient"; Enable = $false }) }
            @{ Id = "enable"; Label = "啟用"; LabelEn = "Enable"
               Task = @(@{ Path = "\Microsoft\Windows\Feedback\Siuf\"; Name = "DmClient"; Enable = $true }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        VerifiedDate = "2026-07-05"
        Notes        = "上傳意見回饋資料的排程,停用純減少回傳,不影響使用。建議停用。"
        NotesEn        = "A task that uploads feedback data; disabling simply reduces reporting without affecting use. Recommended to disable."
    },
    @{
        Id      = "task_feedback_scenario"
        Category = 10
        NameZh  = "Windows 回饋情境下載"
        NameEn  = "Windows Feedback Scenario Download"
        DescZh  = "下載 Windows 回饋情境設定。停用減少回饋相關背景活動。"
        DescEn  = "Downloads Windows feedback scenario settings. Disabling reduces feedback-related background activity."
        Choices = @(
            @{ Id = "disable"; Label = "停用"; LabelEn = "Disable"
               Task = @(@{ Path = "\Microsoft\Windows\Feedback\Siuf\"; Name = "DmClientOnScenarioDownload"; Enable = $false }) }
            @{ Id = "enable"; Label = "啟用"; LabelEn = "Enable"
               Task = @(@{ Path = "\Microsoft\Windows\Feedback\Siuf\"; Name = "DmClientOnScenarioDownload"; Enable = $true }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        VerifiedDate = "2026-07-05"
        Notes        = "回饋情境下載排程,與回饋上傳同組。建議停用。"
        NotesEn        = "A feedback scenario download task, in the same group as feedback upload. Recommended to disable."
    },
    @{
        Id      = "task_cloudexp"
        Category = 10
        NameZh  = "雲端體驗遙測"
        NameEn  = "Cloud Experience Telemetry"
        DescZh  = "CloudExperienceHost 的背景物件建立與遙測。停用不影響一般使用。"
        DescEn  = "CloudExperienceHost background object creation and telemetry. Disabling doesn't affect general use."
        Choices = @(
            @{ Id = "disable"; Label = "停用"; LabelEn = "Disable"
               Task = @(@{ Path = "\Microsoft\Windows\CloudExperienceHost\"; Name = "CreateObjectTask"; Enable = $false }) }
            @{ Id = "enable"; Label = "啟用"; LabelEn = "Enable"
               Task = @(@{ Path = "\Microsoft\Windows\CloudExperienceHost\"; Name = "CreateObjectTask"; Enable = $true }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        VerifiedDate = "2026-07-05"
        Notes        = "雲端體驗主機的背景排程,停用不影響一般使用。部分系統可能無此排程。建議停用。"
        NotesEn        = "A background task for the cloud experience host; disabling doesn't affect general use. Some systems may lack this task. Recommended to disable."
    },
    @{
        Id      = "task_maps_update"
        Category = 10
        NameZh  = "地圖自動更新"
        NameEn  = "Maps Auto-Update"
        DescZh  = "自動下載更新離線地圖資料。若不使用「地圖」App,停用可省背景下載。"
        DescEn  = "Automatically downloads offline map updates. If you don't use the Maps app, disabling saves background downloads."
        Choices = @(
            @{ Id = "disable"; Label = "停用"; LabelEn = "Disable"
               Task = @(@{ Path = "\Microsoft\Windows\Maps\"; Name = "MapsUpdateTask"; Enable = $false }) }
            @{ Id = "enable"; Label = "啟用"; LabelEn = "Enable"
               Task = @(@{ Path = "\Microsoft\Windows\Maps\"; Name = "MapsUpdateTask"; Enable = $true }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        VerifiedDate = "2026-07-05"
        Notes        = "自動更新離線地圖。不用內建地圖 App 者停用純賺 (省背景下載/流量)。會用地圖離線功能者可維持。建議停用。"
        NotesEn        = "Automatically updates offline maps. For those not using the built-in Maps app, disabling is pure upside (saves background downloads/data). Those using offline map features may keep it. Recommended to disable."
    },
    @{
        Id      = "task_werreport"
        Category = 10
        NameZh  = "Windows 錯誤回報佇列"
        NameEn  = "Windows Error Reporting Queue"
        DescZh  = "處理排隊中的 Windows 錯誤回報 (當機資料上傳)。停用不再上傳當機報告。"
        DescEn  = "Processes queued Windows Error Reporting (crash data upload). Disabling stops uploading crash reports."
        Choices = @(
            @{ Id = "disable"; Label = "停用"; LabelEn = "Disable"
               Task = @(@{ Path = "\Microsoft\Windows\Windows Error Reporting\"; Name = "QueueReporting"; Enable = $false }) }
            @{ Id = "enable"; Label = "啟用"; LabelEn = "Enable"
               Task = @(@{ Path = "\Microsoft\Windows\Windows Error Reporting\"; Name = "QueueReporting"; Enable = $true }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        VerifiedDate = "2026-07-05"
        Notes        = "【知情取捨】處理當機錯誤報告的上傳。停用後不再回傳當機資料 (較隱私),但若你需要微軟協助診斷當機問題,保留較有幫助。一般使用可停;此項保守建議維持。"
        NotesEn        = "[Informed tradeoff] Handles crash error report uploads. Once disabled, crash data is no longer reported (more private), but keeping it helps if you need Microsoft's help diagnosing crashes. General use can disable; this item conservatively recommends Keep current."
    },
    @{
        Id      = "task_diskdiag"
        Category = 10
        NameZh  = "磁碟診斷資料收集"
        NameEn  = "Disk Diagnostic Data Collection"
        DescZh  = "收集磁碟健康診斷資料。停用可減少回傳,但系統對磁碟問題的自我診斷能力會降低。"
        DescEn  = "Collects disk health diagnostic data. Disabling reduces reporting but lowers the system's self-diagnosis capability for disk issues."
        Choices = @(
            @{ Id = "disable"; Label = "停用"; LabelEn = "Disable"
               Task = @(@{ Path = "\Microsoft\Windows\DiskDiagnostic\"; Name = "Microsoft-Windows-DiskDiagnosticDataCollector"; Enable = $false }) }
            @{ Id = "enable"; Label = "啟用"; LabelEn = "Enable"
               Task = @(@{ Path = "\Microsoft\Windows\DiskDiagnostic\"; Name = "Microsoft-Windows-DiskDiagnosticDataCollector"; Enable = $true }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        VerifiedDate = "2026-07-05"
        Notes        = "【知情取捨】收集磁碟診斷資料回傳,也用於系統自我偵測磁碟問題。停了不再回傳,代價是磁碟健康診斷能力略降。在意隱私可停;想保留磁碟問題預警建議維持。此項建議維持。"
        NotesEn        = "[Informed tradeoff] Collects disk diagnostic data for reporting, also used for the system to self-detect disk issues. Disabling stops reporting, at the cost of slightly reduced disk health diagnosis. Disable if you care about privacy; keep for disk-issue early warning. This item recommends Keep current."
    }
    )
}
