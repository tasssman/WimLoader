#Requires AutoHotkey v2.0
#SingleInstance Force
SendMode "Input"
SetWorkingDir A_ScriptDir

;=====================Globals=====================
global iniPath
global textLog := ""
global uniqFileName := ""
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
version := "2.1.2"
;=====================Functions=====================

RunCMD(P_CmdLine, P_WorkingDir := "", P_Codepage := "CP0", P_Func := 0, P_Slow := 1)
{
;  RunCMD Temp_v0.99 for ah2 By SKAN on D532/D67D @ autohotkey.com/r/?p=448912
;-----------------------------------------------------------------------
    ;Log cmd commands INPUT (my personal add)
        timeCmd := FormatTime(,"yyyy-MM-dd_HH:mm:ss")
        CmdText := timeCmd . " - " . P_CmdLine
        CmdText := RegExReplace(CmdText, "\r\n", " ")
        FileAppend "`n============CMD Start==============`n" . CmdText . "`n", "wimlog_" . uniqFileName . "_StdOutput.txt"
    ;-----------------------------------------------------------------------

    Global G_RunCMD

    If  Not IsSet(G_RunCMD)
        G_RunCMD := {}

    G_RunCMD                     :=  {PID: 0, ExitCode: ""}

    Local  CRLF                  :=  Chr(13) Chr(10)
        ,  hPipeR                :=  0
        ,  hPipeW                :=  0
        ,  PIPE_NOWAIT           :=  1
        ,  HANDLE_FLAG_INHERIT   :=  1
        ,  dwMask                :=  HANDLE_FLAG_INHERIT
        ,  dwFlags               :=  HANDLE_FLAG_INHERIT

    DllCall("Kernel32\CreatePipe", "ptrp",&hPipeR, "ptrp",&hPipeW, "ptr",0, "int",0)
  , DllCall("Kernel32\SetHandleInformation", "ptr",hPipeW, "int",dwMask, "int",dwFlags)
  , DllCall("Kernel32\SetNamedPipeHandleState", "ptr",hPipeR, "uintp",PIPE_NOWAIT, "ptr",0, "ptr",0)

    Local  B_OK                  :=  0
        ,  P8                    :=  A_PtrSize=8
        ,  STARTF_USESTDHANDLES  :=  0x100
        ,  STARTUPINFO
        ,  PROCESS_INFORMATION

    PROCESS_INFORMATION          :=  Buffer(P8 ?  24 : 16, 0)                  ;  PROCESS_INFORMATION
  , STARTUPINFO                  :=  Buffer(P8 ? 104 : 68, 0)                  ;  STARTUPINFO

  , NumPut("uint", P8 ? 104 : 68, STARTUPINFO)                                 ;  STARTUPINFO.cb
  , NumPut("uint", STARTF_USESTDHANDLES, STARTUPINFO, P8 ? 60 : 44)            ;  STARTUPINFO.dwFlags
  , NumPut("ptr",  hPipeW, STARTUPINFO, P8 ? 88 : 60)                          ;  STARTUPINFO.hStdOutput
  , NumPut("ptr",  hPipeW, STARTUPINFO, P8 ? 96 : 64)                          ;  STARTUPINFO.hStdError

    Local  CREATE_NO_WINDOW      :=  0x08000000
        ,  PRIORITY_CLASS        :=  DllCall("Kernel32\GetPriorityClass", "ptr",-1, "uint")

    B_OK :=  DllCall( "Kernel32\CreateProcessW"
                    , "ptr", 0                                                 ;  lpApplicationName
                    , "ptr", StrPtr(P_CmdLine)                                 ;  lpCommandLine
                    , "ptr", 0                                                 ;  lpProcessAttributes
                    , "ptr", 0                                                 ;  lpThreadAttributes
                    , "int", True                                              ;  bInheritHandles
                    , "int", CREATE_NO_WINDOW | PRIORITY_CLASS                 ;  dwCreationFlags
                    , "int", 0                                                 ;  lpEnvironment
                    , "ptr", DirExist(P_WorkingDir) ? StrPtr(P_WorkingDir) : 0 ;  lpCurrentDirectory
                    , "ptr", STARTUPINFO                                       ;  lpStartupInfo
                    , "ptr", PROCESS_INFORMATION                               ;  lpProcessInformation
                    , "uint"
                    )

    DllCall("Kernel32\CloseHandle", "ptr",hPipeW)

    If  Not B_OK
        Return ( DllCall("Kernel32\CloseHandle", "ptr",hPipeR), "" )

    G_RunCMD.PID := NumGet(PROCESS_INFORMATION, P8 ? 16 : 8, "uint")

    Local  FileObj
        ,  Line                  :=  ""
        ,  LineNum               :=  1
        ,  sOutput               :=  ""
        ,  ExitCode              :=  0

    FileObj  :=  FileOpen(hPipeR, "h", P_Codepage)
  , P_Slow   :=  !! P_Slow

    Sleep_() =>  (Sleep(P_Slow), G_RunCMD.PID)

    While   DllCall("Kernel32\PeekNamedPipe", "ptr",hPipeR, "ptr",0, "int",0, "ptr",0, "ptr",0, "ptr",0)
      and   Sleep_()
            While  G_RunCMD.PID and not FileObj.AtEOF
                   Line           :=  FileObj.ReadLine()
                ,  sOutput        .=  StrLen(Line)=0 and FileObj.Pos=0
                                   ?  ""
                                   :  (
                                         P_Func
                                      ?  P_Func.Call(Line CRLF, LineNum++)
                                      :  Line CRLF
                                      )

    hProcess                     :=  NumGet(PROCESS_INFORMATION, 0, "ptr")
  , hThread                      :=  NumGet(PROCESS_INFORMATION, A_PtrSize, "ptr")

  , DllCall("Kernel32\GetExitCodeProcess", "ptr",hProcess, "ptrp",&ExitCode)
  , DllCall("Kernel32\CloseHandle", "ptr",hProcess)
  , DllCall("Kernel32\CloseHandle", "ptr",hThread)
  , DllCall("Kernel32\CloseHandle", "ptr",hPipeR)
  , G_RunCMD := {PID: 0, ExitCode: ExitCode}

    ;-----------------------------------------------------------------------
    ;Log cmd commands OUTPUT (my personal add)
        timeOutput := FormatTime(,"yyyy-MM-dd_HH:mm:ss")
        timeFile := FormatTime(,"yyyy-MM-dd")
        OutputText := timeOutput . "-" . sOutput
        OutputText := RegExReplace(OutputText, "\r\n", " ")
        FileAppend OutputText, "wimlog_" . uniqFileName . "_StdOutput.txt"
    ;-----------------------------------------------------------------------
    Return RTrim(sOutput, CRLF)
}

