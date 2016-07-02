$ErrorActionPreference = 'Stop';


$packageName= 'SQL Server Management Studio'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url = 'http://download.microsoft.com/download/6/F/C/6FCFDC7F-772F-4FEF-BD48-D75C9A3CFB54/SSMS-Setup-ENU.exe'

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'EXE'
  url           = $url

  silentArgs    = "/quiet /install /norestart /log `"$env:TEMP\chocolatey\$($packageName)\$($packageName).MsiInstall.log`""
  validExitCodes= @(0, 3010, 1641)

  softwareName  = 'SQL Server Management Studio*'
  checksum      = 'E00897FEC547B6112A2037AC6C37FE75'
  checksumType  = 'md5'
}

Install-ChocolateyPackage @packageArgs
