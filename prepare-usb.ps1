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
$sizelimit_fat32_file = 4294967295 # = 4GB
$sizelimit_fat32_partition = 32212254720 # = 32GB
$size_partition_p1 = 1073741824 # = 1GB
$size_partition_p2 = 8589934592 # = 8GB

Write-Host ""

# mount ISO
# 
Write-Host "Mount ISO ..."
Write-Host "Select file to mount, Close small window to mount manually"
Write-Host ""
# 
# prep env
Add-Type -AssemblyName "System.Windows.Forms"
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
# 
# select file
if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $selectedFilePath = $openFileDialog.FileName
    Write-Output "Selected file: $selectedFilePath"
} else {
    Write-Output "Selected file: none"
}
# 
Write-Host ""
# 
# check if any file selected
# if file selected, mount with script
# if no file selected, mount manually
if ($null -eq $selectedFilePath) {
    # mount ISO manually
    # 
    # ask user to mount
    Write-Host "Do Now - manually mount ISO before continuing ..."
    Write-Host "Right-click ISO file ; Open with ; Windows Explorer"
    pause
    # 
    Write-Host ""
    # 
    # ask user to check
    Write-Host "Check now - make sure mounted ISO can be seen in This-PC"
    Start-Process -FilePath "explorer.exe" -ArgumentList "shell:::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
    pause
    # 
    # Write-Host ""
    # 
    # list drives
    Get-PSDrive
    # 
    Write-Host ""
    # 
    # get drive letter
    [char]$driveletter_mountedISO = (Read-Host -Prompt "Enter letter - Drive Letter of Mounted ISO ").ToLower()
} else {
    # mount ISO with script
    # 
    # mount iso
    $mountResult = Mount-DiskImage -ImagePath $selectedFilePath -PassThru
    # 
    # get drive letter
    $driveletter_mountedISO = ($mountResult | Get-Volume).DriveLetter
}
# 
# 
# derived constants
$source = $driveletter_mountedISO + ":\"
$path_installwim = $source + "sources\install.wim"
$path_orig_eicfg = $source + "sources\ei.cfg"

Write-Host ""

# cmd diskpart clean
# 
Write-Host "use cmd diskpart to clean USB"
Write-Host "select disk 1 ; clean ; clean ; exit"
# 
Start-Process -FilePath "cmd.exe" -ArgumentList "/c diskpart" -Wait

Write-Host ""

# get USB disk number
# 
# list
Write-Host " USB disks "
Write-Host "-----------"
Get-Disk | Select-Object -Property Number, Size
# 
# ask
while ($disk_number -lt 0) {
    [int]$disk_number = Read-Host -Prompt "Enter number - USB disk number "
}

Write-Host ""

# do some checks
# 
Write-Host "Some checks on file and USB sizes ..."
# 
# check size of install.wim > 4GB
# for >4GB, cannot put in FAT32 partition
$is_installwim_greaterthan_fourgb = (Get-Item -Path $path_installwim).length -gt $sizelimit_fat32_file
Write-Host "Fact - install.wim > 4GB - $is_installwim_greaterthan_fourgb"
# 
# check size of USB drive > 32GB
# for >32GB, cannot format whole drive as FAT32
$is_usbdrive_greaterthan_32gb = (Get-Disk -Number $disk_number).Size -gt $sizelimit_fat32_partition
Write-Host "Fact - USB-Disk > 32GB - $is_usbdrive_greaterthan_32gb"
# 
Write-Host "... Done"

Write-Host ""

# get partition type
# 
$partition_style = "m"
while ($partition_style -notin @("g","m")) {
    $partition_style = (Read-Host -Prompt "Enter letter - Partition Type? (g)pt , (m)br ").ToLower()
}
Write-Host "CONFIRMED - PartitionStyle: $partition_style"
# 
# derived constants

Write-Host ""

