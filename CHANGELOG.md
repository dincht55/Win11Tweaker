# 變更紀錄 / Changelog

本專案的所有重要變更皆記錄於此。

格式參考 [Keep a Changelog](https://keepachangelog.com/zh-TW/1.1.0/)，
版本編號遵循 [語意化版本 2.0.0](https://semver.org/lang/zh-TW/)。

---

## [1.0.0] - 2026-07-06

### 首次公開發佈 🎉

Windows 11 設定精靈（Win11Tweaker）首個正式版本。

### 新增

#### 模組化架構（14 大類，共約 175 項）

| 編號 | 類別 | 說明 |
|:----:|------|------|
| 01 | Privacy | 隱私設定 |
| 02 | AppPermissions | 應用程式權限 |
| 03 | AI | AI 功能（Copilot、Recall） |
| 04 | AppBehavior | 應用程式行為 |
| 05 | Personalize | 個人化 |
| 06 | Network | 網路設定 |
| 07 | Hardware | 硬體 |
| 08 | VisualPerformance | 視覺與效能 |
| 09 | Security | 安全性 |
| 10 | ScheduledTasks | 排程任務 |
| 11 | Services | 系統服務 |
| 12 | SystemBehavior | 系統行為 |
| 13 | PreinstalledApps | 預裝軟體移除 |
| 14 | DiskCleanup | 磁碟清理 |

#### 三種提問類型

- **逐題類**（9 類）：每項獨立提問
- **分組類**（1 類）：08 視覺與效能分組批次調整
- **動態掃描類**（4 類）：02 / 11 / 13 / 14 即時掃描系統決定候選項

#### 完整繁體中文 / 英文雙語介面

- 語言檔集中於 `Lang/`（`lang_zh-TW.psd1`、`lang_en.psd1`）
- 知識庫以 `NameZh/NameEn`、`NoteZh/NoteEn` 雙欄位管理
- `Get-Text` / `Get-Field` 引擎自動依當前語言取值
- `Get-Field` 同時支援 `IDictionary` 與 `PSCustomObject`（動態掃描相容）

#### 兩種執行模式

- **完整模式**：依 01~14 順序全流程
- **自訂模式**：自選類別執行

#### 五種回覆選項

`Y`（套用）／`N`（略過）／`S`(跳過整類）／`P`（暫停續傳）／`Q`（結束）

#### 其他核心功能

- **即時進度儲存與續傳**：中途中斷可從上次進度繼續
- **刪除保護機制**：登錄檔值刪除前自動備份，可用 `Restore.ps1` 還原
- **重置工具**：`Reset.ps1` 一鍵清除報告 / 日誌 / 設定檔 / 還原備份
- **語言共用**：`Select-Language` 為 `Common.ps1` 共用函式，三支工具共享
- **報告輸出**：ASCII 符號摘要（`[v]` `[x]` `[-]` `[>]` `[NA]`）

### 技術規格

- **目標系統**：Windows 11 24H2（Build 26100）以上，涵蓋 24H2 / 25H2
- **執行環境**：PowerShell 5.1（Windows 11 內建版本）
- **檔案編碼**：所有 `.ps1` / `.psd1` 為 UTF-8 with BOM（PowerShell 5.1 跨語系相容）
- **授權**：MIT License

### 已知限制

- **13 預裝軟體移除**：因沙盒測試環境無 OEM 預裝軟體，此類別已通過流程與引擎測試，但尚未在有實際 bloatware 的 OEM 電腦上完整驗證。使用時建議先確認報告內容再套用。

---

[1.0.0]: https://github.com/dincht55/Win11Tweaker/releases/tag/v1.0.0
