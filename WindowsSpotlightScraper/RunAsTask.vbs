dim fso: set fso = CreateObject("Scripting.FileSystemObject")
dim currentDirectory
currentDirectory = fso.GetAbsolutePathName(".")
dim path
path = fso.BuildPath(currentDirectory, "SpotlightScraper.ps1")
command = Replace("powershell.exe -nologo -ExecutionPolicy Unrestricted -Command ""& '{{Path}}' -setCurrent $true""", "{{Path}}", path)
set shell = CreateObject("WScript.Shell")
shell.Run command,0