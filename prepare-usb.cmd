:: prepare-usb.cmd
:: ==================================================
:: Description
:: ==================================================
:: Usage
:: ==================================================


echo prepare-usb.cmd ...

:: echo off
@echo off

:: get disk number
echo list disk | diskpart

:: assume
:: disk number = 1
:: ISO drive letter = E

:: run diskpart script
diskpart /s diskpart-script.txt

:: bootsect
cd /d e:\boot (assume e: is the mounted DVD drive letter)
bootsect.exe /nt60 j:

:: copy files
:: 
:: partition 1
robocopy E:\ J:\ /e /copyall /xd "E:\sources"
mkdir J:\sources
robocopy E:\sources\boot.wim J:\sources /copyall
:: 
:: partition 2
robocopy E:\ J:\ /e /copyall
:: 
:: partition 3
type nul > L:\files_go_here.txt

:: exit
echo.
echo Terminating run_as_administrator.cmd ...
pause >nul
exit


:: ==================================================
:: Notes
:: ==================================================
