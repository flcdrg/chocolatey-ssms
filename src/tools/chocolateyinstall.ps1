$ErrorActionPreference = 'Stop';


$packageName= 'SQL Server Management Studio'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'http://download.microsoft.com/download/E/E/1/EE12CC0F-A1A5-4B55-9425-2AFBB2D63979/SSMS-Full-Setup.exe'

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'EXE'
  url           = $url

  silentArgs    = "/quiet /install /norestart"
  validExitCodes= @(0, 3010, 1641)

  softwareName  = 'SQL Server Management Studio - February 2016'
  checksum      = '34843BEB2A42D5BDE4822027B9619851'
  checksumType  = 'md5'
}

Install-ChocolateyPackage @packageArgs
