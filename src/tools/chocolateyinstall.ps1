$ErrorActionPreference = 'Stop';


$packageName= 'SQL Server Management Studio'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url = 'http://download.microsoft.com/download/8/6/3/8639523C-7F12-4CC3-8D2F-908C7A78B4C6/SSMS-Setup-ENU.exe'

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'EXE'
  url           = $url

  silentArgs    = "/quiet /install /norestart /log `"$env:TEMP\chocolatey\$($packageName)\$($packageName).MsiInstall.log`""
  validExitCodes= @(0, 3010, 1641)

  softwareName  = 'SQL Server Management Studio - April 2016'
  checksum      = '6F8E96B876DB7207058AE80FADF2C66A'
  checksumType  = 'md5'
}

Install-ChocolateyPackage @packageArgs
