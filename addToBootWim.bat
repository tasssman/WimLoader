echo Mounting
dism /Mount-image /imagefile:c:\winpe\media\sources\boot.wim /Index:1 /MountDir:c:\winpe\mount\

echo Copy files
xcopy WimLoader.exe c:\winpe\mount\windows\system32\ /y

echo Unmouting
Dism /Unmount-Image /MountDir:c:\winpe\mount /commit

echo
echo To Create ISO in Deployment Envroiment run: MakeWinPEMedia /ISO c:\winpe\WinPE_amd64.iso
echo 

pause