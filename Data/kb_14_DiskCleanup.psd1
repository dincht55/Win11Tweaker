<#
    Windows 11 設定精靈 - 知識庫:第 15 類 磁碟清理 (Disk Cleanup)
    ================================================================
    本類與設定型類別不同:定義「清理對象」而非設定選項。模組執行時先估算
    各項可釋放空間,顯示後再逐一詢問是否清理。

    分兩區:
      SafeItems     - 安全清理區 (純賺,清了幾乎無副作用)
      AdvancedItems - 進階區 (知情取捨,清了有代價,需說明清楚)

    清理方式 (Method) 由模組對應處理:
      "folder"   - 直接清空資料夾內容 (鎖住的檔案略過),Path 指定資料夾
      "wusvc"    - Windows Update 快取 (需停 wuauserv/bits 服務再清)
      "recycle"  - 回收筒 (Clear-RecycleBin)
      "cleanmgr" - 交給系統磁碟清理處理特定類別 (sageset)
      "dism"     - WinSxS 元件清理 (DISM StartComponentCleanup)

    Import-PowerShellDataFile 規定檔案最外層須為 Hashtable。
#>

@{
    # ═══════════════════════════════════════════════════════════
    #  安全清理區:純賺,清了幾乎無副作用 (使用中的檔案會自動略過)
    # ═══════════════════════════════════════════════════════════
    SafeItems = @(
        @{
            Id     = "user_temp"
            NameZh = "使用者暫存檔"
            NameEn = "User Temp Files"
            Method = "folder"
            Path   = "%TEMP%"
            DescZh = "目前使用者的暫存資料夾 (%TEMP%)。程式執行時產生的暫存資料,可安全清除。"
            DescEn = "The current user's temp folder (%TEMP%). Temporary data created while programs run; safe to clear."
            Note   = "正在使用中的暫存檔會自動略過 (不影響執行中的程式)。安裝或更新進行中時建議先完成再清。"
            NoteEn   = "Temp files in use are skipped automatically (running programs unaffected). If an install or update is in progress, finish it first before cleaning."
        }
        @{
            Id     = "windows_temp"
            NameZh = "系統暫存檔"
            NameEn = "System Temp Files"
            Method = "folder"
            Path   = "%SystemRoot%\Temp"
            DescZh = "系統層級的暫存資料夾 (C:\Windows\Temp)。系統與程式產生的暫存資料,可安全清除。"
            DescEn = "The system-level temp folder (C:\Windows\Temp). Temp data from the system and programs; safe to clear."
            Note   = "使用中的檔案會自動略過。需系統管理員權限。"
            NoteEn   = "Files in use are skipped automatically. Requires administrator privileges."
        }
        @{
            Id     = "thumb_cache"
            NameZh = "縮圖快取"
            NameEn = "Thumbnail Cache"
            Method = "folder"
            Path   = "%LocalAppData%\Microsoft\Windows\Explorer"
            Filter = "thumbcache_*.db"
            DescZh = "檔案總管的縮圖快取。清除後首次瀏覽資料夾時會自動重建,略慢一下即恢復。"
            DescEn = "File Explorer's thumbnail cache. After clearing, it rebuilds automatically on first browse, briefly slower then back to normal."
            Note   = "只清縮圖快取檔 (thumbcache_*.db),不影響任何個人檔案。清後縮圖會自動重建。"
            NoteEn   = "Clears only thumbnail cache files (thumbcache_*.db); no personal files affected. Thumbnails rebuild automatically afterward."
        }
        @{
            Id     = "wu_cache"
            NameZh = "Windows Update 快取"
            NameEn = "Windows Update Cache"
            Method = "wusvc"
            Path   = "%SystemRoot%\SoftwareDistribution\Download"
            DescZh = "已下載的 Windows Update 安裝檔快取,更新完成後多為殘留,常達數 GB。"
            DescEn = "Cached downloaded Windows Update installers, mostly leftovers after updates complete, often several GB."
            Note   = "會先暫停 Windows Update 服務再清、清完自動重啟服務。更新進行中請勿清理。需系統管理員權限。"
            NoteEn   = "Pauses the Windows Update service before clearing and restarts it afterward. Don't clean during an update. Requires administrator privileges."
        }
        @{
            Id     = "delivery_opt"
            NameZh = "傳遞最佳化快取"
            NameEn = "Delivery Optimization Cache"
            Method = "folder"
            Path   = "%SystemRoot%\SoftwareDistribution\DeliveryOptimization"
            DescZh = "Windows Update 傳遞最佳化 (P2P 更新分享) 的快取檔。可安全清除,系統會視需要重建。"
            DescEn = "Cache files for Windows Update Delivery Optimization (P2P update sharing). Safe to clear; the system rebuilds as needed."
            Note   = "清除不影響 Windows Update 正常運作。需系統管理員權限。"
            NoteEn   = "Clearing doesn't affect normal Windows Update operation. Requires administrator privileges."
        }
        @{
            Id     = "recycle_bin"
            NameZh = "回收筒"
            NameEn = "Recycle Bin"
            Method = "recycle"
            Path   = ""
            DescZh = "清空回收筒。釋放已刪除但仍佔空間的檔案。"
            DescEn = "Empties the Recycle Bin, freeing space from deleted files still taking room."
            Note   = "清空後回收筒內的檔案將無法再救回,請確認裡面沒有需要保留的檔案。"
            NoteEn   = "After emptying, files in the Recycle Bin can't be recovered; make sure nothing you need is inside."
        }
    )

    # ═══════════════════════════════════════════════════════════
    #  進階區:知情取捨,清了有明確代價,須理解後再決定 (預設不清)
    # ═══════════════════════════════════════════════════════════
    AdvancedItems = @(
        @{
            Id     = "windows_old"
            NameZh = "舊版 Windows (Windows.old)"
            NameEn = "Previous Windows (Windows.old)"
            Method = "cleanmgr"
            Path   = "%SystemRoot%.old"
            DescZh = "系統升級後保留的前一版 Windows (Windows.old),可達 20-30 GB。保留是為了讓你能回退到舊版。"
            DescEn = "The previous Windows version kept after an upgrade (Windows.old), up to 20-30 GB. Kept so you can roll back to the old version."
            Note   = "【重要取捨】清除後將『無法再回退到升級前的舊版 Windows』。若你剛升級、系統運作正常且確定不會回退,清除可釋放大量空間;若不確定,建議暫時保留 (Windows 通常會在 10 天後自動清除)。需系統管理員權限。"
            NoteEn   = "[Important tradeoff] After clearing, you can no longer roll back to the pre-upgrade Windows version. If you just upgraded, the system runs fine, and you're sure you won't roll back, clearing frees a lot of space; if unsure, keep it for now (Windows usually auto-clears after 10 days). Requires administrator privileges."
        }
        @{
            Id     = "component_cleanup"
            NameZh = "元件存放區清理 (WinSxS)"
            NameEn = "Component Store Cleanup (WinSxS)"
            Method = "dism"
            Path   = ""
            DescZh = "清理 WinSxS 元件存放區中已被新版取代的舊元件 (DISM StartComponentCleanup)。可釋放數 GB。"
            DescEn = "Cleans old components in the WinSxS component store superseded by newer versions (DISM StartComponentCleanup). Can free several GB."
            Note   = "【取捨】清理後將無法解除安裝『清理前已安裝』的 Windows 更新 (無法回退那些更新)。系統本身穩定不受影響。此操作耗時較久 (數分鐘),過程請勿中斷。需系統管理員權限。"
            NoteEn   = "[Tradeoff] After cleanup, you can't uninstall Windows updates installed before the cleanup (can't roll those back). System stability itself is unaffected. This operation takes a while (several minutes); don't interrupt it. Requires administrator privileges."
        }
    )
}
