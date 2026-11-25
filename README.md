Installation:
- on USB drive create partition and format it to FAT32
- copy files from \\pchw\d$\winpe\media\*.* to USB drive
Now you can put USB stick on USB port on computer and device should be visible as boot from USB (if not check other settings of your device that prevent USB boot)

Blank GUI:
- Compile `gui_mockup.ahk` with AutoHotkey v2 Ahk2Exe to create a standalone executable, for example:
  `Ahk2Exe.exe /in gui_mockup.ahk /out WimLoaderGui.exe /base "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"` (adjust the base path if needed)
- Put `WimLoaderGui.exe` next to `createWinPEFromScratch.bat`; the script copies it into the WinPE image when present. Launch `WimLoaderGui.exe` from WinPE. The GUI is a blank shell; disk, image, and installation actions are disabled until their functionality is implemented.
