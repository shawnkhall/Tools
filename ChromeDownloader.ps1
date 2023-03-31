
<#PSScriptInfo

.VERSION 1.0

.GUID c65575a3-2b12-461e-99b3-35dfd0e644b4

.AUTHOR shawn@shawnkhall.com

.COMPANYNAME Shawn K. Hall

.COPYRIGHT Unlicense

.TAGS chrome download url stable

.LICENSEURI https://unlicense.org/

.PROJECTURI https://shawnkhall.com/

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
 1.0: Initial release

#> 



<# 

.DESCRIPTION 
 Downloads the current version of Chrome for different hardware and OS

.SYNOPSIS
 ChromeDownloader: Downloads the current version of Chrome for different hardware and OS

.PARAMETER platform
 Specifies the operating system: win or mac

.PARAMETER bits
 Specifies the bit-type: x64 or x86

.PARAMETER release
 Specifies the release type: stable, beta, dev or canary

.PARAMETER osversion
 Specifies the OS version (Windows only): 11, 10, 2012

.PARAMETER disposition
 Specifies disposition: url, download, info, xml

.PARAMETER overwrite
 When disposition is download, determines if an existing file should be overwritten: $true, $false

.PARAMETER rename
 When disposition is download, inserts bit-type into downloaded filename: $true, $false

.EXAMPLE
 .\ChromeDownloader.ps1 win 64 
 Downloads the latest 64-bit build of Chrome for Windows 10

.EXAMPLE
 .\ChromeDownloader.ps1 win 64 -os 2012 -do info
 Displays information about the latest 64-bit build of Chrome for Windows Server 2012

.EXAMPLE
 .\ChromeDownloader.ps1 win 64 -release beta -os 10 -rename $true
 Downloads the latest 64-bit beta build of Chrome for Windows 10 and inserts the bit-type in the file name

.EXAMPLE
 .\ChromeDownloader.ps1 mac
 Downloads the latest build of Chrome for macOS

#>


Param(
	[ValidateSet('win', 'mac', IgnoreCase = $false)]
	[string] $platform = 'win', 
	
	[ValidateSet('x64', '64', 'x86', '32', IgnoreCase = $false)]
	[string] $bits = 'x64', 
	
	[ValidateSet('stable', 'beta', 'dev', 'canary', IgnoreCase = $false)]
	[Alias("Rel")]
	[string] $release = 'stable', 
	
	[ValidateSet('11.0', '11', '10.0', '10', '6.3', '2012', '2012r2', '46.0.2490.86', IgnoreCase = $false)]
	[Alias("OS")]
	[string] $osversion = '10.0', 
	
	[ValidateSet('url', 'download', 'info', 'xml', IgnoreCase = $false)]
	[Alias("Do")]
	[string] $disposition = 'download',
	
	[boolean] $overwrite = $false,
	
	[boolean] $rename = $false
)



function formatXML([xml]$xml, [string]$path="", [boolean]$omitprolog=$true) {
	$sb = New-Object System.Text.StringBuilder
	$sw = New-Object System.IO.StringWriter($sb)
	$encoding = [System.Text.Encoding]::UTF8
	$xmlsettings = New-Object System.Xml.XmlWriterSettings
	$xmlsettings.Encoding = $encoding
	$xmlsettings.Indent = $true
	$xmlsettings.OmitXmlDeclaration = $omitprolog
	$xmlsettings.IndentChars = "`t"
	$xmlsettings.NewLineOnAttributes = $false
	$wr = [System.XML.XmlWriter]::Create($sw, $xmlsettings)
	$wr.Flush()
	$xml.Save($wr)
	if($path){
		$sb.ToString() | out-file $path
	}
	return $sb.ToString()
}


