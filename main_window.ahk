
#Requires Autohotkey v2
;AutoGUI 2.5.8 creator: Alguimist autohotkey.com/boards/viewtopic.php?f=64&t=89901
;AHKv2converter creator: github.com/mmikeww/AHK-v2-script-converter
;Easy_AutoGUI_for_AHKv2 github.com/samfisherirl/Easy-Auto-GUI-for-AHK-v2

myGui := Construct()

Construct() {
	LogsMenu := Menu()
	LogsMenu.Add("Open WIM Log", MenuHandler)
	MenuBar_Storage := MenuBar()
	MenuBar_Storage.Add("&Logs", LogsMenu)
	myGui := Gui()
	myGui.MenuBar := MenuBar_Storage
	myGui.Add("ListBox", "x32 y16 w425 h121")
	myGui.Add("ListBox", "x32 y208 w425 h199")
	ButtonFormatdisk := myGui.Add("Button", "x288 y144 w80 h23", "Format disk")
	CheckBox1 := myGui.Add("CheckBox", "x32 y144 w110 h15", "Show USB drives")
	ButtonRefreshDisks := myGui.Add("Button", "x376 y144 w80 h23", "Refresh Disks")
	DropDownList1 := myGui.Add("DropDownList", "x32 y434 w100", ["UEFI Format", "LEGACY Format"])
	myGui.Add("Text", "x32 y504 w57 h23", "IP Address:")
	myGui.Add("Text", "x88 y504 w91 h23")
	ButtonRenewIP := myGui.Add("Button", "x184 y504 w80 h23", "Renew IP")
	myGui.Add("Text", "x32 y531 w250 h23", "Version  - Copyright Miasik Jakub")
	myGui.Add("Text", "x32 y410 w200 h22", "\\pchw\images\path")
	ButtonRefreshImages := myGui.Add("Button", "x376 y410 w80 h30", "Refresh Images")
	ButtonLoadmanually := myGui.Add("Button", "x376 y464 w80 h23", "Load manually")
	Edit1 := myGui.Add("Edit", "x464 y16 w305 h536 +Multi +ReadOnly")
	ButtonInstallImage := myGui.Add("Button", "Default x32 y464 w99 h28", "Install Image")
	ButtonFormatdisk.OnEvent("Click", OnEventHandler)
	CheckBox1.OnEvent("Click", OnEventHandler)
	ButtonRefreshDisks.OnEvent("Click", OnEventHandler)
	DropDownList1.OnEvent("Change", OnEventHandler)
	ButtonRenewIP.OnEvent("Click", OnEventHandler)
	ButtonRefreshImages.OnEvent("Click", OnEventHandler)
	ButtonLoadmanually.OnEvent("Click", OnEventHandler)
	Edit1.OnEvent("Change", OnEventHandler)
	ButtonInstallImage.OnEvent("Click", OnEventHandler)
	myGui.OnEvent('Close', (*) => ExitApp())
	myGui.Title := "WIM Loader (Clone)"
	myGui.Show("w777 h558")
	
	MenuHandler(*)
	{
		ToolTip("Click! This is a sample action.`n", 77, 277)
		SetTimer () => ToolTip(), -3000 ; tooltip timer
	}
	
	OnEventHandler(*)
	{
		ToolTip("Click! This is a sample action.`n"
		. "Active GUI element values include:`n"  
		. "ButtonFormatdisk => " ButtonFormatdisk.Text "`n" 
		. "CheckBox1 => " CheckBox1.Value "`n" 
		. "ButtonRefreshDisks => " ButtonRefreshDisks.Text "`n" 
		. "DropDownList1 => " DropDownList1.Text "`n" 
		. "ButtonRenewIP => " ButtonRenewIP.Text "`n" 
		. "ButtonRefreshImages => " ButtonRefreshImages.Text "`n" 
		. "ButtonLoadmanually => " ButtonLoadmanually.Text "`n" 
		. "Edit1 => " Edit1.Value "`n" 
		. "ButtonInstallImage => " ButtonInstallImage.Text "`n", 77, 277)
		SetTimer () => ToolTip(), -3000 ; tooltip timer
	}
	
	return myGui
}