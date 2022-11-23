#2022-11-22 ran into a problem today dealing with the conversion and once the bytes start getting into the higher file-sizes in PB
#section is when i'm now running into problems with conversion; and this was after converting the string to an int64 so i'm going to
#save the current script and v3 and start on the new version.


#2022-11-21 YUGE MILESTONES BEING MADE! Latest version executes completely in memory!!!! All made in part with the conversion command i tried
#and it worked. Next things to try:
# params:
#  directory, CN 
# report time - how long did it take to execute?
#  have a param to find the large folders/files?
# automated report to show 4 sub-directories and their sizes?
#ALMOST DONE!

function get-humanreadable(){
    [CmdletBinding()]
    [Alias("cdwTreeSIZE")]
    Param(
        [parameter(valuefrompipeline=$true)]
        [string]$bytecount,
        [string]$directory,
        [string]$Save_Report = $true
    )
#switch -Regex ([math]::Truncate([system.convert]::ToInt64($bytecount,1024))){
switch -Regex ([math]::Truncate([math]::Log([system.convert]::ToUInt64($bytecount),1024))){
    '^0' {"$bytecount Bytes"}                                                #ps default listing
    '^1' {"{0:n2} KB" -f ($bytecount/1024)}                                  #kilo-bytes
    '^2' {"{0:n2} MB" -f ($bytecount/1048576)}                               #mega-bytes
    '^3' {"{0:n2} GB" -f ($bytecount/1073741824)}                            #giga-bytes
    '^4' {"{0:n2} TB" -f ($bytecount/1099511627776)}                         #tera-bytes
    #                                1125899906842624
    #                                1125899906842624
    #                                1125899906842624
    '^5' {"{0:n2} PB" -f ($bytecount/1125899906842624)}                      #peta-bytes
    '^6' {"{0:n2} EB" -f ($bytecount/1152921504606846976)}                   #exa-bytes
    '^7' {"{0:n2} ZB" -f ($bytecount/1180591620717411303424)}                #zeta-bytes
    '^8' {"{0:n2} YB" -f ($bytecount/1208925819614629174706176)}             #yotta-bytes
    '^9' {"{0:n2} XB" -f ($bytecount/1237940039285380274899124224)}          #xenotta-bytes
    '^10' {"{0:n2} SB" -f $($bytecount/1267650600228229401496703205376)}     #shilentno-bytes - displays in KB and in DB and my guess due to too high a number
    '^11' {"{0:n2} DB" -f ($bytecount/1298074214633706907132624082305024)}   #domegemegrotte-bytes - displays in KB and in DB and my guess due to too high a number
    default {"0 bytes" }
    }
}

$directory_b4 = $($pwd.path)
$drive = read-host "drive to check"
$directory = read-host "enter file-path to view (defaults to 'c:\')"
$SAVE_Report = read-host "executing 'get-humanreadable' script now, press enter/return  save file size report?"

#setting var for saving report for later use, ie, emailing appropriate team, etc.
if([string]::IsNullOrWhiteSpace($SAVE_Report)){
	$SAVE_Report = $false
}
else{
	$SAVE_Report = $true
}

#for some reason i can't get the passing the directory location within the script - NEEDS FURTHER RESEARCH!
if([string]::IsNullOrWhiteSpace($directory)){
    push-location
    $directory = "c:\"
#    if([bool]::TrueString($report_needed)){  #i tried passing the param $directory in here but for some reason the param var isn't getting passed.
#        $report_needed = $true
#    }
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
$drive = ""
$HourMinDATE = $date.ToString("HH" + "mm" + "__yyyy_MM_dd")
#make drive var more generic so it can gather data for luns/etc
$EA_b4 = $ErrorActionPreference
$ErrorActionPreference = "silentlycontinue"
$report = "c:\temp"
$report_ALL = [ordered]@{}
###write $report_needed

$rootDIR = psdrive $drive
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
#            (("+ ") + $gci_DIR.name[$i]) = ([system.convert]::ToInt64((((robocopy.exe $gci_DIR.name[$i] "NoCOPY" /L /XJ /R:0 /W:1 /NP /E /BYTES /NFL /NDL /NJH /MT:64)[-4] -replace '\D+(\d+).*','$1'))))
        }
    }
}
#2022-11-18 AWESOME!!! MADE A YUGE MILESTONE TODAY! I was able to convert the Value into int64 and that will help with everything here on out.
#Thank you JESUS!!!!!!!!!!!!!!

#i want to go thru the top 4 highest directories, or make it a var in the future to select how many to drill down thru and do the file size report
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


######### 11/9 left-off here. trying to fix the to-screen report to list top 10 directories and display the comment '..NOTE:...' at the end of
###if($gci_DIR.count -gt "1" -and $gci_files.Count -gt "1"){
###    $DIR_Count_HT += @{
###        "top '10' Folders/Files" = "$server  loc: '$directory'  report TS: $($HourMinDATE)" #'$($directory)'
###        "# of folder(s): '$($gci_DIR.count)' - with '$($gci_DIR.count - 10)' not displayed" = "# of file(s): '$($gci_files.Count)' - with '$($gci_files.Count - 10)' not displayed"
###         # folders not displayed." = "$($directory) total directories: '$($gci_DIR.count)'"
###                " NOTE: Top 10 files listed within '$($directory)'" = "Total files: '$($gci_files.Count)' - with '$($gci_files.Count - 10)' not displayed on the screen report"
###    }
###}

