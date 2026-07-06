<#
    Windows 11 設定精靈 - 知識庫:第 01 類 隱私與遙測 (Privacy & Telemetry)
    ================================================================
    格式:選項式統一模型 (Choices + Recommend)。

    ── 三選項模型 (2026-07-04 修正) ──
    每個可切換的二元設定提供「啟用 / 停用 / 維持現狀」三個明確選項:
      - 兩個對立狀態都是實際的登錄檔寫入 (反向 = 寫入相反值),
        使用者可隨時雙向切換 (第一次停用、日後想還原也選得到「啟用」)。
      - 「維持現狀」(None) 保留為安全選項,適用於不確定現狀或不想更動時。
    Recommend 指向對大眾有益的一邊 (隱私/安全項);多值項 (如 Telemetry)
    則每個狀態各一選項。

    Choice 欄位:
      Id / Label (必要);Reg / RegDel / None (擇一);MinBuild / EditionOnly / Note (可選)
    Item 層級:Recommend (選項 Id 字串) / MinBuild / Notes

    Import-PowerShellDataFile 規定檔案最外層須為 Hashtable。
#>

@{
    Items = @(

    # ── 診斷資料回傳 (AllowTelemetry, 多值:每個狀態各一選項) ──
    @{
        Id           = "telemetry"
        Category     = 1
        NameZh       = "診斷資料回傳 (Telemetry / Diagnostic Data)"
        NameEn       = "Telemetry / Diagnostic Data"
        DescZh       = "Windows 定期把系統使用資料回傳微軟,含當機記錄、裝置資訊、使用習慣等。此政策可指定不同層級。"
        DescEn       = "Windows periodically sends system usage data to Microsoft, including crash logs, device info, and usage patterns. This policy sets the data level."
        Choices      = @(
            @{ Id = "lock_lowest"
               Label = "鎖定最低 (Enterprise/Education/Server 可完全關;Home/Pro 為 Required 底限)"; LabelEn = "Lock to lowest (Enterprise/Education/Server can fully disable; Home/Pro floor is Required)"
               Note  = "Home/Pro 上會被系統 clamp 為值 1 (Required)"; NoteEn = "On Home/Pro this is clamped to value 1 (Required)"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "required_only"
               Label = "僅必要資料 (Required)"; LabelEn = "Required data only"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "optional_full"
               Label = "完整選用資料 (Optional,含使用習慣、當機記憶體片段)"; LabelEn = "Full optional data (includes usage habits, crash memory snippets)"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Value = 3; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀 (不設政策,使用者可從設定 App 自控)"; LabelEn = "Keep current (no policy set; user controls via Settings app)"; None = $true }
        )
        Recommend    = "lock_lowest"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/windows/privacy/configure-windows-diagnostic-data-in-your-organization"
        VerifiedDate = "2026-07-04"
        Notes        = "AllowTelemetry 政策值:0=Diagnostic data off、1=Required、3=Optional (值 2=Enhanced 已於 Windows 10 廢棄)。Home/Pro 的政策底限為 1;僅 Enterprise/Education/Server 可真正完全關閉。四個選項可隨時互相切換。"
        NotesEn        = "AllowTelemetry policy values: 0=Diagnostic data off, 1=Required, 3=Optional (value 2=Enhanced deprecated in Windows 10). Home/Pro floor is 1; only Enterprise/Education/Server can fully disable. All four options are interchangeable anytime."
    },

    # ── 廣告識別碼 ──
    @{
        Id           = "advertising_id"
        Category     = 1
        NameZh       = "廣告識別碼 (Advertising ID)"
        NameEn       = "Advertising ID"
        DescZh       = "系統給每位使用者一組廣告 ID,App 用它追蹤使用習慣以投放個人化廣告。"
        DescEn       = "The system assigns each user an advertising ID that apps use to track usage habits for personalized ads."
        Choices      = @(
            @{ Id = "disable"
               Label = "停用廣告識別碼"; LabelEn = "Disable advertising ID"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"; Name = "DisabledByGroupPolicy"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "啟用廣告識別碼"; LabelEn = "Enable advertising ID"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"; Name = "DisabledByGroupPolicy"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-privacy (DisableAdvertisingId)"
        VerifiedDate = "2026-07-04"
        Notes        = "DisabledByGroupPolicy:1=停用廣告 ID (App 無法追蹤,廣告變非個人化)、0=啟用。不影響其他功能。"
        NotesEn        = "DisabledByGroupPolicy: 1=disable ad ID (apps can't track, ads become non-personalized), 0=enable. Does not affect other features."
    },

    # ── 活動記錄 (三鍵一組) ──
    @{
        Id           = "activity_history"
        Category     = 1
        NameZh       = "活動記錄 (Activity History)"
        NameEn       = "Activity History"
        DescZh       = "系統記錄你開啟的 App、檔案、活動並可同步到微軟帳號,用於時間軸與跨裝置接續。"
        DescEn       = "The system records apps, files, and activities you open, and can sync them to your Microsoft account for Timeline and cross-device resume."
        Choices      = @(
            @{ Id = "disable"
               Label = "停用活動記錄"; LabelEn = "Disable activity history"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "EnableActivityFeed";    Value = 0; Type = "DWord" }
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "PublishUserActivities"; Value = 0; Type = "DWord" }
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "UploadUserActivities";  Value = 0; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "啟用活動記錄"; LabelEn = "Enable activity history"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "EnableActivityFeed";    Value = 1; Type = "DWord" }
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "PublishUserActivities"; Value = 1; Type = "DWord" }
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "UploadUserActivities";  Value = 1; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-privacy (EnableActivityFeed / PublishUserActivities / UploadUserActivities)"
        VerifiedDate = "2026-07-04"
        Notes        = "三個政策鍵一併切換:EnableActivityFeed 控制功能、PublishUserActivities 控制記錄本地活動、UploadUserActivities 控制上傳雲端。停用不影響單機使用。"
        NotesEn        = "Toggles three policy keys together: EnableActivityFeed (feature), PublishUserActivities (local recording), UploadUserActivities (cloud upload). Disabling does not affect standalone use."
    },

    # ── 剪貼簿跨裝置同步 ──
    @{
        Id           = "cloud_clipboard"
        Category     = 1
        NameZh       = "剪貼簿跨裝置同步 (Cloud Clipboard)"
        NameEn       = "Cloud Clipboard (Cross-Device Sync)"
        DescZh       = "將剪貼簿內容同步到微軟帳號,讓多台裝置共用複製貼上的內容。"
        DescEn       = "Syncs clipboard content to your Microsoft account so multiple devices can share copied content."
        Choices      = @(
            @{ Id = "disable"
               Label = "停用跨裝置同步"; LabelEn = "Disable cross-device sync"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "AllowCrossDeviceClipboard"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "啟用跨裝置同步"; LabelEn = "Enable cross-device sync"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "AllowCrossDeviceClipboard"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-system (AllowCrossDeviceClipboard)"
        VerifiedDate = "2026-07-04"
        Notes        = "AllowCrossDeviceClipboard:0=不上傳雲端 (敏感資料不外流)、1=啟用。本機剪貼簿與 Win+V 歷程不受影響。若要連本機歷程也停,另有 AllowClipboardHistory。"
        NotesEn        = "AllowCrossDeviceClipboard: 0=no cloud upload (sensitive data stays local), 1=enable. Local clipboard and Win+V history are unaffected. To also disable local history, see AllowClipboardHistory."
    },

    # ── 量身打造體驗 ──
    @{
        Id           = "tailored_experiences"
        Category     = 1
        NameZh       = "量身打造體驗 (Tailored Experiences)"
        NameEn       = "Tailored Experiences"
        DescZh       = "微軟依你的診斷資料,在開始選單、設定等處顯示個人化建議與推銷。"
        DescEn       = "Microsoft uses your diagnostic data to show personalized suggestions and promotions in Start menu, Settings, etc."
        Choices      = @(
            @{ Id = "disable"
               Label = "停用量身打造體驗"; LabelEn = "Disable tailored experiences"
               Reg = @(
                   @{ Path = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Name = "DisableTailoredExperiencesWithDiagnosticData"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "啟用量身打造體驗"; LabelEn = "Enable tailored experiences"
               Reg = @(
                   @{ Path = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Name = "DisableTailoredExperiencesWithDiagnosticData"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-experience (DisableTailoredExperiencesWithDiagnosticData)"
        VerifiedDate = "2026-07-04"
        Notes        = "DisableTailoredExperiencesWithDiagnosticData:1=停用個人化推播、0=啟用。不影響系統功能。"
        NotesEn        = "DisableTailoredExperiencesWithDiagnosticData: 1=disable personalized suggestions, 0=enable. Does not affect system features."
    },

    # ── 意見反應通知 ──
    @{
        Id           = "feedback_notifications"
        Category     = 1
        NameZh       = "意見反應通知 (Feedback Notifications)"
        NameEn       = "Feedback Notifications"
        DescZh       = "Windows 會不定期跳出意見反應調查,要求你評分或回報使用感受。"
        DescEn       = "Windows periodically pops up feedback surveys asking you to rate or report your experience."
        Choices      = @(
            @{ Id = "disable"
               Label = "停用意見反應通知"; LabelEn = "Disable feedback notifications"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "DoNotShowFeedbackNotifications"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "啟用意見反應通知"; LabelEn = "Enable feedback notifications"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "DoNotShowFeedbackNotifications"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-feedback (DoNotShowFeedbackNotifications)"
        VerifiedDate = "2026-07-04"
        Notes        = "DoNotShowFeedbackNotifications:1=不再跳意見反應調查、0=顯示。若想保留通知但只調頻率,請不用此項改從設定 App 調整。"
        NotesEn        = "DoNotShowFeedbackNotifications: 1=stop feedback surveys, 0=show. To keep notifications but adjust frequency, use the Settings app instead of this item."
    },

    # ── 位置服務 ──
    @{
        Id           = "location"
        Category     = 1
        NameZh       = "位置服務 (Location Services)"
        NameEn       = "Location Services"
        DescZh       = "允許系統與 App 存取裝置定位。此為系統層級的總開關 (kill switch)。"
        DescEn       = "Allows the system and apps to access device location. This is a system-level master switch (kill switch)."
        Choices      = @(
            @{ Id = "disable"
               Label = "停用位置服務 (系統層級關閉)"; LabelEn = "Disable location services (system-level)"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"; Name = "DisableLocation"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "啟用位置服務"; LabelEn = "Enable location services"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"; Name = "DisableLocation"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "keep"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-system (AllowLocation) / LocationAndSensors 政策"
        VerifiedDate = "2026-07-04"
        Notes        = "DisableLocation:1=系統層級關閉所有 App 定位、0=啟用。屬個人需求 (筆電/導航常需定位、桌機多半用不到),故預設維持現狀。細部個別 App 權限見第 02 類。"
        NotesEn        = "DisableLocation: 1=system-level disable of all app location, 0=enable. This is need-based (laptops/navigation often need it, desktops rarely), so default is Keep current. For per-app permissions see category 02."
    },

    # ── 手寫與輸入個人化 (三鍵一組) ──
    @{
        Id           = "inking_typing"
        Category     = 1
        NameZh       = "手寫與輸入個人化 (Inking & Typing Personalization)"
        NameEn       = "Inking & Typing Personalization"
        DescZh       = "系統蒐集你的手寫與輸入內容以改善辨識,資料可能上傳微軟。"
        DescEn       = "The system collects your inking and typing content to improve recognition; data may be uploaded to Microsoft."
        Choices      = @(
            @{ Id = "disable"
               Label = "停用手寫與輸入蒐集"; LabelEn = "Disable inking & typing collection"
               Reg = @(
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Personalization\Settings"; Name = "AcceptedPrivacyPolicy";          Value = 0; Type = "DWord" }
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\InputPersonalization";     Name = "RestrictImplicitTextCollection"; Value = 1; Type = "DWord" }
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\InputPersonalization";     Name = "RestrictImplicitInkCollection";  Value = 1; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "啟用手寫與輸入蒐集"; LabelEn = "Enable inking & typing collection"
               Reg = @(
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Personalization\Settings"; Name = "AcceptedPrivacyPolicy";          Value = 1; Type = "DWord" }
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\InputPersonalization";     Name = "RestrictImplicitTextCollection"; Value = 0; Type = "DWord" }
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\InputPersonalization";     Name = "RestrictImplicitInkCollection";  Value = 0; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services (Inking & typing 段落)"
        VerifiedDate = "2026-07-04"
        Notes        = "三鍵一併切換:AcceptedPrivacyPolicy (個人化服務同意)、RestrictImplicitTextCollection (打字內容蒐集)、RestrictImplicitInkCollection (手寫內容蒐集)。停用後輸入法與手寫本身仍正常運作。"
        NotesEn        = "Toggles three keys together: AcceptedPrivacyPolicy (personalization consent), RestrictImplicitTextCollection (typing collection), RestrictImplicitInkCollection (inking collection). IME and handwriting still work normally after disabling."
    },

    # ── 線上語音辨識 (政策層 + 使用者層) ──
    @{
        Id           = "online_speech"
        Category     = 1
        NameZh       = "線上語音辨識 (Online Speech Recognition)"
        NameEn       = "Online Speech Recognition"
        DescZh       = "把你的語音送到微軟雲端做辨識。停用後改用裝置本機語音辨識。"
        DescEn       = "Sends your voice to Microsoft's cloud for recognition. When disabled, on-device speech recognition is used instead."
        Choices      = @(
            @{ Id = "disable"
               Label = "停用線上語音辨識 (政策層強制 + 使用者層撤回)"; LabelEn = "Disable online speech recognition (policy enforce + user opt-out)"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization";                Name = "AllowInputPersonalization"; Value = 0; Type = "DWord" }
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy"; Name = "HasAccepted";                Value = 0; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "啟用線上語音辨識"; LabelEn = "Enable online speech recognition"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization";                Name = "AllowInputPersonalization"; Value = 1; Type = "DWord" }
                   @{ Path = "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy"; Name = "HasAccepted";                Value = 1; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-privacy (AllowInputPersonalization) / 設定 App > 語音 (HasAccepted)"
        VerifiedDate = "2026-07-04"
        Notes        = "AllowInputPersonalization (HKLM 政策層,0=強制關閉並鎖定、1=允許) + HasAccepted (HKCU 使用者層同意)。停用後語音不上傳雲端,本機語音辨識仍可用。政策層需重開機生效。"
        NotesEn        = "AllowInputPersonalization (HKLM policy, 0=force-disable and lock, 1=allow) + HasAccepted (HKCU user consent). After disabling, voice isn't uploaded; on-device recognition still works. Policy layer needs a reboot."
    },

    # ── Windows 錯誤回報 (WER) ──
    @{
        Id           = "error_reporting"
        Category     = 1
        NameZh       = "Windows 錯誤回報 (Windows Error Reporting)"
        NameEn       = "Windows Error Reporting (WER)"
        DescZh       = "程式當機時自動把錯誤報告送微軟,含當機記憶體片段等資訊。"
        DescEn       = "Automatically sends error reports to Microsoft when programs crash, including crash memory snippets."
        Choices      = @(
            @{ Id = "disable"
               Label = "停用錯誤回報"; LabelEn = "Disable error reporting"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting"; Name = "Disabled"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "啟用錯誤回報"; LabelEn = "Enable error reporting"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting"; Name = "Disabled"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/windows/win32/wer/wer-settings (Disabled)"
        VerifiedDate = "2026-07-04"
        Notes        = "WER Disabled:1=停用 (不上傳當機報告)、0=啟用。不影響程式運作。"
        NotesEn        = "WER Disabled: 1=disable (no crash report upload), 0=enable. Does not affect program operation."
    },

    # ── 客戶經驗改進計畫 (CEIP) ──
    @{
        Id           = "ceip"
        Category     = 1
        NameZh       = "客戶經驗改進計畫 (CEIP)"
        NameEn       = "Customer Experience Improvement Program (CEIP)"
        DescZh       = "定期蒐集系統使用統計送微軟,用於產品改進 (Windows 舊有的匿名回報機制)。"
        DescEn       = "Periodically collects system usage statistics for Microsoft product improvement (Windows' legacy anonymous reporting mechanism)."
        Choices      = @(
            @{ Id = "disable"
               Label = "停用 CEIP"; LabelEn = "Disable CEIP"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows"; Name = "CEIPEnable"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "啟用 CEIP"; LabelEn = "Enable CEIP"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows"; Name = "CEIPEnable"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services (SQM 段落)"
        VerifiedDate = "2026-07-04"
        Notes        = "CEIPEnable:0=停用 (不上傳使用統計)、1=啟用。SQM 是 CEIP 內部代號。不影響系統功能。"
        NotesEn        = "CEIPEnable: 0=disable (no usage statistics upload), 1=enable. SQM is CEIP's internal codename. Does not affect system features."
    },

    # ── 設定線上提示 ──
    @{
        Id           = "online_tips"
        Category     = 1
        NameZh       = "設定線上提示 (Settings Online Tips)"
        NameEn       = "Settings Online Tips"
        DescZh       = "設定 App 會從微軟線上抓取提示內容,產生額外連線。"
        DescEn       = "The Settings app fetches tip content online from Microsoft, generating extra connections."
        Choices      = @(
            @{ Id = "disable"
               Label = "停用設定線上提示"; LabelEn = "Disable settings online tips"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"; Name = "AllowOnlineTips"; Value = 0; Type = "DWord" }
               ) }
            @{ Id = "enable"
               Label = "啟用設定線上提示"; LabelEn = "Enable settings online tips"
               Reg = @(
                   @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"; Name = "AllowOnlineTips"; Value = 1; Type = "DWord" }
               ) }
            @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
        )
        Recommend    = "disable"
        MinBuild     = $null
        Source       = "https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-experience (AllowOnlineTips)"
        VerifiedDate = "2026-07-04"
        Notes        = "AllowOnlineTips:0=停用 (設定 App 不再連線抓提示)、1=啟用。設定功能本身正常運作。"
        NotesEn        = "AllowOnlineTips: 0=disable (Settings app stops fetching tips online), 1=enable. Settings functionality works normally."
    }
    )
}
