# prepare-usb.ps1
# ==================================================
# Description
# ==================================================
# Usage
# ==================================================


Write-Host "Starting prepare-usb.ps1 ..."

# include
# . ".\functions.ps1"
# . ".\urls.ps1"
# . ".\values.ps1"

# var
# $var = ""

# constants
$partitionsize_P1 = 1073741824 # = 1GB
$partitionsize_P2 = 8589934592 # = 8GB
$fa32_filesize_limit = 4294967295 # = 4GB
$fat32_partitionsize_limit = 32212254720 # = 32GB


Write-Host ""
Write-Host ""


# mount ISO
Write-Host "Mount ISO ..."


# mount ISO
# 
# prep
Add-Type -AssemblyName "System.Windows.Forms"
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
# select file
if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $selectedFilePath = $openFileDialog.FileName
    Write-Output "You selected: $selectedFilePath"
} else {
    Write-Output "Manually mount ..."
}
# check if any file selected
if ($null -eq $selectedFilePath) {
    # mount ISO manually
    # 
    Write-Host "Now - manually mount ISO before continuing ..."
    pause
    Write-Host "Check - make sure mounted ISO can be seen in This-PC"
    Start-Process -FilePath "explorer.exe" -ArgumentList "shell:::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
    pause
    # list drives
    Get-PSDrive
    # get drive letter
    [char]$driveLetter_mountedISO = Read-Host -Prompt "Enter letter - Drive Letter of Mounted ISO: "
} else {
    # mount ISO with script
    # 
    # mount iso
    $mountResult = Mount-DiskImage -ImagePath $selectedFilePath -PassThru
    # 
    # get drive letter
    $driveLetter_mountedISO = ($mountResult | Get-Volume).DriveLetter
}

Write-Host ""

# use diskpart to clean
Start-Process -FilePath "cmd.exe" -ArgumentList "/c diskpart" -Wait

Write-Host ""

# get USB disk number
# 
# list
Write-Host ""
Write-Host "USB disks"
Write-Host "---------"
Get-Disk | Select-Object -Property Number, Size
# ask
while ($disk_number -lt 0) {
    [int]$disk_number = Read-Host -Prompt "Enter number - USB disk number: "
}

Write-Host ""

# do some checks
Write-Host " Checks on file and partition sizes ..."
# 
# check install.wim size
# for >4GB, cannot put in FAT32 partition
$path_installwim = $driveLetter_mountedISO + ":\sources\install.wim"
$is_installwim_greaterthan_fourgb = (Get-Item $path_installwim).length -gt $fa32_filesize_limit
Write-Host "status - install.wim>4GB - $is_installwim_greaterthan_fourgb"
# 
# check USB drive size > 32GB
$is_usbdrive_greaterthan_32gb = (Get-Disk -Number $disk_number).Size -gt $fat32_partitionsize_limit
Write-Host "status - USB>32GB - $is_usbdrive_greaterthan_32gb"

Write-Host ""

# ask how many partitions
Write-Host "Partitions details"
Write-Host "1 partition - FAT32 - for install.wim <= 4GB"
Write-Host "2 partitions - FAT32, NTFS - for install.wim > 4GB"
# Write-Host "3 partitions - FAT32, NTFS, exFAT - if data partition is needed"
while ( ($number_of_partitions -lt 1) -or ($number_of_partitions -gt 3) ) {
    [int]$number_of_partitions = Read-Host -Prompt "Enter number of partitions "
}

Write-Host ""

# list drive letters
Get-PSDrive

Write-Host ""

# Ask drive letters for each USB partition
[char]$driveLetter_P1 = Read-Host -Prompt "Enter letter - Drive Letter of USB Partition 1: "
if ($number_of_partitions -ge 2) {
    [char]$driveLetter_P2 = Read-Host -Prompt "Enter letter - Drive Letter of USB Partition 2 "
}
if ($number_of_partitions -ge 3) {
    [char]$driveLetter_P3 = Read-Host -Prompt "Enter letter - Drive Letter of USB Partition 3 "
}

