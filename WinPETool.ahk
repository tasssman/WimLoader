#Requires AutoHotkey v2.0
; #Warn All, StdOut  ; Enable warnings to assist with detecting common errors.
SetWorkingDir A_ScriptDir  ; Ensures a consistent starting directory.
#SingleInstance Force ;Only one copy can be run
#Include RunCmd.ahk
;Globals and assigning
textLog := ""

;MainWindow
DisplayMainWindow()
{
    ;Globals
    global LogWindow

    ;Menu
	MainMenu := Gui()
	logWindow := MainMenu.Add("Edit", "x521 y8 w279 h401 +ReadOnly +Multi")
    LogWindow.SetFont("s7")
	MainMenu.Add("Text", "x16 y24 w34 h23 +0x200", "Path:")
	;Create WinPE
	pathCreate := MainMenu.Add("Edit", "x56 y24 w201 h21")
	ButtonCreate := MainMenu.Add("Button", "x264 y24 w80 h23", "Create")
    ButtonCreate.OnEvent("Click", CreateWINPE)

	MainMenu.Add("GroupBox", "x8 y0 w504 h57", "Create WinPE")
	MainMenu.OnEvent('Close', (*) => ExitApp())
	MainMenu.Title := "WinPE Tool"

    ;Menu functions
    CreateWINPE(*)
    {
        ShowOnLog("Creating WinPE in path " . pathCreate.text . "...",1,1)
        
    }
	return MainMenu
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
    SendMessage(0xB1, -2, -1, logWindow) ; EM_SETSEL - originally by SKAN: sets the selection to the end of the control                                                                                                                                       ;
    SendMessage(0xC2, 0, StrPtr(message), logWindow) ; EM_REPLACESEL
}

HelpText(text)
{
    ShowOnLog(text,1,1)
}

;Script start
MainMenu := DisplayMainWindow()
MainMenu.Show("w817 h420")
