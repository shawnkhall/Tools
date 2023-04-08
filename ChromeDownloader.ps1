
<#PSScriptInfo

.VERSION 2.0

.GUID c65575a3-2b12-461e-99b3-35dfd0e644b4

.AUTHOR shawn@shawnkhall.com

.COMPANYNAME Shawn K. Hall

.COPYRIGHT Unlicense

.TAGS chrome version download url stable

.LICENSEURI https://unlicense.org/

.PROJECTURI https://shawnkhall.com/

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
 2.0: Removes OS Version validation, removes bit-massaging for unsupported operating systems, improves parsing for named OS versions, adds pipeline support (now default), changes disposition behavior, expands examples and parameters. This version also changes default OS version to 11 since that number is safely cross-platform.
 1.4: Add 32-bit support for Server 2003 (5.2) through 2008 (6.0) and 32/64-bit support for Server 2008 R2 (6.1)
 1.3: Bug fixes
 1.2: Add option to assign the prefix for output and binary files, bug fixes, verbosity
 1.1: Add JSON export support
 1.0: Initial release

#> 



<# 

.SYNOPSIS
 ChromeDownloader: Obtains information about the current version of Chrome for different hardware and operating system

.DESCRIPTION 
 Obtains information about the current version of Chrome for different hardware and operating system, optionally downloading, exporting as JSON, XML or displaying information.
 Note: While you can use any value for the OS version, unsupported operating systems do not receive security updates and the versions available for download from Google are not secure and are not supported. Likewise, not all operating systems support both a 32-bit and 64-bit version. 

.PARAMETER platform
 Specifies the operating system: win or mac

.PARAMETER osversion
 Specifies the OS version: 5.2, 6.0, 6.1, 6.2, 6.3, 7, 8, 10, 11, 12, 13, 2003, 2008, 2008r2, 2012, 2012r2, 2016, 2019, 2022, 21H1, ...

.PARAMETER bits
 Specifies the bit-type: x64 or x86

.PARAMETER release
 Specifies the release type: stable, beta, dev or canary

.PARAMETER disposition
 Specifies disposition: pipeline, url, info, status

.PARAMETER download
 Determines if the file should be downloaded

.PARAMETER overwrite
 Determines if an existing file should be overwritten

.PARAMETER rename
 When disposition is download, inserts bit-type into downloaded filename. This option has no effect when -prefix is in use.

.PARAMETER jsonsave
 Save the JSON output to a file

.PARAMETER xmlsave
 Save the XML output to a file

.PARAMETER prefix
 Specify a custom naming pattern. The following strings will be replaced with their values: %platform/%p, %bits/%b, %osversion/%osv, %release/%r, %version/%v

.INPUTS
 You can pass named values to this script from the pipeline.

.EXAMPLE
 .\ChromeDownloader.ps1 win 64 
 Display the latest 64-bit build of Chrome for Windows 11

.EXAMPLE
 .\ChromeDownloader.ps1 win 64 -download
 Download the latest 64-bit build of Chrome for Windows 11

.EXAMPLE
 .\ChromeDownloader.ps1 win -os 2012 -b 64 -do info
 Display information about the latest 64-bit build of Chrome for Windows Server 2012

.EXAMPLE
 .\ChromeDownloader.ps1 win 10 64 -download -release beta -rename
 Download the latest 64-bit beta build of Chrome for Windows 10 and inserts the bit-type in the file name

.EXAMPLE
 .\ChromeDownloader.ps1 mac
 Display the latest build of Chrome for macOS 11

.EXAMPLE
 .\ChromeDownloader.ps1 -download -jsonsave -xmlsave -prefix 'C:/Browsers/Chrome-%v_%p%osv_%b_%r'
 Download the current build of Chrome x64 for Windows 11 to a file under C:/Browsers, named to include the version of Chrome, the platform and OS version, the bit-type and release type, as well as creating both an XML and a JSON file with details about the download beside the binary, and returns details via the pipeline.

.EXAMPLE
 $commonParams = @{ platform = 'win'; bits = 64; do = 'pipeline' };  '2008r2','2012','10' | ForEach-Object {.\ChromeDownloader.ps1  @commonParams -osversion $_} | Select platform,osversion,version,url | Format-Table
 Display information about the latest 64-bit releases of Chrome for Windows 2008r2, 2012 and 10, formatting the results in a table.

#>

Param(
	[ValidateSet("win", "mac", IgnoreCase = $false)]
	[Parameter(ValueFromPipelineByPropertyName=$true, position=0)]
	[Alias("P")]
	[string] $platform = "win", 
	
	[Parameter(ValueFromPipelineByPropertyName=$true, position=1)]
	[Alias("OS")]
	[string] $osversion = "11.0", 
	
	[ValidateSet("x64", "64", "x86", "32", IgnoreCase = $false)]
	[Parameter(ValueFromPipelineByPropertyName=$true, position=2)]
	[Alias("B")]
	[string] $bits = "x64", 
	
	[ValidateSet("url", "info", "status", "pipeline", IgnoreCase = $false)]
	[Parameter(ValueFromPipelineByPropertyName=$true, position=3)]
	[Alias("Do")]
	[string] $disposition = "pipeline",
	
	[ValidateSet("stable", "beta", "dev", "canary", IgnoreCase = $false)]
	[Parameter(ValueFromPipelineByPropertyName=$true)]
	[Alias("Rel")]
	[string] $release = "stable", 
	
	[Parameter(ValueFromPipelineByPropertyName=$true)]
	[Alias("down")]
	[switch] $download = $false,
	
	[Parameter(ValueFromPipelineByPropertyName=$true)]
	[Alias("o", "clobber")]
	[switch] $overwrite = $false,
	
	[Parameter(ValueFromPipelineByPropertyName=$true)]
	[Alias("Ren")]
	[switch] $rename = $false, 
	
	[Parameter(ValueFromPipelineByPropertyName=$true)]
	[Alias("JS")]
	[switch] $jsonsave = $false, 
	
	[Parameter(ValueFromPipelineByPropertyName=$true)]
	[Alias("XS")]
	[switch] $xmlsave = $false, 
	
	[Parameter(ValueFromPipelineByPropertyName=$true)]
	[Alias("Pre")]
	[string] $prefix = ""
)



