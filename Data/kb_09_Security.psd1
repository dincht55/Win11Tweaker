<#
    Windows 11 設定精靈 - 知識庫:第 10 類 安全性 (Security)
    ================================================================
    格式:選項式統一模型 (Choices + Recommend),多狀態模型。

    安全類特性:多數防護該保持預設,故本類項目經嚴格篩選只收「使用者應知情
    自選」的項目 (HVCI、UAC、SmartScreen),且每項說明都寫清楚安全取捨,
    讓使用者理解後正確設定。已排除:自動登入 (明文存密碼,嚴重風險)、
    喚醒需密碼 (預設已安全、機制多套易衝突)。

    UAC 為多鍵項:每個等級同時寫 ConsentPromptBehaviorAdmin (行為) +
    PromptOnSecureDesktop (是否鎖定桌面) + EnableLUA=1 (確保 UAC 開啟)。

    Import-PowerShellDataFile 規定檔案最外層須為 Hashtable。
#>

@{
    Items = @(

    # ── HVCI 記憶體完整性 (核心隔離) ──
    @{
        Id           = "hvci"
        Category     = 9
        NameZh       = "記憶體完整性 HVCI (核心隔離)"
        NameEn       = "Memory Integrity HVCI (Core Isolation)"
        DescZh       = "核心隔離的記憶體完整性:用硬體虛擬化把核心程式碼放進隔離環境驗證,大幅提高惡意程式/rootkit 攻擊核心的難度。但會阻擋『從記憶體層修改系統』的行為,這正是許多遊戲修改器、記憶體作弊工具、部分反作弊/舊驅動所依賴的。"
        DescEn       = "Core Isolation's Memory Integrity uses hardware virtualization to verify kernel code in an isolated environment, greatly raising the bar for malware/rootkit attacks on the kernel. But it blocks 'modifying the system from the memory layer', which is exactly what many game trainers, memory cheat tools, and some anti-cheat/legacy drivers rely on."
        Choices      = @(
            @{ Id = "enable"; Label = "啟用 (核心防護更強,但擋遊戲修改器/舊驅動)"; LabelEn = "Enable (stronger kernel protection, but blocks game trainers/legacy drivers)"
               Reg = @(@{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"; Name = "Enabled"; Value = 1; Type = "DWord" }) }
            @{ Id = "disable"; Label = "停用 (可跑記憶體修改工具,核心防護降低)"; LabelEn = "Disable (allows memory-modification tools, lower kernel protection)"
               Reg = @(@{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"; Name = "Enabled"; Value = 0; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/ (HypervisorEnforcedCodeIntegrity);HKLM\SYSTEM\...\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity\Enabled (1=開、0=關)"
        VerifiedDate = "2026-07-05"
        Notes        = "重要取捨,請理解後再設:【啟用】核心防護更強,但會擋掉遊戲修改器/記憶體作弊工具/部分舊驅動;極端狀況下若有不相容的舊驅動,啟用後可能開機失敗藍屏 (需進 WinRE 關閉才能開機)。【停用】可正常執行記憶體修改工具、相容舊驅動,但降低對核心層攻擊的防護。24H2 相容硬體多已預設啟用。建議維持現狀,由你依用途 (常玩需修改記憶體的遊戲 vs 重視安全) 自行決定。需重開機生效。"
        NotesEn        = "Important tradeoff, understand before setting: [Enable] stronger kernel protection but blocks game trainers/memory cheat tools/some legacy drivers; in extreme cases with an incompatible legacy driver, enabling may cause boot failure/BSOD (requiring WinRE to disable before booting). [Disable] lets memory-modification tools and legacy drivers work but lowers protection against kernel-layer attacks. On 24H2-compatible hardware it's often enabled by default. Recommend Keep current and decide by your use (frequently playing games needing memory modification vs. prioritizing security). Requires a reboot."
    },

    # ── UAC 使用者帳戶控制 (6 等級多鍵) ──
    @{
        Id           = "uac_level"
        Category     = 9
        NameZh       = "使用者帳戶控制 UAC 等級"
        NameEn       = "User Account Control (UAC) Level"
        DescZh       = "程式要求系統管理員權限時的提示行為。等級越高越安全 (每次都要確認/輸密碼),越低越方便 (少提示甚至不提示)。所有選項都會確保 UAC 本體維持開啟 (EnableLUA=1),僅調整提示行為。"
        DescEn       = "The prompt behavior when programs request administrator privileges. Higher levels are safer (always confirm/enter password), lower levels more convenient (fewer or no prompts). All options keep UAC itself on (EnableLUA=1), adjusting only the prompt behavior."
        Choices      = @(
            @{ Id = "credential_secure"; Label = "最高:每次要求輸入管理員密碼 (安全桌面)"; LabelEn = "Highest: prompt for admin password every time (secure desktop)"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "EnableLUA";                  Value = 1; Type = "DWord" }
                   @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "ConsentPromptBehaviorAdmin"; Value = 1; Type = "DWord" }
                   @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "PromptOnSecureDesktop";       Value = 1; Type = "DWord" }
               ) }
            @{ Id = "consent_secure"; Label = "高:每次要求同意 (安全桌面)"; LabelEn = "High: prompt for consent every time (secure desktop)"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "EnableLUA";                  Value = 1; Type = "DWord" }
                   @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "ConsentPromptBehaviorAdmin"; Value = 2; Type = "DWord" }
                   @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "PromptOnSecureDesktop";       Value = 1; Type = "DWord" }
               ) }
            @{ Id = "default"; Label = "平衡:僅非 Windows 程式要求同意 (系統預設)"; LabelEn = "Balanced: prompt only for non-Windows programs (system default)"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "EnableLUA";                  Value = 1; Type = "DWord" }
                   @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "ConsentPromptBehaviorAdmin"; Value = 5; Type = "DWord" }
                   @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "PromptOnSecureDesktop";       Value = 1; Type = "DWord" }
               ) }
            @{ Id = "credential_nodesktop"; Label = "中:每次要求輸入密碼 (不鎖定桌面)"; LabelEn = "Medium: prompt for password every time (no secure desktop)"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "EnableLUA";                  Value = 1; Type = "DWord" }
                   @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "ConsentPromptBehaviorAdmin"; Value = 3; Type = "DWord" }
                   @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "PromptOnSecureDesktop";       Value = 0; Type = "DWord" }
               ) }
            @{ Id = "consent_nodesktop"; Label = "中:每次要求同意 (不鎖定桌面)"; LabelEn = "Medium: prompt for consent every time (no secure desktop)"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "EnableLUA";                  Value = 1; Type = "DWord" }
                   @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "ConsentPromptBehaviorAdmin"; Value = 4; Type = "DWord" }
                   @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "PromptOnSecureDesktop";       Value = 0; Type = "DWord" }
               ) }
            @{ Id = "no_prompt"; Label = "最低:不提示直接提升權限 (不建議)"; LabelEn = "Lowest: elevate silently without prompting (not recommended)"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "EnableLUA";                  Value = 1; Type = "DWord" }
                   @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "ConsentPromptBehaviorAdmin"; Value = 0; Type = "DWord" }
                   @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "PromptOnSecureDesktop";       Value = 0; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "default"
        MinBuild     = $null
        Source       = "HKLM\...\Policies\System\ConsentPromptBehaviorAdmin (0/1/2/3/4/5) + PromptOnSecureDesktop + EnableLUA;官方 learn 各值定義"
        VerifiedDate = "2026-07-05"
        Notes        = "各等級安全性由高到低:最高(值1,密碼+安全桌面)>高(值2,同意+安全桌面)>平衡(值5,系統預設,只有非 Windows 程式才提示)>中(值3/4,不鎖定桌面)>最低(值0,完全不提示)。『安全桌面』會把畫面變暗只允許提示框輸入,防止其他程式偽造點擊,更安全但稍慢。建議維持系統預設(平衡),它已在安全與便利間取得平衡;調更高更安全但更常跳提示,調更低較方便但降低防護。所有等級都保持 UAC 開啟,不會完全關閉 UAC。需重開機或登出生效。"
        NotesEn        = "Security from high to low: Highest (value 1, password + secure desktop) > High (value 2, consent + secure desktop) > Balanced (value 5, system default, prompts only for non-Windows programs) > Medium (value 3/4, no secure desktop) > Lowest (value 0, no prompt at all). The 'secure desktop' dims the screen and allows input only in the prompt, preventing other programs from faking clicks — safer but slightly slower. Recommend keeping the system default (Balanced), which balances security and convenience; higher is safer but prompts more often, lower is more convenient but reduces protection. All levels keep UAC on and never fully disable it. Requires a reboot or sign-out."
    },

    # ── SmartScreen ──
    @{
        Id           = "smartscreen"
        Category     = 9
        NameZh       = "SmartScreen 信譽防護"
        NameEn       = "SmartScreen Reputation Protection"
        DescZh       = "Microsoft Defender SmartScreen:下載/執行程式時,依信譽資料庫檢查是否為已知惡意或釣魚內容並警告。預設開啟,是純防護功能。少數人基於隱私 (檔案資訊會送微軟做信譽查詢) 或不想被擋自製/冷門程式而選擇關閉。"
        DescEn       = "Microsoft Defender SmartScreen: when downloading/running programs, it checks a reputation database for known malicious or phishing content and warns you. On by default, a pure protection feature. A few people disable it for privacy (file info is sent to Microsoft for reputation checks) or to avoid blocks on homemade/obscure programs."
        Choices      = @(
            @{ Id = "enable"; Label = "開啟 (警告已知惡意/釣魚,系統預設)"; LabelEn = "On (warn on known malware/phishing, system default)"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "EnableSmartScreen";     Value = 1;      Type = "DWord" }
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "ShellSmartScreenLevel"; Value = "Warn"; Type = "String" }
               ) }
            @{ Id = "disable"; Label = "關閉 (不檢查、不上傳,安全性降低)"; LabelEn = "Off (no checks, no upload, lower security)"
               Reg = @(@{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "EnableSmartScreen"; Value = 0; Type = "DWord" }) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/ (SmartScreen);HKLM\SOFTWARE\Policies\Microsoft\Windows\System\EnableSmartScreen (1=開、0=關) + ShellSmartScreenLevel"
        VerifiedDate = "2026-07-05"
        Notes        = "預設已開啟,對大眾是有益的防護 (防釣魚/惡意程式)。開啟的取捨:執行程式時會將檔案資訊送微軟做信譽查詢 (隱私考量),偶爾對冷門正常程式跳警告 (可略過)。建議維持現狀:重視安全者保持開啟,重視隱私或常跑自製/冷門程式者可自行關閉。需重開機生效。"
        NotesEn        = "On by default, a beneficial protection for the general public (anti-phishing/malware). The tradeoff of keeping it on: file info is sent to Microsoft for reputation checks when running programs (a privacy consideration), and it occasionally warns on legitimate obscure programs (dismissible). Recommend Keep current: those prioritizing security keep it on; those prioritizing privacy or frequently running homemade/obscure programs may disable it. Requires a reboot."
    }
    )
}
