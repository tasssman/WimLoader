#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

;=====================Timers=====================
;Timer for buttons on/off
SetTimer, ButtonsControl, 300

;=====================Functions=====================

;Reading output from command
StdOutToVar(cmd) {
    ;Log cmd command
    FormatTime, timeCmd,,yyyy-MM-dd_HH:mm:ss
    CmdText = %timeCmd% - %cmd%
    CmdText := RegExReplace(CmdText, "\r\n", " ")
    FileAppend, `n============CMD Start==============`n%CmdText%`n, wimlog_%uniqFileName%_StdOutput.txt

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
    ;Log output
    FormatTime, timeOutput,,yyyy-MM-dd_HH:mm:ss
    FormatTime, timeFile,,yyyy-MM-dd
    OutputText = %timeOutput% - %sOutput%
    OutputText := RegExReplace(OutputText, "\r\n", " ")
    FileAppend, %OutputText%, wimlog_%uniqFileName%_StdOutput.txt
	return sOutput
}

;Logger
Log(text)
{
    FormatTime, timeNow,,yyyy-MM-dd_HH:mm:ss
    textToLog = %timeNow%  %text%
    FileAppend, %textToLog%`n, wimlog_%uniqFileName%.txt
}

;Listing disks
listDisk()
{
    Log("Loading disks")
    diskShow =
    GuiControlGet, usbcheck,,UsbCheckbox
    if (usbcheck = 1)
    {
        diskList := StdOutToVar("powershell Get-Disk | Format-List")
    } else {
        diskList := StdOutToVar("powershell Get-Disk | Where-Object -FilterScript {$_.Bustype -notcontains 'usb'} | Format-List")
    }
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
    Log(diskShow)
}

;Listing images from PCHW
loadingImages(pathToImages)
{
    Log("Loading images")
    ;Adding colon to path
    pathToImages = %pathToImages%:
	listImages =
	IfNotExist,%pathToImages%
	{
        Log("Path to images not found")
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
        Log("Loaded list of images")
	}

}

;Load from USB where WINPE images
loadManually()
{
    Log("Start manually load image")
    FileSelectFile, selectedWim, 3, , Load wim manually, Windows Image (*.wim)
    if (selectedWim = "")
    {
        MsgBox, The user didn't select anything.
    }
    else
    {
        GuiControlGet, Mode
        diskInstall := InstallDiskNumber()
        Log("Selected disk "diskInstall)
        if Mode = UEFI Format
        {
            lettersDisks := UEFIFormat(diskInstall)
        } else if Mode = LEGACY Format
        {
            lettersDisks := LEGACYFormat(diskInstall)
        }
        InstallImage(selectedWim, lettersDisks)
    }
    Log("End manually load")
    return
}


;Display Main Window
DisplayMainWindow()
{
    Log("Loading main window")
    ;Menu loading
    Gui Main: New
    Menu, Options, Add, Open WIM log, OpenWimlog
    Menu, Options, Add, Open StdOut log, OpenStdOutlog
    Menu, BarMenu, Add, Options, :Options
    Menu, About, Add, Update App, UpdateApp
    Menu, BarMenu, Add, About, :About
    Gui Main:Menu, BarMenu
    ;Gui loading
    Gui Font, s9, Segoe UI
    Gui Add, ListBox, x32 y16 w425 h134 vdiskList, ...Loading list of disk...
    Gui Add, ListBox, x32 y208 w425 h212 vimagesList, ...Loading list of images...
    Gui Add, Button, x288 y160 w80 h23 gFormatDisk vButtonFormatDisk Disabled, Format Disk
    Gui Add, Button, x32 y432 w80 h23 gButtonInstallImage vInstallImage Disabled, Install image
    Gui Add, CheckBox, x32 y165 w120 h20 vUsbCheckbox gRunCheckUsb, Show USB drives
    Gui Add, Button, x376 y160 w80 h23 gButtonRefreshDisks, Refresh Disks
    Gui Add, DropDownList, x32 y459 w100 vMode, UEFI Format||LEGACY Format
    Gui Add, Text, x24 y504 w57 h23 +0x200 , IP Address:
    Gui Add, Text, x88 y504 w91 h23 +0x200 vip
    Gui Add, Button, x184 y504 w80 h23 gButtonRenew, Renew IP
    Gui Add, Text, x25 y531 w250 h23 +0x200, Version %version% - Copyright Miasik Jakub
    Gui Add, Text, x120 y432 w200 h22 +0x200 vCurrImagePathText
    Gui Font
    Gui Font, s8
    Gui Add, Button, x376 y432 w80 h30 gButtonRefreshImages, Refresh Images
    Gui Add, Button, x376 y464 w80 h23 gButtonLoadManually, Load manually
    Gui Font
    Gui Font, s9, Segoe UI
    Gui Add, Edit, x464 y16 w305 h536 +ReadOnly +Multi vLogWindow
    Gui Show, w777 h558, WIM Loader
}

