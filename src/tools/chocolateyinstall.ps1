$ErrorActionPreference = 'Stop';

(Get-WmiObject -Class Win32_OperatingSystem).Version -match "(?<Major>\d+).(?<Minor>\d+).(?<Build>\d+)" | Out-Null

if ($Matches.Major -eq 6 -and $Matches.Minor -eq 3)
{
    # Windows 8.1 / Server 2012 R2 requires a prerequisite hotfix 
    if (-not (Get-HotFix -Id KB2919355 -ErrorAction SilentlyContinue))
    {
        Write-Error "A prerequisite for installing SQL 2016 on Windows 8.1 and Windows Server 2012 R2 is to have hotfix KB2919355 installed. See https://msdn.microsoft.com/library/ms143506.aspx for more details"
    }
}

$packageName= 'SQL Server Management Studio'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url = 'https://download.microsoft.com/download/C/8/A/C8AE3D51-5AAD-4DCF-809C-667D691629E4/SSMS-Setup-ENU.exe'

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'EXE'
  url           = $url

  silentArgs    = "/quiet /install /norestart /log `"$env:TEMP\chocolatey\$($packageName)\$($packageName).MsiInstall.log`""
  validExitCodes= @(0, 3010, 1641)

  softwareName  = 'SQL Server Management Studio - 17.0'
  checksum      = '54692d0a38b44c6d0318c12c32ca69d3852c68116642914c8efdcba020c89dda'
  checksumType  = 'SHA256'
}

Install-ChocolateyPackage @packageArgs
