
#Requires Autohotkey v2
;AutoGUI creator: Alguimist autohotkey.com/boards/viewtopic.php?f=64&t=89901
;AHKv2converter creator: github.com/mmikeww/AHK-v2-script-converter
;EasyAutoGUI-AHKv2 github.com/samfisherirl/Easy-Auto-GUI-for-AHK-v2

if A_LineFile = A_ScriptFullPath && !A_IsCompiled
{
	myGui := Constructor()
	myGui.Show("w361 h352")
}

Constructor()
{	
	myGui := Gui()
	CheckBox1 := myGui.Add("CheckBox", "x16 y8 w337 h20", "select on startup last used image")
	CheckBox2 := myGui.Add("CheckBox", "x16 y+1 w337 h20", "select first disk on list")
	CheckBox2 := myGui.Add("CheckBox", "x16 y+1 w337 h20", "fast start (no info about machine)")
	ButtonClose := myGui.Add("Button", "x137 y320 w80 h23", "&Close")
	CheckBox1.OnEvent("Click", OnEventHandler)
	ButtonClose.OnEvent("Click", OnEventHandler)
	myGui.OnEvent('Close', (*) => myGui.Destroy)
	myGui.Title := "Options"
	
	OnEventHandler(*)
	{
		ToolTip("Click! This is a sample action.`n"
		. "Active GUI element values include:`n"  
		. "CheckBox1 => " CheckBox1.Value "`n" 
		. "ButtonClose => " ButtonClose.Text "`n", 77, 277)
		SetTimer () => ToolTip(), -3000 ; tooltip timer
	}
	
	return myGui
}