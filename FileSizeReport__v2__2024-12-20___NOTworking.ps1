#2024-12-20  THIS IS GETTING WEIRD.... Script works great if gci_DIR/gci_FILE are gt '1', but if there is only 1 directory, ie C:\Temp\debug_logs and when executing the script via command:
#getfilesize c:\temp
# OUTPUT
#NULL/NOTHING/NODA/ZILTCH/NOT A DAMN THING!!!!!!!!!!!!!!
#Then, even though there are 71 files with C:\Temp - NOTHING IS SHOWN!

#if i execute old code it works, but within my logic statement of 'if condition is zero then state - no dirs/files/, else - populate a totally different HT and it works??? weird.

#from looking at the logic - it looks good to me but something isn't working...

#fileNULL_report - line 149 is set to PSCUSTOMOBJECT! Set to an [ordered] HT just like dirNULL_report and then
#verify all is working as it should.

#i verified the remote execution code by copying/pasting into another working script and the code worked - just
#need to verifying it from a working server and currently it works great on my GFE.

#line 317
#2024-12-17 - another bug.... when going thru the directories i found an issue if there was only 1 directory
#an no files and re-test tomorrow at:
# "C:\Program Files\PowerShell"
#Output from the above file-size check and when checking against the GUI the folder size was 267 MB!
<#
PS C:\Users\VHAV20GIESEJ\.ms-ad> getfilesize "C:\Program Files\PowerShell"

Name          Value                                
----          -----                                
..NO FILE(S)! no FILES to issue a file-size report!

Corporate Data Warehouse (CDW) FileSize Report
WCO-TB30818	 3:22 PM  12/17/2024
Path file-size report executed on:	C:\Program Files\PowerShell
no permissions issues during execution of script... 
(total execution time:	 00:00:00.0982730)
end FileSize report at path:	 C:\Program Files\PowerShell

	 C:\Program Files\PowerShell\7


#>

<#
.Synopsis
  cdw-getFileSize.ps1 - script to display file-size contents in human-readable format from the command prompt
.DESCRIPTION
  cdw-getFileSize.ps1 - script to display file-size contents of a given system in human-readable format
.EXAMPLE
  executed on a local system taking defaults ([return]):
    > .\cdw-getFileSize.ps1 [return]  - default execution that displays file-size information on the root C:\
.EXAMPLE
    > . .\cdw-getFileSize.ps1 [return]  - default execution that displays output to the screen
.EXAMPLE
    > getFileSize C:\Users -TOP 10 -Free 1 [return]  - gets the 'top 10' folders/files and displays current freespace of C:\ drive
.EXAMPLE
    >  icm -FilePath .\cdw-getFileSize.ps1 -cn TestSERVER10.abc.net (fqdn) [return]
.EXAMPLE
  remotely executed with an 'Administrative PowerShell' session with the script located in current directory and saving the output to c:\temp:
    > icm -cn ("TestSERVER10.abc.net","TestSERVER11.abc.net") -FilePath .\cdw-getFileSize.ps1 | tee-object -FilePath .\zzDELETE123_TRN01A_TRN01B.txt