LogToWindow(text, userWindow := true)
{
    global textLog
    global uniqFileName
    timeNow := FormatTime(,"yyyy-MM-dd_HH:mm:ss")
    if(userWindow = true)
    {
        textLog := textLog . "`r`n" . timeNow " - " . text
        LogWindow.Value := textLog
    }
    FileAppend timeNow . "-" . text . "`n", "wimlog_" . uniqFileName . ".txt"
}

iniPathChk()
{
    bootLoc := RegRead("HKLM\SYSTEM\ControlSet001\Control", "PEBootRamdiskSourceDrive")
    iniPath := bootLoc . iniName
    LogToWindow("INI Regex command result: " . bootLoc, false)
    LogToWindow("INI Path: " . iniPath)
    return iniPath
}

;Get first free letter drive without comma
GetFirstFreeLetter()
{
    freeDiskLetter := RunCMD("powershell ls function:[k-u]: -n | ?{ !(test-path $_) } | select -first 1")
    freeDiskLetter := StrReplace(freeDiskLetter, "`r`n")
    freeDiskLetter := StrReplace(freeDiskLetter, ":", "")
    LogToWindow("First free disk letter: " . freeDiskLetter, false)
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
        LogToWindow("First free disk letter: " . value, false)
    }
	return freeDiskLetters
}

getServiceTagPC()
{
    PCTag := RunCMD("powershell Get-WmiObject win32_SystemEnclosure | select serialnumber | ft -HideTableHeaders")
    PCTag := RegExReplace(PCTag, "\r\n", "")
    PCTag := RegExReplace(PCTag, " ", "")
    LogToWindow("PC TAG: " . PCTag)
}

getProcessorInfo()
{
    processorInfo := RunCMD("powershell Get-WmiObject Win32_Processor | select Name | ft -HideTableHeaders")
    processorInfo := RegExReplace(processorInfo, "\R+\R", "`r`n")
    LogToWindow("Processor " . processorInfo)
}

getRamInfo()
{
    ramInfo := RunCMD("powershell Get-WmiObject Win32_PhysicalMemory | Select-Object SerialNumber, Capacity, Configuredclockspeed | Format-List")
    ramInfo := RegExReplace(ramInfo, "\R+\R", "`r`n")
    LogToWindow("RAM: " . ramInfo)
}

