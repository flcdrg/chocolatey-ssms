Set-StrictMode -Version Latest

# Based on Update-Version from https://github.com/shiftkey/chocolatey-beyondcompare

Add-type -Path .\packages\HtmlAgilityPack.1.4.9\lib\Net45\HtmlAgilityPack.dll
Add-Type -Path .\packages\ReverseMarkdown.0.1.25\lib\net45\ReverseMarkdown.dll

function Parse-ReleaseNotes()
{
    $htmlWeb = New-Object HtmlAgilityPack.HtmlWeb
    $htmlWeb.AutoDetectEncoding = $true
    $doc = $htmlWeb.Load("https://docs.microsoft.com/en-us/sql/ssms/sql-server-management-studio-changelog-ssms")

    [HtmlAgilityPack.HtmlNode] $mainBody = $doc.DocumentNode.SelectSingleNode("//div[@class='content']")

    $h2count = 0

    foreach ($node in $mainBody.ChildNodes) {      
        # stop when we find the next heading
        if ($node.Name -eq "H2") {
            $h2count++

            if ($h2count -eq 2) {
                break
            }

            $node.OuterHtml
        }
        else {
            $node.OuterHtml
        }
    }
}

function Update-Version
{
   $response = Invoke-WebRequest -Uri "https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms"
   $content = $response.Content

   # The version number for this latest preview is: 13.0.12000.65
   $isMatch = $content -match "(The release number: (?<release>\d+\.\d+(\.\d+){0,2})).*(The build number for this release).*: (?<version>\d+\.\d+\.\d+\.\d+)"

   if ($isMatch)
   {
        $version = $matches.version
        $release = $matches.release

        Write-Host "Found version $version, release $release"

        $c = New-Object ReverseMarkDown.Converter

        $html = Parse-ReleaseNotes
        $releaseNotes = $c.Convert($html) -replace "##", "####"

        $nuspec = Join-Path $PSScriptRoot "src/sql-server-management-studio.nuspec"
        $contents = [xml] (Get-Content $nuspec -Encoding Utf8)

        # $contents.package.metadata.title = "SQL Server Management Studio $release"
        $contents.package.metadata.version = "$version"
        $contents.package.metadata.releaseNotes = $releaseNotes

        $contents.Save($nuspec)

        # Reprocess file to make line-endings consistent
        (Get-Content $nuspec -Encoding UTF8) | Set-Content $nuspec -Encoding UTF8

        Write-Host
        Write-Host "Updated nuspec, commit this change and open a pull request to the upstream repository on GitHub!"

   }
   else
   {
        Write-Host "Unable to find the release on the download page. Check the regex above"
   }

   $isMatch = $content -match '\<a href\=\"(?<url>https://([\w+?\.\w+])+([a-zA-Z0-9\~\!\@\#\$\%\^\&\*\(\)_\-\=\+\\\/\?\.\:\;\''\,]*))\".*\>Download SQL Server Management Studio'

   if ($isMatch)
   {
        $installScript = Join-Path $PSScriptRoot "src/tools/chocolateyInstall.ps1"
        $contents = Get-Content $installScript -Encoding Utf8

        # Find actual download URL
        $request = Invoke-WebRequest -Uri $($Matches.url) -MaximumRedirection 0 -ErrorAction Ignore
 
        if($request.StatusCode -lt 400)
        {
            # $url        = 'http://download.microsoft.com/download/E/E/1/EE12CC0F-A1A5-4B55-9425-2AFBB2D63979/SSMS-Full-Setup.exe'

            $location = [UriBuilder] $request.Headers.Location

            # Switch to https
            $location.Scheme = "https"
            $location.Port = 443

            $newContents = $contents -replace "\`$url\s*=\s*['`"]http.+['`"]", "`$url = '$($location.Uri.ToString())'"

            Write-Host "Downloading $($location.Uri)"

            $tempFile = New-TemporaryFile

            Invoke-WebRequest -Uri $location.Uri -OutFile $tempFile

            $hash = Get-FileHash $tempFile -Algorithm SHA256

            #$tempFile.Delete()
            Write-Host "Delete $tempFile if no longer required"

            #   checksum      = '34843BEB2A42D5BDE4822027B9619851'
            $newContents = $newContents -replace "checksum\s*=\s*'[a-fA-F0-9]+'", "checksum      = '$($hash.Hash)'"
            $newContents = $newContents -replace "softwareName\s*=\s*'.+'", "checksum      = 'SQL Server Management Studio - $($release)'"

            $newContents | Out-File $installScript -Encoding Utf8

            Write-Host
            Write-Host "Updated install script. Manually update 'softwareName', commit this change and open a pull request to the upstream repository on GitHub!"
            
        }

    }
   else
   {
       Write-Host "Unable to find the download link on the download page. Check the regex above"
   }

}

Update-Version