function cdFormatXML([string]$xmlpath, [switch]$omitprolog) {
	Write-Verbose	"cdFormatXML"
	$sb	= New-Object System.Text.StringBuilder
	$sw	= New-Object System.IO.StringWriter($sb)
	$encoding	= [System.Text.Encoding]::UTF8
	$xmlsettings	= New-Object System.Xml.XmlWriterSettings
	$xmlsettings.Encoding	= $encoding
	$xmlsettings.Indent	= $true
	$xmlsettings.OmitXmlDeclaration	= $omitprolog
	$xmlsettings.IndentChars	= "`t"
	$xmlsettings.NewLineOnAttributes	= $false
	$wr	= [System.XML.XmlWriter]::Create($sw, $xmlsettings)
	$wr.Flush()
	($chromeDownload|ConvertTo-Xml -NoTypeInformation).Save($wr)
	if($xmlpath){
		$sb.ToString() | Set-Content -Path ($xmlpath -replace "'", "")
	}else{
		return $sb.ToString()
	}
}


function cdFormatJSON([string]$jsonpath) {
	Write-Verbose	"cdFormatJSON"
	$json	= ($chromeDownload | ConvertTo-Json)
	if($jsonpath){
		$json | Set-Content -Path ($jsonpath -replace "'", "")
	}else{
		return $json
	}
}


# parse input
$thisversion	= (((Get-Content($PSCommandPath)) -match '\.VERSION\s+(.+)') -split " ")[1];
Write-Verbose	"ChromeDownloader.ps1 $thisversion"
Write-Verbose	""
Write-Verbose	"  platform:	$platform"
Write-Verbose	"  bits:	$bits"
Write-Verbose	"  release:	$release"
Write-Verbose	"  osversion:	$osversion"
Write-Verbose	"  disposition:	$disposition"
Write-Verbose	"  download:	$download"
Write-Verbose	"  overwrite:	$overwrite"
Write-Verbose	"  rename:	$rename"
Write-Verbose	"  jsonsave:	$jsonsave"
Write-Verbose	"  xmlsave:	$xmlsave"
Write-Verbose	"  prefix:	$prefix"


Switch ($platform) {
	'win' {
		$ext	= '.exe'
		$appid	= '{8A69D345-D564-463C-AFF1-A69D9E530F96}'
		Switch ($osversion) {
			{ @('21H2', '2022', '22H2') -contains $_ } 	{ $osversion = '11.0'; break }
			{ @('1507', '1511', '1607', '1703', '1709', 	
			    '1803', '1809', '1903', '1909', '19H1', 	
			    '19H2', '2004', '2009', '2016', '2019', 	
			    '20H1', '20H2', '21H1') -contains $_ } 	{ $osversion = '10.0'; break }
			{ @('8.1', '2012r2') -contains $_ } 	{ $osversion = '6.3'; break }
			{ @('8', '8.0', '2012') -contains $_ } 	{ $osversion = '6.2'; break }
			{ @('7', '7.0', '2008r2') -contains $_ } 	{ $osversion = '6.1'; break }
			{ @('vista', '2008') -contains $_ } 	{ $osversion = '6.0'; break }
			{ @('xp', '2003', '2003r2') -contains $_ } 	{ $osversion = '5.2'; break }
			default	{ break }
		}
		Switch ($bits) {
			{ @('x64', '64') -contains $_ } {
				$bits	= 'x64'
				Switch ($release) {
					'stable'	{ $ap = 'x64-stable-multi-chrome'; 	break }
					'beta'	{ $ap = 'x64-beta-multi-chrome'; 	break }
					'dev'	{ $ap = 'x64-dev-multi-chrome'; 	break }
					'canary'	{ $ap = 'x64-canary'; $appid = '{4EA16AC7-FD5A-47C3-875B-DBF4A2008C20}'; 	break }
					default	{ $ap = 'x64-stable-multi-chrome'; 	break }
				}
			}
			{ @('x86', '32') -contains $_ } {
				$bits	= 'x86'
				Switch ($release) {
					'stable'	{ $ap = '-multi-chrome'; 	break }
					'beta'	{ $ap = '1.1-beta'; 	break }
					{ @('dev','canary') -contains $_ }	{ $ap = '2.0-dev'; 	break }
					default	{ $ap = '-multi-chrome'; 	break }
				}
			}
			default {
				$bits	= 'x64'
				$release	= 'stable'
				$ap	= 'x64-stable-multi-chrome'
			}
		}
	}
	{ @('mac', 'macos') -contains $_ } {
		$ext	= '.dmg'
		$bits	= 'x64'
		Switch ($osversion) {
			{ @('10', '10.0') -contains $_ } { $osversion = "11.0"; break }
			{ @('11', '12', '13') -contains $_ } { $osversion = "$osversion.0"; break }
			default	{ break }
		}
		Switch ($release) {
			'stable'	{ $ap = ''; 	$appid = 'com.google.Chrome'; 	break }
			'beta'	{ $ap = 'betachannel'; 	$appid = 'com.google.Chrome.Beta'; 	break }
			'dev'	{ $ap = 'devchannel'; 	$appid = 'com.google.Chrome.Dev'; 	break }
			'canary'	{ $ap = ''; 	$appid = 'com.google.Chrome.Canary'; 	break }
			default	{ $ap = ''; 	$appid = 'com.google.Chrome'; 	break }
		}
	}
	default {
		$platform	= 'win'
		$bits	= 'x64'
		$release	= 'stable'
		$osversion	= '10.0'
		$ap	= 'x64-stable-multi-chrome'
		$appid	= '{8A69D345-D564-463C-AFF1-A69D9E530F96}'
	}
}
Write-Verbose	"  ap:	$ap"
Write-Verbose	"  appid:	$appid"


# generate the initial request
Write-Verbose	""
Write-Verbose	"Update check"
$header	= @{ "Accept"="text/xml"; "Content-Type"="text/xml" }
Write-Verbose 	"  header:	$header"
$body	= "<?xml version='1.0' encoding='UTF-8'?><request protocol='3.0' version='1.3.23.9' shell_version='1.3.21.103' ismachine='0' sessionid='{00000000-0000-0000-0000-000000000000}' installsource='ondemandcheckforupdate' requestid='{00000000-0000-0000-0000-000000000000}' dedup='cr'><hw sse='1' sse2='1' sse3='1' ssse3='1' sse41='1' sse42='1' avx='1' physmemory='12582912' /><os platform='$platform' version='$osversion' arch='$bits'/><app appid='$appid' ap='$ap' version='' nextversion='' lang='' brand='GGLS' client=''><updatecheck/></app></request>"
Write-Verbose 	"  body:	$body"
$xmlfile	= New-TemporaryFile
Write-Verbose 	"  xmlfile:	$xmlfile"
Invoke-RestMethod -Uri "https://tools.google.com/service/update2" -Method POST -Body $body -Headers $header -OutFile $xmlfile


