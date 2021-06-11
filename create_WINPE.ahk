#SingleInstance, force
;Functions
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


;Get first free letter drive
GetFirstFreeLetter()
{
	freeDiskLetter := StdOutToVar("powershell -windowstyle hidden ls function:[h-z]: -n | ?{ !(test-path $_) } | select -first 1")
	freeDiskLetter := RegExReplace(freeDiskLetter, "\r\n", "")
	freeDiskLetter := RegExReplace(freeDiskLetter, ":", "")
	return freeDiskLetter
}

MenuFormat(listdisks)
{
	Gui, CreateWINPE: +AlwaysOnTop
	Gui, CreateWINPE:Add, ListBox, x15 y25 w535 h186 vListaDyskow, %listdisks%
	Gui, CreateWINPE:Add, Button, x15 y220 w115 h45 gCreateWinpe vCreateWinpeButton, Create WINPE
	Gui, CreateWINPE:Add, Button, x152 y220 w115 h45 gUpdateWinpe vUpdateWinpeButton, Update WINPE
	;Gui, CreateWINPE:Add, Button, x292 y220 w115 h50 , Copy Images
    Gui, CreateWINPE:Add, Text, x16 y270 w89 h15 +0x200, %version%
	Gui, CreateWINPE:Add, Button, x435 y220 w115 h50 gButtonClose vCloseButton, Close
	Gui, CreateWINPE:Show, w565 h290, WINPE Creator
	return
}

WaitWindow(text)
{
	Gui, Wait: +AlwaysOnTop +Disabled -SysMenu +Owner  ; +Owner avoids a taskbar button.
	Gui, Wait:Font, s20
	Gui, Wait:Add, Text,w200 Center, %text%
	Gui, Wait:-Caption
	Gui, Wait:Show, NoActivate
}

