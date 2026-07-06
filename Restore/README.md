# Restore 還原資料夾

此資料夾存放「**刪除登錄檔值**」操作的還原檔。當設定精靈執行了刪除類設定(例如停止 OneDrive、Teams 開機自啟)時,會在刪除前先把原值備份到這裡,供日後還原。

---

## 一、還原檔命名原則

還原檔的檔名格式為:

```
{設定檔名稱}_{類別代號}_restore_{日期}_{時間}.json
```

各欄位說明:

| 欄位 | 說明 | 範例 |
|------|------|------|
| 設定檔名稱 | 執行時使用的名稱 (預設為 `電腦名稱_使用者名稱`,或自訂) | `DINCHT-PC_Dincht` |
| 類別代號 | 產生此還原檔的模組 | `05_AppBehavior` |
| `restore` | 固定字樣,標示這是還原檔 | `restore` |
| 日期 | 執行日期 (yyyyMMdd) | `20260704` |
| 時間 | 執行時間 (HHmmss) | `015348` |

**完整範例:**

```
DINCHT-PC_Dincht_05_AppBehavior_restore_20260704_015348.json
```

> 每次執行刪除操作都會產生一個獨立的還原檔 (時間戳精確到秒),不會互相覆蓋,方便對應到不同時間點的操作。

---

## 二、還原檔內容

還原檔是 JSON 格式,記錄被刪除的每一個登錄檔值的完整資訊:

```json
{
    "profile_name": "DINCHT-PC_Dincht",
    "module": "05_AppBehavior",
    "timestamp": "20260704_015348",
    "note": "此檔記錄被刪除的登錄檔值,可用於還原。",
    "deleted": [
        {
            "Path":  "HKCU:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run",
            "Name":  "OneDrive",
            "Value": "C:\\Program Files\\Microsoft OneDrive\\OneDrive.exe /background",
            "Type":  "String"
        }
    ]
}
```

`deleted` 陣列中的每一筆包含:

- **Path** — 登錄檔路徑
- **Name** — 值名稱
- **Value** — 被刪除前的原始值 (還原時寫回)
- **Type** — 值的型別 (String / DWord / QWord / Binary / ExpandString 等)

---

## 三、如何還原

### 方法一:使用還原工具 (推薦)

專案根目錄提供 `Restore.ps1` 還原工具,可一鍵還原,不需手動操作登錄檔。

**步驟:**

1. 以**系統管理員**身分開啟 PowerShell
2. 切換到專案根目錄 (Restore.ps1 所在位置)
3. 執行:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\Restore.ps1
   ```

4. 工具會列出所有還原檔,輸入編號選擇要還原的檔案
5. 確認後,工具會把被刪除的值寫回登錄檔

**安全機制:**

- 還原前會列出將寫回的項目並要求確認
- **若某個值目前已存在,會自動略過,不覆蓋** — 避免蓋掉你後來自行設定的內容
- 每筆寫回後會讀回驗證,確保還原成功
- 結果分為「已還原 / 已存在略過 / 還原失敗」三類清楚呈現

### 方法二:手動還原

若不使用工具,也可依還原檔內容手動寫回。以上方範例為例:

```powershell
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" `
                 -Name "OneDrive" `
                 -Value "C:\Program Files\Microsoft OneDrive\OneDrive.exe /background" `
                 -Type String -Force
```

依 `deleted` 陣列中每一筆的 Path / Name / Value / Type 逐一寫回即可。

---

## 四、注意事項

- **還原檔可保留備查**:還原後不會自動刪除還原檔,你可以保留它,日後或在其他電腦上再次還原。
- **開機自啟項目的還原效果**:還原 OneDrive、Teams 等自啟項目後,需**重新開機或重新登入**才會恢復開機自動啟動。
- **此資料夾不會上傳 GitHub**:還原檔屬於個人執行產物,已由 `.gitignore` 排除,不會被納入版本控制。
- **請勿手動修改還原檔格式**:若要保留,建議原樣保存,以確保 `Restore.ps1` 能正確讀取。

---

*本工具僅還原「被本精靈刪除的登錄檔值」。它不是系統還原,無法復原其他變更。*
