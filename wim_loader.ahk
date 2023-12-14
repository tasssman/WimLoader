#SingleInstance Force
SendMode "Input"
SetWorkingDir A_ScriptDir

;=====================Timers=====================
;Timer for buttons on/off
;SetTimer ButtonsControl, 300

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

generUniqFileName()
{
    timeFile := FormatTime(,"yyyy_MM_dd_HH_mm_ss")
    return timeFile
}

;Logger
Log(text)
{
    timeNow := FormatTime(,"yyyy-MM-dd_HH:mm:ss")
    textToLog := timeNow . " " . text
    FileAppend textToLog . "`n", "wimlog_" . uniqFileName . ".txt"
}

;Get first free letter drive without comma
GetFirstFreeLetter()
{
    freeDiskLetter := RunCMD("powershell ls function:[k-u]: -n | ?{ !(test-path $_) } | select -first 1")
    freeDiskLetter := StrReplace(freeDiskLetter, "`r`n")
    freeDiskLetter := StrReplace(freeDiskLetter, ":", "")
    Log("First free letter: " . freeDiskLetter)
	return freeDiskLetter
}

;Letters with comma in array
GetFreeLetters(amount)
{
    freeDiskLetters := RunCMD("powershell (ls function:[k-u]: -n | ?{ !(test-path $_) } | select -first " amount ") -join ';' ")
	freeDiskLetters := StrReplace(freeDiskLetters, "`r`n")
    freeDiskLetters := StrReplace(freeDiskLetters, ":", "")
	freeDiskLetters := StrSplit(freeDiskLetters, ";")
    Log("Get free letters")
	return freeDiskLetters
}

getServiceTagPC()
{
    Log("Get PC tag")
    PCTag := RunCMD("powershell Get-WmiObject win32_SystemEnclosure | select serialnumber | ft -HideTableHeaders")
    PCTag := RegExReplace(PCTag, "\r\n", "")
    PCTag := RegExReplace(PCTag, " ", "")
    LogToWindow("PC TAG: " . PCTag)
}

getProcessorInfo()
{
    Log("Get proccessor info")
    processorInfo := RunCMD("powershell Get-WmiObject Win32_Processor | select Name | ft -HideTableHeaders")
    processorInfo := RegExReplace(processorInfo, "\R+\R", "`r`n")
    LogToWindow("Processor " . processorInfo)
}

getRamInfo()
{
    Log("Get RAM info")
    ramInfo := RunCMD("powershell Get-WmiObject Win32_PhysicalMemory | Select-Object SerialNumber, Capacity, Configuredclockspeed | Format-List")
    ramInfo := RegExReplace(ramInfo, "\R+\R", "`r`n")
    LogToWindow("RAM: " . ramInfo)
}

delAllConn()
{
    RunCMD("net use * /DELETE /Y")
}

IpCheck()
{
    Log("Check for IP")
    LogToWindow("Waiting for IP address...")
    ipAddress := RunCMD("powershell gwmi Win32_NetworkAdapterConfiguration | Where { $_.IPAddress } | Select -Expand IPAddress | Where { $_ -like '172.29.*' }")
    ipAddress := RegExReplace(ipAddress, "\r\n", " ")
    ipField.Value := ipAddress
    LogToWindow("IP: " . ipAddress)
}

LogToWindow(text)
{
	global textLog
    timeNow := FormatTime(,"yyyy-MM-dd_HH:mm:ss")
	textLog := textLog . "`r`n" . timeNow " - " . text
    LogWindow.Value := textLog
	
    ;SendMessage,0x115,7,0,Edit1,WIM Loader
}

;Listing disks
listDisk()
{
    LogToWindow("Listing disks...")
    Log("Loading disks")
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
    Log("Loading disks DONE")
    LogToWindow("Loading disks DONE")
}

;Display Main Window
DisplayMainWindow()
{
    Log("Loading main window")
    ;Top Menu
    LogMenu := Menu()
    LogMenu.Add("Open WIM Log", Menu)
    LogMenu.Add("Open StdOut log", Menu)
    TopMenu := MenuBar()
    TopMenu.Add "&Logs", LogMenu
    ;Main Menu
    MainMenu := Gui(, "WIM Loader")
    MainMenu.MenuBar := TopMenu
    MainMenu.SetFont("s9", "Segoe UI")
    ;Disk list
    global diskListing
    diskListing := MainMenu.Add("ListBox", "x32 y16 w425 h134", ["...Loading list of disk..."])
    ;Images list
    MainMenu.Add("ListBox", "x32 y208 w425 h212 vimagesList", ["...Loading list of images..."])
    ;Button Format
    FormatBtn := MainMenu.Add("Button", "x288 y160 w80 h23", "Format disk")
    FormatBtn.OnEvent("Click", FormatDisk)
    ;Show only USB
    global UsbShow
    UsbShow := MainMenu.Add("CheckBox",, "Show USB drives")
    UsbShow.OnEvent("Click", ShowDrivesUsb)
    ;Refresh disks
    MainMenu.Add("Button", "x376 y160 w80 h23", "Refresh Disks")
    ;Format legacy or UEFI
    MainMenu.Add("DropDownList", "x32 y459 w100 vMode Choose1", ["UEFI Format","LEGACY Format"])
    ;IP Address
    MainMenu.Add("Text", "x24 y504 w57 h23 +0x200", "IP Address:")
    global ipField
    ipField := MainMenu.Add("Text", "x88 y504 w91 h23 +0x200")
    ;Renew IP
    RenewIP := MainMenu.Add("Button", "x184 y504 w80 h23", "Renew IP")
    RenewIP.OnEvent("Click", RenewAddressIP)
    ;Version text
    MainMenu.Add("Text", "x25 y531 w250 h23 +0x200", "Version " . version . " - Copyright Miasik Jakub")
    ;Images path
    MainMenu.Add("Text", "x120 y432 w200 h22 +0x200 vCurrImagePathText")
    MainMenu.SetFont("s8", "Segoe UI")
    ;Button refresh images
    RefrImages := MainMenu.Add("Button", "x376 y432 w80 h30", "Refresh Images")
    RefrImages.OnEvent("Click", RefreshImages)
    ;Load manually
    LoadMan := MainMenu.Add("Button", "x376 y464 w80 h23", "Load manually")
    LoadMan.OnEvent("Click", LoadManually)
    MainMenu.SetFont("s9", "Segoe UI")
    ;Log window
    global LogWindow
    LogWindow := MainMenu.Add("Edit", "x464 y16 w305 h536 ReadOnly Multi")
    MainMenu.Show("w777 h558")
    Log("Loading main window DONE")
}

FormatDisk(*)
{
    MsgBox "Button click"
}

ShowDrivesUsb(*)
{
    listDisk()
}

RenewAddressIP(*)
{

}

RefreshImages(*)
{

}

LoadManually(*)
{

}

;=====================Script START=====================
version := "1.0.0.3"
textLog := ""
;Generate unique name of file
uniqFileName := generUniqFileName()
DisplayMainWindow()
;Get PCTAG info
tagOfPC := getServiceTagPC()
;Get hardware info
getProcessorInfo()
getRamInfo()
;Get all disks
listDisk()
IpCheck()
defLocLett := GetFirstFreeLetter()
