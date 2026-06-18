@echo off

:: prepare-usb.cmd
:: ==================================================
:: Description
:: ==================================================
:: Usage
:: ==================================================


echo prepare-usb.cmd ...

:: get disk number
echo list disk | diskpart

:: set disk number
set /p DISK_NUM=Enter disk number to use:
:: safety check
if "%DISK_NUM%"=="" (
    echo No disk number entered. Exiting.
    pause >nul
    exit /b
)

:: drive letters used
echo Drive letters used:
fsutil fsinfo drives

:: ask
set /p DRIVELETTER_ISO=Enter drive letter for ISO:
set /p DRIVELETTER_P1=Enter drive letter for P1:
set /p DRIVELETTER_P2=Enter drive letter for P2:
set /p DRIVELETTER_P3=Enter drive letter for P3:

:: generate diskpart script
(
    echo list disk
    echo select disk %DISK_NUM%
    echo clean
    echo clean
    echo.
    echo create partition primary size=1024
    echo select partition 1
    echo active
    echo format fs=fat32 quick
    echo assign letter=%DRIVELETTER_P1%
    echo.
    echo create partition primary size=16384
    echo select partition 2
    echo format fs=ntfs quick
    echo assign letter=%DRIVELETTER_P2%
    echo.
    echo create partition primary
    echo select partition 3
    echo format fs=exfat quick
    echo assign letter=%DRIVELETTER_P3%
    echo.
    echo exit
) > "%temp%\diskpart-script.txt"

:: run generated diskpart script
diskpart /s "%temp%\diskpart-script.txt"

:: clean up
del "%temp%\diskpart-script.txt"

:: bootsect
cd /d %DRIVELETTER_ISO%:\boot
bootsect.exe /nt60 %DRIVELETTER_P1%:

:: copy files
:: 
:: partition 1
robocopy %DRIVELETTER_ISO%:\ %DRIVELETTER_P1%:\ /e /copyall /xd "%DRIVELETTER_ISO%:\sources"
mkdir %DRIVELETTER_P1%:\sources
robocopy %DRIVELETTER_ISO%:\sources %DRIVELETTER_P1%:\sources boot.wim /copyall
:: 
:: partition 2
robocopy %DRIVELETTER_ISO%:\ %DRIVELETTER_P2%:\ /e /copyall
:: 
:: partition 3
type nul > %DRIVELETTER_P3%:\files_go_here.txt

:: exit
echo.
echo Terminating prepare-usb.cmd ...
pause >nul
exit


:: ==================================================
:: Notes
:: ==================================================