# parse the results
Write-Verbose	""
Write-Verbose	"Response"
$xmlDoc	= [xml](Get-Content -Path $xmlfile -Encoding UTF8)
$status	= $xmlDoc.SelectSingleNode("//response/app/updatecheck/@status").Value
Write-Verbose	"  status:	$status"
$url	= $xmlDoc.SelectSingleNode("//response/app/updatecheck/urls/url[last()]/@codebase").Value
Write-Verbose	"  url:	$url"
$version	= $xmlDoc.SelectSingleNode("//response/app/updatecheck/manifest/@version").Value
Write-Verbose	"  version:	$version"
$package	= $xmlDoc.SelectSingleNode("//response/app/updatecheck/manifest/packages/package/@name").Value
Write-Verbose	"  package:	$package"
$size	= $xmlDoc.SelectSingleNode("//response/app/updatecheck/manifest/packages/package/@size").Value
Write-Verbose	"  size:	$size"
$sha256	= $xmlDoc.SelectSingleNode("//response/app/updatecheck/manifest/packages/package/@hash_sha256").Value
Write-Verbose	"  sha256:	$sha256"


# rename the download file if requested
Write-Verbose	""
Write-Verbose	"Output formatting"
Write-Verbose	"  file[0]:	$file"
if($rename){
	$file	= $package -replace "$ext", "_$bits"
} else {
	$file	= $package -replace "$ext", ""
}
Write-Verbose	"  file[1]:	$file"