# partitions and drive letters
# 
# list partitions and use case
Write-Host "Number of partitions"
Write-Host "1 partition - FAT32 - for install.wim < 4GB"
Write-Host "2 partitions - FAT32, NTFS - for install.wim > 4GB"
# Write-Host "3 partitions - FAT32, NTFS, exFAT - with separate data partition"
# 
Write-Host ""
# 
# ask number of partitions
while ($number_of_partitions -notin 1..3) {
    [int]$number_of_partitions = Read-Host -Prompt "Enter number of partitions "
}
# 
Write-Host ""
# 
# list
Get-PSDrive
# 
Write-Host ""
# 
# ask drive letters
Write-Host "Drive letters"
[char]$driveletter_p1 = (Read-Host -Prompt "Enter letter - Drive Letter of USB Partition 1 ").ToLower()
if ($number_of_partitions -ge 2) {
    [char]$driveletter_p2 = (Read-Host -Prompt "Enter letter - Drive Letter of USB Partition 2 ").ToLower()
}
if ($number_of_partitions -ge 3) {
    [char]$driveletter_p3 = (Read-Host -Prompt "Enter letter - Drive Letter of USB Partition 3 ").ToLower()
}
# 
# derived constants
$dest1 = $driveletter_p1 + ":\"
if ($number_of_partitions -ge 2) {
    $dest2 = $driveletter_p2 + ":\"
}
if ($number_of_partitions -ge 3) {
    $dest3 = $driveletter_p3 + ":\"
}

Write-Host ""

# ask if want to create ei.cfg
# 
$is_orig_eicfg_present = Test-Path -Path $path_orig_eicfg
Write-Host "Fact - original ei.cfg present - $is_orig_eicfg_present"
while ($tocreate_eicfg -notin @("c","b","y","n")) {
    $tocreate_eicfg = (Read-Host -Prompt "Enter letter - create ei.cfg? (c)onsumer , (b)usiness , (n)o ").ToLower()
}
# overwrite y with c
if ($tocreate_eicfg -eq "y") {
    $tocreate_eicfg = "c"
}
# 
# derived constants
$dir_dest_eicfg = "$dest1\sources"
if ($number_of_partitions -ge 2) {
    $dir_dest_eicfg = "$dest2\sources"
}
$path_dest_eicfg = "$dir_dest_eicfg\ei.cfg"

Write-Host ""

# ask if want to create oobe\BypassNRO.cmd
while ($tocreate_bypassnro -notin @("y","n")) {
    $tocreate_bypassnro = Read-Host -Prompt "Enter letter - create BypassNRO.cmd? (y)es , (n)o "
}
# 
# derived constants
$dir_oobe = "$dest1\oobe"
if ($number_of_partitions -ge 2) {
    $dir_oobe = "$dest2\oobe"
}
$path_bypassnrocmd = "$dir_oobe\BypassNRO.cmd"

Write-Host ""

# formatting
# 
# clean
Write-Host "Clear disk ..."
Get-Disk -Number $disk_number | Clear-Disk -RemoveData -RemoveOEM -Confirm:$false | Out-Null
Write-Host "... Done"
# 
# initialize
if ($partition_style -eq "g") {
    # gpt
    Write-Host "Initialize disk to GPT ..."
    # Get-Disk -Number $disk_number | Initialize-Disk -PartitionStyle GPT | Out-Null
    Write-Host "... Done"
} else {
    # mbr
    Write-Host "Initialize disk to MBR ..."
    # Get-Disk -Number $disk_number | Initialize-Disk -PartitionStyle MBR | Out-Null
    Write-Host "... Done"
}
# 
# 
# partition
Write-Host "Partitioning and formatting disk ..."
switch ($number_of_partitions) {
    1 {
        # 1
        if ((Get-Disk -Number $disk_number).Size -gt $sizelimit_fat32_partition) {
            New-Partition -DiskNumber $disk_number -Size $sizelimit_fat32_partition -IsActive -DriveLetter $driveletter_p1 | Format-Volume -FileSystem FAT32 -Confirm:$false | Out-Null
        } else {
            New-Partition -DiskNumber $disk_number -UseMaximumSize -IsActive -DriveLetter $driveletter_p1 | Format-Volume -FileSystem FAT32 -Confirm:$false | Out-Null
        }
        break
    }
    2 {
        # 2
        New-Partition -DiskNumber $disk_number -Size $size_partition_p1 -IsActive -DriveLetter $driveletter_p1 | Format-Volume -FileSystem FAT32 -Confirm:$false | Out-Null
        New-Partition -DiskNumber $disk_number -UseMaximumSize -DriveLetter $driveletter_p2 | Format-Volume -FileSystem NTFS -Confirm:$false | Out-Null
        break
    }
    3 {
        # 3
        New-Partition -DiskNumber $disk_number -Size $size_partition_p1 -IsActive -DriveLetter $driveletter_p1 | Format-Volume -FileSystem FAT32 -Confirm:$false | Out-Null
        New-Partition -DiskNumber $disk_number -Size $size_partition_p2 -DriveLetter $driveletter_p2 | Format-Volume -FileSystem NTFS -Confirm:$false | Out-Null
        New-Partition -DiskNumber $disk_number -UseMaximumSize -DriveLetter $driveletter_p3 | Format-Volume -FileSystem exFAT -Confirm:$false | Out-Null
        break
    }
    default {
        # Default
        Write-Host "Invalid option"
        break
    }
}
Write-Host "... Done"

