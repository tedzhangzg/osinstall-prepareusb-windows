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

# add compression tools to PATH
# 
# 7-zip
if (-Not (Test-Path -Path "$env:ProgramFiles\7-Zip")) {
    winget install --id "7zip.7zip"
}
$env:Path += ";$env:ProgramFiles\7-Zip"
# or add permanently
# Add-Content -Path $PROFILE -Value '$env:Path += ";$env:ProgramFiles\7-Zip"'
# 
# WinRAR
# if (-Not (Test-Path -Path "$env:ProgramFiles\WinRAR")) {
    # winget install --id "RARLab.WinRAR"
# }
# $env:Path += ";$env:ProgramFiles\WinRAR"
# or add permanently
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

# cleanup
Optimize-WindowsImage -Path $dir_wimmount -StartComponentCleanup

# dismount
Dismount-WindowsImage -Path $dir_wimmount -Save

# dismount and discard error mounts
Dismount-WindowsImage -Path $dir_wimmount -Discard



Write-Host "Terminating script-winget.ps1 ..."
# pause


# ==================================================
# Notes
# ==================================================