.INPUTS
  Parameters path (directory), TOP (defaults to top 5 or enter new #), Free ([bool] freespace report), SAVE_Report ([bool]save report to C:\Temp)
.OUTPUTS
  Script displays the largets folders and files within a given path (directory) and defaults to the top 5 folders/files in human-readable format.
  For example, lists the largest folders and files in appropriate sizes from largest to smallest. Script displays execution time as-well-as the
  next folder size that can be copied/pasted for the next run and pasted into the path parameter.
.NOTES
Source websites used to making this a functional script:
  cdw-getHUMANReadable function conversion website:      https://www.dataunitconverter.com/pebibyte
  website that helped identify folder permissions view:  https://stackoverflow.com/questions/70410860/check-if-user-has-read-permissions-on-a-directory-powershell
  Website used for gathering results much faster:        http://www.powershelladmin.com/wiki/Get_Folder_Size_with_PowerShell,_Blazingly_Fast
  And many more not listed internet searches when roadblocks were hit.
.COMPONENT
   The component this cmdlet belongs to Jeff Giese
.ROLE
  The role this cmdlet belongs to Corporate Data Warehouse System Administrator Team (CDW SA Team)
.FUNCTIONALITY
  Script to display folders and files in appropriate sizes from the powershell command prompt from largest to smallest in a short amount of time.
#>
function cdw-getHUMANreadable(){
    [CmdletBinding()]
    [Alias("gethumanreadable")]
    Param(
        [parameter(ValueFromPipeline)] #this is byValue or the Entire Object; it would be nice to have the name/length or fullpath/length if possible
        $bytecount
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
    '^9' {"{0:n2} XB" -f [system.convert]::ToDouble(($bytecount/1237940039285380274899124224))}          #xenotta-bytes
    default {"0 bytes" }
    }
}


function cdw-getFileSize(){
    [CmdletBinding()]
    [Alias("getfilesize")]
    Param(
        [parameter(mandatory=$false,
        valuefrompipeline=$true)]
        [string]$path = "c:\",
        [int]$TOP = 5,
        [bool]$Free = $false,
        [bool]$SAVE_Report = $false,
        [bool]$remote = $false,
        [string]$fqdn
    )

#execute on remote system check - ensure script name is correct and within the correct location on final version!
if($remote -eq $true -and $fqdn -ne $null){
    Write-Warning "Remote execution must be executed where the cdw-getFileSize.ps1 script resides!"
    $verify_fqdn = Test-NetConnection $fqdn
    if($verify_fqdn.PingSucceeded -eq $true){
        icm -cn $fqdn -FilePath .\cdw-getFileSize.ps1
        write "`n..end of file-size report on $fqdn`n"
        break
    }
}

#param section
if($TOP -eq 0){
    [int]$TOP = 5
}
#free param
if([bool]($Free) -eq $false){
    $Free = $false
}
else{
    $Free = $true
}
#path param
if([string]::IsNullOrWhiteSpace($path)){
    $dir_B4 = $pwd.Path
    $path = "c:\"
}
else{
    $dir_B4 = $pwd.Path
    $dir_VERIFY = Test-Path -Path $path
    if($dir_VERIFY -eq $false){
        Write-Warning "`t$($path)  :`t PATH ISSUES! Setting location to local 'C:\'"
        $path = "c:\"
    }
}

#Variables
$Account_USED = ($env:USERDOMAIN + "\" + $env:USERNAME)
$date = get-date
$dir_NOaccess = ""
$dirNULL_report = [ordered]@{}
$EA_b4 = $ErrorActionPreference
$ErrorActionPreference = "silentlycontinue"
$fileNULL_report = ""
$Free_report = ""
$gci_DIR = ""
$gci_files = ""
$gciDIR_2SCREEN = "" #[ordered]@{}
$gciDIR_sum = [ordered]@{}
$gciFILES_2screen = [ordered]@{}
$HourMinDATE = $date.ToString("HH" + "mm" + "__yyyy_MM_dd")
$NOaccess = ""
$NOaccess_HT = [ordered]@{}
$report = ""
$report_ALL = [ordered]@{}
$report_DIR = [ordered]@{}
$report_dirNAME = "C:\Temp"
$report_FILE = [ordered]@{}
$report_HT = [ordered]@{}
$report_HT = [ordered]@{}
$report4_DIR = ""
$report4_FILE = ""
$reportNO_dir = [bool]""
$reportNO_file = [bool]""
$server = $env:COMPUTERNAME
$report_HT = [ordered]@{}
$report_HT += @{
    Date = $date
    remote_bool = $remote
    Remote_FQDN = $fqdn
    Server = $server
    Script = "cdw-getHUMANreadable.ps1 : FileSize Human Readable Report"   #Fix renaming on final version
    Account = $Account_USED
    Path_Previous = $dir_B4
    Top_Number = $TOP
    Free_spaceViewed = $Free
    Save_REPORT = $SAVE_Report
}
sl $path

#https://stackoverflow.com/questions/70410860/check-if-user-has-read-permissions-on-a-directory-powershell
$gci_DIR = gci -Path $($path) -Force -Directory | sort
$gci_files = gci -Path $($path) -Force | ?{$_.Attributes -notmatch "directory"} | sort

$NumDIR = [int]($gci_DIR.count)
$NumFILE = [int]($gci_files.Count)


#if directory or files are NULL - THIS MAY NOT BE NEEDED...:
if($NumDIR -eq $null -or $NumDIR -eq 0){ #ORIGINAL  if([string]::IsNullOrWhiteSpace($gci_DIR) -and $gci_DIR.count -eq 0){
    $dirNULL_report += @{
        $($path) = "no DIRECTORIES to issue a file-size report!"
    }
    $gciDIR_2SCREEN += @{
        $($path) = "no DIRECTORIES to issue a file-size report!"
    }
}
elseif($NumDIR -eq 1){
    $gciDIR_2SCREEN = [pscustomobject]@{
        Name = (("+ ") + $g1.name)
        Value = ($g1.value)
    }
    $gciDIR_sum = foreach($g in $gci_DIR){
        if([bool](gci -Directory | ?{$_.Name -eq "$($g.Name)"}) -eq $false){
            [pscustomobject]@{
                Name = $g.Name.ToLower()
                FullName = $g.FullName
                Note = "'Read' permission granted on directory to view file-size report"
                Value =  ([System.Convert]::ToInt64((((robocopy.exe $g.FullName "NoCOPY" /L /XJ /R:0 /W:1 /NP /E /BYTES /NFL /NDL /NJH /MT:64)[-4] -replace '\D+(\d+).*','$1'))))
            }
        }
        else{
            [pscustomobject]@{
                Name = $g.Name
                FullName = $g.FullName
                Note = "file size content"
                Value =  ([System.Convert]::ToInt64((((robocopy.exe $g.FullName "NoCOPY" /L /XJ /R:0 /W:1 /NP /E /BYTES /NFL /NDL /NJH /MT:64)[-4] -replace '\D+(\d+).*','$1'))))
            }
        }
    }
}
else{ #($NumDIR -ge 1){
    $gciDIR_sum = foreach($g in $gci_DIR){
        if([bool](gci -Directory | ?{$_.Name -eq "$($g.Name)"}) -eq $false){
            [pscustomobject]@{
                Name = $g.Name.ToLower()
                FullName = $g.FullName
                Note = "'Read' permission granted on directory to view file-size report"
                Value =  ([System.Convert]::ToInt64((((robocopy.exe $g.FullName "NoCOPY" /L /XJ /R:0 /W:1 /NP /E /BYTES /NFL /NDL /NJH /MT:64)[-4] -replace '\D+(\d+).*','$1'))))
            }
        }
        else{
            [pscustomobject]@{
                Name = $g.Name
                FullName = $g.FullName
                Note = "file size content"
                Value =  ([System.Convert]::ToInt64((((robocopy.exe $g.FullName "NoCOPY" /L /XJ /R:0 /W:1 /NP /E /BYTES /NFL /NDL /NJH /MT:64)[-4] -replace '\D+(\d+).*','$1'))))
            }
        }
    }
}
#directories sorted from largest to smallest
$gciDIR_sum = $gciDIR_sum | sort value -Descending

#No access section - identifies folders the account that is executing the script cannot gather the storage used
$NOaccess = ""
if(($gciDIR_sum | measure | select -ExpandProperty count) -lt ($gci_DIR | measure | select -ExpandProperty count)){    #ORIGINAL    if($gciDIR_sum.Count -lt $gci_DIR.Count){
    $NOaccess = diff $gci_DIR.name $gciDIR_sum.name | select InputObject,SideIndicator | select @{n="Name";e={$_ | select -ExpandProperty InputObject}},@{n="Value";e={"Access denied to listed directory"}}
}
else{
    continue
}
$n = ""
$dir_NOaccess = ""
$dir_NOaccess = foreach($n in $NOaccess){
    [pscustomobject]@{
        Path = $path
        Name = gci -Directory | ?{$_.Name -eq $($n.Name)} | select -ExpandProperty Name
        FullName = ($path + $n.Name + "\")  #ORIGINAL  ($path + "\" + $n.Name + "\")
        Note = $n.Value
        Value = "You must have 'Read' permissions to view the contents of this object.."
    }
}
####place a '+' to indicator directory name to help visualize the difference between folder(s) and file(s)
$g1 = ""
$gciDIR_2SCREEN = foreach($g1 in $gciDIR_sum){
    [pscustomobject]@{
        Name = (("+ ") + $g1.name)
        Value = ($g1.value)
    }
}




if($NumFILE -eq $null -or $NumFILE -eq 0){  #ORIGINAL  if([string]::IsNullOrWhiteSpace($gci_files) -and $gci_files.count -eq 0){
    $fileNULL_report = [pscustomobject]@{
        Name = $($path)
        Value = "no FILES to issue a file-size report!"
    }
}
elseif($NumFILE -ge 1){
    $gciFILES_2screen = [ordered]@{}

    foreach($g in $gci_files){
        $gciFILES_2screen += @{
            (@($g | sort length -Descending | select -ExpandProperty Name) -join ",") = [System.Convert]::ToInt64(@($g | sort length -Descending | select -ExpandProperty length) -join ",")
        }
    }
    $gciFILES_2screen = $gciFILES_2screen.GetEnumerator() | select name,value | sort value -Descending
}
else{
    Write-Warning "something isn't working with setting var $gciFILES_2SCREEN -within if/elseif/esle statement for NumFILE..."
}


#for reporting
if($dir_NOaccess -ne $null){
    foreach($d in $dir_NOaccess){
        $NOaccess_HT += @{
            ($d.FullName) = ($d.Note)
        }
    }
}
else{  #2024-12-20 just added...
    $NOaccess_HT += @{
        $path = "Path/location where script executed from"
    }
}

<#
#getting File info just like above - if there are less than 1 files (aka no files) statement:
if([string]::IsNullOrWhiteSpace($gci_files) -and $gci_files.count -eq 0){
    $gciFILES_2screen = [pscustomobject]@{
        Name = $($path)
        Value = "no FILES to issue a file-size report!"
    }
}
else{
    $gciFILES_2screen = [ordered]@{}

    foreach($g in $gci_files){
        $gciFILES_2screen += @{
            (@($g | sort length -Descending | select -ExpandProperty Name) -join ",") = [System.Convert]::ToInt64(@($g | sort length -Descending | select -ExpandProperty length) -join ",")
        }
    }
    $gciFILES_2screen = $gciFILES_2screen.GetEnumerator() | select name,value | sort value -Descending
}
#>

#2024-12-16  working thru the dirNULL_report to see if it's still needed or not and updated vars to HT as-well...
if($dirNULL_report.Values -eq "no DIRECTORIES to issue a file-size report!"){
    $report_DIR += @{    #ORIGINAL $report_DIR = [pscustomobject]@{
        #ORIGINAL  Name = "..NO DIRECTORIES!"
        "..NO DIRECTORIES!" = $($gciDIR_2SCREEN.Values) #ORIGINAL  Value = $gciDIR_2SCREEN.Value
    }
    $report_DIR.GetEnumerator() | select name,value
}
else{
        $report_DIR = ($gciDIR_2SCREEN.GetEnumerator() | select -First $TOP | select Name,Value)
}

#gathering data for file(s)...
if($fileNULL_report.Value -eq "no FILES to issue a file-size report!"){
    $report_FILE += @{        #ORIGINAL    $report_FILE = [pscustomobject]@{
#        Name = "..NO FILE(S)!"
        "..NO FILE(S)!"= $($gciFILES_2screen.Value) #ORIGINAL        Value = $gciFILES_2screen.Value
    }
    $report_FILE.GetEnumerator() | select name,value
}
else{
        $report_FILE = ($gciFILES_2screen.GetEnumerator() | select -First $TOP | select name,value)
}






#ORIGINAL if($report_DIR.Count -eq 1){
if($report_DIR.Count -le 1){
#    $report_ALL = $report_DIR + $report_FILE
    $report4_DIR += @{
        $path = "there are no DIRECTORIES to issue file-size report."
    }
}
else{
    $r = ""
    $report4_DIR = [ordered]@{}
    foreach($r in $report_DIR){
        $report4_DIR += @{
            ($r | select -ExpandProperty Name)  = ($r | select -ExpandProperty Value)
        }
    }
}
if($report_FILE.Count -eq 1){
    $report_ALL = $report_DIR + $report_FILE
}
else{
    $r = ""
    $report4_FILE = [ordered]@{}
    foreach($r in $report_FILE){
        $report4_FILE += @{
            (("   ") + ($r | select -ExpandProperty Name))  = ($r | select -ExpandProperty Value)
        }
    }
}
$report_ALL = $report4_DIR + $report4_FILE


$Free_report = ""
if($Free -eq $true -or $SAVE_Report -eq $true){
    $Free_report = [pscustomobject]@{
        Size = gcim win32_logicaldisk | ?{$_.DeviceID -eq "$($path.Remove(2))"} | select -ExpandProperty size
        Free = gcim win32_logicaldisk | ?{$_.DeviceID -eq "$($path.Remove(2))"} | select -ExpandProperty freespace
        '% free' = (((gcim win32_logicaldisk | ?{$_.DeviceID -eq $($path.Remove(2))} | select -ExpandProperty freespace)/(gcim win32_logicaldisk | ?{$_.DeviceID -eq "$($path.Remove(2))"} | select -ExpandProperty size))).ToString("P")
    }
}

#Displayed to screen:
write "`nCorporate Data Warehouse (CDW) FileSize Report"
$server + "`t " + $date.ToShortTimeString() + "  " + $date.ToShortDateString()
write "Path file-size report executed on:`t$($path)" | ft -AutoSize -Wrap

if([bool]($dir_NOaccess) -eq $true){
    write "`nPath/location(s) unable to dertermine file-size information due to permissions."
    write "Try executing with administrator account to see all directories/files:" | ft -Wrap -AutoSize
    $dir_NOaccess | select fullname,note | ft -AutoSize -HideTableHeaders
}
else{
    write "no permissions issues during execution of script... "
}

$report_all.GetEnumerator() | select @{n=$($server + "`n path: " + "'$($path)'");e={$_.name}},@{n="size as-of:  '$($date.ToShortTimeString() + "  " + $date.ToShortDateString())'";e={gethumanreadable $_.value}} | ft -AutoSize
if($Free -eq $true){
    write "Current drive information (total size, free, and % free):"
    $Free_report | select @{n="Location/path";e={$path}},@{n="Total size";e={$_.size | gethumanreadable}},@{n="Free";e={$_.free | gethumanreadable}},'% free' | ft -AutoSize
}

$report_HT += @{
    Execution_RUNtime = $($($date::now).subtract($date).ToString())
}
write "(total execution time:`t $($($date::now).subtract($date).ToString()))"
write "end FileSize report at path:`t $($path)" | ft -AutoSize -Wrap
write "`n`t $($gciDIR_sum | select -First 1 | select -ExpandProperty fullname)" | ft -Wrap -AutoSize


if($SAVE_Report -eq $true){
#reporting section that can be imporoved on, but the script is mainly used for interactive executions rather 
#than saving a report...
#CSV:
 #   $report = $report_HT + $NOaccess_HT # + ($report_ALL.GetEnumerator() | select name,@{n="value";e={$_.value | gethumanreadable}})
 #   $report.GetEnumerator() | select name,value | convertto-csv -NoTypeInformation | Out-File C:\Temp\cdwFileSize.csv -Verbose
 #   ($report_ALL.GetEnumerator() | select Name,@{n="Size";e={$_.value | gethumanreadable}}) | select name,size | ConvertTo-Csv -NoTypeInformation | Out-File c:\temp\cdwFileSize.csv -Append
#Text:
    $report = $report_HT + $NOaccess_HT
    $report.GetEnumerator() | select name,value | Out-File $report_dirNAME\cdwFileSize.txt
    ($report_ALL.GetEnumerator() | select Name,@{n="Size";e={$_.value | gethumanreadable}}) | select name,size | ft -HideTableHeaders | Out-File $report_dirNAME\cdwFileSize.txt -Append

    write "Current drive information (total size, free, and % free):" | out-file $report_dirNAME\cdwFileSize.txt -Append
    $Free_report | select @{n="Location/path";e={$path}},@{n="Total size";e={$_.size | gethumanreadable}},@{n="Free";e={$_.free | gethumanreadable}},'% free' | Out-File $report_dirNAME\cdwFileSize.txt -Append

    sl $report_dirNAME
    sleep -Milliseconds 20
    mi cdwFileSize.txt ("$($server)" + "_FileSizeReport" +  "__" + "$($date.ToString("HH" + "mm" + "__yyyy_MM_dd"))" + ".txt") -Force
    Write-Warning "Report saved to '$($report_dirNAME)\ServerNAME_FileSizeReport__TimeStamp.txt'"
}

sl $dir_B4

}
getfilesize