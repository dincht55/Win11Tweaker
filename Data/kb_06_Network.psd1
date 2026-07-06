<#
    Windows 11 設定精靈 - 知識庫:第 07 類 網路設定 (Network)
    ================================================================
    格式:選項式統一模型 (Choices + Recommend),三選項模型。

    ── 收錄標準 (知情取捨) ──
    網路安全設定多屬「取捨」:提升安全/隱私會犧牲部分連線便利。收錄標準是
    「取捨能否被使用者理解與掌控」,而非「無副作用」(任何設定都有代價)。
    故知情取捨型項目一律收錄,並在說明清楚寫出代價、多數建議維持現狀,把
    決定權交還使用者。已收:LLMNR、NCSI、WPAD、NetBIOS。
    (DoH 不收:需另設支援 DoH 的 DNS 伺服器才有意義,非單純開關;
     SMBv1 不收:24H2 預設不存在,設了無意義。)

    Import-PowerShellDataFile 規定檔案最外層須為 Hashtable。
#>

@{
    Items = @(

    # ── LLMNR 本地多播名稱解析 (安全) ──
    @{
        Id           = "llmnr"
        Category     = 6
        NameZh       = "LLMNR 本地多播名稱解析 (安全性)"
        NameEn       = "LLMNR Multicast Name Resolution (Security)"
        DescZh       = "LLMNR 是 DNS 失敗時的後備名稱解析協定,以多播廣播詢問區網內裝置。攻擊者可偽造回應竊取憑證雜湊 (LLMNR poisoning,資安界公認風險)。現代環境都用正常 DNS,關閉後 DNS 仍正常運作。"
        DescEn       = "LLMNR is a fallback name-resolution protocol used when DNS fails, broadcasting multicast queries to LAN devices. Attackers can forge responses to steal credential hashes (LLMNR poisoning, a recognized security risk). Modern environments use normal DNS; disabling it leaves DNS working."
        Choices      = @(
            @{ Id = "disable"; Label = "停用 LLMNR"; LabelEn = "Disable LLMNR"
               Reg = @(@{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"; Name = "EnableMulticast"; Value = 0; Type = "DWord" }) }
            @{ Id = "enable"; Label = "啟用 LLMNR"; LabelEn = "Enable LLMNR"
               Reg = @(@{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"; Name = "EnableMulticast"; Value = 1; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/ + CISA/CIS Benchmark;鍵路徑為 Windows NT\DNSClient\EnableMulticast (0=停用、1=啟用)"
        VerifiedDate = "2026-07-05"
        Notes        = "CISA 與 CIS Benchmark 一致建議停用;LLMNR poisoning (Responder 工具) 是紅隊最常用的憑證竊取手法之一。Windows 11 24H2 起系統已預設停用,本項明確寫入政策鍵確保維持停用 (防止被其他軟體改回)。代價極小:僅在 DNS 失敗時失去多播後備解析,現代環境都有正常 DNS,幾乎不受影響。注意鍵路徑是 Windows NT\DNSClient (非 Windows\DNSClient)。政策需重開機完全生效。"
        NotesEn        = "CISA and the CIS Benchmark both recommend disabling; LLMNR poisoning (the Responder tool) is one of the most common red-team credential-theft techniques. Windows 11 24H2 disables it by default; this item explicitly writes the policy key to keep it disabled (preventing other software from reverting it). The cost is minimal: only losing multicast fallback resolution when DNS fails, which barely matters in modern environments with working DNS. Note the key path is Windows NT\DNSClient (not Windows\DNSClient). The policy needs a reboot to fully take effect."
    },

    # ── NCSI 網路連線狀態探測 (知情取捨) ──
    @{
        Id           = "ncsi"
        Category     = 6
        NameZh       = "NCSI 網路連線探測 (隱私,需理解)"
        NameEn       = "NCSI Connectivity Probe (Privacy, understand first)"
        DescZh       = "Windows 定期連 www.msftconnecttest.com 判斷是否有網路 (工作列網路圖示、captive portal 偵測都靠它)。停用可減少對微軟伺服器的連線 (隱私),但會影響連線狀態判斷。"
        DescEn       = "Windows periodically connects to www.msftconnecttest.com to check connectivity (the taskbar network icon and captive portal detection rely on it). Disabling reduces connections to Microsoft servers (privacy) but affects connectivity detection."
        Choices      = @(
            @{ Id = "disable"; Label = "停用主動探測 (減少連微軟,但影響 Wi-Fi 登入偵測)"; LabelEn = "Disable active probing (fewer Microsoft connections, but affects Wi-Fi login detection)"
               Reg = @(@{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkConnectivityStatusIndicator"; Name = "NoActiveProbe"; Value = 1; Type = "DWord" }) }
            @{ Id = "enable"; Label = "啟用主動探測 (系統預設)"; LabelEn = "Enable active probing (system default)"
               Reg = @(@{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\NetworkConnectivityStatusIndicator"; Name = "NoActiveProbe"; Value = 0; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/ (NoActiveProbe);HKLM\...\NetworkConnectivityStatusIndicator\NoActiveProbe (1=停用探測、0=啟用)"
        VerifiedDate = "2026-07-05"
        Notes        = "強烈建議維持現狀,務必理解代價後再決定:停用後,連公共 Wi-Fi (飯店/機場/咖啡廳) 時的『登入頁面』(captive portal) 可能不會自動跳出,導致上不了網;工作列網路圖示也可能誤判有無網路;還可能影響 Windows Update、Outlook 的連線判斷。這些問題常在設定數週後、換到別的網路環境才發作,屆時難聯想到是此設定。除非你明確知道自己不需要 captive portal 偵測 (如固定桌機、只用家用/公司網路),否則請勿停用。停用需重開機生效。"
        NotesEn        = "Strongly recommend Keep current; understand the cost before deciding: once disabled, the login page (captive portal) on public Wi-Fi (hotels/airports/cafes) may not pop up automatically, leaving you unable to get online; the taskbar network icon may misjudge connectivity; and it may affect Windows Update and Outlook connectivity checks. These issues often surface weeks later in a different network, when it's hard to connect them to this setting. Unless you clearly don't need captive portal detection (e.g., a fixed desktop on home/office networks only), do not disable. Requires a reboot."
    },

    # ── WPAD 自動探索代理 (知情取捨) ──
    @{
        Id           = "wpad"
        Category     = 6
        NameZh       = "WPAD 自動探索代理 (安全,需理解)"
        NameEn       = "WPAD Proxy Auto-Discovery (Security, understand first)"
        DescZh       = "WPAD 讓系統自動探索網路 proxy 設定。此機制可被 poisoning 攻擊 (偽造 proxy 竊取流量),資安上建議停用。本項用較安全的 DisableWpad 政策鍵 (只擋 WinHTTP 的自動探索,不停用整個服務,故不會導致依賴該服務的 App 無法啟動)。"
        DescEn       = "WPAD lets the system auto-discover network proxy settings. This mechanism can be poisoned (forging a proxy to steal traffic), so disabling is recommended for security. This item uses the safer DisableWpad policy key (blocks only WinHTTP auto-discovery without disabling the whole service, so apps relying on that service still start)."
        Choices      = @(
            @{ Id = "disable"; Label = "停用自動探索 (防 WPAD poisoning)"; LabelEn = "Disable auto-discovery (prevent WPAD poisoning)"
               Reg = @(@{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp"; Name = "DisableWpad"; Value = 1; Type = "DWord" }) }
            @{ Id = "enable"; Label = "啟用自動探索 (系統預設)"; LabelEn = "Enable auto-discovery (system default)"
               Reg = @(@{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp"; Name = "DisableWpad"; Value = 0; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/ (DisableWpad);HKLM\...\Internet Settings\WinHttp\DisableWpad (1=停用、0=啟用)"
        VerifiedDate = "2026-07-05"
        Notes        = "建議維持現狀,理解代價後再決定:停用後,若你的網路環境 (多為企業/學校) 依賴 WPAD 自動探索 proxy,將連不到 proxy,需手動設定 proxy 才能上網;某些依賴 Kerberos over proxy 的情境 (如企業 RDP) 也可能受影響。家用一般網路多不使用 WPAD,影響小。本項用較溫和的 DisableWpad 政策鍵,不停用 WinHttpAutoProxySvc 服務,故不會像『停用整個服務』那樣造成部分 App (如某些 VPN 工具) 無法啟動。停用需重開機生效。"
        NotesEn        = "Recommend Keep current; understand the cost before deciding: once disabled, if your network (often enterprise/school) relies on WPAD to auto-discover a proxy, you won't reach it and must set the proxy manually to get online; some Kerberos-over-proxy scenarios (e.g., enterprise RDP) may also be affected. Home networks rarely use WPAD, so impact is small. This item uses the gentler DisableWpad policy key rather than stopping the WinHttpAutoProxySvc service, so it won't prevent apps (like some VPN tools) from starting the way disabling the whole service would. Requires a reboot."
    },

    # ── NetBIOS over TCP/IP (Special:逐介面) ──
    @{
        Id           = "netbios"
        Category     = 6
        NameZh       = "NetBIOS over TCP/IP (安全,需理解)"
        NameEn       = "NetBIOS over TCP/IP (Security, understand first)"
        DescZh       = "NetBIOS 是舊的名稱解析協定,其 NBT-NS 可被 poisoning 攻擊竊取憑證 (與 LLMNR 同類風險)。停用可消除此攻擊面。"
        DescEn       = "NetBIOS is a legacy name-resolution protocol whose NBT-NS can be poisoned to steal credentials (same class of risk as LLMNR). Disabling removes this attack surface."
        Choices      = @(
            @{ Id = "disable"; Label = "停用 NetBIOS (所有介面,防 NBT-NS poisoning)"; LabelEn = "Disable NetBIOS (all interfaces, prevent NBT-NS poisoning)"
               Special = "netbios_disable" }
            @{ Id = "default"; Label = "還原預設 (所有介面,依 DHCP 設定)"; LabelEn = "Restore default (all interfaces, per DHCP)"
               Special = "netbios_default" }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/ + CIS;HKLM\SYSTEM\...\NetBT\Parameters\Interfaces\Tcpip_{GUID}\NetbiosOptions (2=停用、0=預設)"
        VerifiedDate = "2026-07-05"
        Notes        = "建議維持現狀,理解代價後再決定:停用後,依賴 NetBIOS 名稱解析的舊裝置或舊區網芳鄰 (如很舊的 NAS、印表機、Windows 舊版檔案分享) 可能找不到;現代環境幾乎都用 DNS,家用一般用不到 NetBIOS,停用多無感且更安全。此設定是每個網路介面各自設定的,本項會自動列舉所有網路介面逐一套用 (停用=NetbiosOptions 2、還原=0)。目前狀態需所有介面皆為該值才判定成立。停用需重開機生效。"
        NotesEn        = "Recommend Keep current; understand the cost before deciding: once disabled, old devices or legacy network neighbors relying on NetBIOS name resolution (very old NAS, printers, legacy Windows file sharing) may become undiscoverable; modern environments use DNS, and home networks rarely need NetBIOS, so disabling is usually unnoticeable and safer. This setting is per network interface; this item automatically enumerates all interfaces and applies to each (disable=NetbiosOptions 2, restore=0). The current state is recognized only when all interfaces have that value. Requires a reboot."
    }
    )
}
