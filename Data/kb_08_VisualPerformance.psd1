<#
    Windows 11 設定精靈 - 知識庫:第 09 類 視覺與效能 (Visual & Performance)
    ================================================================
    分組型 (group)。整組套用用 VisualFXSetting (1=外觀、2=效能);
    展開個別調整涵蓋完整 17 項視覺效果 (對齊 Windows「效能選項」對話框):
      - 8 項獨立鍵型:各有專屬登錄檔鍵 (Reg)
      - 9 項遮罩型:綁在 UserPreferencesMask 二進位遮罩的特定 bit (Mask)

    Mask 選項格式:@{ BitMask=<位元>; Enable=<$true/$false> },由引擎的
    Set-PreferenceMaskBit 處理 (讀出遮罩→改單一 bit→寫回,不影響其他 bit)。

    多數建議關閉 (效能優先);字型平滑與縮圖建議開啟 (可讀性/易用性)。
    透明效果已在第 13 類,此處不重複。所有變更需登出重登才完全生效。

    Import-PowerShellDataFile 規定檔案最外層須為 Hashtable。
#>

@{
    Groups = @(
        @{
            Name = "視覺效果 (動畫、陰影、平滑等,共 17 項)"
            NameEn = "Visual Effects (animations, shadows, smoothing, etc.; 17 items)"
            Desc = "Windows 的各種視覺特效。效能優先=關閉特效讓系統更快 (適合老機/VM/追求效能);外觀優先=開啟特效較美觀。可整組一鍵套用,或展開個別調整全部 17 項。"

            DescEn = "Various Windows visual effects. Performance first = turn off effects for a faster system (good for old machines/VMs/performance); Appearance first = turn on effects for a nicer look. Apply the whole group at once, or expand to adjust all 17 items individually."
            OptA = @{ Label = "效能優先 (關閉視覺特效,系統較快)"; LabelEn = "Performance first (disable visual effects, faster system)"; Value = 2 }
            OptB = @{ Label = "外觀優先 (開啟視覺特效,較美觀)"; LabelEn = "Appearance first (enable visual effects, nicer look)"; Value = 1 }
            GroupPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
            GroupName = "VisualFXSetting"
            GroupType = "DWord"
            RecommendOpt = "A"

            Items = @(
                @{
                    Id     = "vfx_animate"
                    NameZh = "視窗動畫 (最小化/最大化)"
                    NameEn = "Window Animations (minimize/maximize)"
                    DescZh = "視窗最小化/最大化的動畫。關閉後視窗切換更即時。"
                    DescEn = "Animations for minimizing/maximizing windows. Disabling makes window switching more instant."
                    Choices = @(
                        @{ Id = "off"; Label = "關閉動畫 (較快)"; LabelEn = "Disable animations (faster)"
                           Reg = @(@{ Path = "HKCU:\Control Panel\Desktop\WindowMetrics"; Name = "MinAnimate"; Value = "0"; Type = "String" }) }
                        @{ Id = "on"; Label = "開啟動畫 (較美觀)"; LabelEn = "Enable animations (nicer look)"
                           Reg = @(@{ Path = "HKCU:\Control Panel\Desktop\WindowMetrics"; Name = "MinAnimate"; Value = "1"; Type = "String" }) }
                        @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
                    )
                    Recommend = "off"
                },
                @{
                    Id     = "vfx_dragfull"
                    NameZh = "拖曳時顯示視窗內容"
                    NameEn = "Show Window Contents While Dragging"
                    DescZh = "拖曳視窗時顯示完整內容(而非外框)。關閉後拖曳更輕快。"
                    DescEn = "Shows full window contents while dragging (instead of an outline). Disabling makes dragging snappier."
                    Choices = @(
                        @{ Id = "off"; Label = "只顯示外框 (較快)"; LabelEn = "Outline only (faster)"
                           Reg = @(@{ Path = "HKCU:\Control Panel\Desktop"; Name = "DragFullWindows"; Value = "0"; Type = "String" }) }
                        @{ Id = "on"; Label = "顯示完整內容 (較美觀)"; LabelEn = "Show full contents (nicer look)"
                           Reg = @(@{ Path = "HKCU:\Control Panel\Desktop"; Name = "DragFullWindows"; Value = "1"; Type = "String" }) }
                        @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
                    )
                    Recommend = "off"
                },
                @{
                    Id     = "vfx_fontsmooth"
                    NameZh = "螢幕字型平滑 (ClearType)"
                    NameEn = "Screen Font Smoothing (ClearType)"
                    DescZh = "字型邊緣平滑。建議保持開啟(關閉文字有鋸齒、傷眼),此項少數建議維持開啟。"
                    DescEn = "Smooths font edges. Recommended to keep on (disabling makes text jagged and hard on the eyes); one of the few items recommended to keep enabled."
                    Choices = @(
                        @{ Id = "off"; Label = "關閉字型平滑 (文字有鋸齒)"; LabelEn = "Disable font smoothing (jagged text)"
                           Reg = @(@{ Path = "HKCU:\Control Panel\Desktop"; Name = "FontSmoothing"; Value = "0"; Type = "String" }) }
                        @{ Id = "on"; Label = "開啟字型平滑 (建議,文字清晰)"; LabelEn = "Enable font smoothing (recommended, clear text)"
                           Reg = @(@{ Path = "HKCU:\Control Panel\Desktop"; Name = "FontSmoothing"; Value = "2"; Type = "String" }) }
                        @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
                    )
                    Recommend = "on"
                },
                @{
                    Id     = "vfx_taskbaranim"
                    NameZh = "工作列動畫"
                    NameEn = "Taskbar Animations"
                    DescZh = "工作列圖示的微動畫(hover/點擊)。關閉後工作列反應更即時。"
                    DescEn = "Micro-animations for taskbar icons (hover/click). Disabling makes the taskbar more responsive."
                    Choices = @(
                        @{ Id = "off"; Label = "關閉 (較快)"; LabelEn = "Off (faster)"
                           Reg = @(@{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "TaskbarAnimations"; Value = 0; Type = "DWord" }) }
                        @{ Id = "on"; Label = "開啟 (較美觀)"; LabelEn = "On (nicer look)"
                           Reg = @(@{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "TaskbarAnimations"; Value = 1; Type = "DWord" }) }
                        @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
                    )
                    Recommend = "off"
                },
                @{
                    Id     = "vfx_thumbhibernate"
                    NameZh = "儲存工作列縮圖預覽"
                    NameEn = "Save Taskbar Thumbnail Previews"
                    DescZh = "快取工作列縮圖預覽。關閉可省少量記憶體。"
                    DescEn = "Caches taskbar thumbnail previews. Disabling saves a small amount of memory."
                    Choices = @(
                        @{ Id = "off"; Label = "關閉 (較快)"; LabelEn = "Off (faster)"
                           Reg = @(@{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "AlwaysHibernateThumbnails"; Value = 0; Type = "DWord" }) }
                        @{ Id = "on"; Label = "開啟 (較美觀)"; LabelEn = "On (nicer look)"
                           Reg = @(@{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "AlwaysHibernateThumbnails"; Value = 1; Type = "DWord" }) }
                        @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
                    )
                    Recommend = "off"
                },
                @{
                    Id     = "vfx_iconsonly"
                    NameZh = "縮圖代替圖示"
                    NameEn = "Thumbnails Instead of Icons"
                    DescZh = "顯示檔案縮圖(而非通用圖示)。建議開啟(方便瀏覽圖片檔),此項是少數建議維持開啟的。"
                    DescEn = "Shows file thumbnails (instead of generic icons). Recommended to enable (handy for browsing image files); one of the few items recommended to keep enabled."
                    Choices = @(
                        @{ Id = "on"; Label = "顯示縮圖 (建議,方便瀏覽)"; LabelEn = "Show thumbnails (recommended, easy browsing)"
                           Reg = @(@{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "IconsOnly"; Value = 0; Type = "DWord" }) }
                        @{ Id = "off"; Label = "只顯示圖示 (較快,不顯示縮圖)"; LabelEn = "Icons only (faster, no thumbnails)"
                           Reg = @(@{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "IconsOnly"; Value = 1; Type = "DWord" }) }
                        @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
                    )
                    Recommend = "on"
                },
                @{
                    Id     = "vfx_listviewalpha"
                    NameZh = "半透明選取框"
                    NameEn = "Translucent Selection Rectangle"
                    DescZh = "框選時的半透明矩形。關閉改為外框。"
                    DescEn = "The translucent rectangle when box-selecting. Disabling switches to an outline."
                    Choices = @(
                        @{ Id = "off"; Label = "關閉 (較快)"; LabelEn = "Off (faster)"
                           Reg = @(@{ Path = "HKCU:\Control Panel\Desktop"; Name = "ListviewAlphaSelect"; Value = 0; Type = "DWord" }) }
                        @{ Id = "on"; Label = "開啟 (較美觀)"; LabelEn = "On (nicer look)"
                           Reg = @(@{ Path = "HKCU:\Control Panel\Desktop"; Name = "ListviewAlphaSelect"; Value = 1; Type = "DWord" }) }
                        @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
                    )
                    Recommend = "off"
                },
                @{
                    Id     = "vfx_listviewshadow"
                    NameZh = "桌面圖示標籤陰影"
                    NameEn = "Desktop Icon Label Shadows"
                    DescZh = "桌面圖示文字下的陰影。關閉可省少量資源。"
                    DescEn = "Shadows under desktop icon text. Disabling saves a small amount of resources."
                    Choices = @(
                        @{ Id = "off"; Label = "關閉 (較快)"; LabelEn = "Off (faster)"
                           Reg = @(@{ Path = "HKCU:\Control Panel\Desktop"; Name = "ListviewShadow"; Value = 0; Type = "DWord" }) }
                        @{ Id = "on"; Label = "開啟 (較美觀)"; LabelEn = "On (nicer look)"
                           Reg = @(@{ Path = "HKCU:\Control Panel\Desktop"; Name = "ListviewShadow"; Value = 1; Type = "DWord" }) }
                        @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
                    )
                    Recommend = "off"
                },
                @{
                    Id     = "vfx_menuanim"
                    NameZh = "選單淡入淡出"
                    NameEn = "Menu Fade/Slide"
                    DescZh = "選單開啟時的淡入/滑入。關閉後選單即時出現。"
                    DescEn = "Fade/slide-in when menus open. Disabling makes menus appear instantly."
                    Choices = @(
                        @{ Id = "off"; Label = "關閉 (較快)"; LabelEn = "Off (faster)"
                           Mask = @{ BitMask = 0x2; Enable = $false } }
                        @{ Id = "on"; Label = "開啟 (較美觀)"; LabelEn = "On (nicer look)"
                           Mask = @{ BitMask = 0x2; Enable = $true } }
                        @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
                    )
                    Recommend = "off"
                },
                @{
                    Id     = "vfx_comboanim"
                    NameZh = "下拉方塊滑動"
                    NameEn = "Combo Box Slide"
                    DescZh = "下拉方塊展開的滑動動畫。關閉後即時展開。"
                    DescEn = "The slide animation when combo boxes expand. Disabling makes them expand instantly."
                    Choices = @(
                        @{ Id = "off"; Label = "關閉 (較快)"; LabelEn = "Off (faster)"
                           Mask = @{ BitMask = 0x4; Enable = $false } }
                        @{ Id = "on"; Label = "開啟 (較美觀)"; LabelEn = "On (nicer look)"
                           Mask = @{ BitMask = 0x4; Enable = $true } }
                        @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
                    )
                    Recommend = "off"
                },
                @{
                    Id     = "vfx_smoothscroll"
                    NameZh = "清單平滑捲動"
                    NameEn = "List Smooth Scrolling"
                    DescZh = "清單捲動的平滑效果。關閉後逐列捲動。"
                    DescEn = "Smooth scrolling for lists. Disabling scrolls row by row."
                    Choices = @(
                        @{ Id = "off"; Label = "關閉 (較快)"; LabelEn = "Off (faster)"
                           Mask = @{ BitMask = 0x8; Enable = $false } }
                        @{ Id = "on"; Label = "開啟 (較美觀)"; LabelEn = "On (nicer look)"
                           Mask = @{ BitMask = 0x8; Enable = $true } }
                        @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
                    )
                    Recommend = "off"
                },
                @{
                    Id     = "vfx_gradient"
                    NameZh = "漸層標題列"
                    NameEn = "Gradient Title Bar"
                    DescZh = "視窗標題列的漸層效果。"
                    DescEn = "Gradient effect on window title bars."
                    Choices = @(
                        @{ Id = "off"; Label = "關閉 (較快)"; LabelEn = "Off (faster)"
                           Mask = @{ BitMask = 0x10; Enable = $false } }
                        @{ Id = "on"; Label = "開啟 (較美觀)"; LabelEn = "On (nicer look)"
                           Mask = @{ BitMask = 0x10; Enable = $true } }
                        @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
                    )
                    Recommend = "off"
                },
                @{
                    Id     = "vfx_menufade"
                    NameZh = "選單淡出"
                    NameEn = "Menu Fade-Out"
                    DescZh = "選單關閉時的淡出。"
                    DescEn = "Fade-out when menus close."
                    Choices = @(
                        @{ Id = "off"; Label = "關閉 (較快)"; LabelEn = "Off (faster)"
                           Mask = @{ BitMask = 0x200; Enable = $false } }
                        @{ Id = "on"; Label = "開啟 (較美觀)"; LabelEn = "On (nicer look)"
                           Mask = @{ BitMask = 0x200; Enable = $true } }
                        @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
                    )
                    Recommend = "off"
                },
                @{
                    Id     = "vfx_selfade"
                    NameZh = "選取淡出"
                    NameEn = "Selection Fade-Out"
                    DescZh = "選取項目的淡出效果。"
                    DescEn = "Fade-out effect for selected items."
                    Choices = @(
                        @{ Id = "off"; Label = "關閉 (較快)"; LabelEn = "Off (faster)"
                           Mask = @{ BitMask = 0x400; Enable = $false } }
                        @{ Id = "on"; Label = "開啟 (較美觀)"; LabelEn = "On (nicer look)"
                           Mask = @{ BitMask = 0x400; Enable = $true } }
                        @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
                    )
                    Recommend = "off"
                },
                @{
                    Id     = "vfx_tooltipanim"
                    NameZh = "工具提示動畫"
                    NameEn = "Tooltip Animation"
                    DescZh = "滑鼠停留時提示的動畫。"
                    DescEn = "Animation for tooltips on mouse hover."
                    Choices = @(
                        @{ Id = "off"; Label = "關閉 (較快)"; LabelEn = "Off (faster)"
                           Mask = @{ BitMask = 0x800; Enable = $false } }
                        @{ Id = "on"; Label = "開啟 (較美觀)"; LabelEn = "On (nicer look)"
                           Mask = @{ BitMask = 0x800; Enable = $true } }
                        @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
                    )
                    Recommend = "off"
                },
                @{
                    Id     = "vfx_tooltipfade"
                    NameZh = "工具提示淡出"
                    NameEn = "Tooltip Fade-Out"
                    DescZh = "工具提示的淡出效果。"
                    DescEn = "Fade-out effect for tooltips."
                    Choices = @(
                        @{ Id = "off"; Label = "關閉 (較快)"; LabelEn = "Off (faster)"
                           Mask = @{ BitMask = 0x1000; Enable = $false } }
                        @{ Id = "on"; Label = "開啟 (較美觀)"; LabelEn = "On (nicer look)"
                           Mask = @{ BitMask = 0x1000; Enable = $true } }
                        @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
                    )
                    Recommend = "off"
                },
                @{
                    Id     = "vfx_cursorshadow"
                    NameZh = "滑鼠指標陰影"
                    NameEn = "Mouse Pointer Shadow"
                    DescZh = "滑鼠指標下的陰影。"
                    DescEn = "Shadow under the mouse pointer."
                    Choices = @(
                        @{ Id = "off"; Label = "關閉 (較快)"; LabelEn = "Off (faster)"
                           Mask = @{ BitMask = 0x2000; Enable = $false } }
                        @{ Id = "on"; Label = "開啟 (較美觀)"; LabelEn = "On (nicer look)"
                           Mask = @{ BitMask = 0x2000; Enable = $true } }
                        @{ Id = "keep"; Label = "維持現狀"; LabelEn = "Keep current"; None = $true }
                    )
                    Recommend = "off"
                }
            )
        }
    )
}
