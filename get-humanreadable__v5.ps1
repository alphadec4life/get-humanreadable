#2022-11-28 comments
# should i have a timer so if no entry/selection is made the script will break/cancel?
# should i have it test the folder via test-path before executing?
# should i have it run with the default top 10 so its not looking for the param entries?
# should i create a new cmdlet and populate everything like the clean_remotepc script so it's fully self contained
#  ie, and not calling the get-humanreadable function?
<#2022-11-28  get-humanreadable__v5.ps1 script
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
function get-humanreadable(){
    [CmdletBinding()]
    [Alias("cdwTreeSIZE")]
    Param(
        [parameter(valuefrompipeline=$true)]
        [string]$bytecount
    )
#...$bytecount,1024)),2){   - it's possible to make a change to view the # entered as a certain size, and I tested this command and it worked good 
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

$all_drives = gcim win32_logicaldisk | select *
$all_drives | select DeviceID, Description, FileSystem, ProviderName, VolumeName, VolumeSerialNumber | ft -AutoSize

$directory_b4 = $($pwd.path)
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
##    if([bool]::TrueString($report_needed)){  #i tried passing the param $directory in here but for some reason the param var isn't getting passed.
##        $report_needed = $true
##    }
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
$DIR_2_INT = @{} #HT used for converting string to int64 for conversion process
$DIR_2_Screen = @{} #HT used for displaying info to screen on final section of script; used to display first 15 directories sorted largest to smallest
$DIR_Count_HT = @{}
$EA_b4 = $ErrorActionPreference
$ErrorActionPreference = "silentlycontinue"
$HourMinDATE = $date.ToString("HH" + "mm" + "__yyyy_MM_dd")
$report = "c:\temp"
$report_ALL = [ordered]@{}

$rootDIR = psdrive $drive[0]
$rootDIR_Free = $rootDIR.Free
$rootDIR_Used = $rootDIR.Used
$rootDIR_TOTAL = ($rootDIR_Free + $rootDIR_Used)
$rootDIR_Free_MATH = (($rootDIR_Free/$rootDIR_TOTAL)*100)
$rootDIR_Used_MATH = (($rootDIR_Used/$rootDIR_TOTAL)*100)

$server = $env:COMPUTERNAME
$gci_DIR = gci $($directory) -Force -Directory | sort
$gci_files = gci $($directory) -Force | ?{$_.Attributes -notmatch "directory"} | sort
$gci_files_Screen = @{}

$setPATH = get-location
$gci_DIR_Sum = [ordered]@{}
$gci_DIR_Sum_UPDATED = [ordered]@{}  #used for final report to display to the screen - combines $DIR_2_Screen and $gci_files_screen

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
##            (("+ ") + $gci_DIR.name[$i]) = ([system.convert]::ToInt64((((robocopy.exe $gci_DIR.name[$i] "NoCOPY" /L /XJ /R:0 /W:1 /NP /E /BYTES /NFL /NDL /NJH /MT:64)[-4] -replace '\D+(\d+).*','$1'))))
        }
    }
}
##2022-11-18 AWESOME!!! MADE A YUGE MILESTONE TODAY! I was able to convert the Value into int64 and that will help with everything here on out.
##Thank you JESUS!!!!!!!!!!!!!!

#i want to go thru the top 10 highest directories, or make it a var in the future to select how many to drill down thru and do the file size report
$gci_DIR_Sum = $gci_DIR_Sum.GetEnumerator() | sort value -Descending
###gci_DIR_Sum - maybe populate another HT and have the new HT with a visual to indicate dirs/folders, ie, '+ Temp'
$gci_DIR_ToSCREEN = [ordered]@{}
foreach($dir in $gci_DIR_Sum){
    $gci_DIR_ToSCREEN += @{
        (("+ ") + $dir.name) = ($dir.value)
    }
}

$gci_DIR_Top = [ordered]@{} #to be used in the sub-dirs and i need to work on the sorting so it only grabs the top 4

$gci_DIR_Sum_UPDATED += $gci_DIR_Sum.GetEnumerator() | select name,value
#add the files to the HT:
for($i=0;$i -lt $gci_files.Count;$i++){
    $gci_DIR_Sum_UPDATED += @{
        $gci_files.Name[$i] = $gci_files[$i].Length
    }
}

