RunCMD(P_CmdLine, P_WorkingDir := "", P_Codepage := "cp0", P_Func := 0)
{ ;  RunCMD() v1.18 by SKAN for ah2 on D67D/D91T @ autohotkey.com/r?t=133668
  ;  Based on StdOutToVar.ahk by Sean @ www.autohotkey.com/board/topic/15455-stdouttovar

    Local  hPipeR := 0, hPipeW  := 0,   PIPE_NOWAIT := 1
        ,  dwMask := 1, dwFlags := 1 ;  dwMask = dwFlags = HANDLE_FLAG_INHERIT = 1

    DllCall("Kernel32\CreatePipe", "ptrp",&hPipeR, "ptrp",&hPipeW, "ptr",0, "int",0)
  , DllCall("Kernel32\SetHandleInformation", "ptr",hPipeW, "int",dwMask, "int",dwFlags)
  , DllCall("Kernel32\SetNamedPipeHandleState", "ptr",hPipeR, "uintp",PIPE_NOWAIT, "ptr",0, "ptr",0)

    Local  B_OK := 0,       P8  :=  A_PtrSize == 8
        ,  STARTF_USESTDHANDLES :=  0x100
        ,  STARTUPINFO          :=  Buffer(P8 ? 104 : 68, 0)                   ;  STARTUPINFO

    NumPut("uint", P8 ? 104 : 68, STARTUPINFO)                                 ;  STARTUPINFO.cb
  , NumPut("uint", STARTF_USESTDHANDLES, STARTUPINFO, P8 ? 60 : 44)            ;  STARTUPINFO.dwFlags
  , NumPut("ptr",  hPipeW, STARTUPINFO, P8 ? 88 : 60)                          ;  STARTUPINFO.hStdOutput
  , NumPut("ptr",  hPipeW, STARTUPINFO, P8 ? 96 : 64)                          ;  STARTUPINFO.hStdError

    Local  CREATE_NO_WINDOW     :=  0x08000000
        ,  PRIORITY_CLASS       :=  DllCall("Kernel32\GetPriorityClass", "ptr",-1, "uint")
        ,  PROCESS_INFORMATION  :=  Buffer(P8 ?  24 : 16, 0)                   ;  PROCESS_INFORMATION

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
                    , "uint" )

  , DllCall("Kernel32\CloseHandle", "ptr",hPipeW)

    If ( B_OK = False and DllCall("Kernel32\CloseHandle", "ptr",hPipeR) )
         Throw OSError(,, "Create process failed.")

    RunCMD.PID          :=  NumGet(PROCESS_INFORMATION, P8 ? 16 : 8, "uint")
  , RunCMD.ExitCode     :=  0
  , RunCMD.Iterations   :=  0
  , RunCMD.CtrlC        :=  0

    Local  FileObj      :=  FileOpen(hPipeR, "h", P_Codepage)
        ,  Data         :=  {Text: "", Line: "", LineNum: 1, LineFeed: 1, Lines: ""}
        
                    PeekNamedPipe()
                    {
                       RunCMD.Iterations += ( Sleep(1), 1 )
                       Return DllCall( "Kernel32\PeekNamedPipe", "ptr",hPipeR, "ptr",0, "int",0, "ptr",0
                                     , "uintp",&B_OK, "ptr",0 )
                    }

                    
                    ExitProcess()                           ;  Refer CtrlC() @ autohotkey.com/r?t=140000
                    {
                        Local  hConsoleInput
                            ,  STD_INPUT_HANDLE :=  -10
                            ,  INPUT_RECORD     :=  Buffer(20, 0)
                            ,  CTRL_C_EVENT     :=  0
                    
                        DllCall("Kernel32\AttachConsole", "uint",RunCMD.PID)
                      , NumPut("short",  1, INPUT_RECORD, 0)  ;  INPUT_RECORD.EventType =  KEY_EVENT
                      , NumPut("uint",   1, INPUT_RECORD, 4)  ;  KEY_EVENT_RECORD.bKeyDown =  True
                      , NumPut("short", 13, INPUT_RECORD, 14) ;  VK_RETURN = 13

                      , hConsoleInput := DllCall("Kernel32\GetStdHandle", "int",STD_INPUT_HANDLE, "ptr")
                      , DllCall( "Kernel32\WriteConsoleInputW"
                               , "ptr",  hConsoleInput
                               , "ptr",  INPUT_RECORD
                               , "uint", 1
                               , "uintp",0 )
                      , DllCall("Kernel32\CloseHandle", "ptr",hConsoleInput)

                      , DllCall("Kernel32\SetConsoleCtrlHandler", "ptr",0, "uint",True)
                      , DllCall("Kernel32\GenerateConsoleCtrlEvent", "uint",CTRL_C_EVENT, "uint",0)
                      , DllCall("Kernel32\FreeConsole")

                      , RunCMD.CtrlC := ProcessWaitClose(RunCMD.PID, 5)
                      , DllCall("Kernel32\SetConsoleCtrlHandler", "ptr",0, "uint",False)
                        Return RunCMD.CtrlC
                    }


                    LineSplit(LF?)
                    {
                        RegExMatch(Data.Text, "\R", &LF)

                        If ( Data.LineFeed := LF == "" ? 0 : LF[] == "`r" ? -1 : 1 )
                             Data.Line := SubStr(Data.Text, 1, LF.Pos - 1)
                           , Data.Text := SubStr(Data.Text, LF.Pos + LF.Len)
                    
                        Return Data.LineFeed
                    }

    While ( RunCMD.PID and PeekNamedPipe() )
    {
        If ( RunCMD.CtrlC And ExitProcess() )
             Break 
             
        If ( B_OK == 0 )
             Continue 

        Data.Text .= FileObj.Read()

        If ( P_Func )
        While ( LineSplit() )
                Data.Lines .= P_Func.Call(Data.Line, Data.LineNum++, Data.LineFeed)
    }
    
    If ( P_Func and Data.Text )  
         P_Func.Call(Data.Text, Data.LineNum++, 0)

    Local  hProcess   :=  NumGet(PROCESS_INFORMATION, 0, "ptr")
        ,  hThread    :=  NumGet(PROCESS_INFORMATION, A_PtrSize, "ptr")
        ,  ExitCode   :=  0
 
    DllCall("Kernel32\GetExitCodeProcess", "ptr",hProcess, "uintp",&ExitCode)
  , DllCall("Kernel32\CloseHandle", "ptr",hProcess)
  , DllCall("Kernel32\CloseHandle", "ptr",hThread)
  , DllCall("Kernel32\CloseHandle", "ptr",hPipeR)

  , RunCMD.PID        :=  0
  , RunCMD.ExitCode   :=  Format(ExitCode  > 259 ? "0x{:X}" : "{}", ExitCode)
    Return P_Func == 0 ? Data.Text : Data.Lines
}