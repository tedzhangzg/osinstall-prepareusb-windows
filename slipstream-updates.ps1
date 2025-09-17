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



# define
$dir_workingdirroot = "C:\slipstream"
$dir_extractediso = "$dir_workingdirroot\iso"
$dir_updatefiles = "$dir_workingdirroot\upd"
$dir_wimmount = "$dir_workingdirroot\mnt"
$dir_extractedwim = "$dir_extractediso\sources\install.wim"
$path_extractedbootimage = "$dir_extractediso\boot\etfsboot.com"

# create folders
mkdir $dir_workingdirroot
mkdir $dir_extractediso
mkdir $dir_updatefiles
mkdir $dir_wimmount

# delete
# Remove-Item -Path $dir_extractediso -Recurse -Force

# download
# into "$HOME\Downloads"
# 
# iso
https://www.microsoft.com/en-us/software-download/windows11
# english (us) x64
# 
# update msu
https://www.catalog.update.microsoft.com/
# search for yyyy-mm windows 11 x64

# before moving
# 
# assume
# 
# in "$HOME\Downloads" there are only
# 1 ISO
# relevant MSU
# no other ISO and MSU for other projects

# move downloads
Get-ChildItem -Path "$HOME\Downloads" -Filter "*.iso" | ForEach-Object { Move-Item -Path $_.FullName -Destination $dir_workingdirroot -Force }
Get-ChildItem -Path "$HOME\Downloads" -Filter "*.msu" | ForEach-Object { Move-Item -Path $_.FullName -Destination $dir_updatefiles -Force }

# get name of iso
$name_origiso = (Get-ChildItem -Path "$dir_workingdirroot" -Filter "*.iso").Name
$path_newiso = "$dir_workingdirroot\new_" + "$name_origiso"

# add compression tools to PATH
# 
# 7-zip
if (-Not (Test-Path -Path "$env:ProgramFiles\7-Zip")) {
    winget install --id "7zip.7zip"
}
# 
# WinRAR
# if (-Not (Test-Path -Path "$env:ProgramFiles\WinRAR")) {
    # winget install --id "RARLab.WinRAR"
# }

# add tools to PATH
# 
# 7z
$env:Path += ";$env:ProgramFiles\7-Zip"
# permanently
Add-Content -Path $PROFILE -Value '$env:Path += ";$env:ProgramFiles\7-Zip"'
# 
# rar unrar
# $env:Path += ";$env:ProgramFiles\WinRAR"
# permanently
# Add-Content -Path $PROFILE -Value '$env:Path += ";$env:ProgramFiles\WinRAR"'

# extract ISO
Get-ChildItem -Path "$dir_workingdirroot" -Filter "*.iso" | ForEach-Object { 7z x $_.FullName -o"$dir_extractediso" }
# 
# syntax
# 7z x $path_file -o$dir_dest -p$password
# unrar x $path_file $dir_dest -p$password

# get index
# 
Get-WindowsImage -ImagePath $dir_extractedwim

# ask installwim_index
# 
if ($null -eq $installwim_index) {
    [int]$installwim_index = Read-Host -Prompt "Enter index "
}
# 
$installwim_index = 10

# mount image
Mount-WindowsImage -ImagePath $dir_extractedwim -Index $installwim_index -Path $dir_wimmount

##################################################
# start of mounted install.wim
##################################################
# order
# 
# setup / safeos / dynamic updates
# servicing stack update - prerequisite, now integrated in cumulative update
# latest cumulative update - monthly rollup
# optional update - dot net
# winpe / boot.wim
##################################################

# get packages installed in mounted image
Get-WindowsPackage -Path $dir_wimmount
Get-WindowsPackage -Path $dir_wimmount > $HOME\Desktop\out.txt

# ask num_kb
# 
if ($null -eq $num_kb) {
    [int]$num_kb = Read-Host -Prompt "Enter KB number "
}
# 
# $num_kb = 5065426

# add packages
# 
# add one by one
Get-ChildItem -Path $dir_updatefiles -Filter "*kb$num_kb*" | ForEach-Object { Add-WindowsPackage -Path $dir_wimmount -PackagePath $_.FullName }
# 
# install all
# not recommended, need to follow order
# 
# install all - method 1 - add whole directory
# Add-WindowsPackage -Path $dir_wimmount -PackagePath $dir_updatefiles
# or
# install all - method 2 - loop through msu
# Get-ChildItem -Path $dir_updatefiles | ForEach-Object { Add-WindowsPackage -Path $dir_wimmount -PackagePath $_.FullName }
# 
# remove var
Remove-Variable -Name "num_kb"

# also
# good to have

# enable netfx3
Enable-WindowsOptionalFeature -Path $dir_wimmount -FeatureName "NetFx3" -All -LimitAccess -Source "$dir_extractediso\sources\sxs"

##################################################
# end of mounted install.wim
##################################################

# copy ei.cfg
# 
# method 1 - downloaded to Downloads
# $path_eicfg = "$HOME\Downloads\ei.cfg"
# Copy-Item -Path $path_eicfg -Destination "$dir_extractediso\sources\" -Recurse -Force
# 
# method 2 - create new
$path_eicfg = "$dir_extractediso\sources\ei.cfg"
New-Item -Path $path_eicfg -ItemType "File"
Add-Content -Path $path_eicfg -Value "[Channel]"
Add-Content -Path $path_eicfg -Value "Retail"

# cleanup
# 
# Start-Process -FilePath "dism.exe" -ArgumentList "/Image:$dir_wimmount /Cleanup-Image /StartComponentCleanup /ResetBase" -Wait
# 
# to see what is happening
dism.exe /Image:$dir_wimmount /Cleanup-Image /StartComponentCleanup /ResetBase

# health
Start-Process -FilePath "dism.exe" -ArgumentList "/Image:$dir_wimmount /Cleanup-Image /ScanHealth" -Wait
Start-Process -FilePath "dism.exe" -ArgumentList "/Image:$dir_wimmount /Cleanup-Image /RestoreHealth" -Wait

# dismount
Dismount-WindowsImage -Path $dir_wimmount -Save

# dismount and discard error mounts
Dismount-WindowsImage -Path $dir_wimmount -Discard

# rebuild iso

# install Windows ADK
winget install --id "Microsoft.WindowsADK"

# locate
$path_to_dir_with_oscdimg = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
$path_to_oscdimg = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"

# add to path
$env:Path += ";$path_to_dir_with_oscdimg"
# permanently
Add-Content -Path $PROFILE -Value '$env:Path += ";${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"'
# 
# or put in a variable
$oscdimg = $path_to_oscdimg

# do
& "$oscdimg" -b"$path_extractedbootimage" -u2 -h -m -o $dir_extractediso $path_newiso



Write-Host "Terminating script-winget.ps1 ..."
# pause


# ==================================================
# Notes
# ==================================================
