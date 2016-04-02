$ErrorActionPreference = 'Stop';


$packageName= 'SQL Server Management Studio'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url = 'http://download.microsoft.com/download/7/A/3/7A3FDD42-8461-48D8-AECB-F126AB60FED8/SSMS-Setup-ENU.exe'

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'EXE'
  url           = $url

  silentArgs    = "/quiet /install /norestart"
  validExitCodes= @(0, 3010, 1641)

  softwareName  = 'SQL Server Management Studio - March 2016'
  checksum      = '5AB8183BA1C143E4B8971FA19F660F18'
  checksumType  = 'md5'
}

Install-ChocolateyPackage @packageArgs
