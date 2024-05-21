
<#PSScriptInfo

.VERSION 3.1

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
 3.1: Adds proxy support (thanks to @pethrowilo)
 3.0: Adds "current" OS version support (treated as current year), release type (for adm, admx, admadmx, bundle, dmg, msi, pkg, and policy files), vastly improves direct download performance (thanks to @robcmo), removes dependence on a temporary file, and expands examples.
 2.0: Removes OS Version validation, removes bit-massaging for unsupported operating systems, improves parsing for named OS versions, adds pipeline support (now default), changes disposition behavior, expands examples and parameters. This version also changes default OS version to 11 since that number is safely cross-platform.
 1.4: Add 32-bit support for Server 2003 (5.2) through 2008 (6.0) and 32/64-bit support for Server 2008 R2 (6.1)
 1.3: Bug fixes
 1.2: Add option to assign the prefix for output and binary files, bug fixes, verbosity
 1.1: Add JSON export support
 1.0: Initial release

#> 



<# 

.SYNOPSIS
 ChromeDownloader: Obtains information about the current version of Chrome for different hardware and operating systems

.DESCRIPTION 
 Obtains information about the current version of Chrome for different hardware and operating systems, optionally downloading, exporting as JSON, XML or displaying information.
 Note: While you can use any value for the OS version, unsupported operating systems do not receive security updates and the versions available for download from Google are not secure and are not supported. Likewise, not all operating systems support both a 32-bit and 64-bit version. 

.PARAMETER platform
 Specifies the operating system: win or mac

.PARAMETER osversion
 Specifies the OS version: 5.2, 6.0, 6.1, 6.2, 6.3, 7, 8, 10, 11, 12, 13, 2003, 2008, 2008r2, 2012, 2012r2, 2016, 2019, 2022, 21H1, 22H2, ...

.PARAMETER bits
 Specifies the bit-type: x64 or x86

.PARAMETER release
 Specifies the release: stable, beta, dev or canary

.PARAMETER type
 Specifies the release type: default, adm, admx, admadmx, bundle, dmg, exe, msi, pkg, policy
 Note: ONLY stable releases of these files are available, with few exceptions (beta for msi, dmg, pkg, and policy). Older releases, like v109 for Windows Server 2012, do not offer non-exe release types.

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
 .\ChromeDownloader.ps1 win cur 64 -t msi -download -prefix 'Chrome-%v_%b_%r'
 Download the latest 64-bit MSI stable release of Chrome for Windows 10/11 and save it with the version, bit-type and release type in the filename.

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
 .\ChromeDownloader.ps1 -do url -t adm -download
 Download the current Windows Group Policy administrative templates for Chrome

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
	
	[ValidateSet("default", "adm", "admx", "admadmx", "bundle", "dmg", "exe", "msi", "pkg", "policy", IgnoreCase = $false)]
	[Parameter(ValueFromPipelineByPropertyName=$true)]
	[Alias("t")]
	[string] $type = "default", 
	
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


# settings
Set-Variable ProgressPreference SilentlyContinue
[System.Net.WebRequest]::DefaultWebProxy = [System.Net.WebRequest]::GetSystemWebProxy()
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

# support
function cdFormatXML([string]$xmlpath, [switch]$omitprolog) {
	Write-Verbose	"cdFormatXML `"$xmlpath`", $omitprolog"
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
	Write-Verbose	"cdFormatJSON `"$jsonpath`""
	$json	= ($chromeDownload | ConvertTo-Json)
	if($jsonpath){
		$json | Set-Content -Path ($jsonpath -replace "'", "")
	}else{
		return $json
	}
}


