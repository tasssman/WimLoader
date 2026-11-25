#Requires AutoHotkey v2.0
#SingleInstance Force

mainGui := Gui(, "WIM Loader - Windows image deployment")
mainGui.BackColor := "F4F7FB"
mainGui.SetFont("s10", "Segoe UI")

mainGui.SetFont("s10 bold", "Segoe UI")
mainGui.Add("GroupBox", "x24 y24 w570 h302", "1. Select a destination disk")
mainGui.SetFont("s9", "Segoe UI")
mainGui.Add("Text", "x40 y52 w400 h20 c64748B", "The selected disk will be erased during installation.")
mainGui.Add("CheckBox", "x40 y81 w130 h22 Disabled", "Show USB drives")
mainGui.Add("Button", "x460 y76 w118 h28 Disabled", "Refresh disks")
diskList := mainGui.Add("ListView", "x40 y114 w538 h154 -Multi Disabled", ["Disk", "Model", "Size", "Partition style"])
diskList.ModifyCol(1, 65)
diskList.ModifyCol(2, 190)
diskList.ModifyCol(3, 85)
diskList.ModifyCol(4, 150)
mainGui.Add("Text", "x40 y276 w520 h20 c64748B", "No destination disk selected")
mainGui.Add("Button", "x40 y298 w160 h27 Disabled", "Format selected disk")
mainGui.Add("Button", "x208 y298 w130 h27 Disabled", "Format all disks")

mainGui.SetFont("s10 bold", "Segoe UI")
mainGui.Add("GroupBox", "x24 y340 w570 h268", "2. Select a Windows image")
mainGui.SetFont("s9", "Segoe UI")
mainGui.Add("Text", "x40 y369 w360 h20 c64748B", "Choose a WIM file from the image source.")
mainGui.Add("Button", "x342 y365 w112 h28 Disabled", "Change path")
mainGui.Add("Button", "x463 y365 w115 h28 Disabled", "Refresh images")
mainGui.Add("Edit", "x40 y401 w538 h27 ReadOnly")
mainGui.Add("ListBox", "x40 y438 w538 h152 Disabled")

mainGui.SetFont("s10 bold", "Segoe UI")
mainGui.Add("GroupBox", "x610 y24 w346 h314", "3. Review installation")
mainGui.SetFont("s9", "Segoe UI")
mainGui.Add("Text", "x626 y52 w310 h20 c64748B", "Select a disk and image to review.")
mainGui.Add("Text", "x626 y85 w82 h20 c64748B", "Destination")
mainGui.Add("Text", "x716 y85 w220 h20", "Not selected")
mainGui.Add("Text", "x626 y116 w82 h20 c64748B", "Model")
mainGui.Add("Text", "x716 y116 w220 h20", "Not selected")
mainGui.Add("Text", "x626 y147 w82 h20 c64748B", "Image")
mainGui.Add("Text", "x716 y147 w220 h34", "Not selected")
mainGui.Add("Text", "x626 y185 w82 h20 c64748B", "Boot mode")
mainGui.Add("DropDownList", "x716 y181 w145 Disabled", ["UEFI", "Legacy BIOS"])
mainGui.Add("Text", "x626 y214 w314 h54 BackgroundFFF4DC c785113", "  DATA LOSS WARNING`n  Installation erases all data on the selected disk.`n  Confirmation will be required before proceeding.")
mainGui.Add("Button", "x626 y276 w314 h32 Disabled", "Install image")
mainGui.Add("Text", "x626 y314 w314 h20 Center c64748B", "Installation not yet available")

mainGui.SetFont("s10 bold", "Segoe UI")
mainGui.Add("GroupBox", "x610 y350 w346 h258", "Activity")
mainGui.SetFont("s9", "Segoe UI")
mainGui.Add("Text", "x626 y377 w250 h20", "Ready")
mainGui.Add("Text", "x896 y377 w40 h20 Right c64748B", "0%")
mainGui.Add("Progress", "x626 y402 w310 h10", 0)
LogWindow := mainGui.Add("Edit", "x626 y421 w310 h171 ReadOnly Multi")

mainGui.SetFont("s9", "Segoe UI")
mainGui.Add("Text", "x24 y626 w600 h22 c52647A", "No disks or images loaded")
mainGui.Add("Text", "x656 y626 w300 h22 Right c64748B", "WinPE-ready  |  WIM Loader")

mainGui.OnEvent("Close", (*) => ExitApp())
mainGui.Show("w980 h660")
LogToWindow("Main menu was loaded", 1, 1)

LogToWindow(message, timeLine := 0, CR := 0, onlyLog := 0)
{
    global LogWindow

    enterNum := ""
    if CR > 0 {
        Loop CR {
            enterNum := "`r`n" . enterNum
        }
    }

    if timeLine = 1 {
        time := FormatTime(, "HH:mm:ss")
        message := time . ": " . message . enterNum
    } else {
        message := message . enterNum
    }

    logTime := FormatTime(, "yyyy-MM-dd_hh:mm:ss")
    fileLog := A_ScriptDir . "\log.txt"
    FileAppend("[" . logTime . "]" . " " . message, fileLog)

    if (onlyLog = 0) {
        SendMessage(0xB1, -2, -1, LogWindow)
        SendMessage(0xC2, 0, StrPtr(message), LogWindow)
    }
}