#sort and add the top 10 folders and files to the gci_files_screen HT:
$gci_files_Screen = $gci_DIR_ToSCREEN.GetEnumerator() | select name,value | sort value -Descending | select -First 10
$gci_files_Screen += $gci_files.GetEnumerator() | sort length -Descending | select name,@{n="value";e="length"} | select -First 10

#REPORT
$report_ALL = $gci_DIR_ToSCREEN.GetEnumerator() | select name,value | sort value -Descending
$report_ALL += $gci_files.GetEnumerator() | sort length -Descending | select name,@{n="value";e="length"}
#good report info:    $report_ALL.GetEnumerator() | select name,@{n="size";e={cdwtreesize $_.value}}

#i don't think i need these 2 lines of code due to getting the HT working
#saving-off folders/files information for complete listing - not sure if this will work on remote systems:
#$gci_DIR_Sum.GetEnumerator() | sort {$_.value} -Descending | select @{n="$server : '$directory'";e="name"},@{n="size sorted on: $HourMinDATE";e={cdwtreesize $_.value}} | ConvertTo-Csv -NoTypeInformation | Out-File $report\dir_size_SORTED.csv -Force
#$gci_files | select name,length | sort length -Descending | select @{n="$server - file name(s)";e="name"},@{n="$server - file size sorted";e={cdwtreesize $_.length}} | ConvertTo-Csv -NoTypeInformation | out-file $report\dir_size_SORTED.csv -append

#for($i=0;$i -lt $gci_files.Count;$i++){
#    $gci_DIR_Sum += @{
#        (" " + $gci_files.name[$i]) = ($gci_files_SORT.value[$i])
#        (" " + $gci_files.name[$i]) = ($gci_files[3] | select @{n="value";e={cdwtreesize $_.length}})
#    }
#}
#$gci_files | select name,@{n="value";e="length"} | sort {$_.value} -Descending | select name,@{n="value";e={cdwtreesize $_.value}}


#$gci_files | select name,@{n="value";e="length"} | sort {$_.value} -Descending | select name,@{n="value";e={cdwtreesize $_.value}} | ConvertTo-Csv -NoTypeInformation | out-file $report\file_SORT.csv -Force
#$gci_files_SORT = ipcsv $report\file_SORT.csv
#for($i=0;$i -lt $gci_files.Count;$i++){
#    $gci_DIR_Sum += @{
#        (" " + $gci_files_SORT.name[$i]) = ($gci_files_SORT.value[$i])
#    }
#}


<#

$gci_DIR_Sum_UPDATED += @{
    $server = $date::now
    ("C Root Drive Total Size:") = (cdwtreesize $($rootDIR_TOTAL))
    (" C Drive in use " + "("  + $(cdwtreesize ($rootDIR_Used)) + ")" ) = ("$($rootDIR_Used_MATH -as [int])% USED `t ( $(cdwtreesize ($rootDIR_Used)) used / $(cdwtreesize ($rootDIR_Total)) total )")
    (" C Drive free " + "("  + $(cdwtreesize ($rootDIR_Free)) + ")" ) = ("$($rootDIR_Free_MATH -as [int])% FREE `t ( $(cdwtreesize ($rootDIR_free)) used / $(cdwtreesize ($rootDIR_Total)) total )")
}
write "$($rootDIR_Free_MATH -as [int])% USED `t $(cdwtreesize ($rootDIR_Used))"
#>
cls
#####should i have a var/param to select the # of folders/files to display? i'm thinking of keeping it set to '10' for on-screen reports
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
sleep 3


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



<#BREAK
Bug section
2022-11-22 today i found an bug that appears to be in all versions of the get-humanreadable script and i believe it deals with the larger
conversions when it gets to the PB conversion and my guess is due to the math may be using 1000 instead of 1024 - at least that's my guess
and here are the examples:





#$zzDEL = [ordered]@{}

#for($i=0;$i -lt $gci_DIR.Count;$i++){
#    $t = if((gci -Directory "$($gci_DIR.name['$i'])")) {$true} else {$false}
#    if($t -eq $false){
#        $zzDEL += @{
#        (("!+ ") + $gci_DIR.name[$i]) = "PermissionDenied/Unauthorized to view with current signed-on credentials"
#        }
#    }
#    else{
#        $zzDEL += @{
#            (("+ ") + $gci_DIR.name[$i]) = (((robocopy.exe $gci_DIR.name[$i] "NoCOPY" /L /XJ /R:0 /W:1 /NP /E /BYTES /NFL /NDL /NJH /MT:64)[-4] -replace '\D+(\d+).*','$1'))
#        }
#    }
#}

#>