function cdFixURL([string]$root, [string]$path) {
	Write-Verbose	"cdFixURL `"$root`", `"$path`""
	if( $path -like "*:*" ){
		return $path.Trim()
	}else{
		return "$($root.Trim())$($path.Trim())"
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
Write-Verbose	"  type:	$type"
Write-Verbose	"  download:	$download"
Write-Verbose	"  overwrite:	$overwrite"
Write-Verbose	"  rename:	$rename"
Write-Verbose	"  jsonsave:	$jsonsave"
Write-Verbose	"  xmlsave:	$xmlsave"
Write-Verbose	"  prefix:	$prefix"


Switch ($platform) {
	'win' {
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
			{ @('c', 'cur', 'current') -contains $_ } 	{ $osversion = Get-Date -Format "yyyy"; break }
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
		$bits	= 'x64'
		Switch ($osversion) {
			{ @('10', '10.0') -contains $_ } 	{ $osversion = "11.0"; break }
			{ @('11', '12', '13') -contains $_ } 	{ $osversion = "$osversion.0"; break }
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
$xmlDoc	= Invoke-RestMethod -Uri "https://tools.google.com/service/update2" -Method POST -Body $body -Headers $header 
$constants	= Invoke-RestMethod -Uri "https://chromeenterprise.google/static/js/browser-template.min.js" -Method GET

# stable		
$match = select-string "DOWNLOAD_HOST\:`"([^'`"]+)`"" -inputobject $constants;	 $sDOWNLOAD_HOST	 = $match.Matches.groups[1].value.Trim();
$match = select-string "FILESIZES\:.+?WIN64_MSI\:`"([^'`"]+)`"" -inputobject $constants;	 $sSize_WIN64_MSI	 = $match.Matches.groups[1].value.Trim();
$match = select-string "INSTALLER_PATH\:.+?WIN64_MSI\:`"([^'`"]+)`"" -inputobject $constants;	 $sPath_WIN64_MSI	 = $match.Matches.groups[1].value.Trim();
$match = select-string "FILESIZES\:.+?WIN_MSI\:`"([^'`"]+)`"" -inputobject $constants;	 $sSize_WIN32_MSI	 = $match.Matches.groups[1].value.Trim();
$match = select-string "INSTALLER_PATH\:.+?WIN_MSI\:`"([^'`"]+)`"" -inputobject $constants;	 $sPath_WIN32_MSI	 = $match.Matches.groups[1].value.Trim();
$match = select-string "FILESIZES\:.+?WIN64_BUNDLE\:`"([^'`"]+)`"" -inputobject $constants;	 $sSize_WIN64_BUNDLE	 = $match.Matches.groups[1].value.Trim();
$match = select-string "INSTALLER_PATH\:.+?WIN64_BUNDLE:`"([^'`"]+)`"" -inputobject $constants;	 $sPath_WIN64_BUNDLE	 = $match.Matches.groups[1].value.Trim();
$match = select-string "FILESIZES\:.+?WIN_BUNDLE\:`"([^'`"]+)`"" -inputobject $constants;	 $sSize_WIN32_BUNDLE	 = $match.Matches.groups[1].value.Trim();
$match = select-string "INSTALLER_PATH\:.+?WIN_BUNDLE\:`"([^'`"]+)`"" -inputobject $constants;	 $sPath_WIN32_BUNDLE	 = $match.Matches.groups[1].value.Trim();
$match = select-string "FILESIZES\:.+?MAC_DMG\:`"([^'`"]+)`"" -inputobject $constants;	 $sSize_MAC_DMG	 = $match.Matches.groups[1].value.Trim();
$match = select-string "INSTALLER_PATH\:.+?MAC\:`"([^'`"]+)`"" -inputobject $constants;	 $sPath_MAC_DMG	 = $match.Matches.groups[1].value.Trim();
$match = select-string "FILESIZES\:.+?MAC_PKG\:`"([^'`"]+)`"" -inputobject $constants;	 $sSize_MAC_PKG	 = $match.Matches.groups[1].value.Trim();
$match = select-string "INSTALLER_PATH\:.+?MAC_PKG\:`"([^'`"]+)`"" -inputobject $constants;	 $sPath_MAC_PKG	 = $match.Matches.groups[1].value.Trim();
$match = select-string "FILESIZES\:.+?ADMADMX\:`"([^'`"]+)`"" -inputobject $constants;	 $sSize_ADMADMX	 = $match.Matches.groups[1].value.Trim();
$match = select-string "INSTALLER_PATH\:.+?ADMADMX\:`"([^'`"]+)`"" -inputobject $constants;	 $sPath_ADMADMX	 = $match.Matches.groups[1].value.Trim();
$match = select-string "FILESIZES\:.+?ADM\:`"([^'`"]+)`"" -inputobject $constants;	 $sSize_ADM	 = $match.Matches.groups[1].value.Trim();
$match = select-string "INSTALLER_PATH\:.+?ADM\:`"([^'`"]+)`"" -inputobject $constants;	 $sPath_ADM	 = $match.Matches.groups[1].value.Trim();
$match = select-string "FILESIZES\:.+?ADMX\:`"([^'`"]+)`"" -inputobject $constants;	 $sSize_ADMX	 = $match.Matches.groups[1].value.Trim();
$match = select-string "INSTALLER_PATH\:.+?ADMX\:`"([^'`"]+)`"" -inputobject $constants;	 $sPath_ADMX	 = $match.Matches.groups[1].value.Trim();
$match = select-string "FILESIZES\:.+?POLICY_DEV\:`"([^'`"]+)`"" -inputobject $constants;	 $sSize_POLICY_DEV	 = $match.Matches.groups[1].value.Trim();
$match = select-string "INSTALLER_PATH\:.+?POLICY_DEV\:`"([^'`"]+)`"" -inputobject $constants;	 $sPath_POLICY_DEV	 = $match.Matches.groups[1].value.Trim();
# beta		
$match = select-string "FILESIZES\:.+?WIN64_MSI_BETA\:`"([^'`"]+)`"" -inputobject $constants;	 $sSize_WIN64_MSI_BETA	 = $match.Matches.groups[1].value.Trim();
$match = select-string "INSTALLER_PATH\:.+?WIN64_MSI_BETA\:`"([^'`"]+)`"" -inputobject $constants;	 $sPath_WIN64_MSI_BETA	 = $match.Matches.groups[1].value.Trim();
$match = select-string "FILESIZES\:.+?WIN_MSI_BETA\:`"([^'`"]+)`"" -inputobject $constants;	 $sSize_WIN_MSI_BETA	 = $match.Matches.groups[1].value.Trim();
$match = select-string "INSTALLER_PATH\:.+?WIN_MSI_BETA\:`"([^'`"]+)`"" -inputobject $constants;	 $sPath_WIN_MSI_BETA	 = $match.Matches.groups[1].value.Trim();
$match = select-string "FILESIZES\:.+?MAC_DMG_BETA\:`"([^'`"]+)`"" -inputobject $constants;	 $sSize_MAC_DMG_BETA	 = $match.Matches.groups[1].value.Trim();
$match = select-string "INSTALLER_PATH\:.+?MAC_DMG_BETA\:`"([^'`"]+)`"" -inputobject $constants;	 $sPath_MAC_DMG_BETA	 = $match.Matches.groups[1].value.Trim();
$match = select-string "FILESIZES\:.+?MAC_PKG_BETA\:`"([^'`"]+)`"" -inputobject $constants;	 $sSize_MAC_PKG_BETA	 = $match.Matches.groups[1].value.Trim();
$match = select-string "INSTALLER_PATH\:.+?MAC_PKG_BETA\:`"([^'`"]+)`"" -inputobject $constants;	 $sPath_MAC_PKG_BETA	 = $match.Matches.groups[1].value.Trim();
$match = select-string "FILESIZES\:.+?POLICY_BETA\:`"([^'`"]+)`"" -inputobject $constants;	 $sSize_POLICY_BETA	 = $match.Matches.groups[1].value.Trim();
$match = select-string "INSTALLER_PATH\:.+?POLICY_BETA\:`"([^'`"]+)`"" -inputobject $constants;	 $sPath_POLICY_BETA	 = $match.Matches.groups[1].value.Trim();


# parse the results
Write-Verbose	""
Write-Verbose	"Response"
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


# type handling
Switch ($type) {
	'adm'	{ 
			$ext = '.adm'; 
			$sha256 = ''
			$package = ''
			$url = cdFixURL "$sDOWNLOAD_HOST" "$sPath_ADM"
			$size = $sSize_ADM
			break
		}
	'admx'	{ 
			$ext = '.zip';
			$sha256 = ''
			$package = ''
			$url = cdFixURL "$sDOWNLOAD_HOST" "$sPath_ADMX"
			$size = $sSize_ADMX
			break
		}
	'admadmx'	{ 
			$ext = '.zip';
			$sha256 = ''
			$package = ''
			$url = cdFixURL "$sDOWNLOAD_HOST" "$sPath_ADMADMX"
			$size = $sSize_ADMADMX
			break
		}
	'bundle'	{
			Write-Verbose	"Note: The Bundle version only supports the currently available stable release."
			$ext = '.zip';
			$sha256 = ''
			$package = ''
			if ( $bits -eq 'x64' ){
				$url = cdFixURL "$sDOWNLOAD_HOST" "$sPath_WIN64_BUNDLE"
				$size = $sSize_WIN64_BUNDLE
			}else{
				$url = cdFixURL "$sDOWNLOAD_HOST" "$sPath_WIN32_BUNDLE"
				$size = $sSize_WIN32_BUNDLE
			}
			break
		}
	'msi'	{
			Write-Verbose	"Note: The MSI version only supports the currently available stable and beta releases."
			$ext = '.msi';
			$sha256 = ''
			$package = ''
			if ( $bits -eq 'x64' ){
				if ( @('beta','dev','canary') -contains $release ){
					#beta
					$url = cdFixURL "$sDOWNLOAD_HOST" "$sPath_WIN64_MSI_BETA"
					$size = $sSize_WIN64_MSI_BETA
				} else {
					#stable
					$url = cdFixURL "$sDOWNLOAD_HOST" "$sPath_WIN64_MSI"
					$size = $sSize_WIN64_MSI
				}
			}else{
				if ( @('beta','dev','canary') -contains $release ){
					#beta
					$url = cdFixURL "$sDOWNLOAD_HOST" "$sPath_WIN_MSI_BETA"
					$size = $sSize_WIN_MSI_BETA
				} else {
					#stable
					$url = cdFixURL "$sDOWNLOAD_HOST" "$sPath_WIN32_MSI"
					$size = $sSize_WIN32_MSI
				}
			}
			break
		}
	'pkg'	{
			Write-Verbose	"Note: The PKG version only supports the currently available stable and beta releases."
			$ext = '.pkg';
			$sha256 = ''
			$package = ''
			if ( @('beta','dev','canary') -contains $release ){
				#beta
				$url = cdFixURL "$sDOWNLOAD_HOST" "$sPath_MAC_PKG_BETA"
				$size = $sSize_MAC_PKG_BETA
			} else {
				#stable
				$url = cdFixURL "$sDOWNLOAD_HOST" "$sPath_MAC_PKG"
				$size = $sSize_MAC_PKG
			}
			break
		}
	'policy'	{
			$ext = '.zip';
			$sha256 = ''
			$package = ''
			if ( @('beta','dev','canary') -contains $release ){
				#beta
				$url = cdFixURL "$sDOWNLOAD_HOST" "$sPath_POLICY_BETA"
				$size = $sSize_POLICY_BETA
			} else {
				#stable
				$url = cdFixURL "$sDOWNLOAD_HOST" "$sPath_POLICY_DEV"
				$size = $sSize_POLICY_DEV
			}
			break
		}
	default	{
			Switch ($platform) {
				{ @('mac', 'macos') -contains $_ } 	{ $ext = '.dmg'; break }
				default 	{ $ext = '.exe'; break }
			}
		}
}
if($package -eq ''){
	$package 	= Split-Path $url -leaf
	$url 	= $url -replace $package, ''
}
$url 	= $url -replace ' ', ''

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
	$prefix	= $prefix -replace "%type", "$type"
	$prefix	= $prefix -replace "%version", "$version"
	$prefix	= $prefix -replace "%t", "$type"
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
	Type	= $type
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
	Write-Warning "Error: $platform $osversion $bits $release $type"
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

# SIG # Begin signature block
# MIIrKQYJKoZIhvcNAQcCoIIrGjCCKxYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdRdejBwPFu68yyujxcyJgvOf
# 5ceggiQ6MIIEMjCCAxqgAwIBAgIBATANBgkqhkiG9w0BAQUFADB7MQswCQYDVQQG
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
# anSevUiumDCCBvUwggTdoAMCAQICEDlMJeF8oG0nqGXiO9kdItQwDQYJKoZIhvcN
# AQEMBQAwfTELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3Rl
# cjEQMA4GA1UEBxMHU2FsZm9yZDEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSUw
# IwYDVQQDExxTZWN0aWdvIFJTQSBUaW1lIFN0YW1waW5nIENBMB4XDTIzMDUwMzAw
# MDAwMFoXDTM0MDgwMjIzNTk1OVowajELMAkGA1UEBhMCR0IxEzARBgNVBAgTCk1h
# bmNoZXN0ZXIxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDEsMCoGA1UEAwwjU2Vj
# dGlnbyBSU0EgVGltZSBTdGFtcGluZyBTaWduZXIgIzQwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCkkyhSS88nh3akKRyZOMDnDtTRHOxoywFk5IrNd7Bx
# ZYK8n/yLu7uVmPslEY5aiAlmERRYsroiW+b2MvFdLcB6og7g4FZk7aHlgSByIGRB
# bMfDCPrzfV3vIZrCftcsw7oRmB780yAIQrNfv3+IWDKrMLPYjHqWShkTXKz856vp
# HBYusLA4lUrPhVCrZwMlobs46Q9vqVqakSgTNbkf8z3hJMhrsZnoDe+7TeU9jFQD
# kdD8Lc9VMzh6CRwH0SLgY4anvv3Sg3MSFJuaTAlGvTS84UtQe3LgW/0Zux88ahl7
# brstRCq+PEzMrIoEk8ZXhqBzNiuBl/obm36Ih9hSeYn+bnc317tQn/oYJU8T8l58
# qbEgWimro0KHd+D0TAJI3VilU6ajoO0ZlmUVKcXtMzAl5paDgZr2YGaQWAeAzUJ1
# rPu0kdDF3QFAaraoEO72jXq3nnWv06VLGKEMn1ewXiVHkXTNdRLRnG/kXg2b7HUm
# 7v7T9ZIvUoXo2kRRKqLMAMqHZkOjGwDvorWWnWKtJwvyG0rJw5RCN4gghKiHrsO6
# I3J7+FTv+GsnsIX1p0OF2Cs5dNtadwLRpPr1zZw9zB+uUdB7bNgdLRFCU3F0wuU1
# qi1SEtklz/DT0JFDEtcyfZhs43dByP8fJFTvbq3GPlV78VyHOmTxYEsFT++5L+wJ
# EwIDAQABo4IBgjCCAX4wHwYDVR0jBBgwFoAUGqH4YRkgD8NBd0UojtE1XwYSBFUw
# HQYDVR0OBBYEFAMPMciRKpO9Y/PRXU2kNA/SlQEYMA4GA1UdDwEB/wQEAwIGwDAM
# BgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMEoGA1UdIARDMEEw
# NQYMKwYBBAGyMQECAQMIMCUwIwYIKwYBBQUHAgEWF2h0dHBzOi8vc2VjdGlnby5j
# b20vQ1BTMAgGBmeBDAEEAjBEBgNVHR8EPTA7MDmgN6A1hjNodHRwOi8vY3JsLnNl
# Y3RpZ28uY29tL1NlY3RpZ29SU0FUaW1lU3RhbXBpbmdDQS5jcmwwdAYIKwYBBQUH
# AQEEaDBmMD8GCCsGAQUFBzAChjNodHRwOi8vY3J0LnNlY3RpZ28uY29tL1NlY3Rp
# Z29SU0FUaW1lU3RhbXBpbmdDQS5jcnQwIwYIKwYBBQUHMAGGF2h0dHA6Ly9vY3Nw
# LnNlY3RpZ28uY29tMA0GCSqGSIb3DQEBDAUAA4ICAQBMm2VY+uB5z+8VwzJt3jOR
# 63dY4uu9y0o8dd5+lG3DIscEld9laWETDPYMnvWJIF7Bh8cDJMrHpfAm3/j4MWUN
# 4OttUVemjIRSCEYcKsLe8tqKRfO+9/YuxH7t+O1ov3pWSOlh5Zo5d7y+upFkiHX/
# XYUWNCfSKcv/7S3a/76TDOxtog3Mw/FuvSGRGiMAUq2X1GJ4KoR5qNc9rCGPcMMk
# eTqX8Q2jo1tT2KsAulj7NYBPXyhxbBlewoNykK7gxtjymfvqtJJlfAd8NUQdrVgY
# a2L73mzECqls0yFGcNwvjXVMI8JB0HqWO8NL3c2SJnR2XDegmiSeTl9O048P5RNP
# WURlS0Nkz0j4Z2e5Tb/MDbE6MNChPUitemXk7N/gAfCzKko5rMGk+al9NdAyQKCx
# GSoYIbLIfQVxGksnNqrgmByDdefHfkuEQ81D+5CXdioSrEDBcFuZCkD6gG2UYXvI
# brnIZ2ckXFCNASDeB/cB1PguEc2dg+X4yiUcRD0n5bCGRyoLG4R2fXtoT4239xO0
# 7aAt7nMP2RC6nZksfNd1H48QxJTmfiTllUqIjCfWhWYd+a5kdpHoSP7IVQrtKcMf
# 3jimwBT7Mj34qYNiNsjDvgCHHKv6SkIciQPc9Vx8cNldeE7un14g5glqfCsIo0j1
# FfwET9/NIRx65fWOGtS5QDGCBlkwggZVAgEBMGkwVDELMAkGA1UEBhMCR0IxGDAW
# BgNVBAoTD1NlY3RpZ28gTGltaXRlZDErMCkGA1UEAxMiU2VjdGlnbyBQdWJsaWMg
# Q29kZSBTaWduaW5nIENBIFIzNgIRAMJDCbvUivMkjChBT/ObTMQwCQYFKw4DAhoF
# AKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisG
# AQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcN
# AQkEMRYEFCIrA/qs/FrmtaLGSx2RP47YZWfLMA0GCSqGSIb3DQEBAQUABIICAKTR
# 1HvHtK/TDqtgcMTGYel7qpERzDEUFRQvJD7wn3Y7asqTYqJcSG5MzPyAyndWXAsZ
# cPzQjVZDVfv173CfxI4d7uWFvEKy+JXtfGGjm8MiIDpwqWIWURr0Bj64sw4C7/iK
# dWZ2t8qrrTaT90xoGzk5Al/PRGUPbdZBTlwZgd4iwaq3Jwnw7JH0WvZh1OHFhG3V
# buy6nDXa8U2Se8yb9yUUa2ih9LhN0MsnajwdnJ5b0NjMQ2wLNRhfPXaPRSrMmj0C
# IVhoijWefo9QB5SPTgS2elsoXPEHDBTV9On3T8gSTwPyXoumGaQw1QduSQyAi+7R
# 1rH096cG9y+RJKqJeTw/JDU6rbLvatt0BcUmpX804Zj425FBAFc9S80MiG7r2wvK
# tpvANjQtNM5SmLwjutWZPb5r88SIIb/V51x6wRgKTZrp9MW65xtnFfGh1UnvPOS5
# dLHz85WBRd+tJ4s06jRAdIMTkzr60kBOi4UZNSXyDYjpCngp/ZgrtKDIO+g+JwN2
# EDP+g/wtra/7kqSOQY47wzy8gIB3K5aQHs7sU/UdsJy6xd1YQ2HnUC9x5DHVAdx0
# I750NsNlHp19wC9wvxcpIagthhRtm5AOienaiZYeUk0fs3uw3wTw+PsKdAAnYboU
# HP2b51iPiHByk6AoVMv5uyvaLKt25getLT3zkNNuoYIDSzCCA0cGCSqGSIb3DQEJ
# BjGCAzgwggM0AgEBMIGRMH0xCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVy
# IE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28g
# TGltaXRlZDElMCMGA1UEAxMcU2VjdGlnbyBSU0EgVGltZSBTdGFtcGluZyBDQQIQ
# OUwl4XygbSeoZeI72R0i1DANBglghkgBZQMEAgIFAKB5MBgGCSqGSIb3DQEJAzEL
# BgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTI0MDUyMTIyMTA0M1owPwYJKoZI
# hvcNAQkEMTIEMLM3MaWhsjz3tAUneVjt8h7XP7pWVsytlBk6UrzF63WGLBOTbJ13
# iaLpddC2v6VOfjANBgkqhkiG9w0BAQEFAASCAgB1w34gPo5c8wv19UOIdigLi1TR
# GexXKOBMtdykAnfWugLHdIX2qxk0IkneftxVRmRLAeTCKMKsdkKwXio70ZHWCIjK
# FFyTrr5aYuLguP79orL+rdgW4oLrHooCxyBE34yEttVVmnZLjrhKZzjEuwhm4Y5u
# 8jCeOenzg1xvFFkhhzIyuFBB0nLbSvceCPdkxbp2iEM0ldp5eGl+Z9Rnkz+1hLZq
# oBzxeKy95adgZbkgJJA6BY3pNGzRck3OxiPcPjeSta7rAq/3Aq1eNNIsxrxSrb3J
# AvCE6cFY2+JNE5gG7tvk7k7Z4UnGVgWccMPfSv9sWJ4ise7zpxq4PkSVKqDuQWO5
# 1k4C/tImY1a83bGr/jbpyyBcG/ciGTTGMedEw1IJF7mFWjcXoUnydomwZ/5kqQS0
# V21E6ONO2maAmG3NAs9xNQF0TP5ICRR5UsCjjSvgeicTswsYfm4fSn57caJ/TmzR
# +Ad7oIAY8zG+lSaMct7YSsqL6DQM9sclmvhfIbv5+gu1ZQl94oAK5s8f2AL7WVoE
# 0Ewad0/6CEVQYR9g9HDLdOrn0C4HuB8+zvVVZyGqOiOpEFVWVGcDvjAtKpbfRw08
# OP9V97IEFAEfcqxRh1469UGCDgfrS/iVczo748Dy2EbChJsiOgk2yfYFvUs4RrHF
# oCdydftb4IHQAEodag==
# SIG # End signature block
