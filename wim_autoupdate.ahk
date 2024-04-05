#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

;Reading output from command
RunCMD(P_CmdLine, P_WorkingDir := "", P_Codepage := "CP0", P_Func := 0, P_Slow := 1)
{
;  RunCMD Temp_v0.99 for ah2 By SKAN on D532/D67D @ autohotkey.com/r/?p=448912
;----------------------------------------------------------------------

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
    Return RTrim(sOutput, CRLF)
}

CreateMainWindow()
{
	MainWindow := Gui()
	MainWindow.SetFont("s9","Segoe UI")
	
}









MainWindow()
{
	Gui Main: New
	Gui Font, s9, Segoe UI
	Gui Add, Edit, x8 y56 w736 h312 +ReadOnly +Multi vLogWindow
	Gui Add, Text, x320 y16 w124 h27 +0x200, Updating Wim Loader
	Gui Show, w753 h385, Autoupdate
	Return
}


;Get first free letter drive without comma
GetFirstFreeLetter()
{
    freeDiskLetter := StdOutToVar("powershell ls function:[h-u]: -n | ?{ !(test-path $_) } | select -first 1")
	freeDiskLetter := RegExReplace(freeDiskLetter, "\r\n", "")
    freeDiskLetter := RegExReplace(freeDiskLetter, ":", "")
	return freeDiskLetter
}

LogToWindow(text)
{
	FormatTime, timeNow,,yyyy-MM-dd_HH:mm:ss
	textLog = %textLog%`r`n%timeNow% - %text%
	GuiControl, Main:, LogWindow, %textLog%
    SendMessage,0x115,7,0,Edit1,Autoupdate
}

;=====================Script START=====================
;=====================Variables=====================
;Variables
global LogWindow
global ProgressBar
global Status
global textLog
defaLocUpdate = "\\pchw\winpe"
defaLocSources = "\\pchw\images\sources"
defaultUser = cos\images
defaultPass = "123edc!@#EDC"
updateFileUpdate = WimLoader.exe
disk := "c,d,e,f,g,h,i,j,k,l,m,o,p"

MainWindow()

LogToWindow("Searching fo USB drive with WinPE...")
Loop, Parse, disk, `,
{
	usbLetter := A_LoopField
	pathToBootWim := A_LoopField . ":\sources\boot.wim"
	if FileExist(pathToBootWim)
	{
		Goto, Continue
	}
}
;I USB drive not exist
MsgBox 0x40010, USB not found, USB drive with WimLoader not found. Please copy manualy boot.wim from PCHW
	Goto, Exiting

Continue:
LogToWindow("Mounting PCHW ...")
mountLetter := GetFirstFreeLetter()
commandMount = net use %mountLetter%: %defaLocUpdate% /user:%defaultUser% %defaultPass% /p:no
LogToWindow(commandMount)
commandMountReturn := StdOutToVar(commandMount)
LogToWindow(commandMountReturn)
LogToWindow("Deleting old boot.wim")
FileDelete, %usbLetter%:\sources\boot.wim
LogToWindow("Done")
LogToWindow("Copy new boot.wim")
commandCopyNewBootWim = robocopy %mountLetter%:\media\sources\ %usbLetter%:\sources boot.wim /eta /is
commandCopyNewBootWimReturn := StdOutToVar(commandCopyNewBootWim)
LogToWindow(commandCopyNewBootWimReturn)
deleteMounts = net use %mountLetter%: /DELETE /Y
deleteMountsReturn := StdOutToVar(deleteMounts)
LogToWindow(deleteMountsReturn)
LogToWindow("Runnig latest version")
mountLetter := GetFirstFreeLetter()
mountCommand = net use %mountLetter%: %defaLocSources% /user:%defaultUser% %defaultPass% /p:no
mountCommandReturn := StdOutToVar(mountCommand)
LogToWindow(mountCommandReturn)
copyToXLoc := StdOutToVar("xcopy " mountLetter ":\WimLoader.exe x:\windows\system32 /y")

Exiting:
LogToWindow("Unmouting all")
commandUnmouting = net use %mountLetter%: /DELETE /Y
StdOutToVar(commandUnmouting)
LogToWindow("Done")
LogToWindow("Exiting...")
Sleep, 2000
Run, WimLoader.exe
ExitApp