;Get first free letter drive without comma
GetFirstFreeLetter()
{
    freeDiskLetter := StdOutToVar("powershell ls function:[k-u]: -n | ?{ !(test-path $_) } | select -first 1")
	freeDiskLetter := RegExReplace(freeDiskLetter, "\r\n", "")
    freeDiskLetter := RegExReplace(freeDiskLetter, ":", "")
    Log("First free letter: "freeDiskLetter)
	return freeDiskLetter
}

;Letters with comma in array
GetFreeLetters(amount)
{
    freeDiskLetters := StdOutToVar("powershell (ls function:[k-u]: -n | ?{ !(test-path $_) } | select -first " amount ") -join ';' ")
	freeDiskLetters := RegExReplace(freeDiskLetters, "\r\n", "")
    freeDiskLetters := RegExReplace(freeDiskLetters, ":", "")
	freeDiskLetters := StrSplit(freeDiskLetters, ";")
    Log("Get free letters")
	return freeDiskLetters
}

;Format disk
FormatDisk(diskId)
{
    Log("Formating disk ID: " diskId)
    format =
    (
        select disk disk_number
        clean
        convert gpt
        create partition primary
        format quick fs=ntfs
        assign
        exit
    )
    GuiControl, Main:, diskList, |...Formating disk ID: %diskId%...
    Sleep, 100
    formatToFile := StrReplace(format, "disk_number", diskId)
    FileDelete, x:\format_disk.txt
    FileAppend, %formatToFile%, x:\format_disk.txt
    formatDisk := StdOutToVar("diskpart /s x:\format_disk.txt")
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

InstallImage(imageFile, disksLetters)
{
    Log("Selected image file: "imageFile)
    Log("Windows system letter: "windowsLetter)
    Log("System letter: "systemLetter)
    windowsLetter := disksLetters["winLetter"]
    systemLetter := disksLetters["sysLetter"]
    Log("dism apply image start")
    RunWait, dism /apply-image /imagefile:%imageFile% /index:1 /applydir:%windowsLetter%:\ /NoRpFix,,Min
    Log("dism apply image end")
    Log("bcdboot copy")
    RunWait, %windowsLetter%:\Windows\System32\bcdboot %windowsLetter%:\Windows /s %systemLetter%:
    MsgBox, 64, Reset, Will be Reset after OK is pressed or in 5 sec, 5
    Log("Rebooting")
    Run, wpeutil Reboot,,Min

}

InstallDiskNumber()
{
    GuiControlGet, diskInstallID,,diskList
    RegExMatch(diskInstallID,"[0-9]{1}",diskInstallID)
    return diskInstallID
}

UEFIFormat(diskIdToFormat)
{
    Log("Loaded UEFI diskpart format")
    uefi_partitions =
    (
        select disk disk_number
        clean
        convert gpt
        rem == 1. System partition =========================
        create partition efi size=100
        format quick fs=fat32 label="System"
        assign letter="first_letter"
        rem == 2. Microsoft Reserved (MSR) partition =======
        create partition msr size=16
        rem == 3. Windows partition ========================
        create partition primary
        format quick fs=ntfs label="Windows"
        assign letter="second_letter"
        exit
    )
    uefiPartiToFile := StrReplace(uefi_partitions, "disk_number", diskIdToFormat)
    letters := GetFreeLetters(2)
    uefiPartiToFile := StrReplace(uefiPartiToFile, "first_letter", letters[1])
    systemLetter :=  letters[1]
    uefiPartiToFile := StrReplace(uefiPartiToFile, "second_letter", letters[2])
    windowsLetter :=  letters[2]
    FileDelete, x:\uefi_format.txt
    FileAppend, %uefiPartiToFile%, x:\uefi_format.txt
    formatUefi := StdOutToVar("diskpart /s x:\uefi_format.txt")
    formatLetters := {sysLetter:systemLetter, winLetter:windowsLetter}
    return formatLetters
}

LEGACYFormat(diskIdToFormat)
{
    Log("Loaded LEGACY diskpart format")
    legacy_partitions =
    (
        select disk disk_number
        clean
        rem == 1. System partition =========================
        create partition efi size=100
        format quick fs=fat32 label="System"
        assign letter="first_letter"
        rem == 2. Microsoft Reserved (MSR) partition =======
        create partition msr size=16
        rem == 3. Windows partition ========================
        create partition primary
        format quick fs=ntfs label="Windows"
        assign letter="second_letter"
        exit
    )
    uefiPartiToFile := StrReplace(uefi_partitions, "disk_number", diskIdToFormat)
    letters := GetFreeLetters(2)
    uefiPartiToFile := StrReplace(uefiPartiToFile, "first_letter", letters[1])
    systemLetter :=  letters[1]
    uefiPartiToFile := StrReplace(uefiPartiToFile, "second_letter", letters[2])
    windowsLetter :=  letters[2]
    FileDelete, x:\uefi_format.txt
    FileAppend, %uefiPartiToFile%, x:\uefi_format.txt
    formatLegacy := StdOutToVar("diskpart /s x:\uefi_format.txt")
    formatLetters := {sysLetter:sysytemLetter, winLetter:windowsLetter}
    return formatLetters
}

getServiceTagPC()
{
    PCTag := StdOutToVar("powershell Get-WmiObject win32_SystemEnclosure | select serialnumber | ft -HideTableHeaders")
    PCTag := RegExReplace(PCTag, "\r\n", "")
    PCTag := RegExReplace(PCTag, " ", "")
    return PCtag
}

getProcessorInfo()
{
    processorInfo := StdOutToVar("powershell Get-WmiObject Win32_Processor | select Name | ft -HideTableHeaders")
    processorInfo := RegExReplace(processorInfo, "\R+\R", "`r`n")
    return processorInfo
}

getRamInfo()
{
    ramInfo := StdOutToVar("powershell Get-WmiObject Win32_PhysicalMemory | Select-Object SerialNumber, Capacity, Configuredclockspeed | Format-List")
    ramInfo := RegExReplace(ramInfo, "\R+\R", "`r`n")
    return ramInfo
}

generUniqFileName()
{
    FormatTime, timeFile,,yyyy_MM_dd_HH_mm_ss
    return timeFile
}

delAllConn()
{
    StdOutToVar("net use * /DELETE /Y")
}

IpCheck()
{
    ipAddress := StdOutToVar("powershell gwmi Win32_NetworkAdapterConfiguration | Where { $_.IPAddress } | Select -Expand IPAddress | Where { $_ -like '172.29.*' }")
    ipAddress := RegExReplace(ipAddress, "\r\n", " ")
    return ipAddress
}

IpTextUpdate()
{
    GuiControl, Main:, ip, %AddressIp%
}

renewIpAddress()
{
    GuiControl Main: Disable, ButtonRenew
    GuiControl, Main:, ip,  Wait please...
    StdOutToVar("ipconfig /renew")
    IpCheck()
    IpTextUpdate()
    GuiControl Main: Enable, ButtonRenew
}

LogToWindow(text)
{
	FormatTime, timeNow,,yyyy-MM-dd_HH:mm:ss
	textLog = %textLog%`r`n%timeNow% - %text%
	GuiControl, Main:, LogWindow, %textLog%
    SendMessage,0x115,7,0,Edit1,WIM Loader
}

;=====================Script START=====================
;Generate unique name of file
uniqFileName := generUniqFileName()
;Get service tag
serviceTag := getServiceTagPC()
;=====================Variables=====================
global version = "1.0.0.3"
Log("Script version: "version)
global diskList
global imagesList
global ButtonRefreshDisks
global ButtonRefreshImages
global CurrImagePathText
global ButtonFormatDisk
global InstallImage
global Status
global Mode
global serviceTag
global uniqFileName
global UsbCheckbox
global AddressIp
global ip
global ButtonRenew
global textLog
global LogWindow
global Processor
global RAM
global defaLocImages = "\\pchw\images"
defaLocImagesUser = cos\images
defaLocImagesPass = 123edc!@#EDC
updateLocFile = \sources\WimLoader.exe

Log("=========================Script started for " serviceTag "=====================================")
;Display Main Window
LogToWindow("Generating main window...")
DisplayMainWindow()
;Get hardware info
LogToWindow("Getting info about processor and RAM")
processor := getProcessorInfo()
ram := getRamInfo()
LogToWindow(processor)
LogToWindow(ram)

;Load disk to main window and display them
LogToWindow("Listing disk...")
listDisk()
;Get IP ipAddress
LogToWindow("Waiting for network...")
AddressIp := IpCheck()
LogToWindow(AddressIp)
IpTextUpdate()
;Get free letter to mount default location for images
defLocLett := GetFirstFreeLetter()

;Connect to default location and assign letter
LogToWindow("Connecting to IMAGES...")
Log("Connecting to: "defaLocImages)
defaultLoc := StdOutToVar("net use " defLocLett ": " defaLocImages " /user:" defaLocImagesUser " " defaLocImagesPass " /p:no")

;Load wims to main window and display them
LogToWindow("Loading images...")
loadingImages(defLocLett)

;Check for updates
LogToWindow("Checking for updates...")
Log("Checking for update")

IfExist, %defLocLett%:%updateLocFile%
{
    FileGetVersion, wimLoaderVer , %defLocLett%:%updateLocFile%
    if (wimLoaderVer == version)
    {
        Log("Update not found")
        LogToWindow("No updates found...")
        return
    } Else
    {
        Log("Update found")
        LogToWindow("Update found...")
        Gui Main:Add, Button, x340 y515 w120 h33 gButtonUpdateApp, Update App!`nto %wimLoaderVer%
    }
}
return

;Load images on startup app or refresh on demand
ButtonRefreshDisks:
LogToWindow("Refreshing disks...")
GuiControl Main: Disable, ButtonFormatDisk
GuiControl, Main:, diskList, |...Wait please...
Sleep, 100 ;Only for see above
listDisk()
GuiControl Main: Enable, ButtonFormatDisk
LogToWindow("Done")
return

;Refresh list of images on demand
ButtonRefreshImages:
LogToWindow("Refreshing images...")
Log("Images refresh demand")
GuiControl, Main:, imagesList, |...Wait please...
Sleep, 100 ;Only for see text above
loadingImages(defLocLett)
LogToWindow("Done")
return

ButtonInstallImage:
LogToWindow("Starting install proccess...")
Log("Install image by user")
GuiControlGet, Mode
diskInstall := InstallDiskNumber()
if Mode = UEFI Format
{
    LogToWindow("Formating to UEFI...")
    lettersDisks := UEFIFormat(diskInstall)
} else if Mode = LEGACY Format
{
    LogToWindow("Formating to LEGACY...")
    lettersDisks := LEGACYFormat(diskInstall)
}
GuiControlGet, imageToInstall,, imagesList ;global variable
LogToWindow("Loading " . imageToInstall . " to disk " . lettersDisks)
LogToWindow("Loading. Please wait...")
InstallImage(imageToInstall, lettersDisks)
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
    LogToWindow("Formating disk ID " . diskId . " Please wait...")
    FormatDisk(diskId)
    LogToWindow("Done")
    listDisk()
}
return

;Load images from USB drive where winpe PE exist
ButtonLoadManually:
loadManually()
return

RunCheckUsb:
Goto, ButtonRefreshDisks
Return

OpenWimlog:
Run notepad.exe wimlog_%uniqFileName%.txt
return

OpenStdOutlog:
Run notepad.exe wimlog_%uniqFileName%_StdOutput.txt
return

ButtonRenew:
LogToWindow("Renew IP address in progress...")
renewIpAddress()
LogToWindow("Done")
return

ButtonUpdateApp:
UpdateApp:
LogToWindow("Updating app...")
Log("Update script started")
copyAutoUpdate := StdOutToVar("xcopy " defLocLett ":\sources\wimautoupdate.exe x:\windows\system32 /y")
delAllConn()
Run, wimautoupdate.exe
MainGuiEscape:
MainGuiClose:
    Log("Script closed")
    ;Delete letter od default location of defLocLett variable
    delAllConn()
    ExitApp