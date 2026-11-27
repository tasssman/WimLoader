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

WinPE updates:
- Select **Updates > Check for WinPE update**, then **Install WinPE update**. The source is `\\ntshare\helpdesk\scripts\WinPE_HW\media\sources`, independently of the Windows image source. Credentials are requested if needed.
- Updates replace the entire `sources\boot.wim` on the detected WinPE boot drive, not just the application EXE. Installation is blocked outside WinPE, when the boot drive cannot be identified, or when space is insufficient.
- Publish `boot.wim` and `winpe-update.ini` together. The manifest version identifies the WimLoader version included in that image; the current development version is `2.2.0.001`. Versions use three numeric components, with an optional fourth component for development builds (`001`, `002`, etc.). Example manifest for the next test update (replace the hash with the actual 64-character SHA-256):

  ```ini
  [WinPE]
  Version=2.2.0.002
  SHA256=REPLACE_WITH_ACTUAL_SHA256
  ```

- Calculate the hash after building the image: `Get-FileHash -LiteralPath 'C:\WinPE_amd64\media\sources\boot.wim' -Algorithm SHA256`. Publish the manifest only after the matching image is ready.
- The downloaded image is staged and its SHA-256 checked before replacement. Free space for a second image is required. The previous image is retained as `sources\boot.wim.wimloader-backup`; existing backups or staging directories are never overwritten automatically.
- Restart only after successful replacement. If replacement fails, check the boot image and preserved files before rebooting. Before another update, archive the backup elsewhere and remove the earlier backup/staging directory after checking its contents.
- Keep the application's `version` variable consistent with the WimLoader version included when building each published image. SHA-256 detects mismatched or corrupted content; it is not a digital signature and does not authenticate the publisher.
- To test an update from `2.2.0.001` to `2.2.0.002`, build the newer application into a new `boot.wim`, then publish that image with `Version=2.2.0.002` and its matching hash. Changing only the manifest version does not update the application inside the image.

Publishing a WinPE update:
- Place a prepared, trusted WinPE image at `local\WinPE_HW\media\sources\boot.wim` in this repository. Place `Ahk2Exe.exe` and the AutoHotkey v2 `AutoHotkey64.exe` base executable in `local`. This directory is ignored by Git. The script does not create WinPE or add drivers or optional components.
- Set the `version` in `WimLoader.ahk` to the version being published. Use a newer version than the one installed on clients.
- Run an elevated PowerShell session with DISM available and write access to the update share:

  ```powershell
  .\deploy.ps1
  ```

- Pass `-CompilerPath`, `-AutoHotkeyBasePath`, `-ImagePath` or `-Destination` to override the defaults. The default destination is `\\ntshare\helpdesk\scripts\WinPE_HW\media\sources`. The script compiles the application, copies the source image to a temporary working directory, adds the EXE to `Windows\System32`, and commits the copy. The original image is not changed.
- The script reports compilation start and completion, and copying the EXE into the mounted image. It waits for Ahk2Exe to exit before checking its exit code and output file. If the compiler displays an error dialog, dismiss it so the script can report the failure and clean up.
- The image is copied to the destination and verified before publication. The previous manifest is removed first; the new manifest, containing the source version and image SHA-256, is published last. Update checks may temporarily fail during publication.
- Previous published files are replaced without a backup. The temporary `wimloader-deploy-*` directory is removed after successful publication; existing directories from earlier deployments are not removed. The persistent `.wimloader-deploy.lock` file prevents concurrent deployments and should not be removed while a deployment is running. Ensure sufficient free space for the local working copy and staged image on the destination.
- If publication fails, inspect the reported `wimloader-deploy-*` directory and the destination before retrying. There is no automatic rollback: publish a matching image and manifest again, publishing the manifest last. If DISM cannot discard a mount, preserve the reported working directory and resolve the mount before removing it.
