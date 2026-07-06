<#
    Windows 11 設定精靈 - 知識庫:第 06 類 個人化習慣 (Personalization)
    ================================================================
    格式:選項式統一模型 (Choices + Recommend)。

    ── 三選項模型 (2026-07-04) ──
    每個可切換設定列出所有「有意義的狀態」各一選項 + 維持現狀,可雙向切換。
    二元設定 = 兩狀態 (開/關) + 維持;多值設定 = N 狀態 + 維持。
    反向 = 寫入對立狀態值 (非通用機制,只是把另一個狀態也列出來);少數狀態
    需執行期邏輯 (如古典右鍵還原需刪整個 CLSID 鍵),用具名特殊動作 (Special)。

    ── 建議值原則 ──
    公開工具,面對大眾。建議只給「客觀有益」項 (隱私/安全/廣告/效能);
    「純個人偏好」項 (主題色、對齊、桌面圖示、右鍵樣式等) 一律建議「維持現狀」。

    Choice 欄位:Id / Label (必要);Reg / RegDel / Special / None (擇一);Note (可選)
    Item 層級:Recommend (選項 Id) / MinBuild / Notes

    Import-PowerShellDataFile 規定檔案最外層須為 Hashtable。
    (提醒:字串內若需引號,用 PowerShell 規則的兩個雙引號,勿用反斜線跳脫。)
#>

