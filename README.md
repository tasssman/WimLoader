Installation:
- on USB drive create partition and format it to FAT32
- copy files from \\pchw\d$\winpe\media\*.* to USB drive
Now you can put USB stick on USB port on computer and device should be visible as boot from USB (if not check other settings of your device that prevent USB boot)

New GUI:
- Compile `WimLoader.ahk` with AutoHotkey v2 Ahk2Exe to create a standalone executable, for example:
  `Ahk2Exe.exe /in WimLoader.ahk /out WimLoader.exe /base "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"` (adjust the base path if needed)
- Copy `WimLoader.exe` to the WinPE image or another location accessible from WinPE and launch it there.
- The legacy source is retained in `WimLoader_old.ahk`.
- The GUI lists disks and WIM files. Formatting and installation remain disabled.
- For an inaccessible network image source, enter credentials in the connection dialog. Only the user name is saved to `wimloader.ini` on the WinPE source drive; the password is not saved. If the source drive is unavailable or not writable, the dialog reports that the user name could not be saved.
