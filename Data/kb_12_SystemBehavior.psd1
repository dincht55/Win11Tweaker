<#
    Windows 11 設定精靈 - 知識庫:第 13 類 系統行為 (System Behavior)
    ================================================================
    格式:選項式統一模型 (Choices + Recommend),三選項模型。

    涵蓋效能/回應 (遊戲背景錄製、視覺效果、背景 App) 與系統雜項
    (剪貼簿歷程、系統廣告與建議)。

    收錄標準:知情取捨型項目一律收錄,說明清楚代價,建議依性質決定
    (純廣告類建議停用;純偏好/取捨類建議維持現狀)。

    Import-PowerShellDataFile 規定檔案最外層須為 Hashtable。
#>

@{
    Items = @(

    # ── 遊戲背景錄製 GameDVR (效能) ──
    @{
        Id           = "game_dvr"
        Category     = 12
        NameZh       = "遊戲背景錄製 GameDVR (效能)"
        NameEn       = "Game Background Recording GameDVR (Performance)"
        DescZh       = "Xbox Game Bar 的背景錄製 (Win+G)。持續在背景待命以便隨時錄下遊戲畫面,會佔用 CPU/GPU 資源。不錄影/直播的人停用後可提升遊戲 FPS、降低佔用。"
        DescEn       = "Xbox Game Bar background recording (Win+G). Stays on standby in the background to record gameplay anytime, consuming CPU/GPU resources. For those who don't record/stream, disabling improves game FPS and reduces usage."
        Choices      = @(
            @{ Id = "disable"; Label = "停用背景錄製 (提升遊戲效能)"; LabelEn = "Disable background recording (improves game performance)"
               Reg = @(
                   @{ Path = "HKCU:\System\GameConfigStore";                              Name = "GameDVR_Enabled";     Value = 0; Type = "DWord" }
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR";    Name = "AppCaptureEnabled";   Value = 0; Type = "DWord" }
               ) }
            @{ Id = "enable"; Label = "啟用背景錄製"; LabelEn = "Enable background recording"
               Reg = @(
                   @{ Path = "HKCU:\System\GameConfigStore";                              Name = "GameDVR_Enabled";     Value = 1; Type = "DWord" }
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR";    Name = "AppCaptureEnabled";   Value = 1; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "HKCU\System\GameConfigStore\GameDVR_Enabled + HKCU\...\GameDVR\AppCaptureEnabled (0=停用、1=啟用)"
        VerifiedDate = "2026-07-05"
        Notes        = "停用背景錄製對不錄影/直播的人幾乎無感,還能提升遊戲效能 (FPS 提升、CPU/GPU 佔用降低、減少卡頓);唯一代價是 Win+G 的即時錄製快捷失效 (仍可另裝錄影軟體)。兩鍵一組:GameConfigStore 與 GameDVR 都設定,確保徹底。若你會用 Game Bar 錄遊戲,則維持啟用。"
        NotesEn        = "Disabling background recording is barely noticeable for those who don't record/stream, and improves game performance (higher FPS, lower CPU/GPU usage, less stutter); the only cost is that the Win+G instant-record shortcut stops working (you can install separate recording software). Two keys together: both GameConfigStore and GameDVR are set for thoroughness. If you record games with Game Bar, keep it enabled."
    },

    # ── 視覺透明效果 (偏好) ──
    @{
        Id           = "transparency"
        Category     = 12
        NameZh       = "視覺透明效果"
        NameEn       = "Visual Transparency Effects"
        DescZh       = "工作列、開始選單等介面的透明/毛玻璃 (Mica) 效果。純視覺偏好;關閉可讓低階機器稍微更流暢,高效能機器幾乎無感。"
        DescEn       = "Transparency/frosted-glass (Mica) effects for UI like the taskbar and Start menu. A purely visual preference; disabling makes low-end machines slightly smoother, with almost no effect on high-performance machines."
        Choices      = @(
            @{ Id = "disable"; Label = "關閉透明效果"; LabelEn = "Disable transparency effects"
               Reg = @(@{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "EnableTransparency"; Value = 0; Type = "DWord" }) }
            @{ Id = "enable"; Label = "開啟透明效果 (系統預設)"; LabelEn = "Enable transparency effects (system default)"
               Reg = @(@{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; Name = "EnableTransparency"; Value = 1; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "HKCU\...\Themes\Personalize\EnableTransparency (0=關、1=開)"
        VerifiedDate = "2026-07-05"
        Notes        = "純視覺偏好,無功能副作用。關閉在老舊/低階硬體上能稍微提升回應速度,現代高效能機器幾乎無感。喜歡透明美觀就維持開啟,追求極簡/一致就關閉。"
        NotesEn        = "A purely visual preference with no functional side effects. Disabling slightly improves responsiveness on old/low-end hardware, with almost no effect on modern high-performance machines. Keep on if you like the transparent look; disable for minimalism/consistency."
    },

    # ── 剪貼簿歷程 (隱私/便利取捨) ──
    @{
        Id           = "clipboard_history"
        Category     = 12
        NameZh       = "剪貼簿歷程 (Win+V)"
        NameEn       = "Clipboard History (Win+V)"
        DescZh       = "記錄最近複製的多筆內容 (最多 25 筆),可按 Win+V 回頭貼上或釘選。系統預設關閉。便利與隱私的取捨:開啟方便多筆貼上,但複製過的密碼等敏感內容會留存。"
        DescEn       = "Records multiple recently copied items (up to 25) that you can paste back or pin with Win+V. Off by default. A convenience vs. privacy tradeoff: enabling allows multi-item pasting, but copied sensitive content like passwords is retained."
        Choices      = @(
            @{ Id = "enable"; Label = "開啟剪貼簿歷程 (可多筆貼上)"; LabelEn = "Enable clipboard history (multi-item pasting)"
               Reg = @(@{ Path = "HKCU:\Software\Microsoft\Clipboard"; Name = "EnableClipboardHistory"; Value = 1; Type = "DWord" }) }
            @{ Id = "disable"; Label = "關閉剪貼簿歷程 (系統預設,較隱私)"; LabelEn = "Disable clipboard history (system default, more private)"
               Reg = @(@{ Path = "HKCU:\Software\Microsoft\Clipboard"; Name = "EnableClipboardHistory"; Value = 0; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "HKCU\Software\Microsoft\Clipboard\EnableClipboardHistory (1=開、0=關);系統預設關閉"
        VerifiedDate = "2026-07-05"
        Notes        = "便利 vs 隱私的取捨:開啟可回頭貼上最近複製的多筆內容 (工作效率),但複製過的密碼、驗證碼等敏感資料會暫存於歷程,他人操作電腦時可能看到。系統預設關閉 (偏隱私)。需要多筆貼上便利就開啟,重視隱私就維持關閉。"
        NotesEn        = "A convenience vs. privacy tradeoff: enabling lets you paste back multiple recently copied items (productivity), but sensitive data like copied passwords and verification codes is temporarily stored in the history, potentially visible to others using the PC. Off by default (privacy-leaning). Enable for multi-item pasting convenience; keep off if you value privacy."
    },

    # ── 背景 App 執行 (效能/通知取捨) ──
    @{
        Id           = "background_apps"
        Category     = 12
        NameZh       = "背景 App 執行 (Microsoft Store App)"
        NameEn       = "Background App Running (Microsoft Store Apps)"
        DescZh       = "是否允許 Microsoft Store (UWP) App 在背景執行。停用可省背景資源/電力/流量,但 Store App 將無法在背景即時收通知或更新資料 (不影響傳統桌面 exe 程式)。"
        DescEn       = "Whether Microsoft Store (UWP) apps may run in the background. Disabling saves background resources/power/data, but Store apps can't receive notifications or update data in the background in real time (doesn't affect traditional desktop .exe programs)."
        Choices      = @(
            @{ Id = "disable"; Label = "停用背景執行 (省資源,但 Store App 通知會延遲)"; LabelEn = "Disable background running (saves resources, but Store app notifications delayed)"
               Reg = @(@{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsRunInBackground"; Value = 2; Type = "DWord" }) }
            @{ Id = "enable"; Label = "允許背景執行 (即時收通知)"; LabelEn = "Allow background running (real-time notifications)"
               Reg = @(@{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"; Name = "LetAppsRunInBackground"; Value = 1; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/ (LetAppsRunInBackground);HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy (2=停用、1=強制允許)"
        VerifiedDate = "2026-07-05"
        Notes        = "只影響 Microsoft Store (UWP) App,不影響傳統桌面程式 (.exe)。停用的取捨:省背景資源與電力,但 Store 版的郵件、行事曆、Teams、訊息 App 無法在背景即時收通知/更新 (要開啟 App 才收到)。若你依賴這些 Store App 的即時通知就維持;若很少用 Store App、重視效能可停用。用政策鍵 (值 2) 全域停用最徹底,但會鎖住設定 App 的個別開關。需重開機生效。"
        NotesEn        = "Affects only Microsoft Store (UWP) apps, not traditional desktop programs (.exe). The tradeoff of disabling: saves background resources and power, but Store versions of Mail, Calendar, Teams, and Messaging apps can't receive notifications/updates in the background in real time (you must open the app). Keep if you rely on these Store apps' real-time notifications; disable if you rarely use Store apps and value performance. The policy key (value 2) disables globally and most thoroughly but locks the per-app toggles in Settings. Requires a reboot."
    },

    # ── 系統廣告與建議 (廣告清除,多鍵) ──
    @{
        Id           = "system_ads"
        Category     = 12
        NameZh       = "系統廣告與建議內容"
        NameEn       = "System Ads & Suggested Content"
        DescZh       = "Windows 內建的各種建議/推銷:設定 App 建議、開始選單建議 App、自動安裝推薦 App、使用提示通知、完成設定裝置提示、鎖定畫面提示廣告、檔案總管的 OneDrive/365 推廣橫幅、個人化廣告追蹤 ID。這些多屬廣告性質,關閉可讓系統更清爽。"
        DescEn       = "Various built-in Windows suggestions/promotions: Settings app suggestions, Start menu suggested apps, auto-installed recommended apps, tip notifications, finish-setting-up-device prompts, lock screen tip ads, File Explorer OneDrive/365 promo banners, and the personalized ad tracking ID. Mostly advertising in nature; disabling makes the system cleaner."
        Choices      = @(
            @{ Id = "disable"; Label = "關閉廣告與建議"; LabelEn = "Disable ads & suggestions"
               Reg = @(
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338393Enabled"; Value = 0; Type = "DWord" }
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338389Enabled"; Value = 0; Type = "DWord" }
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SystemPaneSuggestionsEnabled";     Value = 0; Type = "DWord" }
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SilentInstalledAppsEnabled";       Value = 0; Type = "DWord" }
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "PreInstalledAppsEnabled";          Value = 0; Type = "DWord" }
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement";  Name = "ScoobeSystemSettingEnabled";       Value = 0; Type = "DWord" }
                   # 鎖定畫面提示/廣告 (Windows Spotlight 的 fun facts/tips)
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "RotatingLockScreenOverlayEnabled"; Value = 0; Type = "DWord" }
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338387Enabled"; Value = 0; Type = "DWord" }
                   # 設定 App 建議內容 (補充鍵)
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-353694Enabled"; Value = 0; Type = "DWord" }
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-353696Enabled"; Value = 0; Type = "DWord" }
                   # 檔案總管的同步供應者通知 (OneDrive/365 推廣橫幅)
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced";      Name = "ShowSyncProviderNotifications";    Value = 0; Type = "DWord" }
                   # 廣告識別碼 (個人化廣告追蹤)
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo";        Name = "Enabled";                          Value = 0; Type = "DWord" }
               ) }
            @{ Id = "enable"; Label = "啟用廣告與建議 (系統預設)"; LabelEn = "Enable ads & suggestions (system default)"
               Reg = @(
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338393Enabled"; Value = 1; Type = "DWord" }
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338389Enabled"; Value = 1; Type = "DWord" }
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SystemPaneSuggestionsEnabled";     Value = 1; Type = "DWord" }
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SilentInstalledAppsEnabled";       Value = 1; Type = "DWord" }
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "PreInstalledAppsEnabled";          Value = 1; Type = "DWord" }
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement";  Name = "ScoobeSystemSettingEnabled";       Value = 1; Type = "DWord" }
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "RotatingLockScreenOverlayEnabled"; Value = 1; Type = "DWord" }
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-338387Enabled"; Value = 1; Type = "DWord" }
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-353694Enabled"; Value = 1; Type = "DWord" }
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SubscribedContent-353696Enabled"; Value = 1; Type = "DWord" }
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced";      Name = "ShowSyncProviderNotifications";    Value = 1; Type = "DWord" }
                   @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo";        Name = "Enabled";                          Value = 1; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "HKCU\...\ContentDeliveryManager\* + Explorer\Advanced\ShowSyncProviderNotifications + AdvertisingInfo\Enabled + UserProfileEngagement\ScoobeSystemSettingEnabled (0=關、1=開)"
        VerifiedDate = "2026-07-05"
        Notes        = "這些是純廣告/推銷性質,關閉幾乎純賺:不再有設定 App 建議、開始選單推銷 App、自動靜默安裝推薦 App、使用提示騷擾、完成設定裝置提示、鎖定畫面的提示廣告、檔案總管頂端的 OneDrive/365 推廣橫幅,並關閉個人化廣告追蹤 ID。唯一代價是新手看不到功能提示。一次關閉所有主要廣告面向,徹底清爽。建議停用。注意:鎖定畫面的 Spotlight 桌布本身不受影響 (只關提示文字);若要完全換掉 Spotlight 桌布請到個人化設定調整。"
        NotesEn        = "These are purely advertising/promotional; disabling is almost all upside: no more Settings app suggestions, Start menu promoted apps, silently auto-installed recommended apps, tip nagging, finish-setting-up-device prompts, lock screen tip ads, or File Explorer OneDrive/365 promo banners, plus it turns off the personalized ad tracking ID. The only cost is that beginners won't see feature tips. Disables all major advertising surfaces at once for a thoroughly clean experience. Recommended to disable. Note: the lock screen Spotlight wallpaper itself is unaffected (only tip text is disabled); to fully replace the Spotlight wallpaper, adjust it in Personalization settings."
    }
    )
}
