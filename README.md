# Tools

[![made-with-powershell](https://img.shields.io/badge/PowerShell-1f425f?style=plastic&logo=Powershell)](https://microsoft.com/PowerShell)
[![License: Unlicense](https://img.shields.io/badge/License-Unlicense-blueviolet.svg?style=plastic&logo=unlicense)](https://opensource.org/licenses/unlicense/)


## ChromeDownloader.ps1

### SYNOPSIS

**ChromeDownloader**: Obtains information about the current version of Chrome for different hardware and operating systems


Inspired by [COI](https://github.com/lyonna/ChromeOfflineInstallerDownloadAPI/) by [lyonna](https://github.com/lyonna/), [this tool](https://github.com/shawnkhall/Tools/blob/main/ChromeDownloader.ps1) provides a command-line interface to download or collect information about various versions of the Google Chrome offline installation packages. The goal of this project was to provide access to the still maintained v109 builds for Windows Server 2012 and 2012r2 for updating devices that are not connected to the Internet. Google has yet to provide a means to fulfill this need so here we are.


### DESCRIPTION

Obtains information about the current version of Chrome for different hardware and operating systems, optionally downloading, exporting as JSON, XML or displaying information.

**Note:** While you can use any value for the OS version, unsupported operating systems do not receive security updates and the versions available for download from Google are not secure and are not supported. Likewise, not all operating systems support both a 32-bit and 64-bit version. 

   
### SYNTAX
```
.\ChromeDownloader.ps1 [[-platform] <String>] [[-osversion] <String>] [[-bits] <String>]
    [[-disposition] <String>] [-release <String>] [-type <String>] [-download] [-overwrite] 
    [-rename] [-jsonsave] [-xmlsave] [-prefix <String>] [<CommonParameters>]
```

### USAGE

Please don't run code you don't understand. While this is free, functional, and works in all my testing, it may not work for you. There is no guarantee or support provided outside of the [issues](https://github.com/shawnkhall/Tools/issues) page. If you don't know what to do, find a trusted advisor to help you set up your environment. 

1. Open `PowerShell` on your device. (Start, PowerShell)
1. [Download ChromeDownloader.ps1](https://raw.githubusercontent.com/shawnkhall/Tools/main/ChromeDownloader.ps1):  `curl.exe -O https://raw.githubusercontent.com/shawnkhall/Tools/main/ChromeDownloader.ps1`
1. Run any of the examples. Try it with: `./ChromeDownloader.ps1 win 11 64 -download -t msi` or `help ./ChromeDownloader.ps1 -examples`

If you have modified the script or removed the code signature, you may need to **unblock** the script with:
```
Unblock-File ChromeDownloader.ps1
```


### EXAMPLES

Display the latest 64-bit build of Chrome for Windows 11
```
.\ChromeDownloader.ps1 win 64 
```

Download the latest 64-bit build of Chrome for Windows 11
```
.\ChromeDownloader.ps1 win 64 -download
```

Download the latest 64-bit MSI stable release of Chrome for Windows 10/11 and save it with the version, bit-type and release type in the filename.
```
.\ChromeDownloader.ps1 win cur 64 -t msi -download -prefix 'Chrome-%v_%b_%r'
```

Displays information about the latest 64-bit build of Chrome for Windows Server 2012
```
.\ChromeDownloader.ps1 win 64 -os 2012 -do info
```

Download the latest 64-bit beta build of Chrome for Windows 10 and inserts the bit-type in the file name
```
.\ChromeDownloader.ps1 win 10 64 -download -release beta -rename
```

Display the latest build of Chrome for macOS
```
.\ChromeDownloader.ps1 mac
```

Download the current Windows Group Policy administrative templates for Chrome
```
.\ChromeDownloader.ps1 -do url -t adm -download
```

Download the current build of Chrome x64 for Windows 11 to a file under C:/Browsers, named to include the version of Chrome, the platform and OS version, the bit-type and release type, as well as creating both an XML and a JSON file with details about the download beside the binary, and returns details via the pipeline.
```
.\ChromeDownloader.ps1 -download -jsonsave -xmlsave -prefix 'C:/Browsers/Chrome-%v_%p%osv_%b_%r'
```

Display information about the latest 64-bit releases of Chrome for Windows 2008r2, 2012 and 10, formatting the results in a table.
```
$commonParams = @{ platform = 'win'; bits = 64; do = 'pipeline' };
'2008r2','2012','10' | ForEach-Object {.\ChromeDownloader.ps1  @commonParams -osversion $_} | Select platform,osversion,version,url | Format-Table
```




