#SingleInstance Force
;RunWait, D:\Programy\AutoHotkey\Compiler\Ahk2Exe.exe /in create_WINPE.ahk /out WinPECreatorUpdater.exe /ahk %A_WorkingDir%\Compiler\autohotkey.exe
;RunWait, D:\Programy\AutoHotkey\Compiler\Ahk2Exe.exe /in create_WINPE.ahk /out \\pchw\d$\winpe\WimLoader\WinPECreatorUpdater.exe /ahk %A_WorkingDir%\Compiler\autohotkey.exe /bin %A_WorkingDir%\Compiler\AutoHotkeySC.bin

;WimLoader_dev
RunWait "C:\Programy\AutoHotkey_v1\Compiler\Ahk2Exe.exe /in C:\Users\jmiasik\Documents\ProjektyGit\WimLoader\wim_loader.ahk /out \\pchw\d$\images\sources\WimLoader_2_0_1_latest.exe /base C:\Programy\AutoHotkey_v2\AutoHotkey64.exe"

;WimLoader
;RunWait, D:\!PC\Dokumenty\winpe_v2\Compiler\Ahk2Exe.exe /in D:\!PC\Dokumenty\winpe_v2\wim_loader.ahk /out \\pchw\d$\images\sources\WimLoader_1_0_0_0.exe /base D:\!PC\Dokumenty\winpe_v2\Compiler\AutoHotkey.exe /bin D:\!PC\Dokumenty\winpe_v2\Compiler\Unicode64-bit.bin

;WimAutoupdate
RunWait "C:\Programy\AutoHotkey_v1\Compiler\Ahk2Exe.exe /in C:\Users\jmiasik\Documents\ProjektyGit\WimLoader\wim_autoupdate.ahk /out \\pchw\d$\images\sources\WimAutoUpdate.exe /base C:\Programy\AutoHotkey_v2\AutoHotkey64.exe"
MsgBox "Done"