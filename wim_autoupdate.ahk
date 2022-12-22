#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

;Reading output from command
StdOutToVar(cmd) {
	DllCall("CreatePipe", "PtrP", hReadPipe, "PtrP", hWritePipe, "Ptr", 0, "UInt", 0)
	DllCall("SetHandleInformation", "Ptr", hWritePipe, "UInt", 1, "UInt", 1)

	VarSetCapacity(PROCESS_INFORMATION, (A_PtrSize == 4 ? 16 : 24), 0)    ; http://goo.gl/dymEhJ
	cbSize := VarSetCapacity(STARTUPINFO, (A_PtrSize == 4 ? 68 : 104), 0) ; http://goo.gl/QiHqq9
	NumPut(cbSize, STARTUPINFO, 0, "UInt")                                ; cbSize
	NumPut(0x100, STARTUPINFO, (A_PtrSize == 4 ? 44 : 60), "UInt")        ; dwFlags
	NumPut(hWritePipe, STARTUPINFO, (A_PtrSize == 4 ? 60 : 88), "Ptr")    ; hStdOutput
	NumPut(hWritePipe, STARTUPINFO, (A_PtrSize == 4 ? 64 : 96), "Ptr")    ; hStdError
	
	if !DllCall(
	(Join Q C
		"CreateProcess",             ; http://goo.gl/9y0gw
		"Ptr",  0,                   ; lpApplicationName
		"Ptr",  &cmd,                ; lpCommandLine
		"Ptr",  0,                   ; lpProcessAttributes
		"Ptr",  0,                   ; lpThreadAttributes
		"UInt", true,                ; bInheritHandles
		"UInt", 0x08000000,          ; dwCreationFlags
		"Ptr",  0,                   ; lpEnvironment
		"Ptr",  0,                   ; lpCurrentDirectory
		"Ptr",  &STARTUPINFO,        ; lpStartupInfo
		"Ptr",  &PROCESS_INFORMATION ; lpProcessInformation
	)) {
		DllCall("CloseHandle", "Ptr", hWritePipe)
		DllCall("CloseHandle", "Ptr", hReadPipe)
		return ""
	}

	DllCall("CloseHandle", "Ptr", hWritePipe)
	VarSetCapacity(buffer, 4096, 0)
	while DllCall("ReadFile", "Ptr", hReadPipe, "Ptr", &buffer, "UInt", 4096, "UIntP", dwRead, "Ptr", 0)
		sOutput .= StrGet(&buffer, dwRead, "CP0")

	DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, 0))         ; hProcess
	DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, A_PtrSize)) ; hThread
	DllCall("CloseHandle", "Ptr", hReadPipe)
	return sOutput
}

MainWindow()
{
	Gui Main: New
	Gui Font, s9, Segoe UI
	Gui Add, Edit, x8 y56 w736 h312 +ReadOnly +Multi vLogWindow
	Gui Add, Text, x320 y16 w124 h27 +0x200, Updating Wim Loader
	Gui Show, w753 h385, Autoupdate
	Return
}


;Get first free letter drive without comma
GetFirstFreeLetter()
{
    freeDiskLetter := StdOutToVar("powershell ls function:[h-u]: -n | ?{ !(test-path $_) } | select -first 1")
	freeDiskLetter := RegExReplace(freeDiskLetter, "\r\n", "")
    freeDiskLetter := RegExReplace(freeDiskLetter, ":", "")
	return freeDiskLetter
}

LogToWindow(text)
{
	FormatTime, timeNow,,yyyy-MM-dd_HH:mm:ss
	textLog = %textLog%`r`n%timeNow% - %text%
	GuiControl, Main:, LogWindow, %textLog%
    SendMessage,0x115,7,0,Edit1,Autoupdate
}

;=====================Script START=====================
;=====================Variables=====================
;Variables
global LogWindow
global ProgressBar
global Status
global textLog
defaLocUpdate = "\\pchw\winpe"
defaLocSources = "\\pchw\images\sources"
defaultUser = cos\images
defaultPass = "123edc!@#EDC"
updateFileUpdate = WimLoader.exe
disk := "c,d,e,f,g,h,i,j,k,l,m,o,p"

MainWindow()

LogToWindow("Searching fo USB drive with WinPE...")
Loop, Parse, disk, `,
{
	usbLetter := A_LoopField
	pathToBootWim := A_LoopField . ":\sources\boot.wim"
	if FileExist(pathToBootWim)
	{
		Goto, Continue
	}
}
;I USB drive not exist
MsgBox 0x40010, USB not found, USB drive with WimLoader not found. Please copy manualy boot.wim from PCHW
	Goto, Exiting

Continue:
LogToWindow("Mounting PCHW ...")
mountLetter := GetFirstFreeLetter()
commandMount = net use %mountLetter%: %defaLocUpdate% /user:%defaultUser% %defaultPass% /p:no
LogToWindow(commandMount)
commandMountReturn := StdOutToVar(commandMount)
LogToWindow(commandMountReturn)
LogToWindow("Deleting old boot.wim")
FileDelete, %usbLetter%:\sources\boot.wim
LogToWindow("Done")
LogToWindow("Copy new boot.wim")
commandCopyNewBootWim = robocopy %mountLetter%:\media\sources\ %usbLetter%:\sources boot.wim /eta /is
commandCopyNewBootWimReturn := StdOutToVar(commandCopyNewBootWim)
LogToWindow(commandCopyNewBootWimReturn)
deleteMounts = net use %mountLetter%: /DELETE /Y
deleteMountsReturn := StdOutToVar(deleteMounts)
LogToWindow(deleteMountsReturn)
LogToWindow("Runnig latest version")
mountLetter := GetFirstFreeLetter()
mountCommand = net use %mountLetter%: %defaLocSources% /user:%defaultUser% %defaultPass% /p:no
mountCommandReturn := StdOutToVar(mountCommand)
LogToWindow(mountCommandReturn)
copyToXLoc := StdOutToVar("xcopy " mountLetter ":\WimLoader.exe x:\windows\system32 /y")

Exiting:
LogToWindow("Unmouting all")
commandUnmouting = net use %mountLetter%: /DELETE /Y
StdOutToVar(commandUnmouting)
LogToWindow("Done")
LogToWindow("Exiting...")
Sleep, 2000
Run, WimLoader.exe
ExitApp