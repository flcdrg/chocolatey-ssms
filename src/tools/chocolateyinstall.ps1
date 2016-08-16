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
$url = 'https://download.microsoft.com/download/4/7/2/47218E85-5903-4EF4-B54E-3B71DD558017/SSMS-Setup-ENU.exe'

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'EXE'
  url           = $url

  silentArgs    = "/quiet /install /norestart /log `"$env:TEMP\chocolatey\$($packageName)\$($packageName).MsiInstall.log`""
  validExitCodes= @(0, 3010, 1641)

  softwareName  = 'SQL Server Management Studio*'
  checksum      = '8C74AB7A8EFA87C74323ED80AD3E1379'
  checksumType  = 'md5'
}

Install-ChocolateyPackage @packageArgs
