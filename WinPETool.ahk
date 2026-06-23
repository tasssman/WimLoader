#Requires AutoHotkey v2.0
; #Warn All, StdOut  ; Enable warnings to assist with detecting common errors.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.
#SingleInstance Force ;Only one copy can be run
;Included files
#Include WinPETool_RunCmd.ahk
;Install files

;Globals and assigning
global AdkPath := "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\DandISetEnv.bat"
;Variables
pathToPackages := "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\"
packages :=
(
    "WinPE-WMI.cab|WinPE-NetFX.cab|WinPE-Scripting.cab|WinPE-PowerShell.cab|WinPE-StorageWMI.cab|WinPE-DismCmdlets.cab"
)

;MainWindow
DisplayMainWindow()
{
    global ButtonShowlog
	MainMenu := Gui()
    ;Show log button
    ButtonShowlog := MainMenu.Add("Button", "x432 y8 w80 h23", "Hide log")
    ButtonShowlog.OnEvent("Click", ShowLog)
    ;Create WinPE
    MainMenu.Add("GroupBox", "x8 y40 w504 h57", "Create WinPE")
	MainMenu.Add("Text", "x16 y64 w34 h23 +0x200", "Path:")
	pathCreate := MainMenu.Add("Edit", "x+2 y64 w201 h21", "C:\WinPE_amd64")
	ButtonCreate := MainMenu.Add("Button", "x+2 y64 w80 h23", "Create")
    ButtonCreate.OnEvent("Click", CreateWINPE)
    ;Add packages
    ButtonPackages := MainMenu.Add("Button", "x+2 y64 w80 h23", "Add Pkgs")
    ButtonPackages.OnEvent("Click", AddPackages)
    ;Add Wimloader and starnet.cmd
    ButtonWimLoader := MainMenu.Add("Button", "x+2 y64 w80 h23", "Add Wimloader")
    ButtonWimLoader.OnEvent("Click", AddWimloader)

	MainMenu.OnEvent('Close', (*) => ExitApp())
	MainMenu.Title := "WinPETool"

    ;Menu functions
    CreateWINPE(*)
    {
        path := pathCreate.Value
        ShowOnLog("Creating WinPE...",1,1)
        RunCMD('cmd.exe /c ""' AdkPath '" && copype amd64 ' path '"',,, RunCmdReturnLine)
        ShowOnLog("Creating WinPE... DONE",1,1)
    }

    ShowLog(*)
    {
        if !WinExist("ahk_id " LogWindow.Hwnd) {
            LogWindow.Show()  ; Show it if hidden
            ButtonShowlog.Text := "Hide log"
        } else {
            LogWindow.Hide()  ; Hide it if visible
            ButtonShowlog.Text := "Show log"
        }
    }

    AddPackages(*)
    {
        checkForWim(pathCreate.Value)
        mountWim(pathCreate.Value, pathCreate.Value . "\mount")
        ShowOnLog("Adding packages...",1,1)
        For package in StrSplit(packages, "|"){
            cabPath := pathToPackages . package
            RunCMD('C:\Windows\System32\dism.exe /Add-Package /Image:"' pathCreate.Value '\mount" /PackagePath:"' cabPath '"',,, RunCmdReturnLine)
        }
        unMountWim(pathCreate.Value . "\mount")
        ShowOnLog("Adding packages... DONE",1,1)
    }

    AddWimloader(*)
    {
        ;mountWim(pathCreate.Value, pathCreate.Value . "\mount")
        ShowOnLog("Select WimLoader.exe...",1,1)
        wimLoaderPath := FileSelect(,,"Select WimLoader file","*.exe")
        ShowOnLog("Copying from " . wimLoaderPath .  " and rename to WimLoader.exe",1,1)
        RunCMD("copy /y " wimLoaderPath " " pathCreate.Value "\mount\Windows\System32\WimLoader.exe",,, RunCmdReturnLine)
        FileCopy(wimLoaderPath, pathCreate.Value "\mount\Windows\System32\WimLoader.exe",1)
        If(!FileExist(pathCreate.Value "\mount\Windows\System32\WimLoader.exe")){
            ShowOnLog("There is problem with copy file")
        } else {
            ShowOnLog("Copying DONE",1,1)
        }
        ShowOnLog("Create necessary line in startnet.cmd...",1,1)
        FileDelete(pathCreate.Value "\mount\Windows\System32\startnet.cmd")
        FileAppend("wpeinit`nstart wimloader.exe", pathCreate.Value "\mount\Windows\System32\startnet.cmd")
        ShowOnLog("Create necessary line in startnet.cmd... DONE",1,1)
    }

	return MainMenu
}

DisplayLogWindow()
{
    global MainMenu
    global Logs
    LogWindow := Gui()
	Logs := LogWindow.Add("Edit", "x8 y8 w380 h544 +ReadOnly +Multi")
    LogWindow.OnEvent("Close", CloseLog)
	
	LogWindow.Title := "Log"
    LogWindow.Opt("+Owner" . MainMenu.Hwnd)
	
    CloseLog(*)
    {
        LogWindow.Hide()
        ButtonShowlog.Text := "Show log"
    }

	return LogWindow
}

;Functions
ShowOnLog(message, timeLine := 0, CR := 0) ;timeLine (default 0) if "1" than time is added; CR default 0. Number constitutes how many "enters" append after text.
{
    enterNum := ""
    if CR > 0 {
        Loop CR {
            enterNum := "`r`n" . enterNum
        }
    }

    if timeLine = 1 {
        time := FormatTime(,"HH:mm:ss")
        message := time . ": " . message . enterNum
    } else {
        message := message . enterNum
    }
    SendMessage(0xB1, -2, -1, Logs) ; EM_SETSEL - originally by SKAN: sets the selection to the end of the control                                                                                                                                       ;
    SendMessage(0xC2, 0, StrPtr(message), Logs) ; EM_REPLACESEL
}

RunCmdReturnLine(Line, LineNum)
{
    ShowOnLog(Line)
}

checkForWim(path)
{
    ShowOnLog("Checking for wim file",1,1)
    if (FileExist(path . "\media\sources\boot.wim")) {
        ShowOnLog("Found boot.wim.",1,1)
    } else {
        ShowOnLog("Can not find " . path . "\media\sources\boot.wim .Exiting.",1,1)
        Exit
    }
}

mountWim(path, mountDir)
{
    ShowOnLog("Mounting WIM file...",1,1)
    RunCMD("Dism /Mount-Image /ImageFile:" . path . "\media\sources\boot.wim /index:1 /MountDir:" . mountDir,,, RunCmdReturnLine)
    ShowOnLog("Mounting WIM file... DONE",1,1)
}

unMountWim(mountDir)
{
    ShowOnLog("Commit and unmount WIM file...",1,1)
    RunCMD("Dism /Unmount-Image /MountDir:" . mountDir . " /commit",,, RunCmdReturnLine)
    ShowOnLog("Unmounting WIM file... DONE",1,1)
    ;Dism /Unmount-Image /MountDir:"D:\WinPE_amd64\mount" /commit
}

;Script start
MainMenu := DisplayMainWindow()
MainMenu.Show()
LogWindow := DisplayLogWindow()
MainMenu.GetPos(&x, &y, &w, &h)
LogWindow.Show(Format("x{} y{} h559", x + w + 10, y))
