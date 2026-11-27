#Requires AutoHotkey v2.0
#SingleInstance Force

#Include lib\RunCmd.ahk

defaLocImages := "\\pchw\images"
version := "2.2.0.003"
updateSource := "\\ntshare\helpdesk\scripts\WinPE_HW\media\sources"
availableUpdate := ""
updateBusy := false
iniName := "wimloader.ini"
imagePath := ""
ownedMappings := []

mainGui := Gui(, "WIM Loader " . version)
mainGui.BackColor := "F4F7FB"
mainGui.SetFont("s10", "Segoe UI")

mainGui.SetFont("s10 bold", "Segoe UI")
mainGui.Add("GroupBox", "x24 y24 w570 h302", "1. Select a destination disk")
mainGui.SetFont("s9", "Segoe UI")
mainGui.Add("Text", "x40 y52 w400 h20 c64748B", "The selected disk will be erased during installation.")
UsbShow := mainGui.Add("CheckBox", "x40 y81 w130 h22", "Show USB drives")
RefreshDiskButton := mainGui.Add("Button", "x460 y76 w118 h28", "Refresh disks")
diskList := mainGui.Add("ListView", "x40 y114 w538 h154 -Multi", ["Disk", "Model", "Size", "Partition style"])
diskList.ModifyCol(1, 65)
diskList.ModifyCol(2, 190)
diskList.ModifyCol(3, 85)
diskList.ModifyCol(4, 150)
diskStatusText := mainGui.Add("Text", "x40 y276 w520 h20 c64748B", "No destination disk selected")
mainGui.Add("Button", "x40 y298 w160 h27 Disabled", "Format selected disk")
mainGui.Add("Button", "x208 y298 w130 h27 Disabled", "Format all disks")

mainGui.SetFont("s10 bold", "Segoe UI")
mainGui.Add("GroupBox", "x24 y340 w570 h268", "2. Select a Windows image")
mainGui.SetFont("s9", "Segoe UI")
mainGui.Add("Text", "x40 y369 w360 h20 c64748B", "Choose a WIM file from the image source.")
ChangePathButton := mainGui.Add("Button", "x342 y365 w112 h28", "Change path")
RefreshImagesButton := mainGui.Add("Button", "x463 y365 w115 h28", "Refresh images")
imagePathText := mainGui.Add("Edit", "x40 y401 w538 h27 ReadOnly")
imagesList := mainGui.Add("ListBox", "x40 y438 w538 h152")

mainGui.SetFont("s10 bold", "Segoe UI")
mainGui.Add("GroupBox", "x610 y24 w346 h254", "3. Review installation")
mainGui.SetFont("s9", "Segoe UI")
mainGui.Add("Text", "x626 y52 w310 h20 c64748B", "Select a disk and image to review.")
mainGui.Add("Text", "x626 y85 w82 h20 c64748B", "Destination")
reviewDestination := mainGui.Add("Text", "x716 y85 w220 h20", "Not selected")
mainGui.Add("Text", "x626 y116 w82 h20 c64748B", "Model")
reviewModel := mainGui.Add("Text", "x716 y116 w220 h20", "Not selected")
mainGui.Add("Text", "x626 y147 w82 h20 c64748B", "Image")
reviewImage := mainGui.Add("Text", "x716 y147 w220 h34", "Not selected")
mainGui.Add("Text", "x626 y185 w82 h20 c64748B", "Boot mode")
mainGui.Add("DropDownList", "x716 y181 w145 Disabled", ["UEFI", "Legacy BIOS"])
mainGui.Add("Button", "x626 y216 w314 h32 Disabled", "Install image")
mainGui.Add("Text", "x626 y254 w314 h20 Center c64748B", "Installation not yet available")

mainGui.SetFont("s10 bold", "Segoe UI")
mainGui.Add("GroupBox", "x610 y290 w346 h318", "Activity")
mainGui.SetFont("s9", "Segoe UI")
mainGui.Add("Text", "x626 y317 w250 h20", "Ready")
mainGui.Add("Text", "x896 y317 w40 h20 Right c64748B", "0%")
mainGui.Add("Progress", "x626 y342 w310 h10", 0)
LogWindow := mainGui.Add("Edit", "x626 y361 w310 h231 ReadOnly Multi")

