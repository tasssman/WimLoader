#SingleInstance, Force
;RunWait, D:\Programy\AutoHotkey\Compiler\Ahk2Exe.exe /in create_WINPE.ahk /out WinPECreatorUpdater.exe /ahk %A_WorkingDir%\Compiler\autohotkey.exe
;RunWait, D:\Programy\AutoHotkey\Compiler\Ahk2Exe.exe /in create_WINPE.ahk /out \\pchw\d$\winpe\WimLoader\WinPECreatorUpdater.exe /ahk %A_WorkingDir%\Compiler\autohotkey.exe /bin %A_WorkingDir%\Compiler\AutoHotkeySC.bin

;WimLoader
RunWait, D:\!PC\Dokumenty\winpe_v2\Compiler\Ahk2Exe.exe /in D:\!PC\Dokumenty\winpe_v2\wim_loader.ahk /out \\pchw\d$\temp\WimLoader.exe /bin D:\!PC\Dokumenty\winpe_v2\Compiler\AutoHotkeySC.bin
;RunWait, D:\!PC\Dokumenty\winpe_v2\Compiler\Ahk2Exe.exe /in D:\!PC\Dokumenty\winpe_v2\wim_loader.ahk /out \\sccmsrv\srvhw\images\help_files\WimLoader.exe /bin D:\!PC\Dokumenty\winpe_v2\Compiler\AutoHotkeySC.bin

;WimAutoupdate
;RunWait, D:\!PC\Dokumenty\winpe_v2\Compiler\Ahk2Exe.exe /in D:\!PC\Dokumenty\winpe_v2\wim_autoupdate.ahk /out D:\Temp\!doSkasowania\WimAutoUpdate.exe 
;RunWait, D:\!PC\Dokumenty\winpe_v2\Compiler\Ahk2Exe.exe /in D:\!PC\Dokumenty\winpe_v2\wim_autoupdate.ahk /out \\pchw\images\sources\WimAutoUpdate.exe 
;RunWait, D:\!PC\Dokumenty\winpe_v2\Compiler\Ahk2Exe.exe /in D:\!PC\Dokumenty\winpe_v2\create_winpe.ahk /out D:\Temp\!doSkasowania\create_winpe.exe 