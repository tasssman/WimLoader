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

;Get first free letter drive without comma
GetFirstFreeLetter()
{
    freeDiskLetter := StdOutToVar("powershell ls function:[h-u]: -n | ?{ !(test-path $_) } | select -first 1")
	freeDiskLetter := RegExReplace(freeDiskLetter, "\r\n", "")
    freeDiskLetter := RegExReplace(freeDiskLetter, ":", "")
	return freeDiskLetter
}

ProgressGui(textStatus)
{
	Gui, Progress:Add, Progress, w200 h20 -Smooth vProgressBar
	Gui, Progress:Add,Text,vStatus w200 h20, %textStatus%
	Gui, Progress:Show, AutoSize, Progress
	Gui, Progress:-Caption
	WinSet, AlwaysOnTop, , Progress
	Sleep, 100
	Return
}

ProgressGuiAddStep(setProgress, changeText)
{
	Loading:
    GuiControl, Progress:, ProgressBar, %setProgress%
	if (changeText != "")
	{
		GuiControl, Progress:, Status, %changeText%
	}
	Sleep, 100
    WinSet, AlwaysOnTop, , Progress
	return
}

;=====================Script START=====================
;=====================Variables=====================
MsgBox 0x40030, , Please DO NOT remove USB stick
global ProgressBar
global Status
defaLocUpdate = "\\pchw\images\sources"
defaultUser = images
defaultPass = "123edc!@#EDC"
updateFileUpdate = WimLoader.exe
disk := "c,d,e,f,g,h,i,j,k,l,m,o,p"

ProgressGui("Mounting location...")
mountLetter := GetFirstFreeLetter()
RunWait, net use %mountLetter%: %defaLocUpdate% /user:%defaultUser% %defaultPass% /p:no,, Min
ProgressGuiAddStep("10", "Searching for usb stick ...")
Loop, Parse, disk, `,
{
	usbLetter := A_LoopField
	pathToBootWim := A_LoopField . ":\sources\boot.wim"
	if FileExist(pathToBootWim)
	{
		Goto, Continue
	}
}

Continue:
ProgressGuiAddStep("20", "Searching for place ...")
Loop, Parse, disk, `,
{
	diskLetter := A_LoopField
	disk = ""\"DeviceID='%diskLetter%:'\"""
	freeSpace := StdOutToVar("powershell Get-WmiObject Win32_LogicalDisk -Filter " disk " | Foreach-Object {$_.FreeSpace/1GB}")
	if (freeSpace > 4)
	{
		dirForMountWim := diskLetter . ":\mount"
		FileCreateDir, %dirForMountWim%
		ProgressGuiAddStep("60", "Mounting WIM ...")
		mount := StdOutToVar("dism /Mount-image /imagefile:" pathToBootWim " /Index:1 /MountDir:" dirForMountWim " ")
		destMountCopy := dirForMountWim . "\Windows\system32"
		ProgressGuiAddStep("80", "Copying files ...")
		copyToMountLoc := StdOutToVar("xcopy " mountLetter ":\WimLoader.exe " destMountCopy " /y")
		copyToXLoc := StdOutToVar("xcopy " mountLetter ":\WimLoader.exe x:\windows\system32 /y")
		ProgressGuiAddStep("80", "Dismount in progress ...")
		dismount := StdOutToVar("dism /Unmount-image /MountDir:" dirForMountWim " /commit")
		ProgressGuiAddStep("100", "Exiting ...")
		Sleep, 1000
		Goto, Exiting
	}
}

Exiting:
Gui, Progress: Destroy
RunWait, net use %mountLetter%: /DELETE /Y
Sleep, 2000
Run, WimLoader.exe
ExitApp