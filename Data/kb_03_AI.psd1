<#
    Windows 11 設定精靈 - 知識庫:第 04 類 AI 功能 (AI Features)
    ============================================================
    格式:選項式統一模型 (Choices + Recommend)。

    Choice 欄位:
      Id          (必要) 選項識別碼,跨版本移植穩定 (如 "disable_all")
      Label       (必要) 顯示文字
      Reg / RegDel / None (擇一) 動作定義
      MinBuild    (可選) 選項自己的最低 Build,不符會被過濾
      EditionOnly (可選) 只在指定 EditionID 出現 (如 @("Enterprise","Education"))
      Note        (可選) 顯示於該選項旁邊的短提示 (版本差異警語等)

    Item 層級:
      Recommend    - 建議選項的 Id 字串 (向後相容:數字視為 1-based 編號)
      MinBuild     - 整個項目的最低 Build,不符則整題跳過
      Notes        - 顯示於選項清單下方的詳細備註

    Import-PowerShellDataFile 規定檔案最外層須為 Hashtable,故陣列包在 Items 鍵下。

    --------------------------------------------------------------
    收錄界線 (2026-07-04 徹查定案)
    --------------------------------------------------------------
    本類收「系統層 Windows AI」政策,共 5 項:
      1. Recall 回顧 (AI 螢幕快照,3 選項分級)
      2. 工作列 Copilot 按鈕 (Copilot 顯示控制)
      3. Click to Do 點選即做
      4. Copilot 硬體鍵 (實體鍵盤按鍵)
      5. 設定 App AI 代理 (Agentic Search)

    不收 / 移至他處:
      * Windows Copilot 政策:舊 TurnOffWindowsCopilot 對 24H2+ 新版無效、
        新 RemoveMicrosoftCopilotApp 對個人使用者不觸發 → 移除;完整移除
        Copilot App 走第 14 類 (Remove-AppxPackage Microsoft.Copilot)。
      * Recall 快照匯出 (AllowRecallExport):Recall 關閉後即多餘,不獨立成題。
      * 隱藏設定 AI 元件頁 (SettingsPageVisibility=hide:aicomponents):
        SettingsPageVisibility 為共用字串鍵,直接覆蓋會蓋掉使用者其他隱藏頁,
        需引擎支援「附加而非覆蓋」才安全 → 暫緩。
      * 個別 App 內建 AI (小畫家 DisableImageCreator/DisableGenerativeFill/
        DisableCocreator、記事本 DisableAIFeatures、Windows Studio Effects):
        屬各 App 範疇,不在系統層 AI 類。
#>