# parse input
Switch ($platform) {
	'win' {
		$appid = '{8A69D345-D564-463C-AFF1-A69D9E530F96}'
		Switch ($osversion) {
			{ @('11.0', '11', '10.0', '10', '6.3') -contains $_ } { break }
			{ @('2012', '2012r2') -contains $_ } { $osversion = '6.3'; break }
			default	{ $osversion = '10.0'; break }
		}
		Switch ($bits) {
			{ @('x64', '64') -contains $_ } {
				$bits = 'x64'
				Switch ($release) {
					'stable'	{ $ap = 'x64-stable-multi-chrome'; break }
					'beta'	{ $ap = 'x64-beta-multi-chrome'; break }
					'dev'	{ $ap = 'x64-dev-multi-chrome'; break }
					'canary'	{ $ap = 'x64-canary'; $appid = '{4EA16AC7-FD5A-47C3-875B-DBF4A2008C20}'; break }
					default	{ $ap = 'x64-stable-multi-chrome'; break }
				}
			}
			{ @('x86', '32') -contains $_ } {
				$bits = 'x86'
				Switch ($release) {
					'stable'	{ $ap = '-multi-chrome'; break }
					'beta'	{ $ap = '1.1-beta'; break }
					{ @('dev','canary') -contains $_ } { $ap = '2.0-dev'; break }
					default	{ $ap = '-multi-chrome'; break }
				}
			}
			default {
				$bits = 'x64';
				$release = 'stable';
				$ap = 'x64-stable-multi-chrome'
			}
		}
	}
	{ @('mac', 'macos') -contains $_ } {
		$osversion = '46.0.2490.86';
		Switch ($release) {
			'stable'	{ $ap = ''; $appid = 'com.google.Chrome'; break }
			'beta'	{ $ap = 'betachannel'; $appid = 'com.google.Chrome.Beta'; break }
			'dev'	{ $ap = 'devchannel'; $appid = 'com.google.Chrome.Dev'; break }
			'canary'	{ $ap = ''; $appid = 'com.google.Chrome.Canary'; break }
			default	{ $ap = ''; $appid = 'com.google.Chrome'; break }
		}
	}
	default {
		$platform = 'win'
		$bits = 'x64'
		$release = 'stable'
		$osversion = '10.0'
		$ap = 'x64-stable-multi-chrome'
		$appid = '{8A69D345-D564-463C-AFF1-A69D9E530F96}'
	}
}


# generate the initial request
$header = @{ "Accept"="text/xml"; "Content-Type"="text/xml" }
#$body = "<?xml version='1.0' encoding='UTF-8'?><request protocol='3.0' version='1.3.23.9' shell_version='1.3.21.103' ismachine='0' sessionid='{3597644B-2952-4F92-AE55-D315F45F80A5}' installsource='ondemandcheckforupdate' requestid='{CD7523AD-A40D-49F4-AEEF-8C114B804658}' dedup='cr'><hw sse='1' sse2='1' sse3='1' ssse3='1' sse41='1' sse42='1' avx='1' physmemory='12582912' /><os platform='$platform' version='$osversion' arch='$bits'/><app appid='$appid' ap='$ap' version='' nextversion='' lang='' brand='GGLS' client=''><updatecheck/></app></request>"
$body = "<?xml version='1.0' encoding='UTF-8'?><request protocol='3.0' version='1.3.23.9' shell_version='1.3.21.103' ismachine='0' sessionid='{00000000-0000-0000-0000-000000000000}' installsource='ondemandcheckforupdate' requestid='{00000000-0000-0000-0000-000000000000}' dedup='cr'><hw sse='1' sse2='1' sse3='1' ssse3='1' sse41='1' sse42='1' avx='1' physmemory='12582912' /><os platform='$platform' version='$osversion' arch='$bits'/><app appid='$appid' ap='$ap' version='' nextversion='' lang='' brand='GGLS' client=''><updatecheck/></app></request>"
$xmlfile = ".\ChromeDownloader.xml"
Invoke-RestMethod -Uri "https://tools.google.com/service/update2" -Method POST -Body $body -Headers $header -OutFile $xmlfile


# parse the results
$xmlDoc = [xml](Get-Content -Path $xmlfile -Encoding UTF8)
$url    = $xmlDoc.SelectSingleNode('//response/app/updatecheck/urls/url[last()]/@codebase').Value
$version= $xmlDoc.SelectSingleNode("//response/app/updatecheck/manifest/@version").Value
$package= $xmlDoc.SelectSingleNode("//response/app/updatecheck/manifest/packages/package/@name").Value
$size   = $xmlDoc.SelectSingleNode("//response/app/updatecheck/manifest/packages/package/@size").Value
$sha256 = $xmlDoc.SelectSingleNode("//response/app/updatecheck/manifest/packages/package/@hash_sha256").Value

# rename the download file if requested
if($rename){
	$file = $package -replace ".exe", "_$bits.exe"
} else {
	$file = $package
}

# generate output
Switch ($disposition){
	'url'	{ echo "$url$package" }
	'info'	{ echo "Version: $version" "Url: $url$package" "File: $package" "Hash: $sha256" "Size: $size" "" }
	'xml'	{ formatXML $xmlDoc }
	'download'	{ 
			if ((!(Test-Path ".\$file")) -or ((Test-Path ".\$file") -and $overwrite)) {
				Invoke-WebRequest -Uri "$url$package" -OutFile ".\$file"
			} else {
				"File '$file' exists."
			}
		}
	default	{ echo "$url$package" }
}