Write-Host ""

# bootsect
Write-Host "Making bootable ..."
$dir_bootsect = $driveletter_mountedISO + ":\boot"
Push-Location $dir_bootsect
$cmd_to_run = "bootsect.exe" + " " + "/nt60" + " " + $driveletter_p1 + ":"
Invoke-Expression $cmd_to_run
Pop-Location
Write-Host "... Done"

Write-Host ""

# copy
# 
Write-Host "Copying ..."
# 
# exclusions
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
# 
Write-Host "... Done"

Write-Host ""

# create ei.cfg
# 
# delete existing ei.cfg if present
if ( ($is_orig_eicfg_present) -and ($tocreate_eicfg -ne "n") ) {
    # delete
    Remove-Item -Path $path_dest_eicfg -Force
}
# 
switch ($tocreate_eicfg) {
    "c" {
        # consumer
        Write-Host "Creating ei.cfg ..."
        # 
        # create file
        # 
        # add content
        Add-Content -Path $path_dest_eicfg -Value "[Channel]"
        Add-Content -Path $path_dest_eicfg -Value "Retail"
        # 
        Write-Host "... Done"
        break
    }
    "b" {
        # business
        Write-Host "Creating ei.cfg ..."
        # 
        # create file
        # 
        # add content
        Add-Content -Path $path_dest_eicfg -Value "[Channel]"
        Add-Content -Path $path_dest_eicfg -Value "volume"
        Add-Content -Path $path_dest_eicfg -Value ""
        Add-Content -Path $path_dest_eicfg -Value "[VL]"
        Add-Content -Path $path_dest_eicfg -Value "1"
        # 
        Write-Host "... Done"
        break
    }
    "n" {
        # no
        Write-Host "ei.cfg not created"
        break
    }
    default {
        # Default
        Write-Host "Invalid option"
        break
    }
}

# create oobe\BypassNRO.cmd
# 
if ($tocreate_bypassnro -eq "y") {
    # proceed to create
    Write-Host "Creating oobe\BypassNRO.cmd ..."
    # 
    # crreate dir
    New-Item -ItemType "directory" -Path "$dir_oobe" | Out-Null
    # 
    # create file
    # 
    # add content
    Add-Content -Path $path_bypassnrocmd -Value "@echo off"
    Add-Content -Path $path_bypassnrocmd -Value "reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f"
    Add-Content -Path $path_bypassnrocmd -Value "shutdown /r /t 0"
    # 
    Write-Host "... Done"
}

Write-Host ""

# dismount
# 
# ask if want to dismount ISO
while ($dismount_iso -notin @("y","n")) {
    $dismount_iso = (Read-Host -Prompt "Enter letter - Want to dismount ISO ? y , n ").ToLower()
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