# format prefix
if($prefix){
	$prefix	= $prefix -replace "%osversion", "$osversion"
	$prefix	= $prefix -replace "%bits", "$bits"
	$prefix	= $prefix -replace "%platform", "$platform"
	$prefix	= $prefix -replace "%osv", "$osversion"
	$prefix	= $prefix -replace "%os", "$platform"
	$prefix	= $prefix -replace "%release", "$release"
	$prefix	= $prefix -replace "%version", "$version"
	$prefix	= $prefix -replace "%b", "$bits"
	$prefix	= $prefix -replace "%p", "$platform"
	$prefix	= $prefix -replace "%r", "$release"
	$prefix	= $prefix -replace "%v", "$version"
	if(!($prefix.Contains('\') -or $prefix.Contains('/'))){
		$prefix = "./$prefix"
	}
	$file	= $prefix
}
Write-Verbose	"  file[2]:	$file"


# build psobject
$chromeDownload	= New-Object PSObject -Property @{
	Status	= $status
	Version	= $version
	Url	= "$url$package"
	File	= $package
	Sha256	= $sha256
	Size	= $size
	Codebase	= $url
	Ext	= $ext
	Platform	= $platform
	Bits	= $bits
	Release	= $release
	OsVersion	= $osversion
	Disposition	= $disposition
	Download	= $download
	Overwrite	= $overwrite
	Rename	= $rename
	JsonSave	= $jsonsave
	XmlSave	= $xmlsave
	Prefix	= $prefix
	Ap	= $ap
	AppId	= $appid
	Timestamp	= $((Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmss'))
}


# generate output
if($status -ne 'ok'){
	Write-Warning "Error: $platform $osversion $bits $release"
}
if($jsonsave){ cdFormatJSON ("$file.json") }
if($xmlsave){  cdFormatXML  ("$file.xml") }
if($download){
	if ((!(Test-Path "$file$ext")) -or ((Test-Path "$file$ext") -and $overwrite)) {
		Invoke-WebRequest -Uri "$url$package" -OutFile "$file$ext"
	} else {
		Write-Warning "File '$file$ext' exists."
	}
}
Switch ($disposition){
	'url'	{ echo "$url$package"; break }
	'info'	{ echo "Version: $version" "Url: $url$package" "File: $package" "SHA256: $sha256" "Size: $size" "Status: $status"; break }
	'status'	{ echo $status; break }
	'pipeline'	{ $chromeDownload; break; }
	default	{ $chromeDownload; break; }
}
Remove-Item $xmlfile


# SIG # Begin signature block
# MIIrKwYJKoZIhvcNAQcCoIIrHDCCKxgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUqzA0wE50Ff5iif5i0dgwCR7n
# 0ZGggiQ7MIIEMjCCAxqgAwIBAgIBATANBgkqhkiG9w0BAQUFADB7MQswCQYDVQQG
# EwJHQjEbMBkGA1UECAwSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHDAdTYWxm
# b3JkMRowGAYDVQQKDBFDb21vZG8gQ0EgTGltaXRlZDEhMB8GA1UEAwwYQUFBIENl
# cnRpZmljYXRlIFNlcnZpY2VzMB4XDTA0MDEwMTAwMDAwMFoXDTI4MTIzMTIzNTk1
# OVowezELMAkGA1UEBhMCR0IxGzAZBgNVBAgMEkdyZWF0ZXIgTWFuY2hlc3RlcjEQ
# MA4GA1UEBwwHU2FsZm9yZDEaMBgGA1UECgwRQ29tb2RvIENBIExpbWl0ZWQxITAf
# BgNVBAMMGEFBQSBDZXJ0aWZpY2F0ZSBTZXJ2aWNlczCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBAL5AnfRu4ep2hxxNRUSOvkbIgwadwSr+GB+O5AL686td
# UIoWMQuaBtDFcCLNSS1UY8y2bmhGC1Pqy0wkwLxyTurxFa70VJoSCsN6sjNg4tqJ
# VfMiWPPe3M/vg4aijJRPn2jymJBGhCfHdr/jzDUsi14HZGWCwEiwqJH5YZ92IFCo
# kcdmtet4YgNW8IoaE+oxox6gmf049vYnMlhvB/VruPsUK6+3qszWY19zjNoFmag4
# qMsXeDZRrOme9Hg6jc8P2ULimAyrL58OAd7vn5lJ8S3frHRNG5i1R8XlKdH5kBjH
# Ypy+g8cmez6KJcfA3Z3mNWgQIJ2P2N7Sw4ScDV7oL8kCAwEAAaOBwDCBvTAdBgNV
# HQ4EFgQUoBEKIz6W8Qfs4q8p74Klf9AwpLQwDgYDVR0PAQH/BAQDAgEGMA8GA1Ud
# EwEB/wQFMAMBAf8wewYDVR0fBHQwcjA4oDagNIYyaHR0cDovL2NybC5jb21vZG9j
# YS5jb20vQUFBQ2VydGlmaWNhdGVTZXJ2aWNlcy5jcmwwNqA0oDKGMGh0dHA6Ly9j
# cmwuY29tb2RvLm5ldC9BQUFDZXJ0aWZpY2F0ZVNlcnZpY2VzLmNybDANBgkqhkiG
# 9w0BAQUFAAOCAQEACFb8AvCb6P+k+tZ7xkSAzk/ExfYAWMymtrwUSWgEdujm7l3s
# Ag9g1o1QGE8mTgHj5rCl7r+8dFRBv/38ErjHT1r0iWAFf2C3BUrz9vHCv8S5dIa2
# LX1rzNLzRt0vxuBqw8M0Ayx9lt1awg6nCpnBBYurDC/zXDrPbDdVCYfeU0BsWO/8
# tqtlbgT2G9w84FoVxp7Z8VlIMCFlA2zs6SFz7JsDoeA3raAVGI/6ugLOpyypEBMs
# 1OUIJqsil2D4kF501KKaU73yqWjgom7C12yxow+ev+to51byrvLjKzg6CYG1a4XX
# vi3tPxq3smPi9WIsgtRqAEFQ8TmDn5XpNpaYbjCCBW8wggRXoAMCAQICEEj8k7Rg
# VZSNNqfJionWlBYwDQYJKoZIhvcNAQEMBQAwezELMAkGA1UEBhMCR0IxGzAZBgNV
# BAgMEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBwwHU2FsZm9yZDEaMBgGA1UE
# CgwRQ29tb2RvIENBIExpbWl0ZWQxITAfBgNVBAMMGEFBQSBDZXJ0aWZpY2F0ZSBT
# ZXJ2aWNlczAeFw0yMTA1MjUwMDAwMDBaFw0yODEyMzEyMzU5NTlaMFYxCzAJBgNV
# BAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxLTArBgNVBAMTJFNlY3Rp
# Z28gUHVibGljIENvZGUgU2lnbmluZyBSb290IFI0NjCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBAI3nlBIiBCR0Lv8WIwKSirauNoWsR9QjkSs+3H3iMaBR
# b6yEkeNSirXilt7Qh2MkiYr/7xKTO327toq9vQV/J5trZdOlDGmxvEk5mvFtbqrk
# oIMn2poNK1DpS1uzuGQ2pH5KPalxq2Gzc7M8Cwzv2zNX5b40N+OXG139HxI9ggN2
# 5vs/ZtKUMWn6bbM0rMF6eNySUPJkx6otBKvDaurgL6en3G7X6P/aIatAv7nuDZ7G
# 2Z6Z78beH6kMdrMnIKHWuv2A5wHS7+uCKZVwjf+7Fc/+0Q82oi5PMpB0RmtHNRN3
# BTNPYy64LeG/ZacEaxjYcfrMCPJtiZkQsa3bPizkqhiwxgcBdWfebeljYx42f2mJ
# vqpFPm5aX4+hW8udMIYw6AOzQMYNDzjNZ6hTiPq4MGX6b8fnHbGDdGk+rMRoO7Hm
# ZzOatgjggAVIQO72gmRGqPVzsAaV8mxln79VWxycVxrHeEZ8cKqUG4IXrIfptskO
# gRxA1hYXKfxcnBgr6kX1773VZ08oXgXukEx658b00Pz6zT4yRhMgNooE6reqB0ac
# DZM6CWaZWFwpo7kMpjA4PNBGNjV8nLruw9X5Cnb6fgUbQMqSNenVetG1fwCuqZCq
# xX8BnBCxFvzMbhjcb2L+plCnuHu4nRU//iAMdcgiWhOVGZAA6RrVwobx447sX/Tl
# AgMBAAGjggESMIIBDjAfBgNVHSMEGDAWgBSgEQojPpbxB+zirynvgqV/0DCktDAd
# BgNVHQ4EFgQUMuuSmv81lkgvKEBCcCA2kVwXheYwDgYDVR0PAQH/BAQDAgGGMA8G
# A1UdEwEB/wQFMAMBAf8wEwYDVR0lBAwwCgYIKwYBBQUHAwMwGwYDVR0gBBQwEjAG
# BgRVHSAAMAgGBmeBDAEEATBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsLmNv
# bW9kb2NhLmNvbS9BQUFDZXJ0aWZpY2F0ZVNlcnZpY2VzLmNybDA0BggrBgEFBQcB
# AQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmNvbW9kb2NhLmNvbTANBgkq
# hkiG9w0BAQwFAAOCAQEAEr+h74t0mphEuGlGtaskCgykime4OoG/RYp9UgeojR9O
# IYU5o2teLSCGvxC4rnk7U820+9hEvgbZXGNn1EAWh0SGcirWMhX1EoPC+eFdEUBn
# 9kIncsUj4gI4Gkwg4tsB981GTyaifGbAUTa2iQJUx/xY+2wA7v6Ypi6VoQxTKR9v
# 2BmmT573rAnqXYLGi6+Ap72BSFKEMdoy7BXkpkw9bDlz1AuFOSDghRpo4adIOKnR
# NiV3wY0ZFsWITGZ9L2POmOhp36w8qF2dyRxbrtjzL3TPuH7214OdEZZimq5FE9p/
# 3Ef738NSn+YGVemdjPI6YlG87CQPKdRYgITkRXta2DCCBhowggQCoAMCAQICEGId
# bQxSAZ47kHkVIIkhHAowDQYJKoZIhvcNAQEMBQAwVjELMAkGA1UEBhMCR0IxGDAW
# BgNVBAoTD1NlY3RpZ28gTGltaXRlZDEtMCsGA1UEAxMkU2VjdGlnbyBQdWJsaWMg
# Q29kZSBTaWduaW5nIFJvb3QgUjQ2MB4XDTIxMDMyMjAwMDAwMFoXDTM2MDMyMTIz
# NTk1OVowVDELMAkGA1UEBhMCR0IxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDEr
# MCkGA1UEAxMiU2VjdGlnbyBQdWJsaWMgQ29kZSBTaWduaW5nIENBIFIzNjCCAaIw
# DQYJKoZIhvcNAQEBBQADggGPADCCAYoCggGBAJsrnVP6NT+OYAZDasDP9X/2yFNT
# GMjO02x+/FgHlRd5ZTMLER4ARkZsQ3hAyAKwktlQqFZOGP/I+rLSJJmFeRno+DYD
# Y1UOAWKA4xjMHY4qF2p9YZWhhbeFpPb09JNqFiTCYy/Rv/zedt4QJuIxeFI61tqb
# 7/foXT1/LW2wHyN79FXSYiTxcv+18Irpw+5gcTbXnDOsrSHVJYdPE9s+5iRF2Q/T
# lnCZGZOcA7n9qudjzeN43OE/TpKF2dGq1mVXn37zK/4oiETkgsyqA5lgAQ0c1f1I
# kOb6rGnhWqkHcxX+HnfKXjVodTmmV52L2UIFsf0l4iQ0UgKJUc2RGarhOnG3B++O
# xR53LPys3J9AnL9o6zlviz5pzsgfrQH4lrtNUz4Qq/Va5MbBwuahTcWk4UxuY+Py
# nPjgw9nV/35gRAhC3L81B3/bIaBb659+Vxn9kT2jUztrkmep/aLb+4xJbKZHyvah
# AEx2XKHafkeKtjiMqcUf/2BG935A591GsllvWwIDAQABo4IBZDCCAWAwHwYDVR0j
# BBgwFoAUMuuSmv81lkgvKEBCcCA2kVwXheYwHQYDVR0OBBYEFA8qyyCHKLjsb0iu
# K1SmKaoXpM0MMA4GA1UdDwEB/wQEAwIBhjASBgNVHRMBAf8ECDAGAQH/AgEAMBMG
# A1UdJQQMMAoGCCsGAQUFBwMDMBsGA1UdIAQUMBIwBgYEVR0gADAIBgZngQwBBAEw
# SwYDVR0fBEQwQjBAoD6gPIY6aHR0cDovL2NybC5zZWN0aWdvLmNvbS9TZWN0aWdv
# UHVibGljQ29kZVNpZ25pbmdSb290UjQ2LmNybDB7BggrBgEFBQcBAQRvMG0wRgYI
# KwYBBQUHMAKGOmh0dHA6Ly9jcnQuc2VjdGlnby5jb20vU2VjdGlnb1B1YmxpY0Nv
# ZGVTaWduaW5nUm9vdFI0Ni5wN2MwIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3NwLnNl
# Y3RpZ28uY29tMA0GCSqGSIb3DQEBDAUAA4ICAQAG/4Lhd2M2bnuhFSCbE/8E/ph1
# RGHDVpVx0ZE/haHrQECxyNbgcv2FymQ5PPmNS6Dah66dtgCjBsULYAor5wxxcgEP
# Rl05pZOzI3IEGwwsepp+8iGsLKaVpL3z5CmgELIqmk/Q5zFgR1TSGmxqoEEhk60F
# qONzDn7D8p4W89h8sX+V1imaUb693TGqWp3T32IKGfIgy9jkd7GM7YCa2xulWfQ6
# E1xZtYNEX/ewGnp9ZeHPsNwwviJMBZL4xVd40uPWUnOJUoSiugaz0yWLODRtQxs5
# qU6E58KKmfHwJotl5WZ7nIQuDT0mWjwEx7zSM7fs9Tx6N+Q/3+49qTtUvAQsrEAx
# wmzOTJ6Jp6uWmHCgrHW4dHM3ITpvG5Ipy62KyqYovk5O6cC+040Si15KJpuQ9VJn
# bPvqYqfMB9nEKX/d2rd1Q3DiuDexMKCCQdJGpOqUsxLuCOuFOoGbO7Uv3RjUpY39
# jkkp0a+yls6tN85fJe+Y8voTnbPU1knpy24wUFBkfenBa+pRFHwCBB1QtS+vGNRh
# sceP3kSPNrrfN2sRzFYsNfrFaWz8YOdU254qNZQfd9O/VjxZ2Gjr3xgANHtM3Hxf
# zPYF6/pKK8EE4dj66qKKtm2DTL1KFCg/OYJyfrdLJq1q2/HXntgr2GVw+ZWhrWgM
# Tn8v1SjZsLlrgIfZHDCCBoYwggTuoAMCAQICEQDCQwm71IrzJIwoQU/zm0zEMA0G
# CSqGSIb3DQEBDAUAMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExp
# bWl0ZWQxKzApBgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBS
# MzYwHhcNMjEwNjIxMDAwMDAwWhcNMjQwNjIwMjM1OTU5WjBoMQswCQYDVQQGEwJV
# UzETMBEGA1UECAwKQ2FsaWZvcm5pYTEUMBIGA1UEBwwLVHdhaW4gSGFydGUxFjAU
# BgNVBAoMDVNoYXduIEsuIEhhbGwxFjAUBgNVBAMMDVNoYXduIEsuIEhhbGwwggIi
# MA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCurOKeC5pQU8fKHh2/QLaIvnkc
# CzZjrak2J9MWCIEPb2ZeO1RRmC02q4x3wOeys0za85TFNDYAAW39pDy7ogS8WsVQ
# YwypReL9FtqEadTO9Fc232MsZct0gmdZPgbZjsd/biHl58XHWsbZYG06R8zdvPX5
# 6FTuY/PSEBsH/oroQsS3604wf/o308eC3w3499XsjeOF8DWmJXwXD6TsUAgTxAy7
# crio7b+2vt/yLtwWj01qkAKFmeHber13Pe1pilCHG/bn9Yhm3o8v0DmEhu0K3Ykq
# XDHlO3B3T3lwn+kSCESKOBRnQk27bpER3+r9QJGBq12VZ6SKl5BGXPpaZdDuG9nH
# k+sMUAriPjYcGvrR6KVrttuCDoVbePdj8P3d3HRbNoAPygd3n9sVyypf4B0wIBeS
# 5/le1OT1Jl+j1otyEyYS9zw57t550EypY7+RnMBcSoVHzqG7QO7jx/VwdyRNKAqN
# gm/tHxgvMUe/wjqQ7m12d9fiNwwECRH2tWv1qktn8B2l3vYzLDh3zW5E6Wy95E1y
# 0Qr19L4TtfseVp8Ud2uY0UJAIupMlf41V3OFIgJ++LA6V1vwKam3syJLWx0mGpWx
# Wnfn+UebzCM/LPJomM1yI3T1axeUDlnllu7tcpBS6E3nYVnzhUoP830ezbsaPtcR
# 7qDPexwaQkdrnrXdXQIDAQABo4IBvTCCAbkwHwYDVR0jBBgwFoAUDyrLIIcouOxv
# SK4rVKYpqhekzQwwHQYDVR0OBBYEFJN12A4BiajRgUXR4BQZvR3SLS06MA4GA1Ud
# DwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMBEG
# CWCGSAGG+EIBAQQEAwIEEDBKBgNVHSAEQzBBMDUGDCsGAQQBsjEBAgEDAjAlMCMG
# CCsGAQUFBwIBFhdodHRwczovL3NlY3RpZ28uY29tL0NQUzAIBgZngQwBBAEwSQYD
# VR0fBEIwQDA+oDygOoY4aHR0cDovL2NybC5zZWN0aWdvLmNvbS9TZWN0aWdvUHVi
# bGljQ29kZVNpZ25pbmdDQVIzNi5jcmwweQYIKwYBBQUHAQEEbTBrMEQGCCsGAQUF
# BzAChjhodHRwOi8vY3J0LnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2RlU2ln
# bmluZ0NBUjM2LmNydDAjBggrBgEFBQcwAYYXaHR0cDovL29jc3Auc2VjdGlnby5j
# b20wHwYDVR0RBBgwFoEUc2hhd25Ac2hhd25raGFsbC5jb20wDQYJKoZIhvcNAQEM
# BQADggGBACw1IJHV3zczfkAgTUKf3atMwR7vBK/W76xoBkojjqCKnqTUi9gK1OlS
# P6VcqffqNfVT7xg+8tyXfsok5yLSIsGFVvbvWomQHaHIE3zdPPTeanuFQZocItKB
# aq267IZ6z7EoJop6XTAkkXpsxlHeg2khCFz7MSYs076ZMFfoBSMHb4bRarflE3rn
# WwkVqMbLAa8Nf/QgoMIFl0/wrAsCjE2boLFvwB0HaXtzHsbml09SOBmgJZjXrx3U
# 3JFw7NIFxsND/0g4VN71wThe9pd5E3ZVIiD7cprueDUwteJWGcPrhGAGzQrQ0SJR
# 9V+zfT7T1bpduei8Ho0GdvkQENWnoICvCUkVG9tXFxCHhvGmHfLwu/AkhJnIbM3O
# l+kBWWi6nvGJ2z/1Vuman3oeRLOLawxU6Jncvxf4z+ryAINfXh4LDdy2vInjnGIr
# 09LB/8X+lgPytnm2QsaYLGBbcY4mD3WQGzpI5Y2pSvYAZbQ46cs6CTnkaorTm3aq
# RwnNn6XreDCCBuwwggTUoAMCAQICEDAPb6zdZph0fKlGNqd4LbkwDQYJKoZIhvcN
# AQEMBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpOZXcgSmVyc2V5MRQwEgYD
# VQQHEwtKZXJzZXkgQ2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3b3Jr
# MS4wLAYDVQQDEyVVU0VSVHJ1c3QgUlNBIENlcnRpZmljYXRpb24gQXV0aG9yaXR5
# MB4XDTE5MDUwMjAwMDAwMFoXDTM4MDExODIzNTk1OVowfTELMAkGA1UEBhMCR0Ix
# GzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEY
# MBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSUwIwYDVQQDExxTZWN0aWdvIFJTQSBU
# aW1lIFN0YW1waW5nIENBMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA
# yBsBr9ksfoiZfQGYPyCQvZyAIVSTuc+gPlPvs1rAdtYaBKXOR4O168TMSTTL80Vl
# ufmnZBYmCfvVMlJ5LsljwhObtoY/AQWSZm8hq9VxEHmH9EYqzcRaydvXXUlNclYP
# 3MnjU5g6Kh78zlhJ07/zObu5pCNCrNAVw3+eolzXOPEWsnDTo8Tfs8VyrC4Kd/wN
# lFK3/B+VcyQ9ASi8Dw1Ps5EBjm6dJ3VV0Rc7NCF7lwGUr3+Az9ERCleEyX9W4L1G
# nIK+lJ2/tCCwYH64TfUNP9vQ6oWMilZx0S2UTMiMPNMUopy9Jv/TUyDHYGmbWApU
# 9AXn/TGs+ciFF8e4KRmkKS9G493bkV+fPzY+DjBnK0a3Na+WvtpMYMyou58NFNQY
# xDCYdIIhz2JWtSFzEh79qsoIWId3pBXrGVX/0DlULSbuRRo6b83XhPDX8CjFT2SD
# AtT74t7xvAIo9G3aJ4oG0paH3uhrDvBbfel2aZMgHEqXLHcZK5OVmJyXnuuOwXhW
# xkQl3wYSmgYtnwNe/YOiU2fKsfqNoWTJiJJZy6hGwMnypv99V9sSdvqKQSTUG/xy
# pRSi1K1DHKRJi0E5FAMeKfobpSKupcNNgtCN2mu32/cYQFdz8HGj+0p9RTbB942C
# +rnJDVOAffq2OVgy728YUInXT50zvRq1naHelUF6p4MCAwEAAaOCAVowggFWMB8G
# A1UdIwQYMBaAFFN5v1qqK0rPVIDh2JvAnfKyA2bLMB0GA1UdDgQWBBQaofhhGSAP
# w0F3RSiO0TVfBhIEVTAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIB
# ADATBgNVHSUEDDAKBggrBgEFBQcDCDARBgNVHSAECjAIMAYGBFUdIAAwUAYDVR0f
# BEkwRzBFoEOgQYY/aHR0cDovL2NybC51c2VydHJ1c3QuY29tL1VTRVJUcnVzdFJT
# QUNlcnRpZmljYXRpb25BdXRob3JpdHkuY3JsMHYGCCsGAQUFBwEBBGowaDA/Bggr
# BgEFBQcwAoYzaHR0cDovL2NydC51c2VydHJ1c3QuY29tL1VTRVJUcnVzdFJTQUFk
# ZFRydXN0Q0EuY3J0MCUGCCsGAQUFBzABhhlodHRwOi8vb2NzcC51c2VydHJ1c3Qu
# Y29tMA0GCSqGSIb3DQEBDAUAA4ICAQBtVIGlM10W4bVTgZF13wN6MgstJYQRsrDb
# Kn0qBfW8Oyf0WqC5SVmQKWxhy7VQ2+J9+Z8A70DDrdPi5Fb5WEHP8ULlEH3/sHQf
# j8ZcCfkzXuqgHCZYXPO0EQ/V1cPivNVYeL9IduFEZ22PsEMQD43k+ThivxMBxYWj
# TMXMslMwlaTW9JZWCLjNXH8Blr5yUmo7Qjd8Fng5k5OUm7Hcsm1BbWfNyW+QPX9F
# csEbI9bCVYRm5LPFZgb289ZLXq2jK0KKIZL+qG9aJXBigXNjXqC72NzXStM9r4MG
# OBIdJIct5PwC1j53BLwENrXnd8ucLo0jGLmjwkcd8F3WoXNXBWiap8k3ZR2+6rzY
# QoNDBaWLpgn/0aGUpk6qPQn1BWy30mRa2Coiwkud8TleTN5IPZs0lpoJX47997FS
# kc4/ifYcobWpdR9xv1tDXWU9UIFuq/DQ0/yysx+2mZYm9Dx5i1xkzM3uJ5rloMAM
# cofBbk1a0x7q8ETmMm8c6xdOlMN4ZSA7D0GqH+mhQZ3+sbigZSo04N6o+TzmwTC7
# wKBjLPxcFgCo0MR/6hGdHgbGpm0yXbQ4CStJB6r97DDa8acvz7f9+tCjhNknnvsB
# Zne5VhDhIG7GrrH5trrINV0zdo7xfCAMKneutaIChrop7rRaALGMq+P5CslUXdS5
# anSevUiumDCCBvYwggTeoAMCAQICEQCQOX+a0ko6E/K9kV8IOKlDMA0GCSqGSIb3
# DQEBDAUAMH0xCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0
# ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDEl
# MCMGA1UEAxMcU2VjdGlnbyBSU0EgVGltZSBTdGFtcGluZyBDQTAeFw0yMjA1MTEw
# MDAwMDBaFw0zMzA4MTAyMzU5NTlaMGoxCzAJBgNVBAYTAkdCMRMwEQYDVQQIEwpN
# YW5jaGVzdGVyMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxLDAqBgNVBAMMI1Nl
# Y3RpZ28gUlNBIFRpbWUgU3RhbXBpbmcgU2lnbmVyICMzMIICIjANBgkqhkiG9w0B
# AQEFAAOCAg8AMIICCgKCAgEAkLJxP3nh1LmKF8zDl8KQlHLtWjpvAUN/c1oonyR8
# oDVABvqUrwqhg7YT5EsVBl5qiiA0cXu7Ja0/WwqkHy9sfS5hUdCMWTc+pl3xHl2A
# ttgfYOPNEmqIH8b+GMuTQ1Z6x84D1gBkKFYisUsZ0vCWyUQfOV2csJbtWkmNfnLk
# Q2t/yaA/bEqt1QBPvQq4g8W9mCwHdgFwRd7D8EJp6v8mzANEHxYo4Wp0tpxF+rY6
# zpTRH72MZar9/MM86A2cOGbV/H0em1mMkVpCV1VQFg1LdHLuoCox/CYCNPlkG1n9
# 4zrU6LhBKXQBPw3gE3crETz7Pc3Q5+GXW1X3KgNt1c1i2s6cHvzqcH3mfUtozlop
# YdOgXCWzpSdoo1j99S1ryl9kx2soDNqseEHeku8Pxeyr3y1vGlRRbDOzjVlg59/o
# FyKjeUFiz/x785LaruA8Tw9azG7fH7wir7c4EJo0pwv//h1epPPuFjgrP6x2lEGd
# ZB36gP0A4f74OtTDXrtpTXKZ5fEyLVH6Ya1N6iaObfypSJg+8kYNabG3bvQF20EF
# xhjAUOT4rf6sY2FHkbxGtUZTbMX04YYnk4Q5bHXgHQx6WYsuy/RkLEJH9FRYhTfl
# x2mn0iWLlr/GreC9sTf3H99Ce6rrHOnrPVrd+NKQ1UmaOh2DGld/HAHCzhx9zPuW
# FcUCAwEAAaOCAYIwggF+MB8GA1UdIwQYMBaAFBqh+GEZIA/DQXdFKI7RNV8GEgRV
# MB0GA1UdDgQWBBQlLmg8a5orJBSpH6LfJjrPFKbx4DAOBgNVHQ8BAf8EBAMCBsAw
# DAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDBKBgNVHSAEQzBB
# MDUGDCsGAQQBsjEBAgEDCDAlMCMGCCsGAQUFBwIBFhdodHRwczovL3NlY3RpZ28u
# Y29tL0NQUzAIBgZngQwBBAIwRAYDVR0fBD0wOzA5oDegNYYzaHR0cDovL2NybC5z
# ZWN0aWdvLmNvbS9TZWN0aWdvUlNBVGltZVN0YW1waW5nQ0EuY3JsMHQGCCsGAQUF
# BwEBBGgwZjA/BggrBgEFBQcwAoYzaHR0cDovL2NydC5zZWN0aWdvLmNvbS9TZWN0
# aWdvUlNBVGltZVN0YW1waW5nQ0EuY3J0MCMGCCsGAQUFBzABhhdodHRwOi8vb2Nz
# cC5zZWN0aWdvLmNvbTANBgkqhkiG9w0BAQwFAAOCAgEAc9rtaHLLwrlAoTG7tAOj
# LRR7JOe0WxV9qOn9rdGSDXw9NqBp2fOaMNqsadZ0VyQ/fg882fXDeSVsJuiNaJPO
# 8XeJOX+oBAXaNMMU6p8IVKv/xH6WbCvTlOu0bOBFTSyy9zs7WrXB+9eJdW2YcnL2
# 9wco89Oy0OsZvhUseO/NRaAA5PgEdrtXxZC+d1SQdJ4LT03EqhOPl68BNSvLmxF4
# 6fL5iQQ8TuOCEmLrtEQMdUHCDzS4iJ3IIvETatsYL254rcQFtOiECJMH+X2D/miY
# NOR35bHOjJRs2wNtKAVHfpsu8GT726QDMRB8Gvs8GYDRC3C5VV9HvjlkzrfaI1Qy
# 40ayMtjSKYbJFV2Ala8C+7TRLp04fDXgDxztG0dInCJqVYLZ8roIZQPl8SnzSIoJ
# AUymefKithqZlOuXKOG+fRuhfO1WgKb0IjOQ5IRT/Cr6wKeXqOq1jXrO5OBLoTOr
# C3ag1WkWt45mv1/6H8Sof6ehSBSRDYL8vU2Z7cnmbDb+d0OZuGktfGEv7aOwSf5b
# vmkkkf+T/FdpkkvZBT9thnLTotDAZNI6QsEaA/vQ7ZohuD+vprJRVNVMxcofEo1X
# xjntXP/snyZ2rWRmZ+iqMODSrbd9sWpBJ24DiqN04IoJgm6/4/a3vJ4LKRhogaGc
# P24WWUsUCQma5q6/YBXdhvUxggZaMIIGVgIBATBpMFQxCzAJBgNVBAYTAkdCMRgw
# FgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxKzApBgNVBAMTIlNlY3RpZ28gUHVibGlj
# IENvZGUgU2lnbmluZyBDQSBSMzYCEQDCQwm71IrzJIwoQU/zm0zEMAkGBSsOAwIa
# BQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgor
# BgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3
# DQEJBDEWBBSBnKQ0xBQwp2E5KeyPMb1Rh5B4WzANBgkqhkiG9w0BAQEFAASCAgBA
# aV9X/kWGeSTUcghp6Z7C+jLTVWuqRRaEFSj1UhN9SRZy161wLj2FqTezb/eNx3rw
# oPqNyO6PLxTxRhKWp+n45tuGTlbZ7yvBKL668rv6Z3y1I9gVKEubOGWetSAvnZo/
# 9xrH4VkdJW8wnFfJ0WhqnO9QpA7/I2h/hefFE2Ni8ScIOqgioeHmLBYcdO5wmVya
# mFlv+0NpcIxQC6cgTCd+Q1T7yr1YToyS1Aecsw1PcSjYyWZMbb9vmUoDtJQLXa4Z
# sFekeKHCXV707aHp5ce9ae8dJk5gZo5H4GsG3+4PqnaOSu2i8Jw/ceN3x2YgtvwT
# BwTZuMCoZmIxR1oOFhgIjCDPvur4TIxh6fdQY6yYgwMTR6VKy33YINJgJPKb387v
# mjQBmvjjvayq5/1YjJHFCburxZnNMLwm4Tt4+a4oLUaZY3/VNwYD/lpAAJodB/5I
# ezFK5dwmsHYpaBR0mt4EMkuW0A9r2JVgmFt9ogxe8vUCL4CqGjKJXD68TcQGlgkL
# MZ6HO5GnIWGIOquDnKqFhqZeNMIPAFVDAtYjNkDP6iaa3zoRy8JjXQh9xz1yThLU
# tRTDjRSNThTiEZQ2XNNHz80ar4IIr/vquB8CwVlxRxVYzkYqjxv+eOIzLNo4RXo2
# 6tDh88UdmOzuSxqIbw6nQHwhwU3eNwaIELWAoAFXIqGCA0wwggNIBgkqhkiG9w0B
# CQYxggM5MIIDNQIBATCBkjB9MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRl
# ciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdv
# IExpbWl0ZWQxJTAjBgNVBAMTHFNlY3RpZ28gUlNBIFRpbWUgU3RhbXBpbmcgQ0EC
# EQCQOX+a0ko6E/K9kV8IOKlDMA0GCWCGSAFlAwQCAgUAoHkwGAYJKoZIhvcNAQkD
# MQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMjMwNDA4MTAwOTI5WjA/Bgkq
# hkiG9w0BCQQxMgQwQCA5RJTpdfUTMYPW/reZtEwgKK3UqedJRe5Hm3IP6ftRblTj
# IH/tsZ1b53K+gErnMA0GCSqGSIb3DQEBAQUABIICAIva3MqIfB9CSrZl0fzrWPJ8
# Q9yJ66x3bbaypSQT8Gk5iaSVILBNIAVEKaZmGtr3nHnoyv4jRGPVK+B9/0p5DBAL
# qmLOc9FH8i1VKEXP2lefURFqvY+wUYBftl0CIp6Cv0NHZ/CD3brF4WJx+17j0XuE
# A0imRiOjk9Xb+qM3xW3N1EzO8nwwe74GvmSS3ziaONDcg5PkIJeK4BnHr6kjthY4
# MVq1K0Uor0ESh0GHy9MoJtyeCxsVkbwVSESjTf5ij5j4CDOzBXXzR6MAmNcDe6Xn
# 9JBdEyJ8xGaQk89OJY+3e7VOT+qNa6CmUj/3GS47iIabRFga+nT2YApRIxi2q+SJ
# ZGd5eBspr9xkCvOBRh3yiarRC2OfA6li/AMoaHBNUS0BOgyY2++N/jgtraPO2XDk
# V9mywAz3+Jzw9I3/pc3guou0jhT7fBv36Bky/OOQXfbXsVjIvoTvBvQ4W2xOimoe
# PlXulH94rUDKNHxh/X3YKPALGEeCajV484kFtJd85QMAq25dKc/KpIWAxi1lvEJU
# n7gLJNKVYnHyn2fXng8ocoL4PsTxr3BscZIR68a6b6oTiFRNEmHPQ+rFbBlCn+or
# keMFUZ2C7LUuw8UKg6pL7VgSyaoqbFb0G1POiPbl2lGxbpEpq+G2Y2WR5veBd4Qi
# ZS38DOlNjz+bdqVBc3OF
# SIG # End signature block
