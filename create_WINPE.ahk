#SingleInstance, force
SetWorkingDir, %A_ScriptDir%
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

listDisk()
{
    diskList := StdOutToVar("powershell Get-Disk | Where-Object {$_.Bustype -Eq 'USB'} | Format-List")
    StringReplace, diskList, diskList, `n, , All
    pos = 1
    While pos := RegExMatch(diskList,"UniqueId.*?IsBoot",disk, pos+StrLen(disk))
    {
        RegExMatch(disk,"O)(Number.*?: )(.*)(Path)",diskId)
        RegExMatch(disk,"O)(Model.*?: )(.*)(Serial)",model)
        RegExMatch(disk,"O)(Size.*?: )(.*)(Allocated)",size)
        RegExMatch(disk,"O)(PartitionStyle.*?: )(.*)(IsReadOnly)",partitionType)
        diskShow = % diskShow "ID: "diskId[2]" == Model: "model[2]" == Size: "size[2]" == Partition Type: "partitionType[2]""
    }
    return diskShow
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

GetFreeLetters(amount)
{
    freeDiskLetters := StdOutToVar("powershell (ls function:[h-u]: -n | ?{ !(test-path $_) } | select -first " amount ") -join ';' ")
	freeDiskLetters := RegExReplace(freeDiskLetters, "\r\n", "")
    freeDiskLetters := RegExReplace(freeDiskLetters, ":", "")
	freeDiskLetters := StrSplit(freeDiskLetters, ";")
	return freeDiskLetters
}

formatForWim(diskNumber)
{
	wimPartToFile := StrReplace(usbFormat, "disk_number", diskNumber)
	letters := GetFreeLetters(2)
	wimPartToFile := StrReplace(wimPartToFile, "first_letter", letters[1])
	winpeLocation := letters[1]
	wimPartToFile := StrReplace(wimPartToFile, "second_letter", letters[2])
	FileDelete, wim_format.txt
	FileAppend, %wimPartToFile%, wim_format.txt
	RunWait, diskpart /s %A_ScriptDir%\wim_format.txt
	return winpeLocation
}

;Variables==============================
usbFormat =
(
	select disk disk_number
	clean
	create partition primary size=2048
	active
	format fs=FAT32 quick label="WinPE"
	assign letter=first_letter
	create partition primary
	format fs=NTFS quick label="Images"
	assign letter=second_letter
	Exit
)

;Globals==============================
global ProgressBar
global Status
global usbFormat

;Start script=====================================================
ProgressGui("Loading Disks...")
ProgressGuiAddStep("25","")
disks := listDisk()
Gui, Progress: Destroy
InputBox, diskToFormat, Choose disk to format, Enter ID to format disk `n`r %disks%,,500,500
If ErrorLevel
{
	ExitApp
}
ProgressGui("Formating for winPE...")
ProgressGuiAddStep("50","")
sourceCopyWinPEFiles := formatForWim(diskToFormat)
ProgressGuiAddStep("50","Copying WINPE")
RunWait, xcopy \\pchw\winpe\media\ %sourceCopyWinPEFiles%:\ /y /e
Gui, Progress: Destroy
MsgBox,,, Done
ExitApp