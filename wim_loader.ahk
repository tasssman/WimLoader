#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Input"
SetWorkingDir A_ScriptDir

#Include lib\RunCmd.ahk

;=====================Globals=====================
global iniPath
global textLog := ""
global disksToFormat := []
;=====================Defined variables=====================
verLatestToDisp := ""
verLatestFile := ""
verCurrent := ""
defaLocImages := "\\pchw\images"
defaLocImagesUser := "cos\images"
defaLocImagesPass := "123edc!@#EDC"
updateFolLoc := "\sources\"
iniName := "wimloader.ini"
version := "2.2.0"
;=====================Functions=====================

LogToWindow(message, timeLine := 0, CR := 0, onlyLog := 0) ;timeLine (default 0) if "1" than time is added; CR default 0. Number constitutes how many "enters" append after text.
{
    global LogWindow
    
    ;Add enter lines
    enterNum := ""
    if CR > 0 {
        Loop CR {
            enterNum := "`r`n" . enterNum
        }
    }

    ;Add time line
    if timeLine = 1 {
        time := FormatTime(,"HH:mm:ss")
        message := time . ": " . message . enterNum
    } else {
        message := message . enterNum
    }

    ;Add text to log    
    logTime := FormatTime(,"yyyy-MM-dd_hh:mm:ss")
    fileLog := A_ScriptDir . "\log.txt"
    FileAppend("[" . logTime . "]" . " " . message, fileLog)
    
    if(onlyLog = 0) {
        SendMessage(0xB1, -2, -1, LogWindow) ; EM_SETSEL - originally by SKAN: sets the selection to the end of the control                                                                                                                                       ;
        SendMessage(0xC2, 0, StrPtr(message), LogWindow) ; EM_REPLACESEL
    }
}

RunCmdReturnLine(Line, LineNum, Feed)
{
    LogToWindow(Line)
}

iniPathChk()
{
    bootLoc := RegRead("HKLM\SYSTEM\ControlSet001\Control", "PEBootRamdiskSourceDrive", "noKey")
    if(bootLoc = "noKey" )
    {
        bootLoc := "x:\"
    }
    iniPath := bootLoc . iniName
    LogToWindow("INI Regex command result: " . bootLoc,1,1,1)
    LogToWindow("INI Path: " . iniPath,1,1,1)
    return iniPath
}

;Get first free letter drive without comma
GetFirstFreeLetter()
{
    freeDiskLetter := RunCMD("powershell ls function:[k-u]: -n | ?{ !(test-path $_) } | select -first 1")
    freeDiskLetter := StrReplace(freeDiskLetter, "`r`n")
    freeDiskLetter := StrReplace(freeDiskLetter, ":", "")
    LogToWindow("First free disk letter: " . freeDiskLetter,1,1,1)
	return freeDiskLetter
}

;Letters with comma in array
GetFreeLetters(amount)
{
    freeDiskLetters := RunCMD("powershell (ls function:[k-u]: -n | ?{ !(test-path $_) } | select -first " amount ") -join ';' ")
	freeDiskLetters := StrReplace(freeDiskLetters, "`r`n")
    freeDiskLetters := StrReplace(freeDiskLetters, ":", "")
	freeDiskLetters := StrSplit(freeDiskLetters, ";")
    for index, value in freeDiskLetters
    {
        LogToWindow("First free disk letter: " . value,1,1)
    }
	return freeDiskLetters
}

getServiceTagPC()
{
    PCTag := RunCMD("powershell Get-WmiObject win32_SystemEnclosure | select serialnumber | ft -HideTableHeaders")
    PCTag := RegExReplace(PCTag, "\r\n", "")
    PCTag := RegExReplace(PCTag, " ", "")
    LogToWindow("PC TAG: " . PCTag,,1)
}

getProcessorInfo()
{
    processorInfo := RunCMD("powershell Get-WmiObject Win32_Processor | select Name | ft -HideTableHeaders")
    processorInfo := RegExReplace(processorInfo, "\R+\R", "`r`n")
    LogToWindow("Processor " . processorInfo,,1)
}