# SIG # Begin signature block
# MIIrKwYJKoZIhvcNAQcCoIIrHDCCKxgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUnY9ARDsSA0aP4/iF16yQqipy
# 8ZiggiQ7MIIEMjCCAxqgAwIBAgIBATANBgkqhkiG9w0BAQUFADB7MQswCQYDVQQG
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
# DQEJBDEWBBQD1drxI5SGdcMmbBTWiFlZFofVqzANBgkqhkiG9w0BAQEFAASCAgAz
# vj+ul/hzNYh1e70sRP+b8lGw5MyYGrgFOg40V6E1vWEJ6+DnG32FzSB1guOHIJ98
# JYKfap1+HZW2wyb6Pe0/K1FEDDCtY3YDuCbCrN5FG286iUhcVHtjBH4IzRULmdOr
# I8r/9W4CW0jvgvn/RDGSsBC9U4Xm/ICtQJuvZ/kKO5sx2c6HhFm2K8oglgwGNrIE
# 4383cy0DqUeIjpWBywPBsQSPdJY4WpUwwsgpgESAKtSjusz1QIujdEx7A08tKa6V
# KJirN1XU765JR0bljSh+ByJYIfgyiK5bnkxQpF0tmuZ4CkDnD2YSvQy+tNevWlO5
# pHbRpvqhEkdbGEdjudl0X43YvOfaiagLp3YQbr61nQkPdnVkUYNBIJc5EY2gIWlk
# MQecaDNQC6ugpTv3uIP4X4zG9sFnms7HR8DPu52mMYveHt6vXaErInIwbTWJNxNG
# SDETgkVuGNlB+SZqVxeUolf5jElT5OyN7Vv91XRss4vuXJsaWVPWKgVnx18lcnQG
# Gnx8UDYeG0sug9JI2ADJtEmV40nSb1sFRv1gpmpe5f7aeEidJ3Alz2hFzPl0H8n+
# 2vHeN9mIr07C5q9WL67rGZX8rAXExEUQ9od1CI+rk+Hm1gToQapszepu7wSShG6h
# +2+qFsmGqayRrILuJQ4l9Y1xbTW2h6VwGgv0W4MbGaGCA0wwggNIBgkqhkiG9w0B
# CQYxggM5MIIDNQIBATCBkjB9MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRl
# ciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdv
# IExpbWl0ZWQxJTAjBgNVBAMTHFNlY3RpZ28gUlNBIFRpbWUgU3RhbXBpbmcgQ0EC
# EQCQOX+a0ko6E/K9kV8IOKlDMA0GCWCGSAFlAwQCAgUAoHkwGAYJKoZIhvcNAQkD
# MQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMjMwMzMxMjMzMDA2WjA/Bgkq
# hkiG9w0BCQQxMgQw1Py9qZw9pzIGl5LKuwa/qsk9Na/GCjdJm+aaebZUeMv17rYv
# cjcX/9cvU4kHNHD7MA0GCSqGSIb3DQEBAQUABIICAEk3WEfh8TRx+mNgRJQL141k
# qv+DAY7D823YVVAUhrL+u+03lk0S2XW/Fs71Bt0ET8eSyxTznHtnKfcN6rj3ffqQ
# omEtv96V/ZKzetAzfJ6hbNAQ2w0BqV+QUUkj3iKCjiOKqZLNPDSuq3FfY+TgNkSU
# ndBUNNNKbDbol9T+qNUYh7LFeRX9Zx+XO1xO/VwAq+2zLx6L+gg4KynoVkkm7+5n
# /CWF6crgWUN6QTwV1XwPUcvGZuG+sJOR1CwES8uClnO4698hItLvWZEM56+C8XU8
# U0P9XVfDx9yvdw87IdwsHN7/I3+zu0YuocrtOoCTL+67oTj800uaLr8SAAnzFeCE
# eQfQuq8xIi0XtbvxvwnYayykKtq0L/OnYvh/XuysHB6H7DHRncxGeb/g/8K5jgxZ
# QhKkVEpKOz/Bxls6UH88Mh6xpdn0aaT98wxC4lzJ8IoRLJV1IYTrd+qEzd6yupiz
# X7MkuiFsvHUCDwv3Dz35mDBuEuFjx8y7fjYeDaWgMmuZxAvV77pM9gXzbSwu/YcV
# wdYvhKN03LXtzg5VEmFsYKHNrVKfpvSmgXI37fMXswLpsdH/lP/Z5l22FKTEoksT
# Jj5sVG09ubRbWpkcWW5e2xh9dkCWRNudF6qqMhqvPL2DtN6EvPsMl50RIfxp9DUa
# Mw6ulpr8SIl9GUNeJa8s
# SIG # End signature block
