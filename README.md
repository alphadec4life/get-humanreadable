# 2022-11-15
# get-humanreadable
PowerShell version similar to Tree-Size to list folder/file sizes largest to smallest in appropriate format, ie, KB, MB,GB, etc.

NOTE - this PowerShell script gathers and sort folders and files from largest to smallest and converts the PowerShell bytes to the appropriate file size, ie, KB, MB, GB, TB, PB, EB, ZB, YB, XB, SB, and DB. There is an error due to a string to int64 conversion problem that I'm still working on if/when a folder/file size is within the XB range, but I'm it can be fixed later since none of the systems I've ever worked on have hit this limit.

I will include the source notes of the website(s) I used for this script once I find them in an earlier script and below are the version notes as I worked thru the issues and updated the script within the default PowerShell ISE.

2022-11-2  get-humanreadable script
  I discovered a bug with the code/script with my most recent version and it deals with the conversion of bytes as a 'string' value when it
  gets to xenotta-bytes (XB) - in theory a very large # that will never be encountered within the VA's databases. Just keep in mind and re-do
  at some point in time.


#2022-10-22  file_size_v15
#X  - DIDN'T WORK:  i tried to re-do the function and removed all the advanced stuff, ie, defining parameters within the function, but still
#     didn't fix it.
#
#
#Past versions fix-items:
#PENDING   needs the temp files (csv's) cleaned-up (when executed locally, for some reason files are not created when exe'ed remotely
#  i think files are not stored due to the way PS works, it opens the remote session, does the code, closes it all. but there is no clean-up
#  due to there are no remote files stored in the local c temp.
#
#X - WORKS, BUT U HAVE TO SET THE VAR 1ST...PENDING - should i have it 'jump' to a typed directory?
# $directory = "c:\users\profile\"
# .\get-humanreadable [return]
#
#X - completed    PENDING -  Need to update the var names and verify the function when dot sourced - maybe have the file name header display
# directory structure where/when the script was executed



#the output looks good, but i still have issues with utilizing the var that will pass the directory i want to issue the report on.
#however, if i set the var directory and then hard code the directory i want the report on and then execute the script it will function
#as designed.

#another issue i found that will need revised on future versions - output should indicate the server and the working directory the report is
#working on, and the last issue would be there needs to be a max # of files (and/or dir's) that the report displays on the screen. The 
#example output at the bottom of this script has the output with lots of files that scroll thru the screen. Maybe have a cut-off after so
#many results, or maybe only display files greater than 'x' amount in size???
# Now that i'm thinking of it, maybe have it be like my compare-file script and depending on the params entered it will let the script
# know to either save the output for a report, and/or display only the first 100 files? More work needed...
# *Needs the total run time of script


#2022-10-21  file_size_v12
# Need to update the var names and verify the function when dot sourced - maybe have the file name header display
# directory structure where/when the script was executed

#previous notes
#x - fixed  the final report, there is a header mis-match that will need cleaned-up
#
#PENDING   needs the temp files (csv's) cleaned-up (when executed locally, for some reason files are not created when exe'ed remotely
#  i think files are not stored due to the way PS works, it opens the remote session, does the code, closes it all. but there is no clean-up
#  due to there are no remote files stored in the local c temp.
#
#x - fixed it's not showing the server name/timestamp in the report - needs fixed

#2022-10-13  Latest version of script 'file_size.ps1' and will be renamed to 'Get-HumanReadable' on final working version.
# I discovered that ogv doesn't work when executed on remote machines, so command was commented out and will be removed on final
# version.

#x - fixed  !! make all sizes in bytes and at the last part of the script then convert it via the function!
#should i have it show the full path name, or just the top-root directory?
#PENDING - needs cleaned-up once executed

#https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/invoke-command?view=powershell-7.2&viewFallbackFrom=powershell-6
#x - FIXED  should i sort the directories/files from large to small???

#add a param for drive for selection
#add a param for saving the report?
#>
<#
2022-11-14  passing the directory isn't working for the icm command and it defaults to the root c, which is good but it needs the ability
to jump to the selected folder structure. commenting out until i figure this out because i tried to setup in the cdwtreesize function but
it didn't work there either...

function director(){
    [CmdletBinding()]
    Param(
        [parameter(valuefrompipeline=$true)]
        [string]$directory
    )
}
#>