getRamInfo()
{
    ramInfo := RunCMD("powershell Get-WmiObject Win32_PhysicalMemory | Select-Object SerialNumber, Capacity, Configuredclockspeed | Format-List")
    ramInfo := RegExReplace(ramInfo, "\R+\R", "`r`n")
    LogToWindow("RAM: " . ramInfo,,1)
}

delAllConn()
{
    result := RunCMD("net use * /DELETE /Y")
    LogToWindow("Delete all connections result: " . result,1,1)
}

IpCheck()
{
    LogToWindow("Waiting for IP address...",1,1)
    ipAddress := RunCMD("powershell gwmi Win32_NetworkAdapterConfiguration | Where { $_.IPAddress } | Select -Expand IPAddress | Where { $_ -like '172.29.*' }")
    ipAddress := RegExReplace(ipAddress, "\r\n", " ")
    ipField.Value := ipAddress
    LogToWindow("IP: " . ipAddress,1,1)
}

RenewIPAdd()
{
    LogToWindow("Renewing IP...",1,1)
    ipField.Value := ""
    ipAddress := RunCMD("powershell ipconfig /renew")
    IpCheck()
}

;Listing disks
listDisk()
{
    LogToWindow("Listing disks...",1,1)
    diskListing.Delete()
    diskListing.Add(["...Loading list of disks..."])
    
    diskList := disk := diskId := model := size := partitionType := diskShow := ""
    isChecked := ControlGetChecked(UsbShow)
    if (isChecked = 1)
    {
        diskList := RunCMD("powershell Get-Disk | Format-List")
    } else {
        diskList := RunCMD("powershell Get-Disk | Where-Object -FilterScript {$_.Bustype -notcontains 'usb'} | Format-List")
    }
    diskList := StrReplace(diskList, "`r`n")
    diskListing.Delete()
    pos := 0, data := []
    While pos := RegExMatch(diskList, "UniqueId.*?IsBoot", &record, pos + 1)
    {
        data.Push(record[])
    }
    For , item in data
    {
        RegExMatch(item,"(Number.*?: )(.*)(Path)", &diskId)
        RegExMatch(item,"(Model.*?: )(.*)(Serial)",&model)
        RegExMatch(item,"(Size.*?: )(.*)(Allocated)",&size)
        RegExMatch(item,"(PartitionStyle.*?: )(.*)(IsReadOnly)",&partitionType)
        diskListing.Add(["No: " . diskId[2] . " == Model: " . model[2] . " == Size: " . size[2] . " == Partition Type: " . partitionType[2]])
    }
    if(ReadOptFirstDisk() = 1)
        {
            diskListing.Choose(1)
        }
    LogToWindow("Loading disks DONE",1,1)
}

;Listing images from PCHW
loadingImages(path)
{
    LogToWindow("Loading images...",1,1)
    imagesList.Delete()
    Sleep 200
    imagesList.Add(["...Loading list of images..."])
    if (path = "" )
	{
        LogToWindow("Path to images not found",1,1)
	} else
	{
        imagesList.Delete()
		Loop Files path . "*.wim"
		{
		    imagesList.Add([A_LoopFilePath])
		}
        optionImName := ReadOptImageName()
        LogToWindow("Options read last image name: " . optionImName,1,1)
        if(ReadOptImageName() != "0")
        { 
            LogToWindow("Auto selecting last image...",1,1)
            listItems := ControlGetItems(imagesList)

            for index, name in listItems
            {
                if InStr(name, ReadOptImageName())
                {
                    imagesList.Choose(index)
                }
            }
        }

	}
    LogToWindow("Loading images... DONE",1,1)
    LogToWindow("Current path set to: " . "path",1,1)
    CurrImagesPathText.Value := "Path to images: " . path
    RegExMatch(path, ".*\\(.*)", &imageName)
}

