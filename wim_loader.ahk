#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

;=====================Timers=====================
;Timer for buttons on/off
SetTimer, ButtonsControl, 300

;=====================Functions=====================

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

;Listing disks
listDisk()
{
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
        diskShow = % diskShow "|No: "diskId[2]" == Model: "model[2]" == Size: "size[2]" == Partition Type: "partitionType[2]"|"
    }
    GuiControl, Main:, diskList, %diskShow%
}

;Listing images from PCHW
loadingImages(pathToImages)
{
    ;Adding colon to path
    pathToImages = %pathToImages%:
	listImages =
	IfNotExist,%pathToImages%
	{
		MsgBox, 0x40010,, Location %pathToImages%. Please select manually.
        GuiControl, Main:, imagesList, |Select images manually
	} else
	{
        GuiControl, Main:, CurrImagePathText, Current images path: %defaLocImages%
		FileList := Object()
		Loop, Files, %pathToImages%\*.wim
		{
		    FileList.Insert(A_LoopFileShortPath)
		}
        listImages = |
        For index, element in FileList
		{
	    	listImages = %listImages%%element%|
		}
        listImages = %listImages%|
		GuiControl, Main:, imagesList, %listImages%
	}

}

;Load from USB where WINPE images
loadManually()
{
    return
}


;Display Main Window
DisplayMainWindow()
{
    Gui Main:Font, s9, Segoe UI
    Gui Main:Add, ListBox, x32 y16 w504 h147 vdiskList, ...Loading list of disk...
    Gui Main:Add, ListBox, x32 y208 w503 h225 vimagesList, ...Loading list of images...
    Gui Main:Add, Button, x32 y160 w80 h23 gFormatDisk vButtonFormatDisk Disabled, Format Disk
    Gui Main:Add, Button, x32 y432 w80 h23 gButtonInstallImage vInstallImage Disabled, Install image
    Gui Main:Add, Button, x456 y160 w80 h23 gButtonRefreshDisks, Refresh Disks
    Gui Main:Add, Text, x25 y497 w200 h23 +0x200, Version %version% - Copyright Miasik Jakub
    Gui Main:Add, Text, x120 y432 w200 h22 +0x200 vCurrImagePathText
    Gui Main:Font
    Gui Main:Font, s8
    Gui Main:Add, Button, x456 y432 w80 h23 gButtonRefreshImages, Refresh Images
    Gui Main:Add, Button, x456 y456 w80 h23 gButtonLoadManually, Load manually
    Gui Main:Font
    Gui Main:Font, s9, Segoe UI
    Gui Main:Show, w563 h526, WIM Loader
}

;Get first free letter drive
GetFirstFreeLetter()
{
    freeDiskLetter := StdOutToVar("powershell ls function:[h-u]: -n | ?{ !(test-path $_) } | select -first 1")
	freeDiskLetter := RegExReplace(freeDiskLetter, "\r\n", "")
	freeDiskLetter := RegExReplace(freeDiskLetter, ":", "")
	return freeDiskLetter
}

;Format disk
FormatDisk(diskId)
{
    GuiControl, Main:, diskList, |...Clearing disk ID: %diskId%...
    Sleep, 100
    clearInfo := StdOutToVar("powershell Get-Disk " diskId " | Clear-Disk -RemoveData -Confirm:$false")
    GuiControl, Main:, diskList, |...Formating disk ID: %diskId%...
    Sleep, 100
    formatInfo := StdOutToVar("powershell Get-Disk | Where-Object Number -Eq " diskId " | Initialize-Disk -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume")
}

;Check if disk in list is selected
CheckIfDiskSelected()
{
    GuiControlGet, diskInfo,,diskList
    If (diskInfo="")
    {
        MsgBox, 4144, Info, Select any disk
        return 0
    }
}

ButtonsControl()
{
    GuiControlGet, diskInfoCheck, Main:, diskList
    If (diskInfoCheck = "")
    {
        GuiControl Main: Disable, ButtonFormatDisk
    } else
    {
        GuiControl Main: Enable, ButtonFormatDisk
    }
    GuiControlGet, imagesCheck, Main:, imagesList
    If (imagesCheck = "")
    {
        GuiControl Main: Disable, InstallImage
    } else
    {
        GuiControl Main: Enable, InstallImage
    }
}

;=====================Script START=====================
;=====================Variables=====================
global version = "0.0.1"
global diskList
global imagesList
global ButtonRefreshDisks
global ButtonRefreshImages
global CurrImagePathText
global ButtonFormatDisk
global InstallImage
global defaLocImages = "\\pchw\images"
defaLocImagesUser = images
defaLocImagesPass = "123edc!@#EDC"

;Display Main Window
DisplayMainWindow()

;Load disk to main window and display them
listDisk()

;Get free letter to mount default location for images
defLocLett := GetFirstFreeLetter()

;Connect to default location and assign letter
RunWait, net use %defLocLett%: %defaLocImages% /user:%defaLocImagesUser% %defaLocImagesPass% /p:no,, Min

;Load wims to main window and display them
loadingImages(defLocLett)
return

;Load images on startup app or refresh on demand
ButtonRefreshDisks:
GuiControl, Main:, diskList, |...Wait please...
Sleep, 100 ;Only for see above
listDisk()
return

;Refresh list of images on demand
ButtonRefreshImages:
GuiControl, Main:, imagesList, |...Wait please...
Sleep, 100 ;Only for see text above
loadingImages(defLocLett)
return

ButtonInstallImage:
GuiControlGet, images,, imagesList
MsgBox  % images
return

;Format selected disk
FormatDisk:
checkSelectedDisk := CheckIfDiskSelected()
If (checkSelectedDisk = 0)
    return
MsgBox, 4148, Warning, Disk will be formated. Are you sure?
IfMsgBox No
{
    return
} else {
    GuiControlGet, diskInfo,,diskList
    RegExMatch(diskInfo,"[0-9]{1}",diskId)
    FormatDisk(diskId)
    listDisk()
}
return

;Load images from USB drive where winpe PE exist
ButtonLoadManually:
loadManually()
return

MainGuiEscape:
MainGuiClose:
    ;Delete letter od default location of defLocLett variable
    RunWait, net use %defLocLett%: /DELETE,, Min
    ExitApp