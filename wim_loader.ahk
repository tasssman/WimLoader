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

;=====================Script START=====================
;Generate unique name of file
uniqFileName := generUniqFileName()


ExitApp