;Display Main Window
DisplayMainWindow()
{
    global diskListing
    global imagesList
    global UsbShow
    global ipField
    global LogWindow
    global CurrImagesPathText
    global UpdateButton
    global FormatBtn
    global FormatAllBtn
    global UefiLegacyControl
    global MainMenu
    ;Top Menu
    FileMenu := Menu()
    FileMenu.Add("Reload App", ReloadApp)
    LogMenu := Menu()
    LogMenu.Add("Open StdOut log", StdOutLog)
    TopMenu := MenuBar()
    TopMenu.Add "&File", FileMenu
    TopMenu.Add "&Options", OptionsMenu
    TopMenu.Add "&Logs", LogMenu
    ;Main Menu
    MainMenu := Gui(, "WIM Loader")
    MainMenu.MenuBar := TopMenu
    MainMenu.SetFont("s9", "Segoe UI")
    ;Disk list
    diskListing := MainMenu.Add("ListBox", "x32 y16 w425 h134", [""])
    ;Images list
    imagesList := MainMenu.Add("ListBox", "x32 y208 w425 h212", [""])
    ;Button Format
    FormatBtn := MainMenu.Add("Button", "x288 y144 w80 h23", "Format disk")
    FormatBtn.OnEvent("Click", FormatDisk)
    ;Button Format All
    MainMenu.SetFont("s8", "Segoe UI")
    FormatAllBtn := MainMenu.Add("Button", "x288 y169 w80 h23", "Format all disks")
    FormatAllBtn.OnEvent("Click", FormatAllDisks)
    MainMenu.SetFont("s9", "Segoe UI")
    ;Show only USB
    UsbShow := MainMenu.Add("CheckBox", "x32 y144 w110 h15", "Show USB drives")
    UsbShow.OnEvent("Click", ShowDrivesUsb)
    ;Refresh disks
    RefreshDiskButt := MainMenu.Add("Button", "x376 y144 w80 h23", "Refresh Disks")
    RefreshDiskButt.OnEvent("Click", RefreshDisks)
    ;Format legacy or UEFI
    UefiLegacyControl := MainMenu.Add("DropDownList", "x32 y434 w100 vMode Choose1", ["UEFI Format","LEGACY Format"])
    ;Install image
    InstallImageButton := MainMenu.Add("Button", "Default x32 y464 w99 h28", "Install Image")
    InstallImageButton.OnEvent("Click", InstallImage)
    ;IP Address
    MainMenu.Add("Text", "x32 y504 w57 h23 +0x200", "IP Address:")
    ipField := MainMenu.Add("Text", "x88 y504 w91 h23 +0x200")
    ;Renew IP
    RenewIP := MainMenu.Add("Button", "x184 y504 w80 h23", "Renew IP")
    RenewIP.OnEvent("Click", RenewAddressIP)
    ;Version text
    MainMenu.Add("Text", "x32 y531 w250 h23 +0x200", "Version " . version . " - Copyright Miasik Jakub")
    UpdateButton := MainMenu.Add("Button", "x300 y531 w150 h25")
    ControlHide UpdateButton
    UpdateButton.OnEvent("Click", UpdateApp)
    ;Images path
    CurrImagesPathText := MainMenu.Add("Text", "x32 y410 w200 h22 +0x200")
    MainMenu.SetFont("s8", "Segoe UI")
    ;Button refresh images
    RefrImages := MainMenu.Add("Button", "x376 y416 w80 h30", "Refresh Images")
    RefrImages.OnEvent("Click", RefreshImages)
    ;Load manually
    LoadMan := MainMenu.Add("Button", "x376 y448 w80 h23", "Change path")
    LoadMan.OnEvent("Click", ChangePath)
    MainMenu.SetFont("s9", "Segoe UI")
    ;Log window
    LogWindow := MainMenu.Add("Edit", "x464 y16 w305 h536 ReadOnly Multi")
    MainMenu.Show()
    LogToWindow("Main menu was loaded",1,1)
    MainMenu.OnEvent("Close", endApp)
}

