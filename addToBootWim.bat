xcopy \\pchw\d$\winpe\media\sources\boot.wim D:\Temp\ /y
mkdir d:\temp\mount
dism /Mount-image /imagefile:D:\Temp\boot.wim /Index:1 /MountDir:D:\Temp\Mount
xcopy \\pchw\d$\images\sources\WimLoader.exe D:\Temp\mount\windows\system32\ /y
Dism /Unmount-image /MountDir:D:\Temp\mount /Commit
xcopy D:\Temp\boot.wim \\pchw\d$\winpe\media\sources\  /y
pause
