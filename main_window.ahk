﻿; Generated by Auto-GUI 3.0.0
#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%
SetBatchLines -1

Gui Font, s9, Segoe UI
Gui Add, ListBox, x32 y16 w504 h147, DiskList
Gui Add, ListBox, x32 y208 w503 h225, ImagesList
Gui Add, Text, x25 y497 w83 h23 +0x200   , Version 1.0.0.0
Gui Add, Button, x32 y464 w80 h23 +Default   , Format Disk
Gui Add, Button, x120 y464 w80 h23 +Default   , Load image
Gui Add, Button, x456 y160 w80 h23 +Default   , Refresh Disks
Gui Add, Button, x456 y432 w80 h23 +Default   , Refresh Images
Gui Add, Text, x33 y425 w153 h22 +0x200 , Text
Gui Add, Button, x456 y456 w80 h23 +Default, Load from USB

Gui Show, w563 h526, WIM Loader
Return

GuiEscape:
GuiClose:
    ExitApp
