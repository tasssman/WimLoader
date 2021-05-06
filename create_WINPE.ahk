#SingleInstance, force
;Get first free letter drive
GetFirstFreeLetter()
{
	freeDiskLetter := ComObjCreate("WScript.Shell").Exec("powershell -windowstyle hidden ls function:[h-z]: -n | ?{ !(test-path $_) } | select -first 1").StdOut.ReadAll()
	freeDiskLetter := RegExReplace(freeDiskLetter, "\r\n", "")
	freeDiskLetter := RegExReplace(freeDiskLetter, ":", "")
	return freeDiskLetter
}

MenuFormat(listdisks)
{
	Gui, CreateWINPE:Add, ListBox, x15 y25 w535 h186 vListaDyskow, %listdisks%
	Gui, CreateWINPE:Add, Button, x15 y220 w115 h50 gCreateWinpe vCreateWinpeButton, Create WINPE
	;Gui, CreateWINPE:Add, Button, x152 y220 w115 h50 gUpdateWinpe, Update WINPE
	;Gui, CreateWINPE:Add, Button, x292 y220 w115 h50 , Copy Images
	Gui, CreateWINPE:Add, Button, x435 y220 w115 h50 gButtonClose vCloseButton, Close
	Gui, CreateWINPE:Show, w565 h283, WINPE Creator
	return
}

WaitWindow(text)
{
	Gui, Wait: +AlwaysOnTop +Disabled -SysMenu +Owner  ; +Owner avoids a taskbar button.
	Gui, Wait:Font, s20
	Gui, Wait:Add, Text,w200 Center, %text%
	Gui, Wait:-Caption
	Gui, Wait:Show, NoActivate
}

;Start script=====================================================
;Globals==============================
global ListaDyskow
global CreateWinpeButton
global CloseButton
;Variables==============================
;Credentials for winpeupdate
user_winpe = images
pass_winpe := 123edc!@#EDC

;Path for copy winpe
path_winpe = \\pcimages\winpe\media

;Take disk data from local PC
diskShow =
diskList := ComObjCreate("WScript.Shell").Exec("powershell -windowstyle hidden Get-Disk | Format-List").StdOut.ReadAll()
StringReplace, diskList, diskList, `n, , All
pos = 1
	While pos := RegExMatch(diskList,"UniqueId.*?IsBoot",disk, pos+StrLen(disk))
	{
		RegExMatch(disk,"O)(Number.*?: )(.*)(Path)",diskId)
		RegExMatch(disk,"O)(Model.*?: )(.*)(Serial)",model)
		RegExMatch(disk,"O)(Size.*?: )(.*)(Allocated)",size)
		RegExMatch(disk,"O)(PartitionStyle.*?: )(.*)(IsReadOnly)",partitionType)
		diskShow = % diskShow "No: "diskId[2]" === Model: "model[2]" === Size: "size[2]" === Partition Type: "partitionType[2]"|"
	}

MenuFormat(diskShow)
return

;~ Creating pendrive
CreateWinpe:
GuiControl,Disable, CreateWinpeButton
GuiControl,Disable, CloseButton
Sleep, 20000
;Check for path if exist
if (!FileExist(path_winpe)) {
	MsgBox, 4112, Not found, Localization %path_winpe% NOT EXIST!`nExiting app.
	return
}
GuiControlGet, diskToFormat,,ListaDyskow
RegExMatch(diskToFormat,"[0-9]{1}",idToFormat)
if (idToFormat != "")
{
	RunWait, powershell.exe -Command "& {Get-Disk %idToFormat% | Clear-Disk -RemoveData -Confirm:$false}"
	partiWinpe := GetFirstFreeLetter()
	command = New-Partition -DiskNumber %idToFormat% -Size 2048MB -IsActive -DriveLetter %partiWinpe% | Format-Volume -FileSystem FAT32 -NewFileSystemLabel WINPE
	RunWait, powershell.exe -Command "& {%command%}"
	partiImages := GetFirstFreeLetter()
	command = New-Partition -DiskNumber %idToFormat% -UseMaximumSize -DriveLetter %partiImages% | Format-Volume -FileSystem NTFS -NewFileSystemLabel Images
	RunWait, powershell.exe -Command "& {%command%}"
} else {
	MsgBox, 4144, Select, Select ANY disk
	return
}
RunWait, powershell.exe -Command $secpasswd = ConvertTo-SecureString 'pass_winpe' -AsPlainText -Force;$mycreds = New-Object System.Management.Automation.PSCredential('%user_winpe%'`, $secpasswd);New-PSDrive -Name 'winpe' -PSProvider 'FileSystem' -Root %path_winpe% -credential $mycred;Copy-Item winpe:\* %partiWinpe%:\ -verbose -Recurse
FileCreateDir, %partiImages%:\Images
GuiControl,Enable, CreateWinpeButton
GuiControl,Enable, CloseButton
MsgBox, 64, Done!, WinPE is created

return

UpdateWinpe:
return

ButtonClose:
CreateWINPEGuiClose:
Gui, CreateWINPE:Destroy
ExitApp