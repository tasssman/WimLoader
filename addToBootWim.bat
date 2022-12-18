echo Mounting
dism /Mount-image /imagefile:C:\WinPE_amd64\media\sources\boot.wim /Index:1 /MountDir:C:\WinPE_amd64\mount\

echo Copy files
xcopy WimLoader.exe C:\WinPE_amd64\mount\windows\system32\ /y

echo Unmouting
Dism /Unmount-Image /MountDir:C:\WinPE_amd64\mount /commit

echo
echo To Create ISO in Deployment Envroiment run: MakeWinPEMedia /ISO C:\WinPE_amd64 C:\WinPE_amd64\WinPE_amd64.iso
echo 

pause