mainGui.SetFont("s9", "Segoe UI")
footerStatus := mainGui.Add("Text", "x24 y626 w175 h22 c52647A", "No disks or images loaded")
mainGui.Add("Text", "x210 y626 w26 h22 c52647A", "IP:")
ipField := mainGui.Add("Edit", "x236 y624 w388 h24 ReadOnly BackgroundF4F7FB -Border -E0x200")
footerBrand := mainGui.Add("Text", "x656 y626 w300 h22 Right c64748B", "WinPE-ready  |  WIM Loader")
updateButton := mainGui.Add("Button", "x710 y620 w246 h32 Hidden", "")
updateButton.OnEvent("Click", UpdateApp)

UsbShow.OnEvent("Click", ShowDrivesUsb)
RefreshDiskButton.OnEvent("Click", RefreshDisks)
diskList.OnEvent("ItemSelect", DiskSelectionChanged)
ChangePathButton.OnEvent("Click", ChangePath)
RefreshImagesButton.OnEvent("Click", RefreshImages)
imagesList.OnEvent("Change", ImageSelectionChanged)
mainGui.OnEvent("Close", CloseApp)
mainGui.Show("w980 h660")
LogToWindow("Main menu was loaded", 1, 1)
listDisk()
IpCheck()
ConnectImageSource(defaLocImages)

IpCheck()
{
    global ipField

    LogToWindow("Loading IPv4 addresses...", 1, 1)
    ipAddress := RunCMD("powershell gwmi Win32_NetworkAdapterConfiguration | Where { $_.IPAddress } | Select -Expand IPAddress | Where { $_ -notlike '*:*' }")
    if (RunCMD.ExitCode != 0) {
        ipField.Value := "Unable to load IPv4 addresses."
        LogToWindow("Could not load IPv4 addresses (exit code " . RunCMD.ExitCode . "): " . Trim(ipAddress), 1, 1)
        return
    }

    ipAddress := Trim(ipAddress, " `t`r`n")
    if (ipAddress = "") {
        ipField.Value := "No IPv4 addresses found."
        LogToWindow("No IPv4 addresses found.", 1, 1)
        return
    }
    ipField.Value := RegExReplace(ipAddress, "\R+", " | ")
    LogToWindow("IPv4 addresses loaded.", 1, 1)
}

listDisk(*)
{
    global UsbShow, diskList, diskStatusText, footerStatus, diskRows
    global reviewDestination, reviewModel

    LogToWindow("Listing disks...", 1, 1)
    diskList.Delete()
    diskRows := []
    diskStatusText.Value := "Loading disks..."
    reviewDestination.Value := "Not selected"
    reviewModel.Value := "Not selected"
    footerStatus.Value := "Loading disks..."

    if (UsbShow.Value = 1) {
        diskOutput := RunCMD("powershell Get-Disk | Format-List")
    } else {
        diskOutput := RunCMD("powershell Get-Disk | Where-Object -FilterScript {$_.Bustype -notcontains 'usb'} | Format-List")
    }

    diskOutput := StrReplace(diskOutput, "`r`n")
    pos := 0
    records := []
    while pos := RegExMatch(diskOutput, "UniqueId.*?IsBoot", &record, pos + 1) {
        records.Push(record[])
    }

    for , item in records {
        if !RegExMatch(item, "(Number.*?: )(.*)(Path)", &diskId)
            || !RegExMatch(item, "(Model.*?: )(.*)(Serial)", &model)
            || !RegExMatch(item, "(Size.*?: )(.*)(Allocated)", &size)
            || !RegExMatch(item, "(PartitionStyle.*?: )(.*)(IsReadOnly)", &partitionType) {
            LogToWindow("Could not parse a disk record: " . item, 1, 1)
            continue
        }

        number := Trim(diskId[2])
        modelName := Trim(model[2])
        diskSize := Trim(size[2])
        partitionStyle := Trim(partitionType[2])
        diskRows.Push({Number: number, Model: modelName})
        diskList.Add(, "Disk " . number, modelName, diskSize, partitionStyle)
    }

    if (diskRows.Length = 0) {
        diskStatusText.Value := "No destination disk selected"
        footerStatus.Value := "No disks found"
        if (Trim(diskOutput) = "") {
            LogToWindow("No disk information was returned.", 1, 1)
        } else if (records.Length = 0) {
            LogToWindow("Could not find disk records in command output: " . Trim(diskOutput), 1, 1)
        }
        return
    }

    diskStatusText.Value := diskRows.Length . " disk(s) found; select a destination disk"
    footerStatus.Value := diskRows.Length . " disk(s) found"
    LogToWindow("Loading disks DONE", 1, 1)
}

