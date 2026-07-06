<#
    Windows 11 設定精靈 - 知識庫:第 02 類 App 權限管理 (App Permissions)
    ================================================================
    本類為動態掃描型:掃描 CapabilityAccessManager\ConsentStore (HKLM+HKCU 合併)
    下各權限的當前狀態,逐一顯示並詢問。只管 Windows 商店 (UWP) 應用程式,
    與第三方 (Win32) 桌面程式無關。

    每個權限三選項:
      關閉 (Deny)  - 不允許 App 使用此權限
      開啟 (Allow) - 允許 App 使用 (可將已關閉的重新開啟)
      維持         - 不變動

    Enter 跟隨該權限的建議值 (Recommend):
      open  = 建議開啟 (大眾常用/硬體功能,有需要就保持開啟)
      close = 建議關閉 (純隱私敏感、多數人用不到、診斷/追蹤/畫面擷取類)

    寫入:HKCU\...\ConsentStore\{權限}\Value (Allow/Deny),無資料夾則自動建立。
    對照表 (Perms):資料夾名 → 中文名/說明/建議。實機掃到但未收錄者也會列出。

    Import-PowerShellDataFile 規定檔案最外層須為 Hashtable。
#>

@{
    Perms = @(
        @{ Key = "location"; NameZh = "位置"; NameEn = "Location"; DescZh = "App 存取你的地理位置。地圖、天氣、尋找裝置需要。"; DescEn = "Apps access your location. Needed by Maps, Weather, Find My Device."; Recommend = "open" }
        @{ Key = "webcam"; NameZh = "相機"; NameEn = "Camera"; DescZh = "App 使用攝影機。視訊、拍照、掃碼需要。"; DescEn = "Apps use the camera. Needed for video, photos, QR scanning."; Recommend = "open" }
        @{ Key = "microphone"; NameZh = "麥克風"; NameEn = "Microphone"; DescZh = "App 使用麥克風。語音、視訊、錄音需要。"; DescEn = "Apps use the microphone. Needed for voice, video, recording."; Recommend = "open" }
        @{ Key = "userNotificationListener"; NameZh = "通知存取"; NameEn = "Notification Access"; DescZh = "App 讀取你的通知內容。少數 App 需要,涉隱私。"; DescEn = "Apps read your notification content. Needed by a few apps; privacy-sensitive."; Recommend = "close" }
        @{ Key = "userAccountInformation"; NameZh = "帳戶資訊"; NameEn = "Account Info"; DescZh = "App 存取你的姓名、頭像等帳戶資訊。"; DescEn = "Apps access your name, avatar, and other account info."; Recommend = "open" }
        @{ Key = "contacts"; NameZh = "連絡人"; NameEn = "Contacts"; DescZh = "App 存取你的連絡人清單。郵件、通訊 App 需要。"; DescEn = "Apps access your contact list. Needed by mail and messaging apps."; Recommend = "open" }
        @{ Key = "appointments"; NameZh = "行事曆"; NameEn = "Calendar"; DescZh = "App 存取你的行事曆。行事曆、郵件 App 需要。"; DescEn = "Apps access your calendar. Needed by Calendar and mail apps."; Recommend = "open" }
        @{ Key = "phoneCallHistory"; NameZh = "通話記錄"; NameEn = "Call History"; DescZh = "App 存取你的通話記錄。桌機幾乎無此需求。"; DescEn = "Apps access your call history. Rarely needed on desktops."; Recommend = "close" }
        @{ Key = "email"; NameZh = "電子郵件"; NameEn = "Email"; DescZh = "App 存取與傳送電子郵件。郵件 App 需要。"; DescEn = "Apps access and send email. Needed by mail apps."; Recommend = "open" }
        @{ Key = "chat"; NameZh = "訊息/簡訊"; NameEn = "Messaging (SMS)"; DescZh = "App 讀取或傳送訊息 (SMS/MMS)。桌機幾乎無此需求。"; DescEn = "Apps read or send messages (SMS/MMS). Rarely needed on desktops."; Recommend = "close" }
        @{ Key = "phoneCall"; NameZh = "電話"; NameEn = "Phone Calls"; DescZh = "App 進行電話通話。桌機無電話功能。"; DescEn = "Apps make phone calls. Desktops have no phone function."; Recommend = "close" }
        @{ Key = "radios"; NameZh = "無線電控制"; NameEn = "Radio Control"; DescZh = "App 開關裝置無線電 (藍牙等)。"; DescEn = "Apps toggle device radios (Bluetooth, etc.)."; Recommend = "open" }
        @{ Key = "bluetoothSync"; NameZh = "藍牙同步"; NameEn = "Bluetooth Sync"; DescZh = "App 透過藍牙與裝置同步。"; DescEn = "Apps sync with devices over Bluetooth."; Recommend = "open" }
        @{ Key = "documentsLibrary"; NameZh = "文件庫"; NameEn = "Documents Library"; DescZh = "App 存取你的「文件」資料夾。涉個人檔案。"; DescEn = "Apps access your Documents folder. Involves personal files."; Recommend = "open" }
        @{ Key = "picturesLibrary"; NameZh = "圖片庫"; NameEn = "Pictures Library"; DescZh = "App 存取你的「圖片」資料夾。"; DescEn = "Apps access your Pictures folder."; Recommend = "open" }
        @{ Key = "videosLibrary"; NameZh = "影片庫"; NameEn = "Videos Library"; DescZh = "App 存取你的「影片」資料夾。"; DescEn = "Apps access your Videos folder."; Recommend = "open" }
        @{ Key = "broadFileSystemAccess"; NameZh = "檔案系統 (廣泛)"; NameEn = "File System (broad)"; DescZh = "App 存取所有檔案 (權限最大,風險高)。"; DescEn = "Apps access all files (broadest permission, high risk)."; Recommend = "close" }
        @{ Key = "cellularData"; NameZh = "行動數據"; NameEn = "Cellular Data"; DescZh = "App 使用行動數據連線。桌機通常無。"; DescEn = "Apps use cellular data. Usually absent on desktops."; Recommend = "open" }
        @{ Key = "gazeInput"; NameZh = "眼球追蹤"; NameEn = "Eye Tracking"; DescZh = "App 使用眼球追蹤輸入。少數輔助裝置用。"; DescEn = "Apps use eye-tracking input. Used by a few assistive devices."; Recommend = "open" }
        @{ Key = "humanPresence"; NameZh = "人員偵測"; NameEn = "Human Presence"; DescZh = "App 使用人員存在感測器。"; DescEn = "Apps use human-presence sensors."; Recommend = "open" }
        @{ Key = "activity"; NameZh = "活動歷程"; NameEn = "Activity History"; DescZh = "App 存取你的活動歷程。涉隱私追蹤。"; DescEn = "Apps access your activity history. Involves privacy tracking."; Recommend = "close" }
        @{ Key = "sensors.custom"; NameZh = "自訂感應器"; NameEn = "Custom Sensors"; DescZh = "App 存取自訂感應器資料。"; DescEn = "Apps access custom sensor data."; Recommend = "open" }
        @{ Key = "serialCommunication"; NameZh = "序列埠通訊"; NameEn = "Serial Communication"; DescZh = "App 透過序列埠與裝置通訊。"; DescEn = "Apps communicate with devices over serial ports."; Recommend = "open" }
        @{ Key = "usb"; NameZh = "USB 裝置"; NameEn = "USB Devices"; DescZh = "App 直接存取 USB 裝置。"; DescEn = "Apps directly access USB devices."; Recommend = "open" }
        @{ Key = "wifiData"; NameZh = "Wi-Fi 資訊"; NameEn = "Wi-Fi Info"; DescZh = "App 存取 Wi-Fi 連線資訊。"; DescEn = "Apps access Wi-Fi connection info."; Recommend = "open" }
        @{ Key = "graphicsCaptureProgrammatic"; NameZh = "畫面擷取"; NameEn = "Screen Capture"; DescZh = "App 以程式方式擷取螢幕畫面。涉隱私。"; DescEn = "Apps programmatically capture the screen. Privacy-sensitive."; Recommend = "close" }
        @{ Key = "graphicsCaptureWithoutBorder"; NameZh = "無邊框擷取"; NameEn = "Borderless Capture"; DescZh = "App 擷取畫面 (無邊框提示)。涉隱私。"; DescEn = "Apps capture the screen (no border indicator). Privacy-sensitive."; Recommend = "close" }
        @{ Key = "appDiagnostics"; NameZh = "App 診斷資訊"; NameEn = "App Diagnostics"; DescZh = "App 存取其他 App 的執行診斷資訊。涉隱私。"; DescEn = "Apps access other apps' runtime diagnostics. Privacy-sensitive."; Recommend = "close" }
        @{ Key = "bluetooth"; NameZh = "藍牙"; NameEn = "Bluetooth"; DescZh = "App 使用藍牙裝置。滑鼠/鍵盤/耳機需要。"; DescEn = "Apps use Bluetooth devices. Needed for mice, keyboards, headphones."; Recommend = "open" }
        @{ Key = "wiFiDirect"; NameZh = "Wi-Fi Direct"; NameEn = "Wi-Fi Direct"; DescZh = "App 使用 Wi-Fi Direct 直連 (無線投影等)。"; DescEn = "Apps use Wi-Fi Direct connections (wireless display, etc.)."; Recommend = "open" }
        @{ Key = "downloadsFolder"; NameZh = "下載資料夾"; NameEn = "Downloads Folder"; DescZh = "App 存取你的「下載」資料夾。"; DescEn = "Apps access your Downloads folder."; Recommend = "open" }
        @{ Key = "musicLibrary"; NameZh = "音樂庫"; NameEn = "Music Library"; DescZh = "App 存取你的「音樂」資料夾。"; DescEn = "Apps access your Music folder."; Recommend = "open" }
        @{ Key = "humanInterfaceDevice"; NameZh = "人機介面裝置 (HID)"; NameEn = "Human Interface Devices (HID)"; DescZh = "App 存取 HID 裝置 (自訂鍵盤/搖桿等)。"; DescEn = "Apps access HID devices (custom keyboards, gamepads, etc.)."; Recommend = "open" }
        @{ Key = "passkeys"; NameZh = "密碼金鑰 (Passkey)"; NameEn = "Passkeys"; DescZh = "App 使用密碼金鑰進行無密碼登入。"; DescEn = "Apps use passkeys for passwordless sign-in."; Recommend = "open" }
        @{ Key = "passkeysEnumeration"; NameZh = "密碼金鑰列舉"; NameEn = "Passkey Enumeration"; DescZh = "App 列舉已儲存的密碼金鑰。涉安全。"; DescEn = "Apps enumerate stored passkeys. Security-sensitive."; Recommend = "close" }
        @{ Key = "systemAIModels"; NameZh = "系統 AI 模型"; NameEn = "System AI Models"; DescZh = "App 存取系統內建 AI 模型 (Copilot+ 功能等)。"; DescEn = "Apps access built-in system AI models (Copilot+ features, etc.)."; Recommend = "open" }
        @{ Key = "userDataTasks"; NameZh = "工作/待辦"; NameEn = "Tasks/To-Do"; DescZh = "App 存取你的工作與待辦事項。待辦 App 需要。"; DescEn = "Apps access your tasks and to-dos. Needed by to-do apps."; Recommend = "open" }
    )
}
