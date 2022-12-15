<#2022-11-28  get-humanreadable__v16.ps1 script
.Synopsis
  get-humanreadable.ps1 - script to display and sort from high to low the top folder(s) and file(s) listing on either local or remote system   
.DESCRIPTION
  get-humanreadable.ps1 - script to display and sort from high to low the top folder(s) and file(s).
.EXAMPLE
  executed on a local system taking defaults ([return]):
    > .\get-humanreadable.ps1
    drive  [return] - default selects C: drive
    path   [return] - default selects root C: path location, possible to enter any other drive/lun
    report [return] - default selects only top 10 folders and files sorted from high to low
  executed on a remote system taking defaults ([return]):
    .> icm -FilePath .\get-humanreadable.ps1 -cn TestSERVER10.abc.net   (fqdn)
    drive  [return] - default selects C: drive
    path   [return] - default selects root C: path location, possible to enter any other drive/lun
    report [return] - default selects only top 10 folders and files sorted from high to low
.EXAMPLE
  executed on a local system:
    > .\get-humanreadable.ps1
    drive  [return] - default selects C: drive
    path  C:\Windows [return] - selects C:\Windows to get the sorted folder/file report information
    report Y [return] - selects Report for 'all' folders and files to be displayed at end of executed script
  executed on a remote system taking defaults ([return]):
    .> icm -FilePath .\get-humanreadable.ps1 -cn TestSERVER10.abc.net   (fqdn)
    drive D [return] - selects D: drive
    path  D:\Temp [return] - selects D:\Temp to get the sorted folder/file report information
    report Y [return] - selects Report for 'all' folders and files to be displayed at end of executed script
.INPUTS
  drive, path, and report paramaters
.OUTPUTS
  Script lists top 10 folder(s)/file(s), or if the report parameter is set it will list all folders/files sorted from
  highest to lowest and is used for tracking down high drive usage locations to either send to the offending end user
  or for the system admins to delete (if applicable) the offending folder/file in question.
.NOTES
Source websites used to making this a functional script:
  icm command(s)         https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/invoke-command?view=powershell-7.2&viewFallbackFrom=powershell-6
  reference site         https://www.powershelladmin.com/wiki/Get_Folder_Size_with_PowerShell,_Blazingly_Fast.php
  robocopy command(s)    https://www.javydekoning.com/fast-dir-size-calculations-powershell/#warning-bugs
  robocopy command(s)/ref  https://social.technet.microsoft.com/Forums/en-US/30efc904-0aea-454e-a8d0-60408258126e/get-folder-size-when-path-is-too-long?forum=ITCG
  various other scripts/websites that were referenced that will be added here if/when i run across them again
.COMPONENT
   The component this cmdlet belongs to Jeff Giese
.ROLE
  The role this cmdlet belongs to Corporate Data Warehouse System Administrator Team (CDW SA Team)
.FUNCTIONALITY
  Script to gather local or remote Window systems top selected drive contents sorted from high to low to be used to help
  track down offending folders/files using drive resources.
#>
function get-cdwTreeSIZE(){
    [CmdletBinding()]
    [Alias("cdwTreeSIZE")]
    Param(
        [parameter(valuefrompipeline=$true)]
        [string]$bytecount
    )
switch -Regex ([math]::Truncate([math]::Log($bytecount,1024))){
    '^0' {"$bytecount Bytes"}                                                #ps default listing
    '^1' {"{0:n2} KB" -f ($bytecount/1024)}                                  #kilo-bytes
    '^2' {"{0:n2} MB" -f ($bytecount/1048576)}                               #mega-bytes
    '^3' {"{0:n2} GB" -f ($bytecount/1073741824)}                            #giga-bytes
    '^4' {"{0:n2} TB" -f ($bytecount/1099511627776)}                         #tera-bytes
    '^5' {"{0:n2} PB" -f ($bytecount/1125899906842624)}                      #peta-bytes
    '^6' {"{0:n2} EB" -f ($bytecount/1152921504606846976)}                   #exa-bytes
    '^7' {"{0:n2} ZB" -f ($bytecount/1180591620717411303424)}                #zeta-bytes
    '^8' {"{0:n2} YB" -f ($bytecount/1208925819614629174706176)}             #yotta-bytes
    '^9' {"{0:n2} XB" -f ($bytecount/1237940039285380274899124224)}          #xenotta-bytes
    '^10' {"{0:n2} SB" -f ($bytecount/1267650600228229401496703205376)}      #shilentno-bytes - displays in KB and in DB and my guess due to too high a number
    '^11' {"{0:n2} DB" -f ($bytecount/1298074214633706907132624082305024)}   #domegemegrotte-bytes - displays in KB and in DB and my guess due to too high a number
    default {"0 bytes" }
    }
}

