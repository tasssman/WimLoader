set /p WinPePath=Wpisz sciezke do WinPE:
echo Mounting
dism /Mount-image /imagefile:%WinPePath%\media\sources\boot.wim /Index:1 /MountDir:%WinPePath%\mount\

echo Copy files
xcopy WimLoader.exe %WinPePath%\mount\windows\system32\ /y

echo Unmouting
Dism /Unmount-Image /MountDir:%WinPePath%\mount /commit

echo
echo To Create ISO in Deployment Envroiment run: MakeWinPEMedia /ISO %WinPePath% %WinPePath%\WinPE_amd64.iso
echo 

pause