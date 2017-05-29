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

function Get-Download($url, $version)
{
    $request = Invoke-WebRequest -Uri $url -MaximumRedirection 0 -ErrorAction Ignore

    $r = @{}
 
    if($request.StatusCode -lt 400)
    {
        # $url        = 'http://download.microsoft.com/download/E/E/1/EE12CC0F-A1A5-4B55-9425-2AFBB2D63979/SSMS-Full-Setup.exe'

        $location = [UriBuilder] $request.Headers.Location

        # Switch to https
        $location.Scheme = "https"
        $location.Port = 443

        $url = $location.Uri
        Write-Host "Downloading $url"

        $filename = [IO.Path]::GetFileName($url)
        $destPath = "$($env:TEMP)\chocolatey\sql-server-management-studio\$version"

        if (-not (Test-Path $destPath)) {
            New-Item -ItemType Directory $destPath | Out-Null
        }

        $filename = [IO.Path]::Combine($destPath, $filename)

        if (Test-Path $filename) {
            Write-Warning "$filename already exists, skipping download"
        } else {
            Invoke-WebRequest -Uri $url -OutFile $filename
        }

        $hash = Get-FileHash $filename -Algorithm SHA256
        $r = @{
            url = $url
            checksum = $hash.Hash
        }
    }

    return $r
}

function Update-Version
{
   $response = Invoke-WebRequest -Uri "https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms"
   $content = $response.Content

    $links = $response.links

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

        $releaseNotes = $releaseNotes -replace "(?smi)^  \- ", "   - "
        $releaseNotes = $releaseNotes -replace "(?smi)^ \- ", "  - "

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

   $downloadLinks = $links | Where-Object InnerText -match '^Download SQL Server Management Studio.*' | select -First 2 InnerText, href

   if ($downloadLinks)
   {
        $installScript = Join-Path $PSScriptRoot "src/tools/chocolateyInstall.ps1"
        $contents = Get-Content $installScript -Encoding Utf8
 
        $first = Get-Download $downloadLinks[0].href $version
        $second = Get-Download $downloadLinks[1].href $version

        if($first.Count -and $second.Count)
        {
            $patterns = @{
                "(^[$]fullUrl\s*=\s*)('.*')"         = "`$1'$($first.url)'"
                "(^[$]fullChecksum\s*=\s*)('.*')"    = "`$1'$($first.checksum)'"
                "(^[$]upgradeUrl\s*=\s*)('.*')"      = "`$1'$($second.url)'"
                "(^[$]upgradeChecksum\s*=\s*)('.*')" = "`$1'$($second.checksum)'"
                "(^[$]release\s*=\s*)('.*')"         = "`$1'$release'"
            }

            foreach ($key in $patterns.Keys) {
                $contents = $contents -replace $key, $patterns[$key]
            }
            $contents | Out-File $installScript -Encoding Utf8
        }

    }
   else
   {
       Write-Host "Unable to find the download link on the download page. Check the regex above"
   }
}

Update-Version