ShowDrivesUsb(*)
{
    LogToWindow("Show USB checkbox selected", 1, 1)
    listDisk()
}

RefreshDisks(*)
{
    LogToWindow("Refresh disks button pressed", 1, 1)
    listDisk()
}

DiskSelectionChanged(control, row, selected)
{
    global diskRows, reviewDestination, reviewModel

    if !selected
        return

    disk := diskRows[row]
    reviewDestination.Value := "Disk " . disk.Number
    reviewModel.Value := disk.Model
    LogToWindow("Selected destination disk " . disk.Number . ": " . disk.Model, 1, 1)
}

ConnectImageSource(path)
{
    global imagePath, imagePathText, imagesList, reviewImage

    path := RTrim(Trim(path), "\")
    if RegExMatch(path, "i)^[a-z]:$")
        path .= "\"
    if (path = "") {
        LogToWindow("Image source path is empty.", 1, 1)
        return false
    }

    if !DirExist(path) {
        if !RegExMatch(path, "^\\\\[^\\]+\\[^\\]+(?:\\.*)?$") {
            LogToWindow("Image source is not accessible: " . path, 1, 1)
            return false
        }
        if !ShowNetworkLogin(path)
            return false
    }

    imagePath := path
    imagePathText.Value := path
    imagesList.Delete()
    reviewImage.Value := "Not selected"
    CheckForUpdate()
    loadingImages(path)
    return true
}

loadingImages(path)
{
    global imagesList

    LogToWindow("Loading images...", 1, 1)
    imagesList.Delete()
    Loop Files RTrim(path, "\") . "\*.wim"
        imagesList.Add([A_LoopFileFullPath])
    LogToWindow("Loading images DONE. Current path: " . path, 1, 1)
}

ChangePath(*)
{
    global mainGui, imagePath, defaLocImages

    currentPath := imagePath != "" ? imagePath : defaLocImages
    pathGui := Gui("+Owner" . mainGui.Hwnd, "Enter new path for WIMs")
    pathGui.BackColor := "F4F7FB"
    pathGui.SetFont("s9", "Segoe UI")
    pathGui.Add("Text", "x16 y18 w440 h20 c64748B", "WIMs Path:")
    pathEdit := pathGui.Add("Edit", "x16 y46 w440 h26", currentPath)
    okButton := pathGui.Add("Button", "x268 y94 w90 h28 Default", "OK")
    cancelButton := pathGui.Add("Button", "x366 y94 w90 h28", "Cancel")

    okButton.OnEvent("Click", Submit)
    cancelButton.OnEvent("Click", Cancel)
    pathGui.OnEvent("Close", Cancel)
    pathGui.OnEvent("Escape", Cancel)
    mainGui.Opt("+Disabled")
    pathGui.Show("w472 h138")
    pathEdit.Focus()
    SendMessage(0xB1, 0, -1, pathEdit)

    Submit(*)
    {
        newPath := pathEdit.Value
        pathGui.Destroy()
        mainGui.Opt("-Disabled")
        mainGui.Show()
        ConnectImageSource(newPath)
    }

    Cancel(*)
    {
        pathGui.Destroy()
        mainGui.Opt("-Disabled")
        mainGui.Show()
        LogToWindow("Image path change canceled.", 1, 1)
    }
}

RefreshImages(*)
{
    global imagePath

    if (imagePath = "") {
        LogToWindow("No image source has been selected.", 1, 1)
        return
    }
    ConnectImageSource(imagePath)
}

ImageSelectionChanged(control, *)
{
    global reviewImage

    reviewImage.Value := control.Text != "" ? control.Text : "Not selected"
}

GetSettingsPath()
{
    global iniName

    bootLoc := RegRead("HKLM\SYSTEM\ControlSet001\Control", "PEBootRamdiskSourceDrive", "")
    if !RegExMatch(bootLoc, "i)^[a-z]:\\?$") || (StrUpper(SubStr(bootLoc, 1, 1)) = "X")
        return ""
    return RTrim(bootLoc, "\") . "\" . iniName
}

ShowNetworkLogin(path, title := "Connect to image source")
{
    global mainGui, ownedMappings

    settingsPath := GetSettingsPath()
    savedUser := ""
    if (settingsPath != "")
        savedUser := IniRead(settingsPath, "Network", "User", "")

    loginGui := Gui("+Owner" . mainGui.Hwnd, title)
    loginGui.SetFont("s9", "Segoe UI")
    loginGui.Add("Text", "x16 y16 w360 h36", "Source: " . path)
    loginGui.Add("Text", "x16 y59 w90 h20", "User")
    userEdit := loginGui.Add("Edit", "x110 y56 w266 h24", savedUser)
    loginGui.Add("Text", "x16 y94 w90 h20", "Password")
    passwordEdit := loginGui.Add("Edit", "x110 y91 w266 h24 Password")
    loginMessage := loginGui.Add("Text", "x16 y128 w360 h60 cA32626", "")
    connectButton := loginGui.Add("Button", "x286 y200 w90 h28 Default", "Connect")
    cancelButton := loginGui.Add("Button", "x188 y200 w90 h28", "Cancel")
    connected := false
    waitingForAcknowledgement := false

    connectButton.OnEvent("Click", Connect)
    cancelButton.OnEvent("Click", Cancel)
    loginGui.OnEvent("Close", Cancel)
    mainGui.Opt("+Disabled")
    loginGui.Show("w392 h244")
    WinWaitClose("ahk_id " . loginGui.Hwnd)
    mainGui.Opt("-Disabled")
    mainGui.Show()
    return connected

    Connect(*)
    {
        if waitingForAcknowledgement {
            loginGui.Destroy()
            return
        }

        username := Trim(userEdit.Value)
        password := passwordEdit.Value
        if (username = "" || password = "") {
            loginMessage.Value := "Enter a user name and password."
            return
        }

        connectButton.Enabled := false
        result := ConnectNetworkShare(path, username, password)
        if (result.Error = "")
            ConnectUpdateSource(username, password)
        password := ""
        passwordEdit.Value := ""
        connectButton.Enabled := true
        if (result.Error != "") {
            loginMessage.Value := result.Error
            return
        }

        ownedMappings.Push({Letter: result.Letter, Share: result.Share})
        connected := true
        if (settingsPath = "") {
            loginMessage.Value := "Connected, but the user name could not be saved: the WinPE source drive is unavailable."
            waitingForAcknowledgement := true
            connectButton.Text := "Continue"
            cancelButton.Enabled := false
            return
        }
        try {
            IniWrite(username, settingsPath, "Network", "User")
        } catch Error as err {
            LogToWindow("Could not save the network user name: " . err.Message, 1, 1)
            loginMessage.Value := "Connected, but the user name could not be saved to the WinPE source drive."
            waitingForAcknowledgement := true
            connectButton.Text := "Continue"
            cancelButton.Enabled := false
            return
        }
        loginGui.Destroy()
    }

    Cancel(*)
    {
        if !connected
            LogToWindow("Image source connection canceled.", 1, 1)
        loginGui.Destroy()
    }
}

ConnectUpdateSource(username, password)
{
    global updateSource, ownedMappings

    try {
        if DirExist(updateSource)
            return
        result := ConnectNetworkShare(updateSource, username, password, false)
        if (result.Error != "")
            throw Error(result.Error)
        ownedMappings.Push({Letter: result.Letter, Share: result.Share})
    } catch Error as err {
        LogToWindow("Could not connect to the update source: " . err.Message, 1, 1)
    }
}

ConnectNetworkShare(path, username, password, assignDrive := true)
{
    global ownedMappings

    if !RegExMatch(path, "^(\\\\[^\\]+\\[^\\]+)", &match)
        return {Error: "Enter a valid network share path."}
    share := match[1]
    letter := ""
    if assignDrive {
        drives := DriveGetList()
        Loop Parse "KLMNOPQRSTU" {
            if InStr(drives, A_LoopField)
                continue
            candidate := A_LoopField . ":"
            remote := Buffer(32768, 0)
            length := remote.Size // 2
            status := DllCall("mpr\WNetGetConnectionW", "str", candidate, "ptr", remote, "uint*", &length, "uint")
            if (status = 2250) {
                letter := candidate
                break
            }
            if (status != 0 && status != 1201)
                return {Error: "Could not check drive " . candidate . " (Windows error " . status . ")."}
        }
        if (letter = "")
            return {Error: "No free drive letter is available between K: and U:."}
    }

    resource := Buffer(16 + 4 * A_PtrSize, 0)
    NumPut("uint", 1, resource, 4)
    NumPut("ptr", assignDrive ? StrPtr(letter) : 0, resource, 16)
    NumPut("ptr", StrPtr(share), resource, 16 + A_PtrSize)
    status := DllCall("mpr\WNetAddConnection2W", "ptr", resource, "str", password, "str", username, "uint", 4, "uint")
    if (status != 0)
        return {Error: "Connection failed (Windows error " . status . "). Check the credentials and network connection."}

    if !DirExist(path) {
        if !DisconnectOwnedMapping(letter, share)
            ownedMappings.Push({Letter: letter, Share: share})
        return {Error: "Connected to the share, but the requested folder is not accessible."}
    }
    LogToWindow("Connected network share: " . share . (letter != "" ? " (" . letter . ")" : " (UNC)") . ".", 1, 1)
    return {Error: "", Letter: letter, Share: share}
}

DisconnectOwnedMapping(letter, share)
{
    if (letter != "") {
        remote := Buffer(32768, 0)
        length := remote.Size // 2
        status := DllCall("mpr\WNetGetConnectionW", "str", letter, "ptr", remote, "uint*", &length, "uint")
        if (status = 2250)
            return true
        if (status != 0) {
            LogToWindow("Could not check mapping " . letter . " (Windows error " . status . ").", 1, 1)
            return false
        }
        if (StrCompare(RTrim(StrGet(remote), "\"), RTrim(share, "\"), false) != 0) {
            LogToWindow("Mapping " . letter . " has changed; leaving it connected.", 1, 1)
            return true
        }
    }

    connection := letter != "" ? letter : share
    status := DllCall("mpr\WNetCancelConnection2W", "str", connection, "uint", 0, "int", false, "uint")
    if (status != 0 && status != 2250) {
        LogToWindow("Could not disconnect " . connection . " (Windows error " . status . ").", 1, 1)
        return false
    }
    LogToWindow("Disconnected network connection " . connection . ".", 1, 1)
    return true
}

CloseApp(*)
{
    global ownedMappings, updateBusy

    if updateBusy {
        LogToWindow("An update operation is in progress; wait before closing.", 1, 1)
        return
    }

    remaining := []
    for mapping in ownedMappings {
        if !DisconnectOwnedMapping(mapping.Letter, mapping.Share)
            remaining.Push(mapping)
    }
    ownedMappings := remaining
    if (ownedMappings.Length > 0) {
        LogToWindow("Some image source mappings could not be disconnected; close the application again to retry.", 1, 1)
        return
    }
    ExitApp()
}

CheckForUpdate(*)
{
    global updateSource, version, availableUpdate, updateButton, footerBrand, updateBusy

    if updateBusy
        return
    availableUpdate := ""
    updateButton.Visible := false
    footerBrand.Visible := true
    updateBusy := true
    try {
        LogToWindow("Checking for a WinPE update...", 1, 1)
        if !DirExist(updateSource)
            throw Error("The update source is not accessible: " . updateSource)
        manifest := ReadUpdateManifest(updateSource)
        if (VerCompare(manifest.Version, version) <= 0) {
            LogToWindow("No newer WinPE image found. Current WimLoader version: " . version . ".", 1, 1)
            return
        }
        if !FileExist(updateSource . "\boot.wim")
            throw Error("The update source does not contain boot.wim.")
        availableUpdate := manifest
        updateButton.Text := "Update to " . manifest.Version
        footerBrand.Visible := false
        updateButton.Visible := true
        LogToWindow("WinPE image with WimLoader " . manifest.Version . " is available. Click " . updateButton.Text . " to install.", 1, 1)
    } catch Error as err {
        LogToWindow("Update check failed: " . err.Message, 1, 1)
    } finally {
        updateBusy := false
    }
}

ReadUpdateManifest(source)
{
    manifestPath := source . "\winpe-update.ini"
    if !FileExist(manifestPath)
        throw Error("Update manifest is missing: " . manifestPath)
    updateVersion := IniRead(manifestPath, "WinPE", "Version", "")
    hash := IniRead(manifestPath, "WinPE", "SHA256", "")
    if !RegExMatch(updateVersion, "^\d+\.\d+\.\d+(?:\.\d+)?$")
        throw Error("The update manifest contains an invalid Version.")
    if !RegExMatch(hash, "i)^[0-9a-f]{64}$")
        throw Error("The update manifest contains an invalid SHA256.")
    return {Version: updateVersion, SHA256: StrUpper(hash)}
}

GetUpdateTarget()
{
    isWinPE := false
    Loop Reg "HKLM\SYSTEM\CurrentControlSet\Control", "K" {
        if (A_LoopRegName = "MiniNT") {
            isWinPE := true
            break
        }
    }
    if !isWinPE
        throw Error("WinPE updates can only be installed from WinPE.")
    settingsPath := GetSettingsPath()
    if (settingsPath = "")
        throw Error("The WinPE boot source drive could not be identified; X: will not be used.")
    SplitPath(settingsPath,, &root)
    target := root . "\sources\boot.wim"
    if !FileExist(target)
        throw Error("The boot source drive does not contain sources\boot.wim.")
    return target
}

GetImageHash(path)
{
    quotedPath := StrReplace(path, "'", "''")
    output := RunCMD("powershell -NoProfile -Command `"$ErrorActionPreference = 'Stop'; (Get-FileHash -LiteralPath '"
        . quotedPath . "' -Algorithm SHA256).Hash`"")
    if (RunCMD.ExitCode != 0)
        throw Error("SHA-256 calculation failed (exit code " . RunCMD.ExitCode . "): " . Trim(output))
    hash := Trim(output, " `t`r`n")
    if !RegExMatch(hash, "i)^[0-9a-f]{64}$")
        throw Error("SHA-256 calculation returned an invalid result.")
    return StrUpper(hash)
}

UpdateApp(*)
{
    global mainGui, updateSource, availableUpdate, updateBusy, updateButton, footerBrand

    if updateBusy
        return
    if !IsObject(availableUpdate) {
        LogToWindow("Check for an available update before installing.", 1, 1)
        return
    }
    updateBusy := true
    mainGui.Opt("+Disabled")
    updateButton.Enabled := false
    try {
        target := GetUpdateTarget()
        InstallBootImage(updateSource, target, availableUpdate)
        availableUpdate := ""
        updateButton.Visible := false
        footerBrand.Visible := true
        LogToWindow("WinPE update completed. Restart to use the updated WimLoader.", 1, 1)
    } catch Error as err {
        LogToWindow("WinPE update failed: " . err.Message, 1, 1)
    } finally {
        updateBusy := false
        mainGui.Opt("-Disabled")
        updateButton.Enabled := true
    }
}

InstallBootImage(source, target, expected)
{
    manifest := ReadUpdateManifest(source)
    if (manifest.Version != expected.Version || manifest.SHA256 != expected.SHA256)
        throw Error("The published update changed; check for updates again.")
    SplitPath(target,, &targetDir,,, &targetDrive)
    stagingDir := targetDir . "\.wimloader-update"
    stagedImage := stagingDir . "\boot.wim"
    backup := target . ".wimloader-backup"
    if FileExist(backup) || FileExist(stagingDir)
        throw Error("An earlier backup or staging directory exists. Preserve or remove it manually before updating.")
    size := FileGetSize(source . "\boot.wim")
    if (size = 0)
        throw Error("The published boot.wim is empty.")
    if (DriveGetFileSystem(targetDrive) = "FAT32" && size > 4294967295)
        throw Error("The image exceeds the FAT32 file size limit.")
    if (DriveGetSpaceFree(targetDrive) * 1048576 < size + 1048576)
        throw Error("Not enough free space for the new image and temporary files. The current boot.wim has not been changed.")

    DirCreate(stagingDir)
    preserveStaging := false
    try {
        LogToWindow("Copying WinPE image. Please wait...", 1, 1)
        RunCMD('robocopy "' . source . '" "' . stagingDir . '" boot.wim /COPY:DAT /R:0 /W:0 /J',,, UpdateLogLine)
        if (RunCMD.ExitCode >= 8)
            throw Error("Robocopy failed with exit code " . RunCMD.ExitCode . ".")
        if !FileExist(stagedImage) || FileGetSize(stagedImage) != size
            throw Error("The copied image has an unexpected size.")
        LogToWindow("Verifying the image SHA-256...", 1, 1)
        if (GetImageHash(stagedImage) != expected.SHA256)
            throw Error("The copied image SHA-256 does not match the manifest.")
        currentManifest := ReadUpdateManifest(source)
        if (currentManifest.Version != expected.Version || currentManifest.SHA256 != expected.SHA256)
            throw Error("The published update changed during copying; check again.")
        if FileExist(backup)
            throw Error("A backup appeared during copying; the current image will not be replaced.")
        preserveStaging := true
        if !DllCall("Kernel32\ReplaceFileW", "str", target, "str", stagedImage, "str", backup,
            "uint", 0, "ptr", 0, "ptr", 0, "int") {
            errorCode := A_LastError
            throw Error("Image replacement failed (Windows error " . errorCode
                . "). Do not reboot until the boot image is checked. Staging and backup files have been preserved.")
        }
        preserveStaging := false
        LogToWindow("Previous image retained at " . backup . ".", 1, 1)
    } finally {
        if !preserveStaging {
            try {
                if FileExist(stagedImage)
                    FileDelete(stagedImage)
                DirDelete(stagingDir)
            } catch Error as err {
                LogToWindow("Could not remove update staging files: " . err.Message, 1, 1)
            }
        }
    }
}

UpdateLogLine(line, *)
{
    LogToWindow(line, 1, 1)
}

LogToWindow(message, timeLine := 0, CR := 0, onlyLog := 0)
{
    global LogWindow

    enterNum := ""
    if CR > 0 {
        Loop CR {
            enterNum := "`r`n" . enterNum
        }
    }

    if timeLine = 1 {
        time := FormatTime(, "HH:mm:ss")
        message := time . ": " . message . enterNum
    } else {
        message := message . enterNum
    }

    logTime := FormatTime(, "yyyy-MM-dd_hh:mm:ss")
    fileLog := A_ScriptDir . "\log.txt"
    FileAppend("[" . logTime . "]" . " " . message, fileLog)

    if (onlyLog = 0) {
        SendMessage(0xB1, -2, -1, LogWindow)
        SendMessage(0xC2, 0, StrPtr(message), LogWindow)
    }
}