@{
    Items = @(

    # ══════════════ 檔案總管顯示 ══════════════

    # ── 顯示已知副檔名 (安全) ──
    @{
        Id           = "show_ext"
        Category     = 5
        NameZh       = "顯示已知副檔名 (安全性)"
        NameEn       = "Show Known File Extensions (Security)"
        DescZh       = "系統預設隱藏已知類型的副檔名。顯示後可看到完整檔名,能識破如『報告.pdf.exe』這類把執行檔偽裝成文件的惡意檔案。"
        DescEn       = "The system hides known file extensions by default. Showing them reveals full filenames, exposing malware like 'report.pdf.exe' that disguises executables as documents."
        Choices      = @(
            @{ Id = "show"; Label = "顯示副檔名"; LabelEn = "Show extensions"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "HideFileExt"; Value = 0; Type = "DWord" }) }
            @{ Id = "hide"; Label = "隱藏副檔名"; LabelEn = "Hide extensions"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "HideFileExt"; Value = 1; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "show"
        MinBuild     = $null
        Source       = "HKCU\...\Explorer\Advanced\HideFileExt (0=顯示、1=隱藏)"
        VerifiedDate = "2026-07-04"
        Notes        = "顯示完整檔名是重要的安全習慣,能辨識偽裝成文件的執行檔。需重新整理或重啟檔案總管生效。"
        NotesEn        = "Showing full filenames is an important security habit for spotting executables disguised as documents. Requires refreshing or restarting File Explorer to take effect."
    },

    # ── 顯示隱藏檔案 (純偏好,反向值為 2) ──
    @{
        Id           = "show_hidden"
        Category     = 5
        NameZh       = "顯示隱藏檔案"
        NameEn       = "Show hidden files"
        DescZh       = "顯示被設為隱藏屬性的檔案與資料夾。"
        DescEn       = "Shows files and folders marked with the hidden attribute."
        Choices      = @(
            @{ Id = "show"; Label = "顯示隱藏檔案"; LabelEn = "Show hidden files"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Hidden"; Value = 1; Type = "DWord" }) }
            @{ Id = "hide"; Label = "不顯示隱藏檔案"; LabelEn = "Don't show hidden files"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Hidden"; Value = 2; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "HKCU\...\Explorer\Advanced\Hidden (1=顯示、2=不顯示;注意不顯示是 2 不是 0)"
        VerifiedDate = "2026-07-04"
        Notes        = "顯示隱藏檔方便進階管理,但畫面會多出系統檔;屬個人偏好。此鍵『不顯示』的值是 2 (非 0)。"
        NotesEn        = "Showing hidden files aids advanced management but clutters the view with system files; a personal preference. The 'don't show' value for this key is 2 (not 0)."
    },

    # ── 檔案總管預設位置 (純偏好,兩狀態 1/2) ──
    @{
        Id           = "launch_to"
        Category     = 5
        NameZh       = "檔案總管預設開啟位置"
        NameEn       = "File Explorer Default Location"
        DescZh       = "檔案總管開啟時預設顯示的位置:『本機』(顯示磁碟機列表) 或『首頁』(系統預設,顯示最近檔案等)。"
        DescEn       = "The default location shown when File Explorer opens: 'This PC' (drive list) or 'Home' (system default, showing recent files, etc.)."
        Choices      = @(
            @{ Id = "thispc"; Label = "開啟本機 (顯示磁碟機)"; LabelEn = "Open This PC (show drives)"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "LaunchTo"; Value = 1; Type = "DWord" }) }
            @{ Id = "home"; Label = "開啟首頁 (系統預設)"; LabelEn = "Open Home (system default)"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "LaunchTo"; Value = 2; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "HKCU\...\Explorer\Advanced\LaunchTo (1=本機、2=首頁)"
        VerifiedDate = "2026-07-04"
        Notes        = "常操作磁碟的人偏好本機,常用最近檔案的人偏好首頁;屬個人習慣。"
        NotesEn        = "Those who work with drives prefer This PC; those who use recent files prefer Home; a personal habit."
    },

    # ── 標題列顯示完整路徑 (純偏好) ──
    @{
        Id           = "full_path"
        Category     = 5
        NameZh       = "標題列顯示完整路徑"
        NameEn       = "Show Full Path in Title Bar"
        DescZh       = "在檔案總管標題列與工作列預覽顯示目前資料夾的完整路徑。"
        DescEn       = "Shows the full path of the current folder in the File Explorer title bar and taskbar preview."
        Choices      = @(
            @{ Id = "show"; Label = "顯示完整路徑"; LabelEn = "Show full path"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CabinetState"; Name = "FullPath"; Value = 1; Type = "DWord" }) }
            @{ Id = "hide"; Label = "不顯示完整路徑"; LabelEn = "Don't show full path"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\CabinetState"; Name = "FullPath"; Value = 0; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "HKCU\...\Explorer\CabinetState\FullPath (1=顯示、0=不顯示)"
        VerifiedDate = "2026-07-04"
        Notes        = "顯示完整路徑方便定位,屬個人偏好。"
        NotesEn        = "Showing the full path helps with navigation; a personal preference."
    },

    # ── 導覽窗格展開至目前資料夾 (純偏好) ──
    @{
        Id           = "nav_expand"
        Category     = 5
        NameZh       = "導覽窗格展開至目前資料夾"
        NameEn       = "Expand Nav Pane to Current Folder"
        DescZh       = "左側導覽窗格自動展開並定位到目前開啟的資料夾。"
        DescEn       = "The left navigation pane automatically expands and scrolls to the currently open folder."
        Choices      = @(
            @{ Id = "expand"; Label = "自動展開至目前資料夾"; LabelEn = "Auto-expand to current folder"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "NavPaneExpandToCurrentFolder"; Value = 1; Type = "DWord" }) }
            @{ Id = "collapse"; Label = "不自動展開"; LabelEn = "Don't auto-expand"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "NavPaneExpandToCurrentFolder"; Value = 0; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "HKCU\...\Explorer\Advanced\NavPaneExpandToCurrentFolder (1=展開、0=不展開)"
        VerifiedDate = "2026-07-04"
        Notes        = "左側樹狀目錄跟著目前位置同步展開,屬個人偏好。"
        NotesEn        = "The left tree expands in sync with the current location; a personal preference."
    },

    # ── 同步提供者通知 (廣告/隱私) ──
    @{
        Id           = "sync_notif"
        Category     = 5
        NameZh       = "同步提供者通知 (廣告/隱私)"
        NameEn       = "Sync Provider Notifications (Ads/Privacy)"
        DescZh       = "檔案總管中顯示 OneDrive、Microsoft 365 等『同步提供者』的提示與推銷橫幅。"
        DescEn       = "Shows prompts and promotional banners from 'sync providers' like OneDrive and Microsoft 365 in File Explorer."
        Choices      = @(
            @{ Id = "disable"; Label = "關閉通知橫幅"; LabelEn = "Turn off notification banners"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowSyncProviderNotifications"; Value = 0; Type = "DWord" }) }
            @{ Id = "enable"; Label = "顯示通知橫幅"; LabelEn = "Show notification banners"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowSyncProviderNotifications"; Value = 1; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "HKCU\...\Explorer\Advanced\ShowSyncProviderNotifications (0=關、1=開)"
        VerifiedDate = "2026-07-04"
        Notes        = "關閉後檔案總管不再出現 OneDrive/廣告提示橫幅,畫面更乾淨。"
        NotesEn        = "Once off, File Explorer no longer shows OneDrive/ad banners, keeping the view cleaner."
    },

    # ── 最近使用檔案 (隱私) ──
    @{
        Id           = "recent_files"
        Category     = 5
        NameZh       = "最近使用檔案記錄 (隱私)"
        NameEn       = "Recent Files History (Privacy)"
        DescZh       = "檔案總管『首頁』記錄並顯示你最近開啟的檔案。"
        DescEn       = "File Explorer 'Home' records and shows your recently opened files."
        Choices      = @(
            @{ Id = "disable"; Label = "關閉最近檔案"; LabelEn = "Turn off recent files"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"; Name = "ShowRecent"; Value = 0; Type = "DWord" }) }
            @{ Id = "enable"; Label = "顯示最近檔案"; LabelEn = "Show recent files"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"; Name = "ShowRecent"; Value = 1; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "HKCU\...\Explorer\ShowRecent (0=關、1=開;在 Explorer 而非 Advanced 底下)"
        VerifiedDate = "2026-07-04"
        Notes        = "關閉後不再記錄與顯示最近開啟的檔案,他人使用電腦時看不到你的檔案歷程,提升隱私。"
        NotesEn        = "Once off, recently opened files are no longer recorded or shown; others using the PC can't see your file history, improving privacy."
    },

    # ── 常用資料夾 (隱私) ──
    @{
        Id           = "frequent_folders"
        Category     = 5
        NameZh       = "常用資料夾記錄 (隱私)"
        NameEn       = "Frequent Folders History (Privacy)"
        DescZh       = "檔案總管『首頁』記錄並顯示你常用的資料夾。"
        DescEn       = "File Explorer 'Home' records and shows your frequently used folders."
        Choices      = @(
            @{ Id = "disable"; Label = "關閉常用資料夾"; LabelEn = "Turn off frequent folders"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"; Name = "ShowFrequent"; Value = 0; Type = "DWord" }) }
            @{ Id = "enable"; Label = "顯示常用資料夾"; LabelEn = "Show frequent folders"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"; Name = "ShowFrequent"; Value = 1; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "HKCU\...\Explorer\ShowFrequent (0=關、1=開;在 Explorer 而非 Advanced 底下)"
        VerifiedDate = "2026-07-04"
        Notes        = "關閉後不再記錄與顯示常用資料夾,提升隱私。"
        NotesEn        = "Once off, frequent folders are no longer recorded or shown, improving privacy."
    },

    # ══════════════ 右鍵選單 ══════════════

    # ── 古典右鍵選單 (純偏好,用具名特殊動作) ──
    @{
        Id           = "classic_context"
        Category     = 5
        NameZh       = "右鍵選單樣式 (Win10 完整 / Win11 精簡)"
        NameEn       = "Context Menu Style (Win10 Full / Win11 Compact)"
        DescZh       = "Windows 11 的右鍵選單精簡化,常用功能被收在『顯示更多選項』裡。可還原成 Win10 的完整選單。"
        DescEn       = "Windows 11's context menu is simplified, tucking common functions under 'Show more options'. Can be restored to the full Win10 menu."
        Choices      = @(
            @{ Id = "classic"; Label = "Win10 完整右鍵選單"; LabelEn = "Win10 full context menu"
               Special = "classic_context_classic" }
            @{ Id = "win11"; Label = "Win11 精簡右鍵選單 (系統預設)"; LabelEn = "Win11 compact context menu (system default)"
               Special = "classic_context_restore" }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "HKCU\Software\Classes\CLSID\{86ca1aa0-...}\InprocServer32 空白 (Default) 值 (社群通用手法)"
        VerifiedDate = "2026-07-04"
        Notes        = "『Win10 完整選單』建立空的 InprocServer32 (Default) 值讓 Explorer 回退舊選單;『Win11 精簡選單』刪除整個 CLSID 鍵還原。兩者皆需重啟檔案總管生效。注意:此手法非微軟官方支援,功能更新後可能被重置需重套用。屬個人偏好,預設維持現狀。目前狀態依 InprocServer32 鍵是否存在判定。"
        NotesEn        = "'Win10 full menu' creates an empty InprocServer32 (Default) value so Explorer falls back to the old menu; 'Win11 compact menu' deletes the whole CLSID key to restore. Both need File Explorer restarted. Note: this isn't officially supported by Microsoft and may be reset by feature updates, requiring reapplication. A personal preference, default Keep current. Current state is judged by whether the InprocServer32 key exists."
    },

    # ══════════════ 主題 (本來就是多狀態,不需補反向) ══════════════

    # ── 系統介面主題 (純偏好) ──
    @{
        Id           = "theme_system"
        Category     = 5
        NameZh       = "系統介面主題 (亮色/暗色)"
        NameEn       = "System UI Theme (Light/Dark)"
        DescZh       = "工作列、開始選單、動作中心等系統介面的亮色或暗色。純視覺偏好,不影響功能。"
        DescEn       = "Light or dark mode for system UI like the taskbar, Start menu, and Action Center. Purely visual, no functional impact."
        Choices      = @(
            @{ Id = "light"; Label = "亮色 (系統預設)"; LabelEn = "Light (system default)"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "SystemUsesLightTheme"; Value = 1; Type = "DWord" }) }
            @{ Id = "dark"; Label = "暗色"; LabelEn = "Dark"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "SystemUsesLightTheme"; Value = 0; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "HKCU\...\Themes\Personalize\SystemUsesLightTheme (1=亮色、0=暗色)"
        VerifiedDate = "2026-07-04"
        Notes        = "純視覺偏好;部分介面需登出重新登入或重啟檔案總管後才完全套用。"
        NotesEn        = "A purely visual preference; some UI fully applies only after signing out and back in or restarting File Explorer."
    },

    # ── 應用程式主題 (純偏好) ──
    @{
        Id           = "theme_apps"
        Category     = 5
        NameZh       = "應用程式主題 (亮色/暗色)"
        NameEn       = "App Theme (Light/Dark)"
        DescZh       = "設定、檔案總管等應用程式介面的亮色或暗色。純視覺偏好,不影響功能。"
        DescEn       = "Light or dark mode for app UI like Settings and File Explorer. Purely visual, no functional impact."
        Choices      = @(
            @{ Id = "light"; Label = "亮色 (系統預設)"; LabelEn = "Light (system default)"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "AppsUseLightTheme"; Value = 1; Type = "DWord" }) }
            @{ Id = "dark"; Label = "暗色"; LabelEn = "Dark"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "AppsUseLightTheme"; Value = 0; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "HKCU\...\Themes\Personalize\AppsUseLightTheme (1=亮色、0=暗色)"
        VerifiedDate = "2026-07-04"
        Notes        = "純視覺偏好;可與系統介面主題分開設定 (例如系統暗色、應用程式亮色)。"
        NotesEn        = "A purely visual preference; can be set separately from the system UI theme (e.g., system dark, apps light)."
    },

    # ══════════════ 工作列 ══════════════

    # ── 工作列圖示對齊 (純偏好,本來就多狀態) ──
    @{
        Id           = "taskbar_align"
        Category     = 5
        NameZh       = "工作列圖示對齊 (置中/靠左)"
        NameEn       = "Taskbar Icon Alignment (Center/Left)"
        DescZh       = "Windows 11 工作列圖示預設置中,可改回 Win10 的靠左對齊。"
        DescEn       = "Windows 11 centers taskbar icons by default; can be changed back to Win10 left alignment."
        Choices      = @(
            @{ Id = "left"; Label = "靠左對齊 (Win10 風格)"; LabelEn = "Left align (Win10 style)"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "TaskbarAl"; Value = 0; Type = "DWord" }) }
            @{ Id = "center"; Label = "置中 (Win11 預設)"; LabelEn = "Center (Win11 default)"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "TaskbarAl"; Value = 1; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "HKCU\...\Explorer\Advanced\TaskbarAl (0=靠左、1=置中,官方 learn 確認)"
        VerifiedDate = "2026-07-04"
        Notes        = "習慣偏好;需重啟檔案總管生效。"
        NotesEn        = "A habit preference; requires restarting File Explorer to take effect."
    },

    # ── 工作列搜尋框 (半偏好,本來就多值 4 樣式) ──
    @{
        Id           = "taskbar_search"
        Category     = 5
        NameZh       = "工作列搜尋框樣式"
        NameEn       = "Taskbar Search Box Style"
        DescZh       = "工作列上的搜尋框/搜尋圖示。可選隱藏、只顯示圖示、大搜尋框、或圖示加標籤。隱藏可省空間,並避免搜尋框整合的網路 (Bing) 搜尋建議。"
        DescEn       = "The search box/icon on the taskbar. Choose hidden, icon only, full box, or icon with label. Hiding saves space and avoids the integrated web (Bing) search suggestions."
        Choices      = @(
            @{ Id = "hide"; Label = "隱藏 (仍可按 Win 鍵搜尋)"; LabelEn = "Hide (Win key search still works)"
               Reg = @(
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "SearchboxTaskbarMode";      Value = 0; Type = "DWord" }
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "SearchboxTaskbarModeCache"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "icon"; Label = "只顯示搜尋圖示 (小)"; LabelEn = "Icon only (small)"
               Reg = @(
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "SearchboxTaskbarMode";      Value = 1; Type = "DWord" }
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "SearchboxTaskbarModeCache"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "box"; Label = "搜尋框 (大,系統預設)"; LabelEn = "Search box (large, system default)"
               Reg = @(
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "SearchboxTaskbarMode";      Value = 2; Type = "DWord" }
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "SearchboxTaskbarModeCache"; Value = 2; Type = "DWord" }
               ) }
            @{ Id = "icon_label"; Label = "搜尋圖示 + 標籤"; LabelEn = "Search icon + label"
               Reg = @(
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "SearchboxTaskbarMode";      Value = 3; Type = "DWord" }
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "SearchboxTaskbarModeCache"; Value = 3; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "hide"
        MinBuild     = $null
        Source       = "HKCU\...\Search\SearchboxTaskbarMode (0=隱藏、1=圖示、2=框、3=圖示+標籤);設定 App > 個人化 > 工作列"
        VerifiedDate = "2026-07-04"
        Notes        = "重要:24H2 起系統會檢查 SearchboxTaskbarModeCache,若此鍵不存在,Taskbar.dll 的 TryMigrateSearchConditionally 會把 Mode 重置為 2 (重新顯示搜尋框)。故每個選項都同時寫入 Mode + Cache 兩鍵確保穩定。建議隱藏以省空間並避免整合的網路搜尋建議。"
        NotesEn        = "Important: from 24H2 the system checks SearchboxTaskbarModeCache; if this key is missing, Taskbar.dll's TryMigrateSearchConditionally resets Mode to 2 (re-showing the search box). So each option writes both Mode + Cache keys for stability. Hiding is recommended to save space and avoid integrated web search suggestions."
    },

    # ── 工作列工作檢視按鈕 (純偏好) ──
    @{
        Id           = "taskbar_taskview"
        Category     = 5
        NameZh       = "工作列『工作檢視』按鈕"
        NameEn       = "Taskbar Task View Button"
        DescZh       = "工作列上的工作檢視 (多桌面) 按鈕。隱藏後仍可按 Win+Tab 使用。"
        DescEn       = "The Task View (virtual desktops) button on the taskbar. After hiding, Win+Tab still works."
        Choices      = @(
            @{ Id = "hide"; Label = "隱藏工作檢視按鈕"; LabelEn = "Hide Task View button"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowTaskViewButton"; Value = 0; Type = "DWord" }) }
            @{ Id = "show"; Label = "顯示工作檢視按鈕"; LabelEn = "Show Task View button"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowTaskViewButton"; Value = 1; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "HKCU\...\Explorer\Advanced\ShowTaskViewButton (0=隱藏、1=顯示,官方 learn 確認)"
        VerifiedDate = "2026-07-04"
        Notes        = "屬個人偏好;隱藏後仍可用 Win+Tab 開啟工作檢視。"
        NotesEn        = "A personal preference; after hiding, Win+Tab still opens Task View."
    },

    # ── 工作列小工具 (廣告/效能益處) ──
    @{
        Id           = "taskbar_widgets"
        Category     = 5
        NameZh       = "工作列小工具 (News/天氣)"
        NameEn       = "Taskbar Widgets (News/Weather)"
        DescZh       = "工作列左側的小工具 (天氣/新聞) 按鈕。此設定從政策層級徹底停用整個小工具平台 (含背景服務與新聞饋送),而非只隱藏按鈕。"
        DescEn       = "The Widgets (weather/news) button on the left of the taskbar. This setting disables the entire widgets platform at policy level (including background service and news feed), not just hiding the button."
        Choices      = @(
            @{ Id = "disable"; Label = "停用小工具 (政策層級,徹底)"; LabelEn = "Disable widgets (policy-level, thorough)"
               Reg = @(@{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"; Name = "AllowNewsAndInterests"; Value = 0; Type = "DWord" }) }
            @{ Id = "enable"; Label = "啟用小工具"; LabelEn = "Enable widgets"
               Reg = @(@{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"; Name = "AllowNewsAndInterests"; Value = 1; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/ (NewsAndInterests/AllowNewsAndInterests) / HKLM\SOFTWARE\Policies\Microsoft\Dsh (0=停用、1=啟用)"
        VerifiedDate = "2026-07-04"
        Notes        = "24H2/25H2 小工具由 Dsh 政策分支控制。AllowNewsAndInterests=0 是政策層級停用,關閉整個小工具平台 (背景服務、WebView2 容器、新聞饋送),按鈕消失且能撐過功能更新;比只隱藏按鈕的 HKCU\TaskbarDa 更徹底可靠。停用可避免新聞饋送拉取網路內容與佔用資源。"
        NotesEn        = "In 24H2/25H2 widgets are controlled by the Dsh policy branch. AllowNewsAndInterests=0 disables at policy level, shutting down the entire widgets platform (background service, WebView2 container, news feed); the button disappears and it survives feature updates — more thorough and reliable than the button-only HKCU\TaskbarDa. Disabling avoids the news feed pulling web content and consuming resources."
    },

    # ── 工作列聊天按鈕 (純偏好) ──
    @{
        Id           = "taskbar_chat"
        Category     = 5
        NameZh       = "工作列『聊天』按鈕"
        NameEn       = "Taskbar Chat Button"
        DescZh       = "工作列上的 Teams 聊天 (Chat) 按鈕。"
        DescEn       = "The Teams Chat button on the taskbar."
        Choices      = @(
            @{ Id = "hide"; Label = "隱藏聊天按鈕"; LabelEn = "Hide Chat button"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "TaskbarMn"; Value = 0; Type = "DWord" }) }
            @{ Id = "show"; Label = "顯示聊天按鈕"; LabelEn = "Show Chat button"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "TaskbarMn"; Value = 1; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "HKCU\...\Explorer\Advanced\TaskbarMn (0=隱藏、1=顯示)"
        VerifiedDate = "2026-07-04"
        Notes        = "屬個人偏好。24H2/25H2 許多乾淨安裝已預設不釘選消費版 Teams 聊天按鈕,此時套用不會有可見差別 (無害)。"
        NotesEn        = "A personal preference. Many clean installs of 24H2/25H2 no longer pin the consumer Teams Chat button by default, so applying may show no visible difference (harmless)."
    },

    # ══════════════ 開始選單 ══════════════

    # ── 開始選單最近項目 (隱私,兩鍵一組) ──
    @{
        Id           = "start_recent"
        Category     = 5
        NameZh       = "開始選單顯示最近開啟項目 (隱私)"
        NameEn       = "Start Menu Recently Opened Items (Privacy)"
        DescZh       = "開始選單『建議』區與跳躍清單顯示你最近開啟的文件與最近新增的 App。"
        DescEn       = "The Start menu 'Recommended' area and jump lists show your recently opened documents and recently added apps."
        Choices      = @(
            @{ Id = "disable"; Label = "關閉最近項目 (文件 + App 追蹤一併關)"; LabelEn = "Turn off recent items (documents + app tracking)"
               Reg = @(
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_TrackDocs";  Value = 0; Type = "DWord" }
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_TrackProgs"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "enable"; Label = "顯示最近項目"; LabelEn = "Show recent items"
               Reg = @(
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_TrackDocs";  Value = 1; Type = "DWord" }
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_TrackProgs"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "HKCU\...\Explorer\Advanced\Start_TrackDocs (最近文件) + Start_TrackProgs (最近新增 App),0=關、1=開"
        VerifiedDate = "2026-07-04"
        Notes        = "兩鍵一併設定最徹底:Start_TrackDocs 關最近文件、Start_TrackProgs 關最近新增 App。關閉後開始選單與跳躍清單不再顯示你最近開啟的東西,提升隱私。"
        NotesEn        = "Setting both keys is most thorough: Start_TrackDocs turns off recent documents, Start_TrackProgs turns off recently added apps. Once off, the Start menu and jump lists no longer show your recently opened items, improving privacy."
    },

    # ══════════════ 桌面圖示 ══════════════

    # ── 桌面本機圖示 (純偏好) ──
    @{
        Id           = "desktop_thispc"
        Category     = 5
        NameZh       = "桌面『本機』圖示"
        NameEn       = "Desktop 'This PC' Icon"
        DescZh       = "在桌面顯示『本機』(我的電腦) 圖示,雙擊即開檔案總管。"
        DescEn       = "Shows the 'This PC' (My Computer) icon on the desktop; double-click to open File Explorer."
        Choices      = @(
            @{ Id = "show"; Label = "顯示本機圖示"; LabelEn = "Show This PC icon"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"; Name = "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"; Value = 0; Type = "DWord" }) }
            @{ Id = "hide"; Label = "隱藏本機圖示"; LabelEn = "Hide This PC icon"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"; Name = "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"; Value = 1; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "HKCU\...\HideDesktopIcons\NewStartPanel\{20D04FE0-...} (0=顯示、1=隱藏)"
        VerifiedDate = "2026-07-04"
        Notes        = "屬個人偏好;需重新整理桌面 (F5) 生效。"
        NotesEn        = "A personal preference; requires refreshing the desktop (F5) to take effect."
    },

    # ── 桌面資源回收筒圖示 (純偏好) ──
    @{
        Id           = "desktop_recyclebin"
        Category     = 5
        NameZh       = "桌面『資源回收筒』圖示"
        NameEn       = "Desktop 'Recycle Bin' Icon"
        DescZh       = "在桌面顯示『資源回收筒』圖示。"
        DescEn       = "Shows the 'Recycle Bin' icon on the desktop."
        Choices      = @(
            @{ Id = "show"; Label = "顯示資源回收筒"; LabelEn = "Show Recycle Bin"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"; Name = "{645FF040-5081-101B-9F08-00AA002F954E}"; Value = 0; Type = "DWord" }) }
            @{ Id = "hide"; Label = "隱藏資源回收筒"; LabelEn = "Hide Recycle Bin"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"; Name = "{645FF040-5081-101B-9F08-00AA002F954E}"; Value = 1; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "HKCU\...\HideDesktopIcons\NewStartPanel\{645FF040-...} (0=顯示、1=隱藏)"
        VerifiedDate = "2026-07-04"
        Notes        = "屬個人偏好;需重新整理桌面 (F5) 生效。"
        NotesEn        = "A personal preference; requires refreshing the desktop (F5) to take effect."
    },

    # ══════════════ 安全習慣 ══════════════

    # ── 刪除確認對話框 (安全) ──
    @{
        Id           = "confirm_delete"
        Category     = 5
        NameZh       = "刪除檔案確認對話框 (安全性)"
        NameEn       = "Delete Confirmation Dialog (Security)"
        DescZh       = "Windows 11 預設刪除檔案時直接移到資源回收筒,不跳確認。可改為刪除前先確認,避免手滑誤刪。"
        DescEn       = "Windows 11 moves files straight to the Recycle Bin without confirmation by default. Can be changed to confirm before deleting, avoiding accidental deletion."
        Choices      = @(
            @{ Id = "enable"; Label = "啟用刪除確認"; LabelEn = "Enable delete confirmation"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name = "ConfirmFileDelete"; Value = 1; Type = "DWord" }) }
            @{ Id = "disable"; Label = "不顯示刪除確認"; LabelEn = "No delete confirmation"
               Reg = @(@{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name = "ConfirmFileDelete"; Value = 0; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "enable"
        MinBuild     = $null
        Source       = "HKCU\...\Policies\Explorer\ConfirmFileDelete (1=確認、0=不確認)"
        VerifiedDate = "2026-07-04"
        Notes        = "啟用後刪除檔案前跳出確認對話框,是防手滑誤刪的安全習慣。"
        NotesEn        = "When enabled, a confirmation dialog appears before deleting files — a safety habit against accidental deletion."
    }
    )
}
