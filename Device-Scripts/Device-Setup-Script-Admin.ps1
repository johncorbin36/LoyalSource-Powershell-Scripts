# Get asset tag
$Option = 'N'
While ($Option -eq 'N'){

    # Menu check to confim asset tag
    $AssetTag = Read-Host "Please enter the LAST four digits of this devices asset tag"
    Write-Host "Last four digits: $AssetTag"
    $Option = Read-Host 'Enter [Y] to confirm or [N] to chance asset tag' 

    # Not valid input
    if (($Option -ne 'Y') -or ($Option -ne 'y')) {
        Write-Host 'Please confirm with [Y] or [y].'
        $Option = 'N'
    }
    
}

# Install PS module
Install-Module PSWindowsUpdate -Force

# Rename computer
Rename-Computer -NewName "LS$AssetTag"
Write-Host "Changed device name to LS$AssetTag." -ForegroundColor Green

# Create local account password
$AccountPassword = 'PASSWORD'
$AccountPasswordSecure = ConvertTo-SecureString $AccountPassword -AsPlainText -Force

# Change local account password
$LocalAdmin = Get-LocalUser -Name "ACCOUNT_NAME"
$LocalAdmin | Set-LocalUser -Password $AccountPasswordSecure
Write-Host "Changed password for local admin to $AccountPassword" -ForegroundColor Green

# Update windows
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
Write-Host "Updates checked and have completed installation." -ForegroundColor Green

# Gather system information and send to email (update to automatic HTTP request at later point)
$Model = $(Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Model).Model
$Manufacturer = $(Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Manufacturer).Manufacturer
$Serial = $(Get-WmiObject win32_bios | Select-Object Serialnumber).Serialnumber

# Set login credentials
$UserLogin = 'EMAIL'
$PasswordLogin = 'PASSWORD'
$PasswordSecure = ConvertTo-SecureString -String $PasswordLogin -AsPlainText -Force
$Login = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserLogin, $PasswordSecure

# Mail Variables
$MailFrom = "MAIL_FROM"
$MailTo = "MAIL_TO"

$SmtpServer = "outlook.office365.com"
$SmtpPort = 587

$Subject = "DEVICE INFO FOR LS$AssetTag"
$Body = "AssetTag: LS$AssetTag `nModel: $Model `nManufacturer: $Manufacturer `nSerial: $Serial"

# Send email
Send-MailMessage -From $MailFrom -to $MailTo -Subject $Subject `
-Body $Body -SmtpServer $SmtpServer -port $SmtpPort `
-Credential $Login -UseSsl
Write-Host "Email has been sent containing device details." -ForegroundColor Green

# Sync time
net stop w32time
w32tm /unregister
w32tm /register
net start w32time
w32tm /resync /nowait
Write-Host "Time has been synced. Waiting ten seconds before continuing execution." -ForegroundColor Green
Start-Sleep -s 10

# Run Comodo installer
$ComodoPath = "PATH_TO_INSTALLER"
Start-Process -FilePath $ComodoPath -Args "/silent /install" -Verb RunAs -Wait
Remove-Item -Path $ComodoPath
Write-Host "Comodo installer running, residual executable file has been removed." -ForegroundColor Green

# HTTP request to update Equipment log automatically, replace email
# Write-Host "Equipment log updated." -ForegroundColor Green

Write-Host "Admin script complete. Comodo will restart this device shortly." -ForegroundColor Green
Write-Host "Please continue onto the User device setup script." -ForegroundColor Green
Read-Host "Press any key to exit prompt"