function get-humanreadable(){
    [CmdletBinding()]
    [Alias("treesize")]
    Param(
        [parameter(mandatory=$false,
        valuefrompipeline=$true)]
        [string]$remote,
        [string]$computername,
        [string]$drive = "c:",
        [string]$directory = "c:\",
        [string]$SAVE_Report = ""
    )

$all_drives = gcim win32_logicaldisk | select *
$all_drives | select @{n="drive(s)";e="DeviceID"}

if($remote -eq "y" -and $computername -ne $null){
    icm -cn $computername -FilePath 'C:\Users\VHAV20GIESEJ\_script\file-size    aka tree-size\Get-HumanReadable\get-humanreadable__v15.ps1'
    write "`n...end of report on $computername...`n"
    break
}


<#interactive mode
the first part the ia_... var works with being equal to the other vars, but the do statement doesn't set the var.
commenting out for now.
$ia_good = ""
if($ia -eq "^"){
    write-warning "executing script in interactive-mode"
    $ia_cn = $cn
    $ia_drive = $drive
    $ia_directory = $directory
    $ia_SAVE_Report = $SAVE_Report
do{
    $ia_cn = read-host "['$($cn)'] :`t computer name"
    $ia_drive = read-host "['$($drive)'] :`t drive (ie, c  or  d  etc.)"
    $ia_directory = read-host "['$($directory)'] :`t directory (ie, c:\temp  or  d:\  etc.)"
    $ia_SAVE_Report = read-host "['$($SAVE_Report)'] :`t save report (default set to 'NO/NULL'  or  any key for 'Yes')"
    $ia_good = read-host "ready to proceed ('y')"
}until($ia_good -match "y")
}
#>

$directory_b4 = $($pwd.path)
$all_drives | select @{n="drive(s)";e="DeviceID"}
$drive = read-host "drive to check (ie, 'c'  or  'd'  etc.)"
$directory = read-host "enter file-path to view (defaults to 'c:\')"
$SAVE_Report = read-host "executing 'get-humanreadable' script now, press enter/return  save file size report?"

#setting var for saving report for later use, ie, emailing appropriate team, etc.
if([string]::IsNullOrWhiteSpace($SAVE_Report)){
	$SAVE_Report = $false
}
else{
	$SAVE_Report = $true
}

if([string]::IsNullOrWhiteSpace($directory)){
    push-location
    $directory = "c:\"
}
else{
    write "Directory location set! `t $($directory)"
    $directory_b4 = $($pwd.Path)
    sl $directory
    $directory = $($pwd.Path)
    $directory_set = $true    
}

sl $directory

$date = get-date
$EA_b4 = $ErrorActionPreference
$ErrorActionPreference = "silentlycontinue"
$HourMinDATE = $date.ToString("HH" + "mm" + "__yyyy_MM_dd")
$report_ALL = [ordered]@{}

<#archived for future version - if/when used populate the HT gci_DIR_Sum_UPDATED:
$rootDIR = psdrive $drive[0]
$rootDIR_Free = $rootDIR.Free
$rootDIR_Used = $rootDIR.Used
$rootDIR_TOTAL = ($rootDIR_Free + $rootDIR_Used)
$rootDIR_Free_MATH = (($rootDIR_Free/$rootDIR_TOTAL)*100)
$rootDIR_Used_MATH = (($rootDIR_Used/$rootDIR_TOTAL)*100)
#>

$server = $env:COMPUTERNAME
$gci_DIR = gci $($directory) -Force -Directory | sort
$gci_files = gci $($directory) -Force | ?{$_.Attributes -notmatch "directory"} | sort
$gci_files_Screen = @{}

$gci_DIR_Sum = [ordered]@{}
#used for final report to display to the screen - commenting out for now, i may use this HT to
#display the drive info, but still on the fence...
#  $gci_DIR_Sum_UPDATED = [ordered]@{}

for($i=0;$i -lt $gci_DIR.Count;$i++){
    $t = if((gci -Directory "$($gci_DIR.name['$i'])")) {$true} else {$false}
    if($t -eq $false){
        $gci_DIR_Sum += @{
            (("!+ ") + $gci_DIR.name[$i]) = "PermissionDenied/Unauthorized to view with current signed-on credentials"
        }
    }
    else{
        $gci_DIR_Sum += @{
            ($gci_DIR.name[$i]) = ([system.convert]::ToInt64((((robocopy.exe $gci_DIR.name[$i] "NoCOPY" /L /XJ /R:0 /W:1 /NP /E /BYTES /NFL /NDL /NJH /MT:64)[-4] -replace '\D+(\d+).*','$1'))))
        }
    }
}

$gci_DIR_Sum = $gci_DIR_Sum.GetEnumerator() | sort value -Descending
#placing a '+' indicator in front of the directory names to help visualize the difference between folder(s) and file(s) 
$gci_DIR_ToSCREEN = [ordered]@{}
foreach($dir in $gci_DIR_Sum){
    $gci_DIR_ToSCREEN += @{
        (("+ ") + $dir.name) = ($dir.value)
    }
}

#REPORTING SECTIONS
#report top 10 folders/files:
$gci_files_Screen = $gci_DIR_ToSCREEN.GetEnumerator() | select name,value | sort value -Descending | select -First 10
$gci_files_Screen += $gci_files.GetEnumerator() | sort length -Descending | select name,@{n="value";e="length"} | select -First 10
# report ALL folders/files:
$report_ALL = $gci_DIR_ToSCREEN.GetEnumerator() | select name,value | sort value -Descending
$report_ALL += $gci_files.GetEnumerator() | sort length -Descending | select name,@{n="value";e="length"}
#in event nested directory length is GT 100 characters:
$report_dirNAME = ""
if($directory.Length -gt "100"){
    $report_dirNAME = ($directory.Substring(0,10) + "'..DIRECTORY_NAME_GT_100_Chars..'" + $directory.Remove(0,100)) `
}
else{
    $report_dirNAME = $directory
}

$report_TOP10_ALL_HT = [ordered]@{}

#HT Top 10:
$report_TOP10_HT = [ordered]@{}
for($i=0;$i -lt $gci_files_Screen.Count;$i++){
    if($gci_files_Screen.name[$i].Length -gt "100"){
        $report_TOP10_HT += @{
            ($gci_files_Screen.name[$i].Substring(0,10) + "'..File_Name_GT_100_Chars..'" + $gci_files_Screen.name[$i].Remove(0,100)) `
            = $gci_files_Screen.value[$i]
        }
    }
    else{
        $report_TOP10_HT += @{
            $gci_files_Screen.name[$i] = $gci_files_Screen.value[$i]
        }
    }
}
#HT report ALL Folders/Files:
$report_ALL_HT = [ordered]@{}
for($i=0;$i -lt $gci_files_Screen.Count;$i++){
    if($gci_files_Screen.name[$i].Length -gt "100"){
        $report_ALL_HT += @{
            ($gci_files_Screen.name[$i].Substring(0,10) + "'..File_Name_GT_100_Chars..'" + $gci_files_Screen.name[$i].Remove(0,100)) `
            = $gci_files_Screen.value[$i]
        }
    }
    else{
        $report_ALL_HT += @{
            $gci_files_Screen.name[$i] = $gci_files_Screen.value[$i]
        }
    }
}

<#
#This is the drive reporting information, i think i'll comment this out for now and i can review at a later date if it's needed or not...
$gci_DIR_Sum_UPDATED += @{
    $server = $date::now
    ("C Root Drive Total Size:") = (cdwtreesize $($rootDIR_TOTAL))
    (" C Drive in use " + "("  + $(cdwtreesize ($rootDIR_Used)) + ")" ) = ("$($rootDIR_Used_MATH -as [int])% USED `t ( $(cdwtreesize ($rootDIR_Used)) used / $(cdwtreesize ($rootDIR_Total)) total )")
    (" C Drive free " + "("  + $(cdwtreesize ($rootDIR_Free)) + ")" ) = ("$($rootDIR_Free_MATH -as [int])% FREE `t ( $(cdwtreesize ($rootDIR_free)) used / $(cdwtreesize ($rootDIR_Total)) total )")
}
#>

#cls
$date::[datetime]::Now
write "Get-HumanReadable Report - displaying top '10' folder(s)/file(s) sorted from largest to smallest...`n"
$ErrorActionPreference = "continue"

sl $directory_b4

#$gci_files_Screen.GetEnumerator() | select @{n=$($server + " loc: " + "$($directory)");e="name"},@{n="Size as-of:  '$($HourMinDATE)'";e={cdwtreesize $_.value}}

#FINAL REPORT DISPLAY TO THE SCREEN - TOP 10 FOLDERS AND FILES:
write "displaying top 10 folders/files in the get-humanreadable script..."
#$gci_files_Screen.GetEnumerator() | select @{n=$($server + " loc: " + "'$($report_dirNAME)'");e="name"},@{n="size as-of:  '$($HourMinDATE)'";e={cdwtreesize $_.value}} | ft -AutoSize
$report_TOP10_HT.GetEnumerator() | select @{n=$($server + " loc: " + "'$($report_dirNAME)'");e="name"}, `
    @{n="size as-of:  '$($HourMinDATE)'";e={cdwtreesize $_.value}} | ft -AutoSize

#REPORTING SECTION - if the parameter was selected to save-off the report:
#paste into a doc:
#https://stackoverflow.com/questions/65383032/copy-and-paste-files-through-clipboard-in-powershell
if($Save_Report -eq $true){
    $sep = "="
    $gci_DIR_Sum_UPDATED.GetEnumerator() | ft -AutoSize
    write $($sep*80)
    $report_ALL_HT.GetEnumerator() | select @{n=$($server + " loc: " + "'$($report_dirNAME)'");e="name"},`
        @{n="size as-of:  '$($HourMinDATE)'";e={cdwtreesize $_.value}}
}
}
treesize

