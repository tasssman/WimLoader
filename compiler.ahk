#SingleInstance, Force
;Run, D:\Programy\AutoHotkey\Compiler\Ahk2Exe.exe /in create_WINPE.ahk /out WinPECreatorUpdater.exe /ahk %A_WorkingDir%\Compiler\autohotkey.exe
;Run, D:\Programy\AutoHotkey\Compiler\Ahk2Exe.exe /in create_WINPE.ahk /out \\pchw\d$\winpe\WimLoader\WinPECreatorUpdater.exe /ahk %A_WorkingDir%\Compiler\autohotkey.exe /bin %A_WorkingDir%\Compiler\AutoHotkeySC.bin
Run, D:\!PC\Dokumenty\winpe_v2\Compiler\Ahk2Exe.exe /in D:\!PC\Dokumenty\winpe_v2\wim_loader.ahk /out D:\Temp\!doSkasowania\WimLoader.exe /bin D:\!PC\Dokumenty\winpe_v2\Compiler\AutoHotkeySC.bin
Run, D:\!PC\Dokumenty\winpe_v2\Compiler\Ahk2Exe.exe /in D:\!PC\Dokumenty\winpe_v2\wim_autoupdate.ahk /out D:\Temp\!doSkasowania\WimAutoUpdate.exe 
Run, D:\!PC\Dokumenty\winpe_v2\Compiler\Ahk2Exe.exe /in D:\!PC\Dokumenty\winpe_v2\create_winpe.ahk /out D:\Temp\!doSkasowania\create_winpe.exe 