Write-Host ""

# Ask if want to copy ei.cfg
while ( ($tocopy_eicfg -ne "c") -and ($tocopy_eicfg -ne "b") -and ($tocopy_eicfg -ne "n") ) {
    [char]$tocopy_eicfg = Read-Host -Prompt "Enter letter - copy EI.cfg? (c)onsumer , (b)usiness , (n)o "
}

# Ask if want to create oobe\BypassNRO.cmd
while ( ($tocreate_bypassnro -ne "y") -and ($tocreate_bypassnro -ne "n") ) {
    [char]$tocreate_bypassnro = Read-Host -Prompt "Enter letter - create BypassNRO.cmd? (y)es , (n)o "
}


Write-Host ""

# Start

# format
Write-Host "Formatting ..."
Get-Disk $disk_number | Clear-Disk -RemoveData -RemoveOEM -Confirm:$false
Write-Host "... Disk Cleared"
# 
# partitioning
switch ($number_of_partitions) {
    1 {
        # 1
        if ((Get-Disk -Number $disk_number).Size -gt $fat32_partitionsize_limit) {
            New-Partition -DiskNumber $disk_number -Size $fat32_partitionsize_limit -IsActive -DriveLetter $driveLetter_P1 | Format-Volume -FileSystem FAT32 | Out-Null
        } else {
            New-Partition -DiskNumber $disk_number -UseMaximumSize -IsActive -DriveLetter $driveLetter_P1 | Format-Volume -FileSystem FAT32 | Out-Null
        }
        break
    }
    2 {
        # 2
        New-Partition -DiskNumber $disk_number -Size $partitionsize_P1 -IsActive -DriveLetter $driveLetter_P1 | Format-Volume -FileSystem FAT32 | Out-Null
        New-Partition -DiskNumber $disk_number -UseMaximumSize -DriveLetter $driveLetter_P2 | Format-Volume -FileSystem NTFS | Out-Null
        break
    }
    3 {
        # 3
        New-Partition -DiskNumber $disk_number -Size $partitionsize_P1 -IsActive -DriveLetter $driveLetter_P1 | Format-Volume -FileSystem FAT32 | Out-Null
        New-Partition -DiskNumber $disk_number -Size $partitionsize_P2 -DriveLetter $driveLetter_P2 | Format-Volume -FileSystem NTFS | Out-Null
        New-Partition -DiskNumber $disk_number -UseMaximumSize -DriveLetter $driveLetter_P3 | Format-Volume -FileSystem exFAT | Out-Null
        break
    }
    default {
        # Default
        Write-Host "Invalid option"
        break
    }
}
Write-Host "... Formatting Done"

Write-Host ""

# bootsect
Write-Host "Making bootable ..."
$dir_bootsect = $driveLetter_mountedISO + ":\boot"
Push-Location $dir_bootsect
$cmd_to_run = "bootsect.exe" + " " + "/nt60" + " " + $driveLetter_P1 + ":"
Invoke-Expression $cmd_to_run
Pop-Location
Write-Host "... Bootable Done"

Write-Host ""

