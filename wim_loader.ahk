#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

;=====================Functions=====================
;Listing disks
listDisk()
{
    diskShow =
    diskList := ComObjCreate("WScript.Shell").Exec("powershell -WindowStyle Minimized Get-Disk | Format-List").StdOut.ReadAll()
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
    Gui Main:Add, Button, x32 y464 w80 h23 gFormatDisk, Format Disk
    Gui Main:Add, Button, x120 y464 w80 h23 gButtonInstallImage, Install image
    Gui Main:Add, Button, x456 y160 w80 h23 gButtonRefreshDisks, Refresh Disks
    Gui Main:Add, Text, x25 y497 w200 h23 +0x200, Version %version% - Copyright Miasik Jakub
    Gui Main:Add, Text, x33 y425 w250 h22 +0x200 vCurrImagePathText
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
	freeDiskLetter := ComObjCreate("WScript.Shell").Exec("powershell -WindowStyle Minimized ls function:[h-u]: -n | ?{ !(test-path $_) } | select -first 1").StdOut.ReadAll()
	freeDiskLetter := RegExReplace(freeDiskLetter, "\r\n", "")
	freeDiskLetter := RegExReplace(freeDiskLetter, ":", "")
	return freeDiskLetter
}

;Format disk
FormatDisk(diskId)
{
    RunWait, powershell.exe -Command "& {Get-Disk %diskId% | Clear-Disk -RemoveData -Confirm:$false;}"
    readOut := ComObjCreate("WScript.Shell").Exec("powershell -WindowStyle Minimized Get-Disk | Where-Object Number -Eq %diskId% | Initialize-Disk -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume").StdOut.ReadAll()
}

;=====================Script START=====================
;=====================Variables=====================
global version = "0.0.1"
global diskList
global imagesList
global ButtonRefreshDisks
global ButtonRefreshImages
global CurrImagePathText
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
Sleep, 100 ;Only for see text wait please
listDisk()
return

;Refresh list of images on demand
ButtonRefreshImages:
GuiControl, Main:, imagesList, |...Wait please...
Sleep, 100 ;Only for see text wait please
loadingImages(defLocLett)
return

ButtonInstallImage:
GuiControlGet, images,, imagesList
MsgBox  % images
return

;Format selected disk
FormatDisk:
MsgBox, 4148, Warning, Disk will be formated. Are you sure?
IfMsgBox No
{
    return
} else {
    GuiControlGet, diskInfo,,diskList
    RegExMatch(diskInfo,"[0-9]{1}",diskId)
    FormatDisk(diskId)
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