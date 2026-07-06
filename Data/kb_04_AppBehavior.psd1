<#
    Windows 11 設定精靈 - 知識庫:第 05 類 應用程式行為 (App Behavior)
    ================================================================
    格式:選項式統一模型 (Choices + Recommend)。

    Choice 欄位:
      Id          (必要) 選項識別碼
      Label       (必要) 顯示文字
      Reg / RegDel / None (擇一) 動作定義
      MinBuild / EditionOnly / Note (可選)

    Item 層級:
      Recommend    - 建議選項的 Id 字串
      MinBuild     - 整個項目的最低 Build
      Notes        - 顯示於選項清單下方的詳細備註

    Import-PowerShellDataFile 規定檔案最外層須為 Hashtable。
#>

@{
    Items = @(

    # ── OneDrive 開機自啟 ──
    @{
        Id           = "onedrive_autostart"
        Category     = 4
        NameZh       = "OneDrive 開機自動啟動"
        NameEn       = "OneDrive Startup on Boot"
        DescZh       = "OneDrive 預設隨開機自動啟動並常駐背景。停用=移除開機啟動項目 (不解除安裝);啟用=偵測 OneDrive 安裝位置後重建開機啟動項目。"
        DescEn       = "OneDrive auto-starts on boot and stays in the background by default. Disable = remove the startup entry (no uninstall); Enable = detect the OneDrive install location and rebuild the startup entry."
        Choices      = @(
            @{ Id = "disable"
               Label = "停止開機自啟"; LabelEn = "Stop startup on boot"
               RegDel = @(
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"; Name = "OneDrive" }
               ) }
            @{ Id = "enable"
               Label = "啟用開機自啟 (自動偵測安裝路徑重建)"; LabelEn = "Enable startup on boot (auto-detect install path and rebuild)"
               Special = "onedrive_enable" }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "Windows 標準開機啟動機制 (HKCU Run 機碼);啟用值格式:「<OneDrive.exe 路徑>」 /background"
        VerifiedDate = "2026-07-04"
        Notes        = "停用刪除的是啟動項目,非解除安裝;需要時仍可從開始功能表手動開啟。啟用時引擎會依序偵測 %LOCALAPPDATA%、%ProgramFiles%、%ProgramFiles(x86)% 三個位置的 OneDrive.exe,用實際路徑重建 Run 機碼;若系統未安裝 OneDrive 則顯示『未安裝』並略過 (不會建出指向不存在程式的壞啟動項)。目前狀態依 Run 機碼是否存在判定。"
        NotesEn        = "Disabling removes the startup entry, not the app; you can still open it manually from the Start menu. When enabling, the engine checks %LOCALAPPDATA%, %ProgramFiles%, %ProgramFiles(x86)% in order for OneDrive.exe and rebuilds the Run key with the actual path; if OneDrive isn't installed it shows 'Not installed' and skips (no broken startup entry pointing to a missing program). Current state is judged by whether the Run key exists."
    },

    # ── Teams 開機自啟 (新版 Teams / Teams 2.0) ──
    @{
        Id           = "teams_autostart"
        Category     = 4
        NameZh       = "Teams 開機自動啟動"
        NameEn       = "Teams Startup on Boot"
        DescZh       = "新版 Teams (Teams 2.0) 安裝後預設隨開機自動啟動並常駐背景。停用方式為把其 StartupTask 狀態設為『使用者已停用』(等同在 設定 > 應用程式 > 啟動 手動關閉)。"
        DescEn       = "The new Teams (Teams 2.0) auto-starts on boot and stays in the background after install. Disabling sets its StartupTask state to 'DisabledByUser' (equivalent to turning it off manually in Settings > Apps > Startup)."
        Choices      = @(
            @{ Id = "disable"
               Label = "停止開機自啟"; LabelEn = "Stop startup on boot"
               RequirePath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData\MSTeams_8wekyb3d8bbwe\TeamsTfwStartupTask"
               Reg = @(
                   @{ Path = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData\MSTeams_8wekyb3d8bbwe\TeamsTfwStartupTask"; Name = "State"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "啟用開機自啟"; LabelEn = "Enable startup on boot"
               RequirePath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData\MSTeams_8wekyb3d8bbwe\TeamsTfwStartupTask"
               Reg = @(
                   @{ Path = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData\MSTeams_8wekyb3d8bbwe\TeamsTfwStartupTask"; Name = "State"; Value = 2; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/answers/questions/4099416 (MSTeams StartupTask State:1=DisabledByUser、2=Enabled) / StartupTaskState 列舉"
        VerifiedDate = "2026-07-04"
        Notes        = "傳統版 Teams (com.squirrel.Teams.Teams Run 機碼) 已於 2024 年終止支援,本項改用新版 Teams (MSTeams_8wekyb3d8bbwe) 的 StartupTask 機制。State 值對應 Windows StartupTaskState 列舉:0=Disabled、1=DisabledByUser (使用者手動停用,本工具停用用此值,最穩定不易被系統還原)、2=Enabled (本工具啟用用此值)。前提:此鍵僅在新版 Teams 已安裝且開啟過一次後才存在;若系統未裝新版 Teams,停用/啟用都會顯示『未安裝,無需設定』並略過 (安全)。目前狀態:State=1 顯示停用、State=2 顯示啟用。"
        NotesEn        = "Classic Teams (com.squirrel.Teams.Teams Run key) reached end of support in 2024, so this item uses the new Teams (MSTeams_8wekyb3d8bbwe) StartupTask mechanism. State maps to the Windows StartupTaskState enum: 0=Disabled, 1=DisabledByUser (user-disabled; this tool uses this value as it's most stable and resists system restore), 2=Enabled (used when this tool enables). Prerequisite: the key exists only after the new Teams is installed and opened once; if not installed, disable/enable both show 'Not installed, no action needed' and skip (safe). Current state: State=1 shows disabled, State=2 shows enabled."
    },

    # ── Edge:啟動增強 ──
    @{
        Id           = "edge_startup_boost"
        Category     = 4
        NameZh       = "Edge 啟動增強 (Startup Boost)"
        NameEn       = "Edge Startup Boost"
        DescZh       = "Edge 在開機後預先載入部分程序常駐背景,以加快開啟速度,但持續佔用資源。"
        DescEn       = "Edge preloads some processes in the background after boot to open faster, but keeps consuming resources."
        Choices      = @(
            @{ Id = "disable"
               Label = "停用啟動增強"; LabelEn = "Disable Startup Boost"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "StartupBoostEnabled"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "啟用啟動增強"; LabelEn = "Enable Startup Boost"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "StartupBoostEnabled"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/deployedge/microsoft-edge-browser-policies/startupboostenabled"
        VerifiedDate = "2026-07-04"
        Notes        = ""
    },

    # ── Edge:背景執行 ──
    @{
        Id           = "edge_background"
        Category     = 4
        NameZh       = "Edge 背景執行"
        NameEn       = "Edge Background Running"
        DescZh       = "關閉 Edge 視窗後,Edge 仍在背景常駐執行 (支援擴充功能、通知等)。"
        DescEn       = "After closing the Edge window, Edge keeps running in the background (for extensions, notifications, etc.)."
        Choices      = @(
            @{ Id = "disable"
               Label = "停用背景執行"; LabelEn = "Disable background running"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "BackgroundModeEnabled"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "啟用背景執行"; LabelEn = "Enable background running"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "BackgroundModeEnabled"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/deployedge/microsoft-edge-browser-policies/backgroundmodeenabled"
        VerifiedDate = "2026-07-04"
        Notes        = ""
    },

    # ── Edge:首次執行體驗 ──
    @{
        Id           = "edge_first_run"
        Category     = 4
        NameZh       = "Edge 首次執行體驗"
        NameEn       = "Edge First Run Experience"
        DescZh       = "首次開啟 Edge 時顯示的歡迎與設定引導畫面。"
        DescEn       = "The welcome and setup guide shown when Edge is first opened."
        Choices      = @(
            @{ Id = "skip"
               Label = "略過首次體驗"; LabelEn = "Skip first run experience"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "HideFirstRunExperience"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "show"
               Label = "顯示首次體驗"; LabelEn = "Show first run experience"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "HideFirstRunExperience"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "skip"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/deployedge/microsoft-edge-browser-policies/hidefirstrunexperience"
        VerifiedDate = "2026-07-04"
        Notes        = ""
    },

    # ── Edge:新分頁新聞內容 ──
    @{
        Id           = "edge_newtab_content"
        Category     = 4
        NameZh       = "Edge 新分頁新聞內容"
        NameEn       = "Edge New Tab News Content"
        DescZh       = "Edge 新分頁下方的新聞資訊摘要 (MSN 內容饋送)。"
        DescEn       = "The news feed below Edge's new tab page (MSN content feed)."
        Choices      = @(
            @{ Id = "disable"
               Label = "關閉新聞內容"; LabelEn = "Turn off news content"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "NewTabPageContentEnabled"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "顯示新聞內容"; LabelEn = "Show news content"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "NewTabPageContentEnabled"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/deployedge/microsoft-edge-browser-policies/newtabpagecontentenabled"
        VerifiedDate = "2026-07-04"
        Notes        = ""
    },

    # ── Edge:精選與推薦內容 ──
    @{
        Id           = "edge_spotlight"
        Category     = 4
        NameZh       = "Edge 精選與推薦內容"
        NameEn       = "Edge Featured & Recommended Content"
        DescZh       = "Edge 各處顯示的精選體驗、推薦與贊助內容。"
        DescEn       = "Featured experiences, recommendations, and sponsored content shown throughout Edge."
        Choices      = @(
            @{ Id = "disable"
               Label = "關閉精選推薦"; LabelEn = "Turn off featured recommendations"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "SpotlightExperiencesAndRecommendationsEnabled"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "顯示精選推薦"; LabelEn = "Show featured recommendations"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "SpotlightExperiencesAndRecommendationsEnabled"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/deployedge/microsoft-edge-browser-policies/spotlightexperiencesandrecommendationsenabled"
        VerifiedDate = "2026-07-04"
        Notes        = ""
    },

    # ── Edge:購物助理 ──
    @{
        Id           = "edge_shopping"
        Category     = 4
        NameZh       = "Edge 購物助理"
        NameEn       = "Edge Shopping Assistant"
        DescZh       = "Edge 在購物網站自動彈出比價、優惠券、回饋等提示。"
        DescEn       = "Edge automatically pops up price comparisons, coupons, and cashback prompts on shopping sites."
        Choices      = @(
            @{ Id = "disable"
               Label = "停用購物助理"; LabelEn = "Disable shopping assistant"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "EdgeShoppingAssistantEnabled"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "啟用購物助理"; LabelEn = "Enable shopping assistant"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "EdgeShoppingAssistantEnabled"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/deployedge/microsoft-edge-browser-policies/edgeshoppingassistantenabled"
        VerifiedDate = "2026-07-04"
        Notes        = ""
    },

    # ── Edge:側邊欄 ──
    @{
        Id           = "edge_sidebar"
        Category     = 4
        NameZh       = "Edge 側邊欄"
        NameEn       = "Edge Sidebar"
        DescZh       = "Edge 視窗右側的側邊欄 (Discover、工具、Copilot 入口等)。"
        DescEn       = "The sidebar on the right of the Edge window (Discover, tools, Copilot entry, etc.)."
        Choices      = @(
            @{ Id = "disable"
               Label = "停用側邊欄"; LabelEn = "Disable sidebar"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "HubsSidebarEnabled"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "啟用側邊欄"; LabelEn = "Enable sidebar"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "HubsSidebarEnabled"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/deployedge/microsoft-edge-browser-policies/hubssidebarenabled"
        VerifiedDate = "2026-07-04"
        Notes        = "停用後為永不顯示側邊欄;Edge 141+ 的 Copilot 工具列圖示屬另一個獨立政策 (Microsoft365CopilotChatIconEnabled),不受此項影響。"
        NotesEn        = "Once disabled, the sidebar never shows; the Copilot toolbar icon in Edge 141+ is a separate policy (Microsoft365CopilotChatIconEnabled) unaffected by this item."
    },

    # ── 自動播放 (AutoPlay,多值分級) ──
    @{
        Id           = "autoplay"
        Category     = 4
        NameZh       = "自動播放 (AutoPlay)"
        NameEn       = "AutoPlay"
        DescZh       = "插入 USB 隨身碟、記憶卡、光碟等媒體時,系統自動執行或開啟內容。可依風險程度分級控制。"
        DescEn       = "When you insert USB drives, memory cards, discs, etc., the system automatically runs or opens content. Can be controlled by risk level."
        Choices      = @(
            @{ Id = "disable_all"
               Label = "全部停用 (最嚴格,關 AutoPlay 選單並封鎖所有磁碟 AutoRun)"; LabelEn = "Disable all (strictest; turn off AutoPlay menu and block AutoRun on all drives)"
               Reg = @(
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers"; Name = "DisableAutoplay";     Value = 1;   Type = "DWord" }
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer";        Name = "NoDriveTypeAutoRun";   Value = 255; Type = "DWord" }
               ) }
            @{ Id = "block_risky_only"
               Label = "只擋高風險裝置 (可移除/光碟/網路,保留 AutoPlay 選單以便選擇動作)"; LabelEn = "Block high-risk devices only (removable/disc/network; keep AutoPlay menu to choose actions)"
               Reg = @(
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers"; Name = "DisableAutoplay";     Value = 0;   Type = "DWord" }
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer";        Name = "NoDriveTypeAutoRun";   Value = 181; Type = "DWord" }
               ) }
            @{ Id = "allow_default"
               Label = "允許自動播放 (還原系統預設,只擋未知/網路磁碟)"; LabelEn = "Allow AutoPlay (restore system default, block only unknown/network drives)"
               Reg = @(
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers"; Name = "DisableAutoplay";     Value = 0;   Type = "DWord" }
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer";        Name = "NoDriveTypeAutoRun";   Value = 145; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "block_risky_only"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/windows/win32/shell/autoplay-reg / NoDriveTypeAutoRun 官方 ADM 位元遮罩定義"
        VerifiedDate = "2026-07-04"
        Notes        = "NoDriveTypeAutoRun 位元遮罩:255 (0xFF) 停用所有磁碟類型 (含固定硬碟);181 (0xB5) 停用可移除裝置/光碟/網路/未知,保留固定硬碟;145 (0x91) 為系統預設,只擋未知類型與網路磁碟。DisableAutoplay 控制 AutoPlay 選單。建議『只擋高風險裝置 (0xB5)』:USB/光碟/網路才是惡意程式 (AutoRun 病毒) 主要途徑,固定硬碟非風險來源。三個作用狀態可隨時互切;『允許自動播放』把值設回系統預設 0x91。"
        NotesEn        = "NoDriveTypeAutoRun bitmask: 255 (0xFF) disables all drive types (including fixed disks); 181 (0xB5) disables removable/disc/network/unknown while keeping fixed disks; 145 (0x91) is the system default, blocking only unknown types and network drives. DisableAutoplay controls the AutoPlay menu. Recommended: 'Block high-risk devices only (0xB5)' — USB/disc/network are the main vectors for malware (AutoRun viruses); fixed disks aren't a risk source. The three active states are interchangeable anytime; 'Allow AutoPlay' resets the value to the system default 0x91."
    },

    # ── Xbox Game Bar (多值分級) ──
    @{
        Id           = "game_bar"
        Category     = 4
        NameZh       = "Xbox Game Bar / 遊戲錄製"
        NameEn       = "Xbox Game Bar / Game Recording"
        DescZh       = "Xbox Game Bar (Win+G) 與背景遊戲錄製 (Game DVR) 由兩個獨立設定值控制,可分別停用。"
        DescEn       = "Xbox Game Bar (Win+G) and background game recording (Game DVR) are controlled by two separate values and can be disabled independently."
        Choices      = @(
            @{ Id = "disable_all"
               Label = "全部停用 (最省資源)"; LabelEn = "Disable all (most resource-saving)"
               Reg = @(
                   @{ Path = "HKCU:\System\GameConfigStore";                              Name = "GameDVR_Enabled";   Value = 0; Type = "DWord" }
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR";   Name = "AppCaptureEnabled"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "disable_dvr_only"
               Label = "只關背景錄製,保留 Game Bar 手動錄影/截圖"; LabelEn = "Turn off background recording only; keep Game Bar manual recording/screenshots"
               Reg = @(
                   @{ Path = "HKCU:\System\GameConfigStore";                              Name = "GameDVR_Enabled";   Value = 0; Type = "DWord" }
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR";   Name = "AppCaptureEnabled"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "enable_all"
               Label = "全部啟用 (Game Bar 與背景錄製都開)"; LabelEn = "Enable all (Game Bar and background recording on)"
               Reg = @(
                   @{ Path = "HKCU:\System\GameConfigStore";                              Name = "GameDVR_Enabled";   Value = 1; Type = "DWord" }
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR";   Name = "AppCaptureEnabled"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable_all"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/answers/questions/3738984/how-to-disable-xbox-game-bar (Microsoft Q&A 官方平台通用作法)"
        VerifiedDate = "2026-07-04"
        Notes        = "GameDVR_Enabled 控制背景自動錄製 (資源消耗來源);AppCaptureEnabled 控制 Game Bar 本身能否錄影/截圖 (含 Win+G 手動錄)。『全部停用』兩項全關;『只關背景錄製』保留手動錄影截圖;『全部啟用』兩項全開。三個作用狀態可隨時互切。"
        NotesEn        = "GameDVR_Enabled controls background auto-recording (the resource drain); AppCaptureEnabled controls whether Game Bar itself can record/screenshot (including Win+G manual recording). 'Disable all' turns off both; 'Turn off background recording only' keeps manual recording/screenshots; 'Enable all' turns on both. The three active states are interchangeable anytime."
    }
    )
}
