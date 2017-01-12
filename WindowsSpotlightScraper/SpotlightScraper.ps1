param(
	[string]$dumpTo = (Join-Path (Split-Path $MyInvocation.MyCommand.Path) "Images"),
	[int]$maxImages = 100,
	[boolean]$setCurrent = $false
)

Add-Type -Assembly "System.Drawing"
$spotlightRegBase = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lock Screen\Creative\"

function Get-ScreenResolution()
{
	$screenRes = (Get-WmiObject -Class Win32_VideoController).VideoModeDescription;
	$screenRes -match "^(?<width>\d+)\sx\s(?<height>\d+)";
	$res = New-Object PSObject -Property @{
		Width = $matches.width
		Height = $matches.height
	}

	Write-Host "Screen Resolution is $($res.Width) x $($res.Height)"

	return $res
}

function Process-Folder($folder){
	Write-Host "Processing $folder"

	$screenRes = Get-ScreenResolution

	if(-not (Test-Path $dumpTo)){
		New-Item $dumpTo -Type Directory
	}
	
	Get-ChildItem $folder -File | %{
		$fullFileName = $_.FullName
		$fileName = $_.Name
		Try{
			$drawing = [Drawing.Image]::FromFile($fullFileName)

			if($drawing.Width -eq $screenRes.Width -and $drawing.Height -eq $screenRes.Height){	
				$imgExt = ""
				if($drawing.RawFormat -eq [System.Drawing.Imaging.ImageFormat]::Jpeg){
					$imgExt = "jpg"
				}
				elseif($drawing.RawFormat -eq [System.Drawing.Imaging.ImageFormat]::Bmp){
					$imgExt = "bmp"
				}
				elseif($drawing.RawFormat -eq [System.Drawing.Imaging.ImageFormat]::Png){
					$imgExt = "png"
				}
				else{
					default {Error "Unknown image format"}
				}
												
				$targetName = "$($fileName).$imgExt"
				$targetFullName = Join-Path $dumpTo $targetName

				if(-not (Test-Path $targetFullName) -and $imgExt)
				{
					Write-Host "Copying $fullFileName to $targetFullName"
					Copy-Item $fullFileName $targetFullName

					#Write-Host "$($fileName) is $($drawing.Width) x $($drawing.Height)"
				}
			}
		}
		Catch{
			Write-Host "$($fileName) is not an image."
		}
	}

	#cleanup
	Write-Host "Cleanup"
	Get-ChildItem -Path $dumpTo | Sort-Object LastAccessTime -Descending | Select-Object -Skip $maxImages | %{
		Write-Host "Deleting $($_.Name)"

		Remove-Item $_.FullName
	}
}

<#Function Set-WallPaper($value)
{
	Write-Host "Setting wallpaper background to $value"

	Set-ItemProperty -path 'HKCU:\Control Panel\Desktop\' -name wallpaper -value $value
	Start-Sleep -Seconds 1
	RUNDLL32.EXE USER32.DLL,UpdatePerUserSystemParameters ,1 ,True
 
}#>

function Get-SpotlightParameters()
{
	$landscapeAssetPath = Get-ItemProperty -Path $spotlightRegBase -Name "LandscapeAssetPath"
	$portraitAssetPath = Get-ItemProperty -Path $spotlightRegBase -Name "PortraitAssetPath"
	$hotspotImageFolderPath = Get-ItemProperty -Path $spotlightRegBase -Name "HotspotImageFolderPath"

	return New-Object PSObject -Property @{
		LandscapeAssetPath = $landscapeAssetPath.LandscapeAssetPath
		LandscapeAssetFile = (Split-Path $landscapeAssetPath.LandscapeAssetPath -Leaf)
		PortraitAssetPath = $portraitAssetPath.PortraitAssetPath
		HotspotImageFolderPath = $hotspotImageFolderPath.HotspotImageFolderPath
	}
}


$spotlightParameters = Get-SpotlightParameters

Process-Folder $spotlightParameters.HotspotImageFolderPath

if($setCurrent){
	if(-not $spotlightParameters.LandscapeAssetPath){
		Write-Host "No lockscreen wallpaper currently set by spotlight."
		Return
		
	}

	Get-ChildItem -Path $dumpTo -Filter "$($spotlightParameters.LandscapeAssetFile).*" | %{
		$currentWallpaper = (Get-ItemProperty -path 'HKCU:\Control Panel\Desktop\' -name Wallpaper).Wallpaper

		if($currentWallpaper -ne $_.FullName){
			. (Join-Path (Split-Path $MyInvocation.MyCommand.Path) "Set-Wallpaper.ps1")

			Set-Wallpaper $_.FullName
		}
	}
}
