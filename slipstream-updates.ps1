# edit-wimgreaterthan4gb.ps1
# ==================================================
# Description
# ==================================================
# Usage
# ==================================================


Write-Host "Starting edit-wimgreaterthan4gb.ps1 ..."

# include
# . ".\functions.ps1"
# . ".\urls.ps1"
# . ".\values.ps1"

# var
# $var = ""



##################################################

Install - Slipstream Windows Updates



# include
# path to 7z
$env:Path += ";$env:ProgramFiles\7-Zip"

# constants
$path_to_extracted_iso = "$env:SystemDrive\ISO"
$path_to_downloaded_updates = "$env:SystemDrive\WinUpdates"
$path_to_mount_folder = "$env:SystemDrive\mnt"

# working folders
New-Item -ItemType "directory" -Path "$path_to_downloaded_updates" -Force | Out-Null
New-Item -ItemType "directory" -Path "$path_to_mount_folder" -Force | Out-Null

# extract
# 7z x $path_to_iso -o"$path_to_extracted_iso"
# eg
7z x "C:\Users\User\Downloads\Win11_24H2_English_x64.iso" -o"$path_to_extracted_iso"

# move update files
Invoke-Item -Path "$HOME\Downloads"
Invoke-Item -Path "$path_to_downloaded_updates"
# manually move or copy

# determine index
##### Get-WindowsImage -ImagePath "$path_to_extracted_iso\sources\install.wim"
dism /get-imageinfo /imagefile:$path_to_extracted_iso\sources\install.wim
# note SKU number
# 1 - Home
# 6 - Pro
# 10 - Pro for Workstations

# mount
##### Mount-WindowsImage -ImagePath "$path_to_extracted_iso\sources\install.wim" -Index "6" -Path "$path_to_mount_folder"
dism /mount-wim /wimfile:$path_to_extracted_iso\sources\install.wim /index:6 /mountdir:$path_to_mount_folder

# slipstream
##### Add-WindowsPackage -Path "$path_to_mount_folder" -PackagePath "$path_to_downloaded_updates"
dism /add-package /image:$path_to_mount_folder /PackagePath:$path_to_downloaded_updates

# verify (optional)
##### Get-WindowsPackage -Path "$path_to_mount_folder"
dism /image:$path_to_mount_folder /get-packages

# save and unmount
##### Dismount-WindowsImage -Path "$path_to_mount_folder" -Save
dism /unmount-wim /mountdir:$path_to_mount_folder /commit


# other steps
dism /cleanup-image /image:"./mnt" /startcomponentcleanup /resetbase

##################################################



Write-Host "Terminating script-winget.ps1 ..."
# pause


# ==================================================
# Notes
# ==================================================
