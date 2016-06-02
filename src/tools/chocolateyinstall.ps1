$ErrorActionPreference = 'Stop';


$packageName= 'SQL Server Management Studio'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url = 'http://download.microsoft.com/download/E/D/3/ED3B06EC-E4B5-40B3-B861-996B710A540C/SSMS-Setup-ENU.exe'

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'EXE'
  url           = $url

  silentArgs    = "/quiet /install /norestart /log `"$env:TEMP\chocolatey\$($packageName)\$($packageName).MsiInstall.log`""
  validExitCodes= @(0, 3010, 1641)

  softwareName  = 'SQL Server Management Studio*'
  checksum      = '5DE280315BCBCB91A70064794FE827D5'
  checksumType  = 'md5'
}

Install-ChocolateyPackage @packageArgs
