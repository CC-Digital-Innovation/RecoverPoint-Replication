# Dot source required functions.
. "$PSScriptRoot\Get-IniFile-Function.ps1"


# Make global variables.
$DATE = Get-Date

# Get global config parameters from config.ini.
$CONFIG = Get-IniFile $PSScriptRoot\..\configs\Emailer-PowerShell-config.ini

# Prepare SMTP-related variables from the config file.
$SMTP_SERVER = $CONFIG.SMTPInfo.server
$SMTP_PORT = $CONFIG.SMTPInfo.port
$SMTP_USERNAME = $CONFIG.SMTPInfo.username
$SMTP_PASSWORD = $CONFIG.SMTPInfo.password

# Prepare party-related variables from the config file.
$SENDER = $CONFIG.Parties.sender
$SENDER_NAME = $CONFIG.Parties.sender_name
$FULL_SENDER = New-Object System.Net.Mail.MailAddress($SENDER, $SENDER_NAME)
$RECIPIENTS = $CONFIG.Parties.recipients
$CC = $CONFIG.Parties.cc
$BCC = $CONFIG.Parties.bcc

# Prepare message content variables from the config file.
$SUBJECT = $CONFIG.MessageContents.subject + " - " + $DATE
$MSG_BODY = Get-Content -Path $PSScriptRoot\..\RecoverPoint-Replication.html -Raw
$ATTACHMENTS = $CONFIG.MessageContents.attachments -Split ","


# Make the email message.
$EmailMessage = New-Object System.Net.Mail.MailMessage($FULL_SENDER, $RECIPIENTS, $SUBJECT, $MSG_BODY)
$EmailMessage.CC.Add($CC)
$EmailMessage.BCC.Add($BCC)
$EmailMessage.IsBodyHtml = $true

# Add any attachments to the email.
Foreach ($att in $ATTACHMENTS) {
    $EmailMessage.Attachments.Add($att)
}

# Make the SMTP client to send the email.
$SMTPClient = New-Object Net.Mail.SmtpClient($SMTP_SERVER, $SMTP_PORT)
$SMTPClient.EnableSsl = $true
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($SMTP_USERNAME,$SMTP_PASSWORD)

# Send the email.
$SMTPClient.Send($EmailMessage)
