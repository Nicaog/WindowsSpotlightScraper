SET DIR=%~dp0%
cd /d %DIR%
PowerShell.exe -ExecutionPolicy Unrestricted -WindowStyle Hidden -Command "& '%DIR%SpotlightScraper.ps1' %*"