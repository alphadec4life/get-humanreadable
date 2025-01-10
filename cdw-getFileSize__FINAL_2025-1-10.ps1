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
  And the internet searches when roadblocks were hit
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
$dirNULL_report = ""
$EA_b4 = $ErrorActionPreference
$ErrorActionPreference = "silentlycontinue"
$fileNULL_report = ""
$Free_report = ""
$gci_DIR = ""
$gci_files = ""
$gciDIR_sum = [pscustomobject]@{}
$gciDIR_2SCREEN = [pscustomobject]@{}
$gciFILES_2screen = [ordered]@{} #Try setting to a PSCustomObject...
$fileNULL_report = ""
$HourMinDATE = $date.ToString("HH" + "mm" + "__yyyy_MM_dd")
$NOaccess = ""
$NOaccess_HT = [ordered]@{}
$report = ""
$report4_DIR = ""
$report4_FILE = ""
$reportNO_dir = [bool]""
$reportNO_file = [bool]""
$report_ALL = [ordered]@{} #line 188/189 only!
$report_DIR = ""
$report_FILE = ""
$report_HT = [ordered]@{}
$report_dirNAME = "C:\Temp"
$server = $env:COMPUTERNAME
$report_HT = [ordered]@{}
$report_HT += @{
    Date = $date
    Remote_CN = $cn
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
$gciDIR_sum = @{
    Name = ""
    FullName = ""
    Note = ""
    Value = [double]""
}
$g = ""

#if directory or files are NULL - THIS MAY NOT BE NEEDED...:
if([string]::IsNullOrWhiteSpace($gci_DIR) -and $gci_DIR.count -eq 0){
    $dirNULL_report = [pscustomobject]@{
        Name = $($path)
        Value = "no DIRECTORIES to issue a file-size report!"
    }
}
if([string]::IsNullOrWhiteSpace($gci_files) -and $gci_files.count -eq 0){
    $fileNULL_report = [pscustomobject]@{
        Name = $($path)
        Value = "no FILES to issue a file-size report!"
    }
}

#DUP command/data - see line 149 and var $dirNULL_report
if([string]::IsNullOrWhiteSpace($gci_DIR) -and $gci_DIR.count -eq 0){
    $gciDIR_2SCREEN = [pscustomobject]@{
        Name = $($path)
        Value = "no DIRECTORIES to issue a file-size report!"
    }
}
else{
    $gciDIR_sum = foreach($g in $gci_DIR){
        if([bool](gci -Directory $g.FullName) -ne $false){
            [pscustomobject]@{
                Name = $g.Name.ToLower()
                FullName = $g.FullName
                Note = "'Read' permission granted on directory to view file-size report"
                Value =  ([double]((((robocopy.exe $g.FullName "NoCOPY" /nocopy /L /XJ /R:0 /W:0 /NP /E /BYTES /NFL /NDL /NJH /MT:128)[-4] -replace '\D+(\d+).*','$1'))))
#Value = ([int64][System.Convert]::ToInt64((((robocopy.exe $($g.FullName) "TotallyBOGUSDIR" /nocopy /l /xj /r:0 /w:0 /np /e /bytes /nfl /ndl /njh /mt:128 | ?{$_ -match "Bytes :"}).trim().split(" ")[2]))))
            }
        }
    }
} #end of else

#directories sorted from largest to smallest
$gciDIR_sum = $gciDIR_sum | sort value -Descending

#No access section - identifies folders the account that is executing the script cannot gather the storage used
$NOaccess = ""
if($gciDIR_sum.Count -lt $gci_DIR.Count){
    $NOaccess = diff $gci_DIR.name $gciDIR_sum.name | select InputObject,SideIndicator | select @{n="Name";e={$_ | select -ExpandProperty InputObject}},@{n="Value";e={"Access denied to listed directory"}}
}
else{
    continue
}

#fix in the event $path is set to C:\ or D:\ E:\ etc - this will fix the reporting section when listing the fullname of the path
if($path.Length -eq 3){
    $path_NEW = $path.Remove(2)
}
else{
    $path_NEW = $path
}

$n = ""
$dir_NOaccess = ""
$dir_NOaccess = foreach($n in $NOaccess){
    [pscustomobject]@{
        Path = $path_NEW #$path
        Name = $n.Name
        FullName = ($path_NEW + "\$($n.Name)")
        Note = $n.Value
        Value = "You must have 'Read' permissions to view the contents of this object.."
    }
}
###} #end of ELSE

####place a '+' to indicator directory name to help visualize the difference between folder(s) and file(s) 
$g1 = ""
$gciDIR_2SCREEN =  foreach($g1 in $gciDIR_sum){
    [pscustomobject]@{
        Name = (("+ ") + $g1.name)
        Value = ($g1.value)
    }
}

#for reporting
if($dir_NOaccess -ne $null){
    foreach($d in $dir_NOaccess){
        $NOaccess_HT += @{
            ($d.FullName) = ($d.Note)
        }
    }
}
$NOaccess_HT += @{
    $path = "Path/location where script executed from"
}

#getting File info just like above - if there are less than 1 files (aka no files) statement:
if([string]::IsNullOrWhiteSpace($gci_files) -and $gci_files.count -eq 0){
    $gciFILES_2screen = [pscustomobject]@{
        Name = $($path)
        Value = "no FILES to issue a file-size report!"
    }
}
else{
    foreach($g in $gci_files){
        $gciFILES_2screen += @{
            (@(("   ") + ($g | sort length -Descending | select -ExpandProperty Name)) -join ",") = [System.Convert]::ToInt64(@($g | sort length -Descending | select -ExpandProperty length) -join ",")
        }
    }
    $gciFILES_2screen = $gciFILES_2screen.GetEnumerator() | select name,value | sort value -Descending
}

if($dirNULL_report.Value -eq "no DIRECTORIES to issue a file-size report!"){
    $report_DIR = [pscustomobject]@{
        Name = "..NO DIRECTORIES!"
        Value = $gciDIR_2SCREEN.Value
#        Value = gcim win32_logicaldisk | ?{$_.DeviceID -eq "$($path.Remove(2))"} | select -ExpandProperty freespace
    }
}
else{
    $report_DIR = $gciDIR_2SCREEN | select -First $TOP | select Name,Value #($gciDIR_2SCREEN.GetEnumerator() | select -First $TOP | select Name,Value)
}
#i think the issue above is it is not a 1-2-1, ie report_dir needs to be a pscustomobject/HT etc as gcidir_2screen

#gathering data for file(s)...
if($fileNULL_report.Value -eq "no FILES to issue a file-size report!"){
    $report_FILE = [pscustomobject]@{
        Name = "..NO FILE(S)!"
        Value = $gciFILES_2screen.Value
    }
}
else{
    $report_FILE = ($gciFILES_2screen.GetEnumerator() | select -First $TOP | select name,value)
}

#create DIR/FILE HT so they can be combined in the final report
$r = ""
$report4_DIR = [ordered]@{}
foreach($r in $report_DIR){
    $report4_DIR += @{
        ($r | select -ExpandProperty Name)  = ($r | select -ExpandProperty Value)
    }
}
$r = ""
$report4_FILE = [ordered]@{}
foreach($r in $report_FILE){
    $report4_FILE += @{
        ($r | select -ExpandProperty Name)  = ($r | select -ExpandProperty Value)
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
write "Corporate Data Warehouse (CDW) FileSize Report"
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
write "`n`t $($gciDIR_sum | select -First 1 | select -ExpandProperty fullname)`n" | ft -Wrap -AutoSize


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
