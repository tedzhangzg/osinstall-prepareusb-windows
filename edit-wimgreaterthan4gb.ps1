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


# Documentation - to create these directories
$dir_main = "C:\dism"
$dir_sub_wim = "imagestore"
$dir_sub_mount = "offline"
$dir_sub_pkg = "packages"
$dir_full_wim = "$dir_main\$dir_sub_wim"
$dir_full_mount = "$dir_main\$dir_sub_mount"
$dir_full_pkg = "$dir_main\$dir_sub_pkg"

Write-Host " "


# Create directories
New-Item -ItemType "directory" -Path "$dir_main" | Out-Null
New-Item -ItemType "directory" -Path "$dir_main\$dir_sub_wim" | Out-Null
New-Item -ItemType "directory" -Path "$dir_main\$dir_sub_mount" | Out-Null
New-Item -ItemType "directory" -Path "$dir_main\$dir_sub_pkg" | Out-Null

Write-Host " "

# Extract wim
# Add 7z to PATH
$env:Path += ";C:\Program Files\7-Zip"
# Get ISO filename
$dir_iso = "$home\Desktop\ISO"
$file_iso = Get-ChildItem -Path $dir_iso -Name
# Extract file
7z e "$dir_iso\$file_iso" "-o$dir_full_wim" "install.wim" -r

Write-Host " "

# Manually copy packages
Invoke-Item $dir_full_pkg

Write-Host " "

# Finish copying and contnue
$finish_copying_continue = Read-Host -Prompt "Finish copying? Continue?"

Write-Host " "

# Mount
Mount-WindowsImage -ImagePath "$dir_full_wim\install.wim" -Index 1 -Path "$dir_full_mount"

Write-Host " "

# Add
Add-WindowsPackage -Path "$dir_full_mount" -PackagePath "$dir_full_pkg" -IgnoreCheck
# Add-WindowsPackage -Path "$dir_full_mount" -PackagePath "$dir_full_pkg\demo_package.msu" -PreventPending

Write-Host " "

# Verify
# Get-WindowsPackage -Path "$dir_full_mount"

Write-Host " "

# Dismount
Dismount-WindowsImage -Path "$dir_full_mount" -Save


Write-Host " "
Write-Host " "

Write-Host "All done."
pause


Write-Host ""

Write-Host "Terminating script-winget.ps1 ..."
# pause


# ==================================================
# Notes
# ==================================================