<#Executing on a remote server:
2022-12-15 Latest example of running on remote server VHACDWDWHTMS10:

PS C:\Users\VHAV20GIESEJ\_script\file-size    aka tree-size\Get-HumanReadable> icm -cn VHACDWDWHtms10.vha.med.va.gov -FilePath .\get-humanreadable__v16.ps1

drive to check (ie, 'c'  or  'd'  etc.):
enter file-path to view (defaults to 'c:\'): D:\Users\VHAV01BURKHD\AppData\Local\Application Data\
executing 'get-humanreadable' script now, press enter/return  save file size report?:
drive(s) PSComputerName                RunspaceId
C:       VHACDWDWHtms10.vha.med.va.gov f198416a-2d83-4324-9c4a-395369b947bd
D:       VHACDWDWHtms10.vha.med.va.gov f198416a-2d83-4324-9c4a-395369b947bd
Z:       VHACDWDWHtms10.vha.med.va.gov f198416a-2d83-4324-9c4a-395369b947bd
C:       VHACDWDWHtms10.vha.med.va.gov f198416a-2d83-4324-9c4a-395369b947bd
D:       VHACDWDWHtms10.vha.med.va.gov f198416a-2d83-4324-9c4a-395369b947bd
Z:       VHACDWDWHtms10.vha.med.va.gov f198416a-2d83-4324-9c4a-395369b947bd
Directory location set!          D:\Users\VHAV01BURKHD\AppData\Local\Application Data\
Get-HumanReadable Report - displaying top '10' folder(s)/file(s) sorted from largest to smallest...

displaying top 10 folders/files in the get-humanreadable script...



VHACDWDWHTMS10 loc: 'D:\Users\VHAV01BURKHD\AppData\Local\Application Data' size as-of:  '1630__2022_12_15'
-------------------------------------------------------------------------- -------------------------------
+ Application Data                                                         70.47 GB
+ Microsoft                                                                34.67 GB
+ Temp                                                                     32.16 GB
+ Temporary Internet Files                                                 22.78 GB
+ Google                                                                   2.43 GB
+ Programs                                                                 645.94 MB
+ CrashDumps                                                               547.64 MB
+ Packages                                                                 19.36 MB
+ TileDataLayer                                                            16.77 MB
+ Power BI Desktop                                                         7.00 MB


PS C:\Users\VHAV20GIESEJ\_script\file-size    aka tree-size\Get-HumanReadable>




2022-11-28
Example of remote execution on server VHACDWDWHTRN01B with version 5 of script.

NOTE - on this script I need to review the older script with the latest v16 of the script due to the older version
I was able to display/select the drives prior to making a selection and the latest version of the script displays
all the drives after it executes.


PS C:\Users\VHAV20GIESEJ\_script\file-size    aka tree-size\Get-HumanReadable> icm -FilePath .\get-humanreadable__v5.ps1 -cn vhacdwdwhtrn01b.vha.med.va.gov

DeviceID Description      FileSystem ProviderName VolumeName      VolumeSerialNumber
-------- -----------      ---------- ------------ ----------      ------------------
C:       Local Fixed Disk NTFS                    OSDisk          F8078285
Q:       Local Fixed Disk NTFS                    8400_1_Q_QUORUM 54ABF1B5


drive to check (ie, 'c'  or  'd'  etc.):
enter file-path to view (defaults to 'c:\'): c:\windows
executing 'get-humanreadable' script now, press enter/return  save file size report?:
Directory location set!          c:\windows

Monday, November 28, 2022 2:05:45 PM
Get-HumanReadable Report - displaying top '10' folder(s)/file(s) sorted from largest to smallest

displaying top 10 folders/files in the get-humanreadable script...


VHACDWDWHTRN01B loc: C:\windows size as-of:  '1605__2022_11_28'
------------------------------- -------------------------------
+ WinSxS                        12.61 GB
+ System32                      4.90 GB
+ SysWOW64                      1.06 GB
+ assembly                      1.04 GB
+ Installer                     947.75 MB
+ Microsoft.NET                 632.66 MB
+ SoftwareDistribution          624.30 MB
+ Fonts                         382.32 MB
+ servicing                     319.91 MB
+ Logs                          146.12 MB
explorer.exe                    4.18 MB
HelpPane.exe                    1.02 MB
regedit.exe                     349.50 KB
WMSysPr9.prx                    309.22 KB
ADDMRemQuery_x86_64_v2.exe      255.13 KB
notepad.exe                     248.50 KB
DfsrAdmin.exe                   227.50 KB
bepnic.rtf                      224.37 KB
splwow64.exe                    130.50 KB
bfsvc.exe                       81.00 KB

PS C:\Users\VHAV20GIESEJ\_script\file-size    aka tree-size\Get-HumanReadable>





#>