# Copy
Write-Host "Copying ..."
# 
# prep dir path
$source = $driveLetter_mountedISO + ":\"
$dest1 = $driveLetter_P1 + ":\"
$dir_eicfg = "$dest1\sources"
$dir_oobe = "$dest1\oobe"
if ($number_of_partitions -ge 2) {
    $dest2 = $driveLetter_P2 + ":\"
    $dir_eicfg = "$dest2\sources"
    $dir_oobe = "$dest2\oobe"
}
$path_eicfg = "$dir_eicfg\ei.cfg"
$path_bypassnrocmd = "$dir_oobe\BypassNRO.cmd"
if ($number_of_partitions -ge 3) {
    $dest3 = $driveLetter_P3 + ":\"
}
$exclude1 = "sources"
$exclude2 = "boot.wim"
$exclude3 = "install.wim"
$exclude4 = @($exclude2, $exclude3)
# 
# copy
switch ($number_of_partitions) {
    1 {
        # 1
        # 
        # for P1
        Copy-Item -Path "$source\*" -Destination "$dest1" -Exclude $exclude4 -Recurse
        Write-Host "Copying boot.wim to Dest1"
        Start-BitsTransfer -Source "$source\sources\boot.wim" -Destination "$dest1\sources\"
        Write-Host "Copying install.wim to Dest1"
        Start-BitsTransfer -Source "$source\sources\install.wim" -Destination "$dest1\sources\"
        # 
        break
    }
    { $_ -ge 2 -and $_ -le 3 } {
        # 2 and 3
        # 
        # for P1
        Copy-Item -Path "$source\*" -Destination "$dest1" -Exclude $exclude1 -Recurse
        New-Item -ItemType "directory" -Path "$dest1\sources" | Out-Null
        Write-Host "Copying boot.wim to Dest1"
        Start-BitsTransfer -Source "$source\sources\boot.wim" -Destination "$dest1\sources"
        # 
        # for P2
        Copy-Item -Path "$source\*" -Destination "$dest2" -Exclude $exclude4 -Recurse
        Write-Host "Copying boot.wim to Dest2"
        Start-BitsTransfer -Source "$source\sources\boot.wim" -Destination "$dest2\sources\"
        Write-Host "Copying install.wim to Dest2"
        Start-BitsTransfer -Source "$source\sources\install.wim" -Destination "$dest2\sources\"
        # 
        # for P3
        if ($number_of_partitions -eq 3) {
            # file
            New-Item -ItemType "file" -Path "$dest3\files_go_here.txt" | Out-Null
        }
        break
    }
    default {
        # Default
        Write-Host "Invalid option"
        break
    }
}
Write-Host "... Copying Done"

Write-Host ""

# Copy EI.cfg
switch ($tocopy_eicfg) {
    "c" {
        # consumer
        Add-Content -Path $path_eicfg -Value "[Channel]"
        Add-Content -Path $path_eicfg -Value "Retail"
        Write-Host "... done copying EI.cfg"
        break
    }
    "b" {
        # business
        Add-Content -Path $path_eicfg -Value "[Channel]"
        Add-Content -Path $path_eicfg -Value "volume"
        Add-Content -Path $path_eicfg -Value ""
        Add-Content -Path $path_eicfg -Value "[VL]"
        Add-Content -Path $path_eicfg -Value "1"
        break
    }
    "n" {
        # no
        Write-Host "EI.cfg not copied"
        break
    }
    default {
        # Default
        Write-Host "Invalid option"
        break
    }
}

# create oobe\BypassNRO.cmd
if ($tocreate_bypassnro -eq "y") {
    New-Item -ItemType "directory" -Path "$dir_oobe" | Out-Null
    Add-Content -Path $path_bypassnrocmd -Value "@echo off"
    Add-Content -Path $path_bypassnrocmd -Value "reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f"
    Add-Content -Path $path_bypassnrocmd -Value "shutdown /r /t 0"
}

Write-Host ""

# Final

# dismount
# 
# ask if want to dismount ISO
while ( ($dismount_iso -ne "y") -and ($dismount_iso -ne "n") ) {
    [char]$dismount_iso = Read-Host -Prompt "Enter letter - Want to dismount ISO ? y , n "
}
# 
if ($dismount_iso -eq "y") {
    # dismount ISO
    if ($null -eq $selectedFilePath) {
        # dismount manually
        Write-Host "Manually dismount ..."
    } else {
        # dismount ISO with script
        Dismount-DiskImage -ImagePath $selectedFilePath
        Write-Host "ISO Dismounted"
    }
}


Write-Host ""
Write-Host ""


Write-Host "All done."
pause


Write-Host ""

Write-Host "Terminating script-winget.ps1 ..."
# pause


# ==================================================
# Notes
# ==================================================