@{
    Items = @(

    # ── Recall 回顧 (AI 螢幕快照,多值分級控制) ──
    @{
        Id           = "recall"
        Category     = 3
        NameZh       = "Recall 回顧 (AI 螢幕快照)"
        NameEn       = "Recall (AI Screen Snapshots)"
        DescZh       = "Copilot+ PC 的 AI 功能,自動截取螢幕畫面建立可 AI 搜尋的歷史記錄。WindowsAI 政策提供分級控制:可完全禁用 Recall 或僅停用快照。"
        DescEn       = "An AI feature on Copilot+ PCs that automatically captures screen snapshots to build an AI-searchable history. The WindowsAI policy offers tiered control: fully disable Recall, or only disable snapshots."
        Choices      = @(
            @{ Id = "disable_all"
               Label = "完全禁用 Recall (阻止啟用 + 停用快照)"; LabelEn = "Fully disable Recall (block enablement + disable snapshots)"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"; Name = "AllowRecallEnablement"; Value = 0; Type = "DWord" }
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"; Name = "DisableAIDataAnalysis"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "disable_snapshots_only"
               Label = "僅停用螢幕快照 (Recall UI 仍存在,但不記錄畫面)"; LabelEn = "Disable snapshots only (Recall UI remains, but no screen recording)"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"; Name = "DisableAIDataAnalysis"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "啟用 Recall (允許啟用 + 允許快照)"; LabelEn = "Enable Recall (allow enablement + allow snapshots)"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"; Name = "AllowRecallEnablement"; Value = 1; Type = "DWord" }
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"; Name = "DisableAIDataAnalysis"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable_all"
        MinBuild     = 26100
        Source       = "https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-windowsai"
        VerifiedDate = "2026-07-04"
        Notes        = "AllowRecallEnablement (0=阻止啟用、1=允許) 與 DisableAIDataAnalysis (1=停用快照、0=允許快照) 兩政策鍵組合。選項『完全禁用』兩者併用最徹底;『僅停用快照』保留 Recall UI 但不記錄;『啟用 Recall』把兩鍵設回允許值以還原。此政策僅 24H2 起才有 (MinBuild 26100),舊版系統會自動略過。"
        NotesEn        = "Combines two policy keys: AllowRecallEnablement (0=block, 1=allow) and DisableAIDataAnalysis (1=disable snapshots, 0=allow). 'Fully disable' uses both for the most thorough effect; 'Disable snapshots only' keeps the Recall UI but records nothing; 'Enable Recall' sets both back to allow. This policy exists only from 24H2 (MinBuild 26100); older systems are skipped automatically."
    },

    # ── 工作列 Copilot 按鈕 ──
    @{
        Id           = "copilot_button"
        Category     = 3
        NameZh       = "工作列 Copilot 按鈕 (Copilot 顯示控制)"
        NameEn       = "Taskbar Copilot Button (Display Control)"
        DescZh       = "工作列上的 Copilot 圖示按鈕,點擊即開啟 AI 助理。這是本類唯一的 Copilot 控制點,作用為『隱藏按鈕』,並非移除 Copilot App。"
        DescEn       = "The Copilot icon button on the taskbar; clicking opens the AI assistant. This is the only Copilot control here, and it hides the button rather than removing the Copilot app."
        Choices      = @(
            @{ Id = "hide"
               Label = "隱藏工作列 Copilot 按鈕"; LabelEn = "Hide taskbar Copilot button"
               Reg = @(
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowCopilotButton"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "show"
               Label = "顯示工作列 Copilot 按鈕"; LabelEn = "Show taskbar Copilot button"
               Reg = @(
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "ShowCopilotButton"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "hide"
        MinBuild     = $null
        Source       = "Explorer\Advanced\ShowCopilotButton (Windows 11 Shell 內建設定,對應設定 App > 個人化 > 工作列 中的 Copilot 開關)"
        VerifiedDate = "2026-07-04"
        Notes        = "重要:隱藏 ≠ 移除。此設定只隱藏工作列圖示,Copilot App 仍在系統中。24H2/25H2 的 Copilot 已是獨立 Store App,舊的 TurnOffWindowsCopilot 政策對它無效,而新的 RemoveMicrosoftCopilotApp 政策有嚴苛前提 (需同時裝 M365 Copilot、非使用者自裝、28 天未開),對個人使用者通常不觸發,故本工具不採用。若要真正移除 Copilot,請於第 14 類「預裝軟體移除」解除安裝 Microsoft.Copilot (Remove-AppxPackage)。"
        NotesEn        = "Important: hiding is not removal. This only hides the taskbar icon; the Copilot app remains. In 24H2/25H2 Copilot is a standalone Store app, so the old TurnOffWindowsCopilot policy no longer works, and the new RemoveMicrosoftCopilotApp policy has strict prerequisites (M365 Copilot installed, not user-installed, unopened for 28 days) that rarely apply to individuals, so this tool does not use it. To truly remove Copilot, uninstall Microsoft.Copilot (Remove-AppxPackage) in category 14 'Preinstalled Apps'."
    },

    # ── Click to Do 點選即做 (AI) ──
    @{
        Id           = "click_to_do"
        Category     = 3
        NameZh       = "Click to Do 點選即做 (AI)"
        NameEn       = "Click to Do (AI)"
        DescZh       = "24H2 引入的 AI 功能,對螢幕上的文字或圖片提供智慧動作建議 (如摘要、複製、搜尋)。屬本機螢幕內容分析,主要出現在 Copilot+ PC。"
        DescEn       = "An AI feature introduced in 24H2 that offers smart action suggestions (summarize, copy, search) for on-screen text or images. It analyzes local screen content, mainly on Copilot+ PCs."
        Choices      = @(
            @{ Id = "disable"
               Label = "停用 Click to Do"; LabelEn = "Disable Click to Do"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"; Name = "DisableClickToDo"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "啟用 Click to Do"; LabelEn = "Enable Click to Do"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"; Name = "DisableClickToDo"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = 26100
        Source       = "https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-windowsai (DisableClickToDo)"
        VerifiedDate = "2026-07-04"
        Notes        = "政策層級的二值開關,停用後系統不再對螢幕內容做 AI 分析提供動作建議,不影響其他 AI 功能。此功能自 build 26100.3915 (24H2) 起以 preview 形式引入,主要限 Copilot+ PC;非 Copilot+ PC 或未達此修補版的系統可能無此功能,但預先設好政策鍵可預防性封鎖,無副作用。"
        NotesEn        = "A policy-level on/off switch. When disabled, the system no longer runs AI analysis on screen content for action suggestions; other AI features are unaffected. Introduced as preview from build 26100.3915 (24H2), mainly on Copilot+ PCs; non-Copilot+ PCs or systems below this patch may lack it, but presetting the policy key blocks it preventively with no side effects."
    },

    # ── Copilot 硬體鍵 (實體 Copilot 鍵行為) ──
    @{
        Id           = "copilot_hardware_key"
        Category     = 3
        NameZh       = "Copilot 硬體鍵 (實體鍵盤按鍵)"
        NameEn       = "Copilot Hardware Key (Physical Keyboard Key)"
        DescZh       = "部分新款鍵盤與筆電有一顆實體 Copilot 鍵,按下即啟動 Copilot。此設定可停用這顆鍵,避免誤觸。僅對『鍵盤上真的有這顆鍵』的機器有效。"
        DescEn       = "Some new keyboards and laptops have a physical Copilot key that launches Copilot when pressed. This setting disables that key to avoid accidental presses. Only effective on machines that actually have the key."
        Choices      = @(
            @{ Id = "disable"
               Label = "停用 Copilot 實體鍵 (按下不啟動任何 App)"; LabelEn = "Disable Copilot physical key (press launches nothing)"
               Reg = @(
                   @{ Path = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CopilotKey"; Name = "SetCopilotHardwareKey"; Value = "0"; Type = "String" }
               ) }
            @{ Id = "restore"
               Label = "還原預設 (刪除設定,實體鍵恢復原本功能)"; LabelEn = "Restore default (delete setting; key returns to original function)"
               RegDel = @(
                   @{ Path = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CopilotKey"; Name = "SetCopilotHardwareKey" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = 26100
        Source       = "https://learn.microsoft.com/en-us/windows/client-management/manage-windows-copilot (SetCopilotHardwareKey / WindowsAI Policy CSP)"
        VerifiedDate = "2026-07-04"
        Notes        = "此鍵值型別為字串 (REG_SZ),設為 0 代表停用實體 Copilot 鍵。反向的『還原預設』是刪除這個設定值 (而非寫入某個開啟值),讓實體鍵回到系統原本的行為 (開啟 Copilot 或搜尋),等同從未用本工具停用過;因此選『還原預設』時引擎會跳出刪除確認並自動備份,屬正常流程。若你的鍵盤沒有這顆鍵,套用後無任何效果 (無害)。若想讓這顆鍵改開別的程式,可到 設定 App > 個人化 > 文字輸入 > 自訂鍵盤上的 Copilot 鍵 自行重新對應。"
        NotesEn        = "This value is a string (REG_SZ); 0 disables the physical Copilot key. The reverse 'Restore default' deletes the value (rather than writing an 'on' value), returning the key to its original behavior (open Copilot or Search), as if never disabled by this tool; so choosing 'Restore default' triggers a delete confirmation with automatic backup, which is normal. If your keyboard lacks the key, applying has no effect (harmless). To remap the key to another app, go to Settings > Personalization > Text input > Customize Copilot key on keyboard."
    },

    # ── 設定 App AI 代理 (Settings Agent) ──
    @{
        Id           = "settings_agent"
        Category     = 3
        NameZh       = "設定 App AI 代理 (Agentic Search)"
        NameEn       = "Settings App AI Agent (Agentic Search)"
        DescZh       = "25H2 引入的功能,在『設定』App 中加入 AI 代理式搜尋,可用自然語言描述需求、由 AI 代為調整設定。停用後設定 App 回到傳統搜尋。"
        DescEn       = "A feature introduced in 25H2 that adds AI agentic search to the Settings app, letting you describe needs in natural language and have AI adjust settings. When disabled, Settings returns to traditional search."
        Choices      = @(
            @{ Id = "disable"
               Label = "停用設定 App AI 代理"; LabelEn = "Disable Settings app AI agent"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"; Name = "DisableSettingsAgent"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "啟用設定 App AI 代理"; LabelEn = "Enable Settings app AI agent"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"; Name = "DisableSettingsAgent"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = 26100
        Source       = "https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-windowsai (DisableSettingsAgent) / Group Policy: Windows AI > Disable Settings agentic search experience"
        VerifiedDate = "2026-07-04"
        Notes        = "政策層級二值開關 (DisableSettingsAgent=1 停用)。此功能為 25H2 era 引進,目前僅在主顯示語言為英文/法文的系統上啟用,繁體中文系統暫時看不到此功能;但預先設好政策鍵可預防性封鎖,待日後支援繁中或系統更新後仍維持停用,無副作用。"
        NotesEn        = "A policy-level on/off switch (DisableSettingsAgent=1 disables). Introduced in the 25H2 era, currently enabled only on systems with English/French as the primary display language; Traditional Chinese systems don't see it yet. Presetting the policy key blocks it preventively, staying disabled even after future Chinese support or updates, with no side effects."
    }
    )
}