CheckIfpathExist(patchWinpe)
{
	;Check for path if exist
	if (!FileExist(patchWinpe))
	{
		MsgBox, 4112, Not found, Localization %patchWinpe% NOT EXIST!`nExiting app.
		return
	}
}

ProgressGui(textStatus)
{
	Gui, Progress:Add, Progress, w200 h20 -Smooth vProgressBar
	Gui, Progress:Add,Text,vStatus w200 h20, %textStatus%
	Gui, Progress:Show, AutoSize, Progress
	Gui, Progress:-Caption
	WinSet, AlwaysOnTop, , Progress,
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
	return
}
ProgressGui("Loading Disks")
ProgressGuiAddStep("25","")
;Start script=====================================================
;Globals==============================
global patchWinpe
global ListaDyskow
global CreateWinpeButton
global UpdateWinpeButton
global CloseButton
global version
global ProgressBar
global Status
;Variables==============================
version = Version 1.0.0.0
;Credentials for winpeupdate
user_winpe = images
pass_winpe := "123edc!@#EDC"

;Path for copy winpe
patchWinpe = \\pchw\winpe\media

;Take disk data from local PC
ProgressGuiAddStep("50", "")
diskShow =
diskList := StdOutToVar("powershell Get-Disk | Format-List")
StringReplace, diskList, diskList, `n, , All
pos = 1
While pos := RegExMatch(diskList,"UniqueId.*?IsBoot",disk, pos+StrLen(disk))
{
	RegExMatch(disk,"O)(Number.*?: )(.*)(Path)",diskId)
	RegExMatch(disk,"O)(Model.*?: )(.*)(Serial)",model)
	RegExMatch(disk,"O)(Size.*?: )(.*)(Allocated)",size)
	RegExMatch(disk,"O)(PartitionStyle.*?: )(.*)(IsReadOnly)",partitionType)
	diskShow = % diskShow "No: "diskId[2]" === Model: "model[2]" === Size: "size[2]" === Partition Type: "partitionType[2]"|"
}
ProgressGuiAddStep("100", "")
MenuFormat(diskShow)
Gui, Progress: Destroy
return

;~ Creating pendrive
CreateWinpe:
GuiControl,CreateWINPE:Disable, CreateWinpeButton
GuiControl,CreateWINPE:Disable, UpdateWinpeButton
GuiControl,CreateWINPE:Disable, CloseButton
Sleep, 100
;CheckIfpathExist(patchWinpe)
GuiControlGet, diskToFormat,,ListaDyskow
RegExMatch(diskToFormat,"[0-9]{1}",idToFormat)
if (idToFormat != "")
{
	ProgressGui("Clearing disk...")
	ProgressGuiAddStep("15", "")
	clearDisk := StdOutToVar("powershell Clear-Disk " idToFormat " -RemoveData -Confirm:$false")
	ProgressGuiAddStep("30", "Initializing disk...")
	InitDisk := StdOutToVar("powershell Get-Disk " idToFormat " | Initialize-Disk -PartitionStyle MBR")
	partiWinpe := GetFirstFreeLetter()
	ProgressGuiAddStep("50", "Formating first partition...")
	command = New-Partition -DiskNumber %idToFormat% -Size 2048MB -IsActive -DriveLetter %partiWinpe% | Format-Volume -FileSystem FAT32 -NewFileSystemLabel WINPE
	RunWait, powershell.exe -Command "& {%command%}"
	partiImages := GetFirstFreeLetter()
	ProgressGuiAddStep("75", "Formating second partition...")
	command = New-Partition -DiskNumber %idToFormat% -UseMaximumSize -DriveLetter %partiImages% | Format-Volume -FileSystem NTFS -NewFileSystemLabel Images
	RunWait, powershell.exe -Command "& {%command%}"
	ProgressGuiAddStep("100", "Formating done...")
	Gui, Progress: Destroy
} else {
	MsgBox, 4144, Select, Select ANY disk
	return
}
;Get first free letter for pchw na mount it
mountPchwLett := GetFirstFreeLetter()
mountDest := StdOutToVar("net use " mountPchwLett ": " patchWinpe " /user:" user_winpe " " pass_winpe "")
RunWait, robocopy %mountPchwLett%:\ %partiWinpe%:\ /e /bytes

FileCreateDir, %partiImages%:\Images
GuiControl,Enable, CreateWinpeButton
GuiControl,Enable, UpdateWinpeButton
GuiControl,Enable, CloseButton
MsgBox, 64, Done!, WinPE is created
return

UpdateWinpe:
GuiControl,Disable, CreateWinpeButton
GuiControl,Disable, UpdateWinpeButton
GuiControl,Disable, CloseButton
CheckIfpathExist(patchWinpe)
GuiControlGet, diskToFormat,,ListaDyskow
RegExMatch(diskToFormat,"[0-9]{1}",idToUpdate)
if (idToUpdate != "")
{
	diskLetter := ComObjCreate("WScript.Shell").Exec("powershell -windowstyle hidden Get-Disk " idtoUpdate " | Get-Partition | Select-Object DriveLetter | Format-Custom").StdOut.ReadAll()
	pos = 1
	While pos := RegExMatch(diskLetter,"DriveLetter.*",partitionId, pos+StrLen(partitionId))
	{
		RegExMatch(partitionId,"(?<= = )[A-Z]{1}",letter)
		pathToBootWim = %letter%:\sources\boot.wim
		if (FileExist(pathToBootWim))
		{
			RunWait, powershell.exe -Command $secpasswd = ConvertTo-SecureString 'pass_winpe' -AsPlainText -Force;$mycreds = New-Object System.Management.Automation.PSCredential('%user_winpe%'`, $secpasswd);New-PSDrive -Name 'winpe' -PSProvider 'FileSystem' -Root %patchWinpe% -credential $mycred;Copy-Item winpe:\sources\boot.wim %pathToBootWim% -verbose -Recurse
			MsgBox, 64, Done!, WinPE is updated.
		}
	}
} else {
	MsgBox, 4144, Select, Select ANY disk
	return
}
GuiControl,Enable, CreateWinpeButton
GuiControl,Enable, UpdateWinpeButton
GuiControl,Enable, CloseButton
return

ButtonClose:
GuiEscape:
CreateWINPEGuiClose:
unmountPchw := StdOutToVar("net use " mountPchwLett ": /DELETE /YES")
Gui, CreateWINPE:Destroy
ExitApp