delAllConn()
{
    result := RunCMD("net use * /DELETE /Y")
    LogToWindow("Delete all connections result: " . result, false)
}

IpCheck()
{
    LogToWindow("Waiting for IP address...")
    ipAddress := RunCMD("powershell gwmi Win32_NetworkAdapterConfiguration | Where { $_.IPAddress } | Select -Expand IPAddress | Where { $_ -like '172.29.*' }")
    ipAddress := RegExReplace(ipAddress, "\r\n", " ")
    ipField.Value := ipAddress
    LogToWindow("IP: " . ipAddress)
}

RenewIPAdd()
{
    LogToWindow("Renewing IP...")
    ipField.Value := ""
    ipAddress := RunCMD("powershell ipconfig /renew")
    IpCheck()
}

;Listing disks
listDisk()
{
    LogToWindow("Listing disks...")
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
    LogToWindow("Loading disks DONE")
}

;Listing images from PCHW
loadingImages(path)
{
    LogToWindow("Loading images...")
    imagesList.Delete()
    Sleep 200
    imagesList.Add(["...Loading list of images..."])
    if (path = "" )
	{
        LogToWindow("Path to images not found")
	} else
	{
        imagesList.Delete()
		Loop Files path . "*.wim"
		{
		    imagesList.Add([A_LoopFileShortPath])
		}
        optionImName := ReadOptImageName()
        LogToWindow("Options read last image name: " . optionImName, false)
        if(ReadOptImageName() != "0")
        { 
            LogToWindow("Auto selecting last image...")
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
    LogToWindow("Loading images... DONE")
    LogToWindow("Current path set to: " . "path")
    CurrImagesPathText.Value := "Path to images: " . path
    RegExMatch(path, ".*\\(.*)", &imageName)
}

;Display Main Window
DisplayMainWindow()
{
    LogToWindow("Loading main window: ", false)
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
    MainMenu.Show("w777 h558")
    LogToWindow("Loading main windows - done: ", false)
    MainMenu.OnEvent("Close", endApp)
}

OptionsWindowFunc()
{
    LogToWindow("Loading options window", false)
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
    LogToWindow("Loading options window - done", false)
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
    LogToWindow("Exiting", false)
    ExitApp
}

StdOutLog(Item,*)
{
    LogToWindow("Open StdOutput log", false)
    Run "notepad.exe wimlog_" . uniqFileName . "_StdOutput.txt"
}

ReloadApp(Item,*)
{
    LogToWindow("Reloading app", false)
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
        LogToWindow("Formating disk ID: " . value . ". Please wait.")
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
        LogToWindow("Format done.")
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
    LogToWindow("Formating all disks.")
    FormatAllBtn.Opt("Disabled")
    formatDisks := Array()
    disks := RunCMD("powershell Get-Disk | Where-Object -FilterScript {$_.Bustype -notcontains 'usb'} | Select-Object -Property @{n='Disk ###';e={'{0}' -f $_.Number}} | ConvertTo-Csv -NoTypeInformation")
    disks := StrSplit(disks, "`r`n")
    for index, value in disks
    {
        if(RegExMatch(value, "[0-1]{1}"))
        {
            RegExMatch(value, "([0-1]{1})", &diskArray)
            formatDisks.Push(diskArray[1])
        }
    }
    DiskFormat(formatDisks)
    FormatAllBtn.Enabled := true
}

ShowDrivesUsb(*)
{
    LogToWindow("Show USB checkbox selected", false)
    listDisk()
}

RenewAddressIP(*)
{
    LogToWindow("Renew button pressed", false)
    RenewIPAdd()
}

RefreshImages(*)
{
    LogToWindow("Refresh images button pressed", false)
    loadingImages(defLocLett . ":\")
}

RefreshDisks(*)
{
    LogToWindow("Refresh disks button pressed", false)
    listDisk()
}

ChangePath(*)
{
    LogToWindow("Waiting for new path of WIMs...")
    NewPath := InputBox("WIMs Path:", "Enter new path for WIMs")
    If (NewPath.Result = "Cancel")
    {
        LogToWindow("Action was canceled")
    } else {
        LogToWindow("New path for WIMs is " . NewPath.Value)
        loadingImages(NewPath.Value)
    }
    return
}

UpdateApp(*)
{
    LogToWindow("Updating app...")
    delAllConn()
    Run "wimautoupdate.exe"
    ExitApp
}

InstallImage(*)
{
    LogToWindow("Starting loading image proccess...")
    diskToInstall := ChckForSelectDisk()
    if (diskToInstall = "")
    {
        LogToWindow("No disk was selected", false)
        MsgBox "Select disk to install image"
        return
    }
    if (imagesList.Text = "")
    {
        LogToWindow("No image was selected", false)
        MsgBox "Select image to install"
        return
    } else {
        imageToInstall := imagesList.Text
        LogToWindow("Image to install: " . imageToInstall, false)
        ;Save to ini when option is selected
        
        if(ReadOptLastImage = 1) {
            LogToWindow("Saving image name to ini", false)
            RegExMatch(imagesList.Text, ".*\\(.*)", &imageSaveIni)
            IniWrite(imageSaveIni[1], iniPath, "Data", "LastLoadImageName" )
        }
    }
    lettersInstall := GetFreeLetters(2)
    if(UefiLegacyControl.Value = 1)
    {
        LogToWindow("Formating to UEFI...")
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
        LogToWindow("System letter: " . lettersInstall[1] . " and Windows letter: " . lettersInstall[2], false)
        If fileExist("x:\uefi_format.txt")
        {
            FileDelete "x:\uefi_format.txt"
        }
        FileAppend uefi_partitions, "x:\uefi_format.txt"
        LogToWindow("Diskpart start", false)
        formatUefi := RunCMD("diskpart /s x:\uefi_format.txt")
        LogToWindow("Done")
    } else if(UefiLegacyControl.Value = 2) {
        LogToWindow("Formating to LEGACY...")
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
        LogToWindow("System letter: " . lettersInstall[1] . " and Windows letter: " . lettersInstall[2], false)
        If fileExist("x:\legacy_format.txt")
        {
            FileDelete "x:\legacy_format.txt"
        }
        FileAppend legacy_partitions, "x:\legacy_format.txt"
        LogToWindow("Diskpart start", false)
        formatUefi := RunCMD("diskpart /s x:\legacy_format.txt")
        LogToWindow("Done")
    }
    LogToWindow("Image loading...")
    RunWait "dism /apply-image /imagefile:" imagesList.Text " /index:1 /applydir:" lettersInstall[2] ":\ /NoRpFix",,"Max"
    RunWait lettersInstall[2] ":\Windows\System32\bcdboot " lettersInstall[2] ":\Windows /s " lettersInstall[1] ":"
    Sleep 5000
    LogToWindow("DONE.")
    LogToWindow("Rebooting...")
    RunCMD("wpeutil Reboot")
}

ReadOptLastImage()
{
    optionRead := IniRead(iniPath, "Options", "ImageLastLoad", "0")
    LogToWindow("Options read last image load: " . optionRead, false)
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
    LogToWindow("Options read first disk: " . optionRead, false)
    return optionRead
}

ReadOptFastStart()
{
    optionRead := IniRead(iniPath, "Options", "FastStart", "0")
    LogToWindow("Options read fast start: " . optionRead, false)
    return optionRead
}
;=====================Script START=====================
;Generate unique name of file
uniqFileName := FormatTime(,"yyyy_MM_dd_HH_mm_ss")
LogToWindow("Generating uniq file name for logs done", false)
;Display Main Window
DisplayMainWindow()
;Get INI file
iniPath := iniPathChk()
;Fast start without pc spec
if(ReadOptFastStart() != 1)
{
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
LogToWindow("Connecting to " . defaLocImages)
defaultLoc := RunCMD("net use " . defLocLett . ": " . defaLocImages . " /user:" . defaLocImagesUser . " " . defaLocImagesPass . " /p:no")
loadingImages(defLocLett . ":\")
;Check for updates
LogToWindow("Checking for updates...")
if (defLocLett . ":" . updateFolLoc = "")
{
    LogToWindow("Path to update location not found")
} else {
    RunCMD("xcopy " defLocLett ":\sources\wimautoupdate.exe x:\windows\system32 /y")
    if FileExist(defLocLett . ":" . updateFolLoc . "*latest.*")
    {
        Loop Files defLocLett . ":" . updateFolLoc . "*latest.*"
        {
            RegExMatch(A_LoopFileShortPath, "[0-9].*[0-9]", &verUpdateFile)
            verLatestFile := StrReplace(verUpdateFile[], "_", "")
            verLatestToDisp := StrReplace(verUpdateFile[], "_", ".")
            verCurrent := StrReplace(version, ".", "")
        }
        if (verLatestFile > verCurrent)
        {
            LogToWindow("Update found ver. " . verLatestToDisp)
            
            UpdateButton.Text :=  "Update to " . verLatestToDisp
            ControlShow UpdateButton
    
        } else {
            LogToWindow("Update not found.")
        }
    } else {
        LogToWindow("Update not found.")
    }
}