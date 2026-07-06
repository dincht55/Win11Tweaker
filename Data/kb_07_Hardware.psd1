<#
    Windows 11 設定精靈 - 知識庫:第 08 類 硬體與電源 (Hardware & Power)
    ================================================================
    格式:選項式統一模型 (Choices + Recommend),三選項模型。

    涵蓋電源 (電源計畫、快速啟動) 與裝置 (裝置中繼資料下載)。
    電源計畫用具名特殊動作 (Special),因其透過 powercfg 命令切換,非登錄檔。

    Import-PowerShellDataFile 規定檔案最外層須為 Hashtable。
#>

@{
    Items = @(

    # ── 電源計畫 (Special:powercfg /setactive) ──
    @{
        Id           = "power_plan"
        Category     = 7
        NameZh       = "電源計畫 (效能/續航)"
        NameEn       = "Power Plan (Performance/Battery)"
        DescZh       = "切換系統電源計畫,影響 CPU 效能與耗電。桌機/工作站可選高效能;筆電重續航可選省電或平衡。此設定透過 powercfg 切換,並以目前使用中的計畫判定狀態。"
        DescEn       = "Switches the system power plan, affecting CPU performance and power draw. Desktops/workstations can pick High performance; laptops prioritizing battery can pick Power saver or Balanced. This uses powercfg to switch, and detects state from the currently active plan."
        Choices      = @(
            @{ Id = "high";     Label = "高效能 (效能優先,適合桌機/插電工作站)"; LabelEn = "High performance (performance priority, good for desktops/plugged-in workstations)";  Special = "powerplan_high" }
            @{ Id = "balanced"; Label = "平衡 (系統預設,效能與續航兼顧)"; LabelEn = "Balanced (system default, performance and battery)";          Special = "powerplan_balanced" }
            @{ Id = "saver";    Label = "省電 (續航優先,適合筆電用電池時)"; LabelEn = "Power saver (battery priority, good for laptops on battery)";         Special = "powerplan_saver" }
            @{ Id = "keep";     Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "powercfg /setactive;標準 GUID 高效能 8c5e7fda.../平衡 381b4222.../省電 a1841308..."
        VerifiedDate = "2026-07-05"
        Notes        = "建議依裝置類型自選,故預設維持現狀:效能優先 (桌機、長期插電) 選『高效能』;續航優先 (筆電用電池) 選『省電』或『平衡』。注意:Win11 另有『設定 > 電源與電池 > 電源模式』滑桿,與傳統電源計畫是兩套系統,設了自訂計畫後該滑桿可能被鎖住。若系統無對應計畫 (GUID 未安裝) 會顯示不適用並跳過。目前狀態依 powercfg 使用中的計畫判定。"
        NotesEn        = "Recommended to choose by device type, so default is Keep current: performance priority (desktops, always plugged in) pick 'High performance'; battery priority (laptops on battery) pick 'Power saver' or 'Balanced'. Note: Win11 also has a 'Settings > Power & battery > Power mode' slider, a separate system from classic power plans; setting a custom plan may lock that slider. If the system lacks the matching plan (GUID not installed), it shows not applicable and skips. Current state is judged from the active plan via powercfg."
    },

    # ── 快速啟動 (Fast Startup) ──
    @{
        Id           = "fast_startup"
        Category     = 7
        NameZh       = "快速啟動 (Fast Startup)"
        NameEn       = "Fast Startup"
        DescZh       = "混合式關機:關機時保存核心狀態以加快下次開機。SSD 上只快 2-5 秒 (可忽略),卻常造成 USB/藍牙/網卡未正確重新初始化、雙系統衝突、更新未完整套用。停用後為真正冷開機。"
        DescEn       = "Hybrid shutdown: saves the kernel state at shutdown to speed up the next boot. On SSDs it only saves 2-5 seconds (negligible) but often causes USB/Bluetooth/NIC to not reinitialize properly, dual-boot conflicts, and incompletely applied updates. Disabling gives a true cold boot."
        Choices      = @(
            @{ Id = "disable"; Label = "停用快速啟動 (每次冷開機,硬體可靠初始化)"; LabelEn = "Disable Fast Startup (cold boot every time, reliable hardware init)"
               Reg = @(@{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"; Name = "HiberbootEnabled"; Value = 0; Type = "DWord" }) }
            @{ Id = "enable"; Label = "啟用快速啟動"; LabelEn = "Enable Fast Startup"
               Reg = @(@{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"; Name = "HiberbootEnabled"; Value = 1; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "HKLM\...\Session Manager\Power\HiberbootEnabled (0=停用、1=啟用)"
        VerifiedDate = "2026-07-05"
        Notes        = "此鍵只控制快速啟動,不影響休眠 (比 powercfg /h off 乾淨,休眠仍可用)。SSD 時代好處 (硬體可靠初始化、雙系統正常、更新完整、真正冷開機) 大於代價 (SSD 慢 2-5 秒);HDD 系統停用後開機會明顯變慢 (30-60 秒),HDD 使用者可斟酌維持。需重開機生效。"
        NotesEn        = "This key controls only Fast Startup, not hibernation (cleaner than powercfg /h off; hibernation still works). In the SSD era the benefits (reliable hardware init, proper dual-boot, complete updates, true cold boot) outweigh the cost (2-5 seconds slower on SSD); on HDD systems boot becomes noticeably slower after disabling (30-60 seconds), so HDD users may keep it. Requires a reboot."
    },

    # ── 裝置中繼資料下載 (擋 OEM App/圖示) ──
    @{
        Id           = "device_metadata"
        Category     = 7
        NameZh       = "裝置中繼資料自動下載 (OEM App/圖示)"
        NameEn       = "Device Metadata Auto-Download (OEM Apps/Icons)"
        DescZh       = "接上裝置時,Windows 自動從網路下載製造商 App 與自訂圖示。停用只擋這些裝飾性內容,不影響驅動 (驅動仍正常透過 Windows Update 取得),可避免自動裝上 OEM 廢 App。"
        DescEn       = "When you connect a device, Windows auto-downloads the manufacturer's app and custom icons from the internet. Disabling blocks only this decorative content without affecting drivers (still obtained normally via Windows Update), avoiding auto-installed OEM bloatware."
        Choices      = @(
            @{ Id = "disable"; Label = "停用中繼資料下載 (不自動裝 OEM App/圖示)"; LabelEn = "Disable metadata download (no auto OEM apps/icons)"
               Reg = @(@{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata"; Name = "PreventDeviceMetadataFromNetwork"; Value = 1; Type = "DWord" }) }
            @{ Id = "enable"; Label = "啟用中繼資料下載"; LabelEn = "Enable metadata download"
               Reg = @(@{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata"; Name = "PreventDeviceMetadataFromNetwork"; Value = 0; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/ (Device Installation > PreventDeviceMetadataFromNetwork);HKLM\SOFTWARE\Policies\Microsoft\Windows\Device Metadata (1=停用、0=啟用)"
        VerifiedDate = "2026-07-05"
        Notes        = "官方政策鍵。停用只擋裝飾性中繼資料 (製造商 App、自訂圖示),驅動不受影響仍正常下載。附帶好處:可消除部分系統的 DeviceSetupManager 中繼資料抓取錯誤日誌。若你重視印表機等裝置的廠商自訂圖示,可維持啟用。"
        NotesEn        = "An official policy key. Disabling blocks only decorative metadata (manufacturer apps, custom icons); drivers are unaffected and still download normally. Side benefit: eliminates DeviceSetupManager metadata-fetch error logs on some systems. If you value vendor custom icons for devices like printers, keep it enabled."
    }
    )
}