#sort and add the top 10 folders and files to the gci_files_screen HT:
$gci_files_Screen = $gci_DIR_ToSCREEN.GetEnumerator() | select name,value | sort value -Descending | select -First 10
$gci_files_Screen += $gci_files.GetEnumerator() | sort length -Descending | select name,@{n="value";e="length"} | select -First 10

#REPORT
$report_ALL = $gci_DIR_ToSCREEN.GetEnumerator() | select name,value | sort value -Descending
$report_ALL += $gci_files.GetEnumerator() | sort length -Descending | select name,@{n="value";e="length"}
#good report info:    $report_ALL.GetEnumerator() | select name,@{n="size";e={cdwtreesize $_.value}}


$gci_DIR_Sum_UPDATED += @{
    $server = $date::now
    ("C Root Drive Total Size:") = (cdwtreesize $($rootDIR_TOTAL))
    (" C Drive in use " + "("  + $(cdwtreesize ($rootDIR_Used)) + ")" ) = ("$($rootDIR_Used_MATH -as [int])% USED `t ( $(cdwtreesize ($rootDIR_Used)) used / $(cdwtreesize ($rootDIR_Total)) total )")
    (" C Drive free " + "("  + $(cdwtreesize ($rootDIR_Free)) + ")" ) = ("$($rootDIR_Free_MATH -as [int])% FREE `t ( $(cdwtreesize ($rootDIR_free)) used / $(cdwtreesize ($rootDIR_Total)) total )")
}
###write "$($rootDIR_Free_MATH -as [int])% USED `t $(cdwtreesize ($rootDIR_Used))"
#>
#cls
#####should i have a var/param to select the # of folders/files to display? i'm thinking of keeping it set to '10' for on-screen reports
[datetime]::Now
write "Get-HumanReadable Report - displaying top '10' folder(s)/file(s) sorted from largest to smallest `n"
###ipcsv $report\dir_size_SORTED.csv | ogv #this command doesn't work when running on remote systems
$ErrorActionPreference = "continue"
####Write-Output "$($date): Script date/time start of execution"
####Write-Output "`n.....`nScript run-time:"
####get-date
#### remove after verifying    $gci_DIR_Sum_UPDATED.GetEnumerator() | sort name -Descending | select @{n="$server : '$directory'";e="name"},@{n="size sorted on: $HourMinDATE";e="value"} | ft -AutoSize
sl $directory_b4

###$gci_DIR_Sum_UPDATED.GetEnumerator() | select @{n=$($server + " loc: " + "$($directory)");e="name"},@{n="Size as-of:  '$($HourMinDATE)'";e={cdwtreesize $_.value}}
#$gci_files_Screen.GetEnumerator() | select @{n=$($server + " loc: " + "$($directory)");e="name"},@{n="Size as-of:  '$($HourMinDATE)'";e={cdwtreesize $_.value}}

write "displaying top 10 folders/files in the get-humanreadable script..."
$gci_files_Screen.GetEnumerator() | select @{n=$($server + " loc: " + "$($directory)");e="name"},@{n="size as-of:  '$($HourMinDATE)'";e={cdwtreesize $_.value}} | ft -AutoSize
sleep 2

#REPORTING SECTION - if the parameter was selected to save-off the report:
#paste into a doc:
#https://stackoverflow.com/questions/65383032/copy-and-paste-files-through-clipboard-in-powershell
if($Save_Report -eq $true){
#    $gci_DIR_Sum_UPDATED.GetEnumerator() | select name,@{n="size as-of:  '$($HourMinDATE)'";e={cdwtreesize $_.value}}
    $sep = "="
    write $($sep*80)
#    $gci_DIR_Sum_UPDATED.GetEnumerator() | select name,@{n="size";e={cdwtreesize $_.value}} | ConvertTo-Csv -NoTypeInformation #| clip |  notepad.exe Set-Clipboard
    $report_ALL.GetEnumerator() | select @{n=$($server + " loc: " + "$($directory)");e="name"},@{n="size as-of:  '$($HourMinDATE)'";e={cdwtreesize $_.value}} | ft -AutoSize
}



<#Executing on a remote server:

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
