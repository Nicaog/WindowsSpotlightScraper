SET DIR=%~dp0%
cd /d %DIR%
PowerShell.exe -ExecutionPolicy Unrestricted -Command "& '%DIR%SpotlightScraper.ps1' -setCurrent $true %*"