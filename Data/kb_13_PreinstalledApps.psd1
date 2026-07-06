<#
    Windows 11 設定精靈 - 知識庫:第 14 類 預裝軟體 (Preinstalled Apps)
    ================================================================
    本類與其他類不同:不是固定設定項,而是「動態掃描實機安裝的 Appx →
    逐一顯示移除建議」。故 KB 內容是「對照表」而非 Choices 清單。

    模組執行時 Get-AppxPackage 掃出實機所有 App,依下列三層處理:
      1. SystemCritical (黑名單):系統關鍵元件,直接不顯示,杜絕誤刪。
      2. KnownApps (對照表):已知可安全移除的 App,顯示中文名 + 移除建議。
      3. 其餘掃到但未收錄者:顯示原始名 + 標「未收錄,請自行判斷」,預設保留。

    移除機制:Remove-AppxPackage (只移除目前使用者)。移除的 App 多數可日後
    從 Microsoft Store 重新安裝;移除清單會記錄於設定檔。

    對照依據:微軟官方 RemoveDefaultMicrosoftStorePackages 政策可移除清單
    (learn.microsoft.com) + 社群公認 bloatware。比對用 Name 欄位 (子字串比對,
    不分大小寫),比顯示名穩定。

    Recommend 欄位:"remove"=建議移除 / "keep"=建議保留 (預設一律尊重使用者)。

    Import-PowerShellDataFile 規定檔案最外層須為 Hashtable。
#>