OptionsWindowFunc()
{
    LogToWindow("Loading options window",1,1)
    global OptionsWindow
    ;Create window
    OptionsWindow := Gui(, "Options")
    ;Last selected image will be selected on next startup
    CheckBoxImAuSta := OptionsWindow.Add("CheckBox", "x16 y8 w337 h20", "select on startup last used image")
    (ReadOptLastImage() = 1) ? CheckBoxImAuSta.Value := 1 : CheckBoxImAuSta.Value := 0
    ;First disk will be selected
    CheckBoxFirstDisk := OptionsWindow.Add("CheckBox", "x16 y+1 w337 h20", "select first disk on list")
    (ReadOptFirstDisk() = 1) ? CheckBoxFirstDisk.Value := 1 : CheckBoxFirstDisk.Value := 0
    ;Fast start (no info about machine)
    CheckBoxFastStart := OptionsWindow.Add("CheckBox", "x16 y+1 w337 h20", "fast start (no info about machine")
    (ReadOptFastStart() = 1) ? CheckBoxFastStart.Value := 1 : CheckBoxFastStart.Value := 0

    ButtonClose := OptionsWindow.Add("Button", "x137 y320 w80 h23", "&Close")
    OptionsWindow.Title := "Options"
    OptionsWindow.Show("w361 h352")
    LogToWindow("Loading options window - done",1,1)
    MainMenu.Opt("+Disabled")
    
    ;Events
    CheckBoxImAuSta.OnEvent("Click", saveOptionValue.Bind(CheckBoxImAuSta,"Options", "ImageLastLoad"))
    CheckBoxFirstDisk.OnEvent("Click", saveOptionValue.Bind(CheckBoxFirstDisk,"Options", "SelectFirstDisk"))
    CheckBoxFastStart.OnEvent("Click", saveOptionValue.Bind(CheckBoxFastStart,"Options", "FastStart"))
	ButtonClose.OnEvent("Click", OptionsClose)
    OptionsWindow.OnEvent("Close", OptionsClose)

    saveOptionValue(nameCheckbox, iniSection, iniSectionKey,*)
    {
        IniWrite(nameCheckbox.Value, iniPath, iniSection, iniSectionKey)
    }

    OptionsClose(*)
    {
        OptionsWindow.Destroy
        MainMenu.Opt("-Disabled")
        MainMenu.Show()
    }
}

endApp(*)
{
    delAllConn()
    LogToWindow("Exiting",1,1)
    ExitApp
}

StdOutLog(Item,*)
{
    LogToWindow("Open StdOutput log",1,1)
    Run "notepad.exe " . A_ScriptDir . "\log.txt"
}

ReloadApp(Item,*)
{
    LogToWindow("Reloading app",1,1)
    Reload
    return
}

OptionsMenu(item, *)
{
    OptionsWindowFunc()
}

ChckForSelectDisk()
{
    SelDisk := diskListing.Text
    if (SelDisk != "")
    {
        RegExMatch(SelDisk, "No: ([0-9]{1,2})", &diskNumber)
        return diskNumber[1]
    } else {
        return ""
    }
}

DiskFormat(disks) ;array
{
    for value in disks
    {
        diskListing.Delete()
        LogToWindow("Formating disk ID: " . value . ". Please wait.",1,1)
        diskListing.Add(["Formating disk " . value . " Please wait..."])
        diskpartText :=
        (
            "select disk " value "
            clean
            convert gpt
            create partition primary
            format quick fs=ntfs
            assign
            exit"
        )
        if fileExist("x:\format_disk.txt")
        {
            FileDelete "x:\format_disk.txt"
        }
        FileAppend diskpartText, "x:\format_disk.txt"
        formatDisk := RunCMD("diskpart /s x:\format_disk.txt")
        Sleep(300)
        LogToWindow("Format done.",1,1)
    }
    listDisk()
}

FormatDisk(*)
{
    diskArray := []
    diskId := ChckForSelectDisk()
    if (diskId = "")
    {
        MsgBox "Select disk to format"
    } else {
        FormatBtn.Opt("Disabled")
        diskArray.Push(diskId)
        DiskFormat(diskArray)
        FormatBtn.Enabled := true
    }
}

