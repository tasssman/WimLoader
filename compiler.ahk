#SingleInstance, Force
;RunWait, D:\Programy\AutoHotkey\Compiler\Ahk2Exe.exe /in create_WINPE.ahk /out WinPECreatorUpdater.exe /ahk %A_WorkingDir%\Compiler\autohotkey.exe
;RunWait, D:\Programy\AutoHotkey\Compiler\Ahk2Exe.exe /in create_WINPE.ahk /out \\pchw\d$\winpe\WimLoader\WinPECreatorUpdater.exe /ahk %A_WorkingDir%\Compiler\autohotkey.exe /bin %A_WorkingDir%\Compiler\AutoHotkeySC.bin

;WimLoader
;RunWait, D:\!PC\Dokumenty\winpe_v2\Compiler\Ahk2Exe.exe /in D:\!PC\Dokumenty\winpe_v2\wim_loader.ahk /out \\pchw\d$\images\sources\WimLoader_0_14_0_4.exe /base D:\!PC\Dokumenty\winpe_v2\Compiler\AutoHotkey.exe /bin D:\!PC\Dokumenty\winpe_v2\Compiler\Unicode64-bit.bin

;WimAutoupdate
RunWait, D:\!PC\Dokumenty\winpe_v2\Compiler\Ahk2Exe.exe /in D:\!PC\Dokumenty\winpe_v2\wim_autoupdate.ahk /out \\pchw\d$\images\sources\WimAutoUpdate.exe