<#
    Windows 11 設定精靈 - 知識庫:第 12 類 不必要服務 (Services)
    ================================================================
    本類與設定型類別不同 (同 14 預裝軟體的動態掃描架構):
    模組執行時 Get-CimInstance Win32_Service 掃出實機所有服務,依三層處理:
      1. Essential (必要服務黑名單):停用會弄壞系統的核心服務,直接不顯示。
      2. KnownServices (對照表):已知非必要服務,顯示中文名 + 建議 + 說明。
      3. 其餘掃到但未收錄者:顯示服務顯示名 + 系統描述,預設維持,自行判斷。

    收錄原則 (使用者自主):排除的只有「必要服務」(黑名單),其餘所有非必要
    服務都列出,附說明讓使用者自行判斷。難判斷不是排除理由,而是需要說明的理由。

    每個服務四選項:停用(4) / 手動(3) / 自動(2) / 維持。多數建議「手動」
    (需要時仍能被觸發啟動,比停用安全)。

    比對用服務名 (Name,不分大小寫,精確比對)。
    Import-PowerShellDataFile 規定檔案最外層須為 Hashtable。
#>

@{
    # ═══════════════════════════════════════════════════════════
    #  第 1 層:必要服務黑名單 (停用會弄壞系統,掃到即隱藏,不給選)
    #  比對:服務 Name 精確符合 (不分大小寫) 即視為必要服務。
    # ═══════════════════════════════════════════════════════════
    Essential = @(
        # 核心 RPC / COM / 隨插即用 (停了系統無法運作)
        "RpcSs", "RpcEptMapper", "DcomLaunch", "PlugPlay", "Power",
        "BrokerInfrastructure", "SystemEventsBroker", "CoreMessagingRegistrar",
        "LSM", "DispBrokerDesktopSvc",
        # 使用者登入 / 設定檔 / 認證
        "ProfSvc", "Winlogon", "SamSs", "gpsvc", "UserManager",
        "SENS", "Schedule", "SystemEventsBroker",
        # 網路核心 (停了斷網)
        "NlaSvc", "netprofm", "Dhcp", "Dnscache", "nsi", "BFE",
        "NetSetupSvc", "Netman", "WinHttpAutoProxySvc",
        # 安全核心 (Defender / 防火牆 / 加密)
        "WinDefend", "mpssvc", "SecurityHealthService", "wscsvc",
        "KeyIso", "CryptSvc", "EventLog", "EventSystem",
        # Windows Update 相關核心 (停了無法更新)
        "wuauserv", "TrustedInstaller", "msiserver", "DcomLaunch",
        # 顯示 / 音效 / 輸入 (停了基本功能失效)
        "Themes", "AudioSrv", "AudioEndpointBuilder", "Audiosrv",
        "UsoSvc", "StorSvc", "ShellHWDetection",
        # 使用者體驗核心
        "CDPUserSvc", "WpnService", "TimeBrokerSvc", "SystemEventsBroker"
    )

    # ═══════════════════════════════════════════════════════════
    #  第 2 層:已知非必要服務對照表 (掃到才顯示,附中文名/建議/說明)
    #  Match     = 服務 Name (精確比對,不分大小寫)
    #  NameZh    = 中文名稱
    #  Recommend = "disable"(停用) / "manual"(手動) / "auto"(自動) / "keep"(維持)
    #  Note      = 用途 + 停用代價說明
    # ═══════════════════════════════════════════════════════════
    KnownServices = @(
        # ── 舊時代功能 (現代幾乎無人用) ──
        @{ Match = "Fax";                NameZh = "傳真服務"; NameEn = "Fax Service";                    Recommend = "manual";  Note = "傳真收發,Windows 2000 時代功能,現代幾乎無人使用。無傳真需求可設手動或停用。"; NoteEn = "Fax send/receive, a Windows 2000-era feature virtually unused today. Set to Manual or Disabled if no fax needs." }
        @{ Match = "TapiSrv";            NameZh = "電話語音 (TAPI)"; NameEn = "Telephony (TAPI)";             Recommend = "manual";  Note = "電話語音應用程式介面,舊功能。少數傳統語音軟體會用,一般設手動。"; NoteEn = "Telephony API, a legacy feature. A few old voice apps use it; generally set to Manual." }
        @{ Match = "SharedAccess";       NameZh = "網際網路連線共用 (ICS)"; NameEn = "Internet Connection Sharing (ICS)";      Recommend = "manual";  Note = "把本機網路分享給其他裝置。沒在做網路共用/熱點可設手動。"; NoteEn = "Shares this PC's network with other devices. Set to Manual if not doing network sharing/hotspot." }
        @{ Match = "WMPNetworkSvc";      NameZh = "WMP 網路共用"; NameEn = "WMP Network Sharing";                Recommend = "manual";  Note = "Windows Media Player 媒體庫網路共用。不用 WMP 分享媒體可設手動或停用。"; NoteEn = "Windows Media Player library network sharing. Set to Manual or Disabled if not sharing media via WMP." }

        # ── 遠端存取 (家用有安全風險) ──
        @{ Match = "RemoteRegistry";     NameZh = "遠端登錄 (Remote Registry)"; NameEn = "Remote Registry";  Recommend = "disable"; Note = "允許遠端修改本機登錄檔,是明確的安全風險,家用電腦不需要。建議停用 (預設多已停用)。"; NoteEn = "Allows remote editing of this PC's registry, a clear security risk unneeded on home PCs. Recommend Disabled (often already disabled)." }
        @{ Match = "RemoteAccess";       NameZh = "路由與遠端存取"; NameEn = "Routing and Remote Access";              Recommend = "disable"; Note = "提供撥號/VPN 路由伺服器功能,家用不需要。建議停用。"; NoteEn = "Provides dial-up/VPN routing server functions, unneeded at home. Recommend Disabled." }
        @{ Match = "SessionEnv";         NameZh = "遠端桌面設定"; NameEn = "Remote Desktop Configuration";                Recommend = "manual";  Note = "遠端桌面連線 (RDP) 相關。你若會被遠端連入才需要,否則可設手動。"; NoteEn = "Related to Remote Desktop (RDP). Needed only if others connect into you; otherwise set to Manual." }
        @{ Match = "TermService";        NameZh = "遠端桌面服務"; NameEn = "Remote Desktop Services";                Recommend = "manual";  Note = "允許他人遠端桌面連入本機。不用被遠端連入可設手動 (你主動連別人不受影響)。"; NoteEn = "Allows others to Remote Desktop into this PC. Set to Manual if you don't need inbound (connecting out to others is unaffected)." }
        @{ Match = "UmRdpService";       NameZh = "遠端桌面 UM 連接埠重新導向"; NameEn = "Remote Desktop UM Port Redirector";  Recommend = "manual";  Note = "遠端桌面的裝置重導向 (印表機/剪貼簿)。不被遠端連入可設手動。"; NoteEn = "Remote Desktop device redirection (printers/clipboard). Set to Manual if not connected into remotely." }

        # ── 隱私 / 遙測 ──
        @{ Match = "DiagTrack";          NameZh = "連線使用者體驗與遙測"; NameEn = "Connected User Experiences and Telemetry";        Recommend = "manual";  Note = "收集診斷與使用資料回傳微軟。重視隱私可設手動或停用 (功能面影響小,但某些回饋/建議會失效)。"; NoteEn = "Collects diagnostic and usage data for Microsoft. Set to Manual or Disabled for privacy (minor functional impact, but some feedback/suggestions stop working)." }
        @{ Match = "dmwappushservice";   NameZh = "裝置管理無線推播訊息"; NameEn = "Device Management Wireless Push";        Recommend = "manual";  Note = "與遙測/裝置管理相關的推播。一般家用可設手動。"; NoteEn = "Push messaging related to telemetry/device management. Home users can set to Manual." }
        @{ Match = "diagnosticshub.standardcollector.service"; NameZh = "診斷中樞標準收集器"; NameEn = "Diagnostic Hub Standard Collector"; Recommend = "manual"; Note = "開發診斷資料收集,一般使用者用不到,可設手動。"; NoteEn = "Developer diagnostic data collection, unneeded by average users. Can set to Manual." }
        @{ Match = "WerSvc";             NameZh = "Windows 錯誤報告"; NameEn = "Windows Error Reporting";            Recommend = "manual";  Note = "當機時收集錯誤報告回傳微軟。設手動不影響系統運作 (只是不主動回報)。"; NoteEn = "Collects error reports for Microsoft on crashes. Setting to Manual doesn't affect operation (just no proactive reporting)." }

        # ── 定位 / 感應器 ──
        @{ Match = "lfsvc";              NameZh = "地理位置服務"; NameEn = "Geolocation Service";                Recommend = "manual";  Note = "提供定位功能給需要的 App (地圖/天氣)。桌機少用定位可設手動 (需要的 App 會自動啟動它)。"; NoteEn = "Provides location to apps that need it (Maps/Weather). Desktops rarely using location can set to Manual (apps that need it will start it)." }
        @{ Match = "MapsBroker";         NameZh = "下載的地圖管理員"; NameEn = "Downloaded Maps Manager";            Recommend = "manual";  Note = "離線地圖下載管理。地圖 App 已淘汰,一般可設手動。"; NoteEn = "Offline map download management. The Maps app is deprecated; generally set to Manual." }
        @{ Match = "SensorService";      NameZh = "感應器服務"; NameEn = "Sensor Service";                  Recommend = "manual";  Note = "管理光線/方向等感應器。桌機通常無這些感應器,可設手動。"; NoteEn = "Manages light/orientation sensors. Desktops usually lack these; can set to Manual." }
        @{ Match = "SensrSvc";           NameZh = "感應器監視服務"; NameEn = "Sensor Monitoring Service";              Recommend = "manual";  Note = "監視感應器資料。桌機無感應器可設手動。"; NoteEn = "Monitors sensor data. Desktops without sensors can set to Manual." }

        # ── 觸控 / 平板 (桌機用不到) ──
        @{ Match = "TabletInputService"; NameZh = "觸控鍵盤與手寫面板"; NameEn = "Touch Keyboard and Handwriting Panel";          Recommend = "manual";  Note = "觸控螢幕鍵盤與手寫輸入。純桌機 (無觸控/手寫筆) 可設手動。"; NoteEn = "Touch keyboard and handwriting input. Pure desktops (no touch/stylus) can set to Manual." }

        # ── Xbox (不玩遊戲用不到,通常一起處理) ──
        @{ Match = "XblAuthManager";     NameZh = "Xbox Live 驗證管理員"; NameEn = "Xbox Live Auth Manager";        Recommend = "manual";  Note = "Xbox 帳號驗證。不玩需 Xbox 登入的遊戲可設手動。"; NoteEn = "Xbox account authentication. Set to Manual if you don't play games needing Xbox sign-in." }
        @{ Match = "XblGameSave";        NameZh = "Xbox Live 遊戲存檔"; NameEn = "Xbox Live Game Save";          Recommend = "manual";  Note = "Xbox 遊戲雲端存檔。不玩 Xbox 遊戲可設手動。"; NoteEn = "Xbox cloud game saves. Set to Manual if you don't play Xbox games." }
        @{ Match = "XboxNetApiSvc";      NameZh = "Xbox Live 網路服務"; NameEn = "Xbox Live Networking";          Recommend = "manual";  Note = "Xbox 網路連線。不玩 Xbox 遊戲可設手動。"; NoteEn = "Xbox network connectivity. Set to Manual if you don't play Xbox games." }
        @{ Match = "XboxGipSvc";         NameZh = "Xbox 週邊裝置管理"; NameEn = "Xbox Accessory Management";           Recommend = "manual";  Note = "Xbox 手把等週邊管理。不用 Xbox 週邊可設手動。"; NoteEn = "Xbox controller and peripheral management. Set to Manual if you don't use Xbox peripherals." }

        # ── 效能相關 (有爭議,交由使用者) ──
        @{ Match = "SysMain";            NameZh = "SysMain (Superfetch 預抓取)"; NameEn = "SysMain (Superfetch prefetch)"; Recommend = "keep";    Note = "分析使用習慣預先載入常用程式到記憶體。SSD 上效益降低且有爭議 (有人覺得造成磁碟活動)。也負責記憶體壓縮。SSD+大記憶體可考慮停用實驗,但建議先維持觀察。"; NoteEn = "Analyzes usage to preload frequent programs into memory. Less beneficial on SSDs and debated (some feel it causes disk activity). Also handles memory compression. SSD + large RAM users may experiment with disabling, but observe first." }
        @{ Match = "WSearch";            NameZh = "Windows Search 搜尋索引"; NameEn = "Windows Search Indexing";     Recommend = "keep";    Note = "建立檔案索引加速搜尋。停用後開始選單/檔案總管搜尋會變慢或不完整。常搜尋檔案者建議維持;很少用搜尋可停用省背景磁碟活動。"; NoteEn = "Builds a file index to speed up search. Disabling makes Start menu/Explorer search slower or incomplete. Keep if you search files often; disable to save background disk activity if rarely searching." }

        # ── 裝置 / 連線 (因人而異) ──
        @{ Match = "bthserv";            NameZh = "藍牙支援服務"; NameEn = "Bluetooth Support Service";                Recommend = "keep";    Note = "藍牙裝置支援。有用藍牙 (滑鼠/鍵盤/耳機) 必須維持;完全不用藍牙可設手動。"; NoteEn = "Bluetooth device support. Must keep if you use Bluetooth (mouse/keyboard/headphones); set to Manual if never using Bluetooth." }
        @{ Match = "BthAvctpSvc";        NameZh = "藍牙音訊/控制 (AVCTP)"; NameEn = "Bluetooth Audio/Control (AVCTP)";       Recommend = "keep";    Note = "藍牙音訊與遙控。用藍牙耳機/喇叭需維持;不用藍牙可設手動。"; NoteEn = "Bluetooth audio and remote control. Keep for Bluetooth headphones/speakers; set to Manual if not using Bluetooth." }
        @{ Match = "WbioSrvc";           NameZh = "生物辨識服務"; NameEn = "Biometric Service";                Recommend = "keep";    Note = "指紋/臉部辨識登入 (Windows Hello)。有用生物辨識登入必須維持;完全不用可設手動。"; NoteEn = "Fingerprint/face sign-in (Windows Hello). Must keep if using biometric sign-in; set to Manual if never using it." }
        @{ Match = "PhoneSvc";           NameZh = "電話服務"; NameEn = "Phone Service";                    Recommend = "manual";  Note = "管理手機連線相關功能。用不到可設手動。"; NoteEn = "Manages phone connection features. Set to Manual if unused." }
        @{ Match = "PrintNotify";        NameZh = "印表機擴充與通知"; NameEn = "Printer Extensions and Notifications";            Recommend = "manual";  Note = "印表機通知與擴充功能。無印表機可設手動 (基本列印不受影響)。"; NoteEn = "Printer notifications and extensions. Set to Manual if no printer (basic printing unaffected)." }
        @{ Match = "Spooler";            NameZh = "列印多工緩衝處理器 (Print Spooler)"; NameEn = "Print Spooler"; Recommend = "keep"; Note = "列印核心服務。有印表機必須維持;完全不列印可停用 (曾有 PrintNightmare 資安漏洞,不列印者停用可降風險)。"; NoteEn = "Core print service. Must keep with a printer; can disable if never printing (the PrintNightmare vulnerability makes disabling lower risk for non-printers)." }

        # ── 其他非必要 ──
        @{ Match = "RetailDemo";         NameZh = "零售展示服務"; NameEn = "Retail Demo Service";                Recommend = "disable"; Note = "賣場展示機模式用,一般使用者完全用不到。建議停用。"; NoteEn = "For retail demo machines, completely unused by average users. Recommend Disabled." }
        @{ Match = "wisvc";              NameZh = "Windows 測試人員服務"; NameEn = "Windows Insider Service";        Recommend = "manual";  Note = "Windows Insider 預覽版功能。非測試人員可設手動。"; NoteEn = "Windows Insider preview features. Non-testers can set to Manual." }
        @{ Match = "AJRouter";           NameZh = "AllJoyn 路由器"; NameEn = "AllJoyn Router";              Recommend = "manual";  Note = "IoT 裝置通訊協定,一般家用少用,可設手動。"; NoteEn = "IoT device protocol, rarely used at home. Can set to Manual." }
        @{ Match = "PcaSvc";             NameZh = "程式相容性小幫手"; NameEn = "Program Compatibility Assistant";            Recommend = "manual";  Note = "偵測舊程式相容性問題。可設手動 (需要時啟動)。"; NoteEn = "Detects legacy program compatibility issues. Can set to Manual (starts when needed)." }

        # ── 網路傳輸 / 更新分享 (家用單機多可設手動) ──
        @{ Match = "DoSvc";              NameZh = "傳遞最佳化 (更新 P2P 分享)"; NameEn = "Delivery Optimization (update P2P)";  Recommend = "manual";  Note = "Windows Update 的 P2P 下載分享,會用你的頻寬分享更新給其他裝置/電腦。單機家用可設手動 (更新仍能正常下載,只是不做 P2P 分享)。"; NoteEn = "Windows Update P2P download sharing, using your bandwidth to share updates with other devices/PCs. Single home PCs can set to Manual (updates still download normally, just no P2P sharing)." }
        @{ Match = "BITS";               NameZh = "背景智慧傳輸 (BITS)"; NameEn = "Background Intelligent Transfer (BITS)";         Recommend = "keep";    Note = "用閒置頻寬在背景傳輸檔案,Windows Update 與很多 App 依賴它。建議維持 (停用會導致更新/下載類功能異常)。"; NoteEn = "Transfers files in the background using idle bandwidth; Windows Update and many apps depend on it. Recommend keeping (disabling breaks update/download features)." }

        # ── 裝置探索 / UPnP / 無線直連 (無相關裝置可設手動) ──
        @{ Match = "SSDPSRV";            NameZh = "SSDP 探索"; NameEn = "SSDP Discovery";                   Recommend = "manual";  Note = "探索使用 SSDP 協定的網路裝置 (UPnP 裝置)。沒在用 DLNA/UPnP 裝置可設手動。"; NoteEn = "Discovers network devices using SSDP (UPnP devices). Set to Manual if not using DLNA/UPnP devices." }
        @{ Match = "upnphost";           NameZh = "UPnP 裝置主機"; NameEn = "UPnP Device Host";               Recommend = "manual";  Note = "讓本機作為 UPnP 裝置被其他裝置探索。無此需求可設手動。"; NoteEn = "Lets this PC be discovered as a UPnP device by others. Set to Manual if not needed." }
        @{ Match = "WFDSConMgrSvc";      NameZh = "Wi-Fi Direct 連線管理"; NameEn = "Wi-Fi Direct Connection Manager";       Recommend = "manual";  Note = "管理 Wi-Fi Direct/無線顯示器 (Miracast) 連線。不用無線投影可設手動 (需要時會自動啟動)。"; NoteEn = "Manages Wi-Fi Direct/wireless display (Miracast) connections. Set to Manual if not using wireless projection (starts when needed)." }
        @{ Match = "wcncsvc";            NameZh = "Windows Connect Now"; NameEn = "Windows Connect Now";         Recommend = "manual";  Note = "無線裝置快速設定 (WPS)。少用,可設手動。"; NoteEn = "Wireless device quick setup (WPS). Rarely used; can set to Manual." }
        @{ Match = "icssvc";             NameZh = "Windows 行動熱點"; NameEn = "Windows Mobile Hotspot";            Recommend = "manual";  Note = "把本機網路分享為 Wi-Fi 熱點。桌機或不開熱點可設手動 (需要時開熱點會自動啟動)。"; NoteEn = "Shares this PC's network as a Wi-Fi hotspot. Desktops or non-hotspot users can set to Manual (starts automatically when hosting)." }

        # ── 舊網路功能 / 撥號 / VPN 輔助 (家用多用不到) ──
        @{ Match = "TrkWks";             NameZh = "分散式連結追蹤用戶端"; NameEn = "Distributed Link Tracking Client";        Recommend = "manual";  Note = "追蹤 NTFS 檔案在電腦間移動的連結。家用幾乎用不到,可設手動或停用。"; NoteEn = "Tracks links of NTFS files moved between computers. Rarely needed at home; can set to Manual or Disabled." }
        @{ Match = "RasAuto";            NameZh = "遠端存取自動連線管理員"; NameEn = "Remote Access Auto Connection Manager";      Recommend = "manual";  Note = "程式需要時自動建立撥號/VPN 連線。無撥號/VPN 需求可設手動。"; NoteEn = "Automatically creates dial-up/VPN connections when programs need them. Set to Manual if no dial-up/VPN needs." }
        @{ Match = "RasMan";            NameZh = "遠端存取連線管理員"; NameEn = "Remote Access Connection Manager";          Recommend = "keep";    Note = "管理撥號與 VPN 連線。若你用 Windows 內建 VPN 需維持;完全不用 VPN 可設手動。"; NoteEn = "Manages dial-up and VPN connections. Keep if using the built-in Windows VPN; set to Manual if never using VPN." }
        @{ Match = "SstpSvc";            NameZh = "SSTP VPN 服務"; NameEn = "SSTP VPN Service";               Recommend = "manual";  Note = "SSTP 協定的 VPN 連線支援。不用 SSTP VPN 可設手動。"; NoteEn = "SSTP protocol VPN connection support. Set to Manual if not using SSTP VPN." }
        @{ Match = "SNMPTrap";           NameZh = "SNMP 設陷"; NameEn = "SNMP Trap";                   Recommend = "manual";  Note = "接收 SNMP 網管陷阱訊息,家用完全用不到,可設手動。"; NoteEn = "Receives SNMP trap messages, completely unused at home. Can set to Manual." }

        # ── 備份 / 磁碟 / 儲存 (無相關需求可設手動) ──
        @{ Match = "SDRSVC";             NameZh = "Windows 備份"; NameEn = "Windows Backup";                Recommend = "manual";  Note = "Windows 備份與還原功能。不用內建備份可設手動 (需要時啟動)。"; NoteEn = "Windows Backup and restore. Set to Manual if not using built-in backup (starts when needed)." }
        @{ Match = "wbengine";           NameZh = "區塊層級備份引擎"; NameEn = "Block Level Backup Engine";            Recommend = "manual";  Note = "Windows 備份的區塊備份引擎。不用內建備份可設手動。"; NoteEn = "The block-level backup engine for Windows Backup. Set to Manual if not using built-in backup." }
        @{ Match = "fhsvc";              NameZh = "檔案歷程記錄"; NameEn = "File History";                Recommend = "manual";  Note = "檔案歷程記錄備份。沒設定檔案歷程可設手動。"; NoteEn = "File History backup. Set to Manual if File History isn't configured." }
        @{ Match = "defragsvc";          NameZh = "最佳化磁碟機 (重組)"; NameEn = "Optimize Drives (defrag)";         Recommend = "keep";    Note = "SSD 的 TRIM 與 HDD 重組排程。建議維持 (它會定期最佳化磁碟,對 SSD 也有 TRIM 益處)。"; NoteEn = "SSD TRIM and HDD defrag scheduling. Recommend keeping (it periodically optimizes drives, including beneficial TRIM for SSDs)." }

        # ── 舊功能 / 少用 ──
        @{ Match = "SCardSvr";           NameZh = "智慧卡"; NameEn = "Smart Card";                      Recommend = "manual";  Note = "讀取智慧卡。無智慧卡讀卡機可設手動。"; NoteEn = "Reads smart cards. Set to Manual if no smart card reader." }
        @{ Match = "ScDeviceEnum";       NameZh = "智慧卡裝置列舉"; NameEn = "Smart Card Device Enumeration";              Recommend = "manual";  Note = "列舉智慧卡讀卡機。無智慧卡可設手動。"; NoteEn = "Enumerates smart card readers. Set to Manual if no smart cards." }
        @{ Match = "SEMgrSvc";           NameZh = "付款與 NFC/SE 管理員"; NameEn = "Payments and NFC/SE Manager";        Recommend = "manual";  Note = "NFC 付款與安全元件。桌機通常無 NFC,可設手動。"; NoteEn = "NFC payments and secure element. Desktops usually lack NFC; can set to Manual." }
        @{ Match = "WalletService";      NameZh = "電子錢包服務"; NameEn = "WalletService";                Recommend = "manual";  Note = "行動支付錢包。桌機用不到可設手動。"; NoteEn = "Mobile payment wallet. Unused on desktops; can set to Manual." }
        @{ Match = "MSiSCSI";            NameZh = "iSCSI 啟動器"; NameEn = "iSCSI Initiator";                Recommend = "manual";  Note = "連線 iSCSI 網路儲存。無 iSCSI 儲存可設手動。"; NoteEn = "Connects to iSCSI network storage. Set to Manual if no iSCSI storage." }
        @{ Match = "AppVClient";         NameZh = "App-V 用戶端"; NameEn = "App-V Client";                Recommend = "manual";  Note = "企業應用程式虛擬化,家用用不到,可設手動或停用。"; NoteEn = "Enterprise application virtualization, unused at home. Can set to Manual or Disabled." }
        @{ Match = "UevAgentService";    NameZh = "使用者體驗虛擬化 (UE-V)"; NameEn = "User Experience Virtualization (UE-V)";     Recommend = "manual";  Note = "企業設定漫遊,家用用不到,可設手動或停用。"; NoteEn = "Enterprise settings roaming, unused at home. Can set to Manual or Disabled." }
        @{ Match = "wercplsupport";      NameZh = "問題報告控制台支援"; NameEn = "Problem Reports Control Panel Support";          Recommend = "manual";  Note = "問題報告檢視功能,少用,可設手動。"; NoteEn = "Problem report viewing feature, rarely used. Can set to Manual." }
    )
}