@{
    # ═══════════════════════════════════════════════════════════
    #  第 1 層:系統關鍵元件黑名單 (掃描時比對到即隱藏,不顯示給使用者)
    #  比對方式:App 的 Name 若「包含」下列任一字串 (不分大小寫) → 視為系統關鍵。
    #  這些移除會弄壞系統 (商店、執行庫、殼層、輸入法、帳戶、安全等)。
    # ═══════════════════════════════════════════════════════════
    SystemCritical = @(
        # 商店與部署核心
        "Microsoft.WindowsStore"
        "Microsoft.StorePurchaseApp"
        "Microsoft.DesktopAppInstaller"      # winget / App Installer
        "Microsoft.Services.Store.Engagement"
        # 執行庫 / 框架 (移除會讓大量 App 打不開)
        "Microsoft.VCLibs"
        "Microsoft.UI.Xaml"
        "Microsoft.NET.Native.Framework"
        "Microsoft.NET.Native.Runtime"
        "Microsoft.WindowsAppRuntime"
        "MicrosoftWindows.Client.CBS"        # 殼層核心元件 (工作列/開始等)
        "MicrosoftWindows.Client.Core"
        "Microsoft.WindowsAppRuntime.CBS"
        # 殼層 / 系統 UI
        "ShellExperienceHost"
        "StartMenuExperienceHost"
        "Windows.CBSPreview"
        "Microsoft.Windows.ShellExperienceHost"
        "Microsoft.Windows.StartMenuExperienceHost"
        "Microsoft.Windows.Search"           # 搜尋
        "Microsoft.Windows.ContentDeliveryManager"
        "Microsoft.AAD.BrokerPlugin"         # 帳戶驗證
        "Microsoft.Windows.CloudExperienceHost"
        "Microsoft.AccountsControl"
        "Microsoft.LockApp"                  # 鎖定畫面
        "Microsoft.Windows.SecHealthUI"      # Windows 安全性中心
        "Microsoft.SecHealthUI"
        "Microsoft.Windows.PeopleExperienceHost"
        "Microsoft.Windows.CapturePicker"
        "Microsoft.Windows.NarratorQuickStart"
        "Microsoft.XboxGameCallableUI"
        "Microsoft.CredDialogHost"
        "Microsoft.ECApp"                    # 色彩管理
        "Microsoft.Win32WebViewHost"
        # 輸入法 / 語言 (移除影響中日韓等輸入)
        "Microsoft.InputApp"
        "Microsoft.LanguageExperiencePack"
        "Microsoft.Windows.CallingShellApp"
        "Microsoft.WindowsFeedback"          # 診斷 (非 Feedback Hub App)
        "Microsoft.MicrosoftEdge"            # Edge 系統元件 (WebView2 相依,不從此處移除)
        "Microsoft.WebpImageExtension"       # 影像編解碼延伸
        "Microsoft.HEIFImageExtension"
        "Microsoft.HEVCVideoExtension"
        "Microsoft.VP9VideoExtensions"
        "Microsoft.AV1VideoExtension"
        "Microsoft.RawImageExtension"
        "Microsoft.DolbyAudioExtensions"
        "Microsoft.AVCEncoderVideoExtension"
    )

    # ═══════════════════════════════════════════════════════════
    #  第 2 層:已知 App 對照表 (可安全移除者;掃到才顯示)
    #  Match  = 用來比對 App Name 的子字串 (不分大小寫)
    #  NameZh = 顯示用中文名稱
    #  Recommend = "remove" (建議移除) / "keep" (建議保留)
    #  Note   = 移除建議說明 (含代價/用途)
    # ═══════════════════════════════════════════════════════════
    KnownApps = @(
        # ── Office / 生產力推銷類 (建議移除) ──
        @{ Match = "Microsoft.MicrosoftOfficeHub";        NameZh = "Office (Microsoft 365) 入口"; NameEn = "Office (Microsoft 365) Portal";  Recommend = "remove"; Note = "只是連往 Office 網頁服務的入口捷徑,移除不影響已安裝的 Office 本體。用不到可移除。"; NoteEn = "Just a shortcut to Office web services; removing doesn't affect installed Office. Remove if unused." }
        @{ Match = "Microsoft.OutlookForWindows";         NameZh = "新版 Outlook (網頁版)"; NameEn = "New Outlook (Web)";        Recommend = "remove"; Note = "新版網頁式 Outlook,功能較陽春且會推銷。若你用傳統 Outlook 或其他郵件軟體,可移除。"; NoteEn = "The new web-based Outlook, basic and promotional. Remove if you use classic Outlook or another mail client." }
        @{ Match = "Microsoft.Todos";                     NameZh = "Microsoft To Do 待辦"; NameEn = "Microsoft To Do";         Recommend = "keep";   Note = "待辦清單 App。有在用就保留,否則可移除。"; NoteEn = "A to-do list app. Keep if you use it, otherwise remove." }
        @{ Match = "Microsoft.MicrosoftStickyNotes";      NameZh = "便利貼 Sticky Notes"; NameEn = "Sticky Notes";          Recommend = "keep";   Note = "桌面便利貼,可同步。有在用就保留。"; NoteEn = "Desktop sticky notes with sync. Keep if you use it." }
        @{ Match = "Microsoft.PowerAutomateDesktop";      NameZh = "Power Automate 桌面版"; NameEn = "Power Automate Desktop";        Recommend = "remove"; Note = "自動化流程工具,一般使用者少用,可移除。"; NoteEn = "A workflow automation tool, rarely used by average users. Can remove." }
        @{ Match = "MicrosoftCorporationII.QuickAssist";  NameZh = "快速助手 Quick Assist"; NameEn = "Quick Assist";        Recommend = "keep";   Note = "遠端協助工具 (求助他人時用)。偶爾需要遠端支援可保留。"; NoteEn = "A remote assistance tool (for getting help). Keep if you occasionally need remote support." }
        @{ Match = "Microsoft.Windows.DevHome";           NameZh = "Dev Home 開發者儀表板"; NameEn = "Dev Home";        Recommend = "remove"; Note = "開發者用儀表板,非開發者可移除。"; NoteEn = "A developer dashboard; non-developers can remove it." }

        # ── 影音 / 剪輯 ──
        @{ Match = "Clipchamp";                           NameZh = "Clipchamp 影片剪輯"; NameEn = "Clipchamp Video Editor";           Recommend = "remove"; Note = "網頁式影片剪輯,部分功能需付費。不剪片可移除;有專案請先匯出。"; NoteEn = "A web-based video editor, some features paid. Remove if you don't edit video; export projects first." }
        @{ Match = "Microsoft.ZuneMusic";                 NameZh = "媒體播放器 (Media Player)"; NameEn = "Media Player";    Recommend = "keep";   Note = "系統音樂/媒體播放器。移除後預設播放器會缺,建議保留。"; NoteEn = "The system music/media player. Removing leaves no default player; recommended to keep." }
        @{ Match = "Microsoft.ZuneVideo";                 NameZh = "電影與電視"; NameEn = "Movies & TV";                   Recommend = "keep";   Note = "影片播放器。有在用就保留。"; NoteEn = "A video player. Keep if you use it." }
        @{ Match = "SpotifyAB.SpotifyMusic";              NameZh = "Spotify (預裝推銷)"; NameEn = "Spotify (preinstalled promo)";           Recommend = "remove"; Note = "預裝的 Spotify 推銷版。用不到可移除,需要可自行從商店裝。"; NoteEn = "A preinstalled Spotify promo. Remove if unused; reinstall from the Store if needed." }

        # ── AI / Copilot ──
        @{ Match = "Microsoft.Copilot";                   NameZh = "Copilot AI 助理"; NameEn = "Copilot AI Assistant";              Recommend = "keep";   Note = "微軟 AI 助理。用不到可移除,想用 AI 就保留。"; NoteEn = "Microsoft's AI assistant. Remove if unused; keep if you want AI." }
        @{ Match = "Microsoft.Windows.Ai.Copilot.Provider"; NameZh = "Copilot 提供者元件"; NameEn = "Copilot Provider Component";         Recommend = "keep";   Note = "Copilot 相關元件。若要完全移除 Copilot 可一併移除。"; NoteEn = "A Copilot-related component. Remove alongside if fully removing Copilot." }

        # ── 通訊 ──
        @{ Match = "MSTeams";                             NameZh = "Teams (新版)"; NameEn = "Teams (new)";                 Recommend = "keep";   Note = "微軟 Teams。工作有用就保留,否則可移除。"; NoteEn = "Microsoft Teams. Keep if useful for work, otherwise remove." }
        @{ Match = "MicrosoftTeams";                      NameZh = "Teams 個人版 (Chat)"; NameEn = "Teams Personal (Chat)";          Recommend = "remove"; Note = "消費版 Teams 聊天。用不到可移除。"; NoteEn = "Consumer Teams Chat. Remove if unused." }
        @{ Match = "Microsoft.YourPhone";                 NameZh = "手機連結 (Phone Link)"; NameEn = "Phone Link";        Recommend = "keep";   Note = "連結 Android/iPhone。有在用就保留,否則可移除。"; NoteEn = "Links Android/iPhone. Keep if you use it, otherwise remove." }
        @{ Match = "Microsoft.People";                    NameZh = "連絡人 People"; NameEn = "People";                Recommend = "remove"; Note = "舊版連絡人 App,多數人用不到,可移除。"; NoteEn = "The legacy contacts app, unused by most. Can remove." }

        # ── 遊戲 / Xbox (非系統關鍵的可移除部分) ──
        @{ Match = "Microsoft.MicrosoftSolitaireCollection"; NameZh = "微軟接龍 Solitaire"; NameEn = "Microsoft Solitaire";        Recommend = "remove"; Note = "內建小遊戲 (含廣告)。不玩可移除。"; NoteEn = "A built-in game (with ads). Remove if you don't play." }
        @{ Match = "Microsoft.GamingApp";                 NameZh = "Xbox App"; NameEn = "Xbox App";                     Recommend = "keep";   Note = "Xbox 遊戲 App (Game Pass、遊戲庫)。玩遊戲會用到就保留,否則可移除。"; NoteEn = "The Xbox gaming app (Game Pass, game library). Keep if you game, otherwise remove." }
        @{ Match = "Microsoft.XboxGamingOverlay";         NameZh = "Xbox Game Bar"; NameEn = "Xbox Game Bar";                Recommend = "keep";   Note = "遊戲列 (Win+G)。搭配 13 類的 GameDVR;不錄影可保留 App、僅關背景錄製即可。"; NoteEn = "The game bar (Win+G). Pairs with GameDVR in category 12; if not recording, keep the app and just disable background recording." }
        @{ Match = "Microsoft.XboxIdentityProvider";      NameZh = "Xbox 登入元件"; NameEn = "Xbox Identity Provider";                Recommend = "keep";   Note = "遊戲登入 Xbox 帳號用。玩需登入的遊戲會用到,建議保留。"; NoteEn = "For signing into an Xbox account in games. Recommended to keep for games requiring sign-in." }
        @{ Match = "Microsoft.XboxSpeechToTextOverlay";   NameZh = "Xbox 語音轉文字"; NameEn = "Xbox Speech-to-Text";              Recommend = "remove"; Note = "遊戲語音字幕覆蓋,少用,可移除。"; NoteEn = "A game voice-caption overlay, rarely used. Can remove." }
        @{ Match = "Microsoft.Xbox.TCUI";                 NameZh = "Xbox TCUI 元件"; NameEn = "Xbox TCUI Component";               Recommend = "keep";   Note = "部分遊戲的 Xbox 介面相依,建議保留。"; NoteEn = "An Xbox UI dependency for some games; recommended to keep." }

        # ── Bing / 資訊 / 小工具 ──
        @{ Match = "Microsoft.BingNews";                  NameZh = "Bing 新聞 News"; NameEn = "Bing News";               Recommend = "remove"; Note = "新聞 App (含推播/廣告),多數人用瀏覽器看新聞,可移除。"; NoteEn = "A news app (with push/ads); most read news in a browser. Can remove." }
        @{ Match = "Microsoft.BingWeather";               NameZh = "Bing 天氣 Weather"; NameEn = "Bing Weather";            Recommend = "keep";   Note = "天氣 App。有在用就保留,否則可移除。"; NoteEn = "A weather app. Keep if you use it, otherwise remove." }
        @{ Match = "Microsoft.BingSearch";                NameZh = "Bing 搜尋 (網頁搜尋整合)"; NameEn = "Bing Search (web search integration)";     Recommend = "remove"; Note = "工作列搜尋的 Bing 網頁搜尋元件,不想要網頁搜尋結果可移除。"; NoteEn = "The Bing web-search component in taskbar search. Remove if you don't want web results." }
        @{ Match = "Microsoft.Windows.Widgets";           NameZh = "小工具平台 Widgets"; NameEn = "Widgets Platform";           Recommend = "remove"; Note = "工作列小工具 (天氣/新聞面板)。用不到可移除;亦可在 06 類僅停用按鈕。"; NoteEn = "Taskbar widgets (weather/news panel). Remove if unused; or just disable the button in category 05." }
        @{ Match = "MicrosoftWindows.Client.WebExperience"; NameZh = "小工具網頁體驗元件"; NameEn = "Widgets Web Experience";          Recommend = "remove"; Note = "小工具的網頁承載元件。要徹底移除小工具可一併移除。"; NoteEn = "The web host component for widgets. Remove alongside to fully remove widgets." }

        # ── 工具 / 附屬 App (多數建議保留,除非確定不用) ──
        @{ Match = "Microsoft.WindowsCamera";             NameZh = "相機 Camera"; NameEn = "Camera";                  Recommend = "keep";   Note = "系統相機 App。有 webcam 且會用到就保留。"; NoteEn = "The system camera app. Keep if you have a webcam and use it." }
        @{ Match = "Microsoft.ScreenSketch";              NameZh = "剪取工具 Snipping Tool"; NameEn = "Snipping Tool";       Recommend = "keep";   Note = "螢幕截圖工具 (Win+Shift+S),很實用,建議保留。"; NoteEn = "A screenshot tool (Win+Shift+S), very useful; recommended to keep." }
        @{ Match = "Microsoft.Paint";                     NameZh = "小畫家 Paint"; NameEn = "Paint";                 Recommend = "keep";   Note = "小畫家。輕量繪圖/看圖,建議保留。"; NoteEn = "Paint. Lightweight drawing/viewing; recommended to keep." }
        @{ Match = "Microsoft.WindowsNotepad";            NameZh = "記事本 Notepad"; NameEn = "Notepad";               Recommend = "keep";   Note = "記事本,基本文字編輯,建議保留。"; NoteEn = "Notepad, basic text editing; recommended to keep." }
        @{ Match = "Microsoft.WindowsCalculator";         NameZh = "小算盤 Calculator"; NameEn = "Calculator";            Recommend = "keep";   Note = "計算機,建議保留。"; NoteEn = "Calculator; recommended to keep." }
        @{ Match = "Microsoft.WindowsSoundRecorder";      NameZh = "錄音機 Sound Recorder"; NameEn = "Sound Recorder";        Recommend = "keep";   Note = "錄音工具。有在用就保留,否則可移除。"; NoteEn = "A voice recorder. Keep if you use it, otherwise remove." }
        @{ Match = "Microsoft.WindowsAlarms";             NameZh = "鬧鐘與時鐘 Clock"; NameEn = "Clock";             Recommend = "keep";   Note = "鬧鐘/計時器/世界時鐘。有在用就保留,否則可移除。"; NoteEn = "Alarms/timers/world clock. Keep if you use it, otherwise remove." }
        @{ Match = "Microsoft.549981C3F5F10";             NameZh = "Cortana (已淘汰)"; NameEn = "Cortana (deprecated)";             Recommend = "remove"; Note = "微軟已淘汰的 Cortana 語音助理,可移除。"; NoteEn = "Microsoft's deprecated Cortana voice assistant. Can remove." }
        @{ Match = "Microsoft.Windows.DevHomeGitHubExtension"; NameZh = "Dev Home GitHub 擴充"; NameEn = "Dev Home GitHub Extension";     Recommend = "remove"; Note = "Dev Home 的 GitHub 擴充,非開發者可移除。"; NoteEn = "Dev Home's GitHub extension; non-developers can remove." }
        @{ Match = "Microsoft.family";                    NameZh = "家庭 Family 家長監護"; NameEn = "Family (parental controls)";         Recommend = "keep";   Note = "家庭安全/家長監護。有在用就保留,否則可移除。"; NoteEn = "Family safety/parental controls. Keep if you use it, otherwise remove." }
        @{ Match = "MicrosoftWindows.CrossDevice";        NameZh = "跨裝置體驗 Cross Device"; NameEn = "Cross Device Experience";      Recommend = "keep";   Note = "手機/裝置整合體驗。用不到可移除。"; NoteEn = "A phone/device integration experience. Remove if unused." }
        @{ Match = "Microsoft.Windows.Photos";            NameZh = "相片 Photos"; NameEn = "Photos";                  Recommend = "keep";   Note = "系統看圖 App。移除後看圖較不便,建議保留。"; NoteEn = "The system photo viewer. Removing makes viewing images inconvenient; recommended to keep." }
        @{ Match = "Microsoft.WindowsTerminal";           NameZh = "Windows 終端機 Terminal"; NameEn = "Windows Terminal";      Recommend = "keep";   Note = "現代終端機 (PowerShell/CMD/WSL),進階使用者很實用,建議保留。"; NoteEn = "A modern terminal (PowerShell/CMD/WSL), very useful for power users; recommended to keep." }
        @{ Match = "Microsoft.MSPaint";                   NameZh = "小畫家 3D (Paint 3D)"; NameEn = "Paint 3D";         Recommend = "remove"; Note = "已淘汰的 3D 小畫家,多數人用不到,可移除。"; NoteEn = "The deprecated Paint 3D, unused by most. Can remove." }
        @{ Match = "Microsoft.WindowsMaps";               NameZh = "地圖 Maps (已淘汰)"; NameEn = "Maps (deprecated)";           Recommend = "remove"; Note = "微軟已於 24H2 淘汰地圖 App。若殘留可移除,改用網頁地圖。"; NoteEn = "Microsoft deprecated the Maps app in 24H2. Remove if left over; use web maps instead." }
        @{ Match = "Microsoft.GetHelp";                   NameZh = "取得協助 Get Help"; NameEn = "Get Help";            Recommend = "remove"; Note = "微軟客服/協助入口,多數人用不到,可移除。"; NoteEn = "Microsoft support/help portal, unused by most. Can remove." }
        @{ Match = "Microsoft.Getstarted";                NameZh = "秘訣 Tips"; NameEn = "Tips";                    Recommend = "remove"; Note = "Windows 使用秘訣 App,老手用不到,可移除。"; NoteEn = "A Windows tips app, unneeded by experienced users. Can remove." }
        @{ Match = "Microsoft.WindowsFeedbackHub";        NameZh = "意見反應中樞 Feedback Hub"; NameEn = "Feedback Hub";    Recommend = "remove"; Note = "回報問題給微軟用,一般人少用,可移除。"; NoteEn = "For reporting issues to Microsoft, rarely used. Can remove." }
        @{ Match = "Microsoft.MicrosoftJournal";          NameZh = "Journal 手寫筆記"; NameEn = "Journal";             Recommend = "keep";   Note = "觸控筆手寫筆記。有觸控筆會用到就保留,否則可移除。"; NoteEn = "Stylus handwriting notes. Keep if you use a stylus, otherwise remove." }

        # ── 第三方預裝推銷 (OEM/微軟塞的,建議移除) ──
        @{ Match = "Disney";                              NameZh = "Disney+ (預裝推銷)"; NameEn = "Disney+ (preinstalled promo)";           Recommend = "remove"; Note = "預裝的 Disney+ 推銷 App,用不到可移除。"; NoteEn = "A preinstalled Disney+ promo app. Remove if unused." }
        @{ Match = "BytedancePte.TikTok";                 NameZh = "TikTok (預裝推銷)"; NameEn = "TikTok (preinstalled promo)";            Recommend = "remove"; Note = "預裝的 TikTok 推銷 App,用不到可移除。"; NoteEn = "A preinstalled TikTok promo app. Remove if unused." }
        @{ Match = "Facebook";                            NameZh = "Facebook (預裝推銷)"; NameEn = "Facebook (preinstalled promo)";          Recommend = "remove"; Note = "預裝的 Facebook 推銷 App,用不到可移除。"; NoteEn = "A preinstalled Facebook promo app. Remove if unused." }
        @{ Match = "Instagram";                           NameZh = "Instagram (預裝推銷)"; NameEn = "Instagram (preinstalled promo)";         Recommend = "remove"; Note = "預裝的 Instagram 推銷 App,用不到可移除。"; NoteEn = "A preinstalled Instagram promo app. Remove if unused." }
        @{ Match = "AmazonVideo.PrimeVideo";              NameZh = "Prime Video (預裝推銷)"; NameEn = "Prime Video (preinstalled promo)";       Recommend = "remove"; Note = "預裝的 Prime Video 推銷 App,用不到可移除。"; NoteEn = "A preinstalled Prime Video promo app. Remove if unused." }
        @{ Match = "Netflix";                             NameZh = "Netflix (預裝推銷)"; NameEn = "Netflix (preinstalled promo)";           Recommend = "remove"; Note = "預裝的 Netflix 推銷 App,用不到可移除。"; NoteEn = "A preinstalled Netflix promo app. Remove if unused." }
        @{ Match = "LinkedInforWindows";                  NameZh = "LinkedIn (預裝推銷)"; NameEn = "LinkedIn (preinstalled promo)";          Recommend = "remove"; Note = "預裝的 LinkedIn 推銷 App,用不到可移除。"; NoteEn = "A preinstalled LinkedIn promo app. Remove if unused." }
        @{ Match = "king.com";                            NameZh = "Candy Crush 等小遊戲 (預裝)"; NameEn = "Candy Crush & casual games (preinstalled)";  Recommend = "remove"; Note = "預裝的 King 小遊戲 (Candy Crush 等),含廣告,不玩可移除。"; NoteEn = "Preinstalled King games (Candy Crush, etc.) with ads. Remove if you don't play." }
    )

    # ═══════════════════════════════════════════════════════════
    #  第 4 層:Win32 排除清單 (掃到但受系統保護/相依過深,不該由本工具移除)
    #  比對方式:Win32 程式的 DisplayName 若「包含」下列任一字串 → 隱藏。
    #  這些即使執行 UninstallString 也移不掉 (Edge) 或會連鎖壞掉 (WebView2),
    #  列出只會給假成功、誤導使用者。
    # ═══════════════════════════════════════════════════════════
    Win32Excluded = @(
        "Microsoft Edge"          # 微軟官方:Edge 為 OS 必要元件,無法解除安裝
        "Microsoft Edge Update"   # Edge 更新器,無有效解除安裝
        "Microsoft EdgeWebView"   # WebView2 執行庫,大量程式相依,移除會連鎖壞掉
        "Microsoft Edge WebView2" # WebView2 (顯示名變體)
    )
}
