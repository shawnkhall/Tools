# Tools



## ChromeDownloader.ps1

### SYNOPSIS
```
ChromeDownloader: Downloads the current version of Chrome for different hardware and OS
```

Inspired by [COI](https://github.com/lyonna/ChromeOfflineInstallerDownloadAPI/) by [lyonna](https://github.com/lyonna/), [this tool](https://github.com/shawnkhall/Tools/blob/main/ChromeDownloader.ps1) provides a command-line interface to download or collect information about various versions of the Google Chrome offline installation packages. The goal of this project was to provide access to the still maintained v109 builds for Windows Server 2012 and 2012r2 for updating devices that are not connected to the Internet. Google has yet to provide a means to fulfill this need so here we are.


### DESCRIPTION
```
Downloads the current version of Chrome for different hardware and OS
```
   
### SYNTAX
```
.\ChromeDownloader.ps1 [[-platform] <String>] [[-bits] <String>] [[-release] <String>]
    [[-osversion] <String>] [[-disposition] <String>] [-overwrite] [-rename] [-jsonsave] [-xmlsave] [[-prefix]
    <String>] [<CommonParameters>]
```


### EXAMPLES

Downloads the latest 64-bit build of Chrome for Windows 10
```
.\ChromeDownloader.ps1 win 64 
```

Displays information about the latest 64-bit build of Chrome for Windows Server 2012
```
.\ChromeDownloader.ps1 win 64 -os 2012 -do info
```

Downloads the current build of Chrome x64 for Windows to a file under C:/Browsers, named to include the version of Chrome, the platform and OS version, the bit-type and release type, as well as creating both an XML and a JSON file with details about the download in the same location beside the binary.
```
.\ChromeDownloader.ps1 -do download -jsonsave -xmlsave -prefix 'C:/Browsers/Chrome-%v_%p%osv_%b_%r'
```

Downloads the latest 64-bit beta build of Chrome for Windows 10 and inserts the bit-type in the file name
```
.\ChromeDownloader.ps1 win 64 -release beta -os 10 -rename
```

Downloads the latest build of Chrome for macOS
```
.\ChromeDownloader.ps1 mac
```



