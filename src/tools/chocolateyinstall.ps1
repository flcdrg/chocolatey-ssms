$ErrorActionPreference = 'Stop';


$packageName= 'SQL Server Management Studio'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url = 'http://download.microsoft.com/download/A/7/7/A77F55AC-6DFF-4B73-B2BD-420A97B946A3/SSMS-Setup-ENU.exe'

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'EXE'
  url           = $url

  silentArgs    = "/quiet /install /norestart"
  validExitCodes= @(0, 3010, 1641)

  softwareName  = 'SQL Server Management Studio - February 2016'
  checksum      = '7989638E6E42A3FC14992BBC3F16C19F'
  checksumType  = 'md5'
}

Install-ChocolateyPackage @packageArgs