FormatAllDisks(*)
{
    result := MsgBox("Do you want format ALL disks?", "Format","4404")
    if(result = "No")
    {
        return
    }
    LogToWindow("Formating all disks.",1,1)
    FormatAllBtn.Opt("Disabled")
    formatDisks := Array()
    disks := RunCMD("powershell Get-Disk | Where-Object -FilterScript {$_.Bustype -notcontains 'usb'} | Select-Object -Property @{n='Disk ###';e={'{0}' -f $_.Number}} | ConvertTo-Csv -NoTypeInformation")
    disks := StrSplit(disks, "`r`n")
    for index, value in disks
    {
        if(RegExMatch(value, "[0-9]{1}"))
        {
            RegExMatch(value, "([0-9]{1})", &diskArray)
            formatDisks.Push(diskArray[1])
        }
    }
    DiskFormat(formatDisks)
    FormatAllBtn.Enabled := true
}

ShowDrivesUsb(*)
{
    LogToWindow("Show USB checkbox selected",1,1)
    listDisk()
}

RenewAddressIP(*)
{
    LogToWindow("Renew button pressed",1,1)
    RenewIPAdd()
}

RefreshImages(*)
{
    LogToWindow("Refresh images button pressed",1,1)
    loadingImages(defLocLett . ":\")
}

RefreshDisks(*)
{
    LogToWindow("Refresh disks button pressed",1,1)
    listDisk()
}

ChangePath(*)
{
    LogToWindow("Waiting for new path of WIMs...",1,1)
    NewPath := InputBox("WIMs Path:", "Enter new path for WIMs")
    If (NewPath.Result = "Cancel")
    {
        LogToWindow("Action was canceled",1,1)
    } else {
        LogToWindow("New path for WIMs is " . NewPath.Value,1,1)
        loadingImages(NewPath.Value)
    }
    return
}

UpdateApp(*)
{
    LogToWindow("Updating app...",1,1)
    delAllConn()
    Run "wimautoupdate.exe"
    ExitApp
}

InstallImage(*)
{
    LogToWindow("Starting loading image proccess...",1,1)
    diskToInstall := ChckForSelectDisk()
    if (diskToInstall = "")
    {
        LogToWindow("No disk was selected",1,1)
        MsgBox "Select disk to install image"
        return
    }
    if (imagesList.Text = "")
    {
        LogToWindow("No image was selected",1,1)
        MsgBox "Select image to install"
        return
    } else {
        imageToInstall := imagesList.Text
        LogToWindow("Image to install: " . imageToInstall,1,1)
        ;Save to ini when option is selected
        
        if(ReadOptLastImage = 1) {
            LogToWindow("Saving image name to ini",1,1)
            RegExMatch(imagesList.Text, ".*\\(.*)", &imageSaveIni)
            IniWrite(imageSaveIni[1], iniPath, "Data", "LastLoadImageName" )
        }
    }
    lettersInstall := GetFreeLetters(2)
    if(UefiLegacyControl.Value = 1)
    {
        LogToWindow("Formating to UEFI...",1,1)
        uefi_partitions := 
        (
            "select disk " diskToInstall "
            clean
            convert gpt
            rem == 1. System partition =========================
            create partition efi size=100
            format quick fs=fat32 label=`"System`"
            assign letter=" lettersInstall[1] "
            rem == 2. Microsoft Reserved (MSR) partition =======
            create partition msr size=16
            rem == 3. Windows partition ========================
            create partition primary
            format quick fs=ntfs label=`"Windows`"
            assign letter=" lettersInstall[2] "
            exit"
        )
        LogToWindow("System letter: " . lettersInstall[1] . " and Windows letter: " . lettersInstall[2],1,1)
        If fileExist("x:\uefi_format.txt")
        {
            FileDelete "x:\uefi_format.txt"
        }
        FileAppend uefi_partitions, "x:\uefi_format.txt"
        LogToWindow("Diskpart start",1,1)
        formatUefi := RunCMD("diskpart /s x:\uefi_format.txt")
        LogToWindow("Done",1,1)
    } else if(UefiLegacyControl.Value = 2) {
        LogToWindow("Formating to LEGACY...",1,1)
        legacy_partitions :=
        (
            "select disk disk_number
            clean
            rem == 1. System partition =========================
            create partition efi size=100
            format quick fs=fat32 label=`"System`"
            assign letter=" lettersInstall[1] "
            rem == 2. Microsoft Reserved (MSR) partition =======
            create partition msr size=16
            rem == 3. Windows partition ========================
            create partition primary
            format quick fs=ntfs label=`"Windows`"
            assign letter=" lettersInstall[2] "
            exit"
        )
        LogToWindow("System letter: " . lettersInstall[1] . " and Windows letter: " . lettersInstall[2],1,1)
        If fileExist("x:\legacy_format.txt")
        {
            FileDelete "x:\legacy_format.txt"
        }
        FileAppend legacy_partitions, "x:\legacy_format.txt"
        LogToWindow("Diskpart start",1,1)
        formatUefi := RunCMD("diskpart /s x:\legacy_format.txt")
        LogToWindow("Done",1,1)
    }
    LogToWindow("Image loading...",1,1)
    RunWait "dism /apply-image /imagefile:" imagesList.Text " /index:1 /applydir:" lettersInstall[2] ":\ /NoRpFix",,"Max"
    RunWait lettersInstall[2] ":\Windows\System32\bcdboot " lettersInstall[2] ":\Windows /s " lettersInstall[1] ":"
    Sleep 5000
    LogToWindow("DONE.",1,1)
    LogToWindow("Rebooting...",1,1)
    RunCMD("wpeutil Reboot")
}

ReadOptLastImage()
{
    optionRead := IniRead(iniPath, "Options", "ImageLastLoad", "0")
    LogToWindow("Options read last image load: " . optionRead,1,1)
    return optionRead
}

ReadOptImageName()
{
    optionRead := IniRead(iniPath, "Data", "LastLoadImageName", "0")
    return optionRead
}

ReadOptFirstDisk()
{
    optionRead := FirstDiskOptions := IniRead(iniPath, "Options", "SelectFirstDisk", "0")
    LogToWindow("Options read first disk: " . optionRead,1,1)
    return optionRead
}

ReadOptFastStart()
{
    optionRead := IniRead(iniPath, "Options", "FastStart", "0")
    LogToWindow("Options read fast start: " . optionRead,1,1)
    return optionRead
}
;=====================Script START=====================
;Generate unique name of file
;Display Main Window
DisplayMainWindow()
;Get INI file
iniPath := iniPathChk()
;Fast start without pc spec
if(ReadOptFastStart() != 1)
{
    LogToWindow("Loading info about hardware",1,1)
    ;Get PCTAG info
    getServiceTagPC()
    ;Get hardware info
    getProcessorInfo()
    getRamInfo()
}

;Get all disks
listDisk()
;IP checking
IpCheck()
;Get free letter to mount default location for images
defLocLett := GetFirstFreeLetter()
;Connect to default location and assign letter
LogToWindow("Connecting to " . defaLocImages,1,1)
defaultLoc := RunCMD("net use " . defLocLett . ": " . defaLocImages . " /user:" . defaLocImagesUser . " " . defaLocImagesPass . " /p:no")
loadingImages(defLocLett . ":\")
;Check for updates
LogToWindow("Checking for updates...",1,1)
if (defLocLett . ":" . updateFolLoc = "")
{
    LogToWindow("Path to update location not found",1,1)
} else {
    RunCMD("xcopy " defLocLett ":\sources\wimautoupdate.exe x:\windows\system32 /y")
    if FileExist(defLocLett . ":" . updateFolLoc . "*latest.*")
    {
        Loop Files defLocLett . ":" . updateFolLoc . "*latest.*"
        {
            RegExMatch(A_LoopFilePath, "[0-9].*[0-9]", &verUpdateFile)
            verLatestFile := StrReplace(verUpdateFile[], "_", "")
            verLatestToDisp := StrReplace(verUpdateFile[], "_", ".")
            verCurrent := StrReplace(version, ".", "")
        }
        if (verLatestFile > verCurrent)
        {
            LogToWindow("Update found ver. " . verLatestToDisp,1,1)
            
            UpdateButton.Text :=  "Update to " . verLatestToDisp
            ControlShow UpdateButton
    
        } else {
            LogToWindow("Update not found.",1,1)
        }
    } else {
        LogToWindow("Update not found.",1,1)
    }
}