# Dot source required functions.
. "$PSScriptRoot\Get-IniFile-Function.ps1"


# Get global config parameters from config.ini.
$CONFIG = Get-IniFile "$PSScriptRoot\..\configs\RecoverPoint-Replication-config.ini"
$USERNAME = $CONFIG.LoginCreds.username
$PASSWORD = $CONFIG.LoginCreds.password
$CUSTOMER = $CONFIG.CustomerInfo.name

$MACHINE_IP1 = $CONFIG.IpAddresses.IP1
$MACHINE_IP2 = $CONFIG.IpAddresses.IP2


# Declare other global variables.
$NEWLINE = [System.Environment]::NewLine
$DATE = Get-Date
$HTML_START = @"
<!DOCTYPE html>
<html>
<head>
  <title>
    $CUSTOMER RecoverPoint Replication
  </title>

  <style>
    table {
      border-width: 1px;
      border-style: solid;
      border-color: black;
      border-collapse: collapse;
    }

    th {
      border-width: 1px;
      padding: 3px;
      border-style: solid;
      border-color: black;
      background-color: #08088A;
      color: white;
      font-size: 100%;
    }

    td {
      border-width: 1px;
      padding: 3px;
      border-style: solid;
      border-color: black;
      font-size: 100%;
    }
  </style>
</head>

<body>
<div align = center>
  <b>$CUSTOMER RecoverPoint Replication<br/>$DATE</b>

  <br/><br/>
  $NEWLINE
"@
$HTML_END = @"
$NEWLINE
</div>
</body>
</html>
"@
$HTML_BREAK = $NEWLINE + $NEWLINE + "  <br/><br/>" + $NEWLINE + $NEWLINE


# Declare global functions.
function New-RecoverPoint-Replication {
    # New-RecoverPoint-Replication -Label [Site Label] -Destination [IP Address] -User [Login Username] -Pass [Login Password]
    Param (
        [Parameter(Mandatory = $true)]
        [string] $Label,
        [Parameter(Mandatory = $true)]
        [string] $Destination,
        [Parameter(Mandatory = $true)]
        [string] $User,
        [Parameter(Mandatory = $true)]
        [string] $Pass
    )

    # Get the RecoverPoint replication information. Initialize loop variables.
    $RPRepInfo = Write-Output y | plink $User@$Destination -pw $Pass "get_group_state"
    $Group = $null
    $DataTransfer = $null
    $RPRepOutput = "  <table> <colgroup><col/><col/></colgroup><tr><th colspan=2>$Label</th></tr> <tr><th>Group</th><th>Status</th></tr>"

    # Go through the information from the RecoverPoint replication information
    # line by line to get the data transfer for each group.
    ForEach ($CurrLine in $RPRepInfo) {
        # Keep track of the last 3 lines we scanned. "Transfer source:" is a
        # unique string for each group and will always be 2 lines below the
        # group name, so when it is in $Line3, then we know the group name will
        # be in $Line1.
        $Line1 = $Line2
        $Line2 = $Line3
        $Line3 = $CurrLine

        # Check if we already found the next group.
        If ($Group -eq $null) {
            $LineCheck = $Line3.IndexOf("Transfer source:")

            # Check if $Line3 has "Transfer source:" in it.
            If ($LineCheck -ne -1) {
                # Get the group name from $Line1.
                $Group = $Line1.Split(":")[0]
            }
        }
        # We have the next group. Look for the "Data Transfer" information.
        Else {
            $LineCheck = $Line3.IndexOf("Data Transfer:")

            # Check if we found the "Data Transfer" information.
            If ($LineCheck -ne -1) {
                # Get the data transfer information and add it to the output
                # HTML file.
                $DataTransfer = $Line3.Split(":")[1]
                $TableRow = " <tr><td>$Group</td><td>$DataTransfer</td></tr>"
                $RPRepOutput = $RPRepOutput + $TableRow

                # Reset the group and data transfer variables to find the next
                # ones.
                $Group = $null
                $DataTransfer = $null
            }
        }
    }

    # End the HTML table and output it.
    $RPRepOutput = $RPRepOutput + " </table>"
    return $RPRepOutput
}


# Get the RecoverPoint replication table in HTML.
$Machine1RPReport = New-RecoverPoint-Replication -Label "Label 1" -Destination $MACHINE_IP1 -User $USERNAME -Pass $PASSWORD
$Machine2RPReport = New-RecoverPoint-Replication -Label "Label 2" -Destination $MACHINE_IP2 -User $USERNAME -Pass $PASSWORD

# Make the full RecoverPoint replication HTML file.
$RPRepOutputFile = $HTML_START + $Machine1RPReport + $HTML_BREAK + $Machine2RPReport + $HTML_END
$RPRepOutputFile | Out-File -FilePath "$PSScriptRoot\..\RecoverPoint-Replication-$CUSTOMER.html"

# Email the RecoverPoint Replication report.
& ".\Emailer-PowerShell.ps1"
