# Powershell Script to prepare the windows install to be used with vagrant-windows

Set-ExecutionPolicy -executionpolicy remotesigned -force

# Step 1: Disable UAC
New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\Policies\System -Name EnableLUA -PropertyType DWord -Value 0 -Force | Out-Null
Write-Host "User Access Control (UAC) has been disabled." -ForegroundColor Green

# Step 2: Disable IE ESC
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0 | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0 | Out-Null
Stop-Process -Name Explorer | Out-Null
Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green

# Step 3: Disable the shutdown tracker
# Reference: http://www.askvg.com/how-to-disable-remove-annoying-shutdown-event-tracker-in-windows-server-2003-2008/
If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Reliability")) {
  New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Reliability"
}
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" -Name "ShutdownReasonOn" -PropertyType DWord -Value 0 -Force -ErrorAction continue 
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" -Name "ShutdownReasonUI" -PropertyType DWord -Value 0 -Force -ErrorAction continue 
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" -Name "ShutdownReasonOn" -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Reliability" -Name "ShutdownReasonUI" -Value 0
Write-Host "Shutdown Tracker has been disabled." -ForegroundColor Green

# Step 4: Disable Automatic Updates
# Reference: http://www.benmorris.me/2012/05/1st-test-blog-post.html
$AutoUpdate = (New-Object -com "Microsoft.Update.AutoUpdate").Settings
$AutoUpdate.NotificationLevel = 1
$AutoUpdate.Save()
Write-Host "Windows Update has been disabled." -ForegroundColor Green

# Step 5: Disable Complex Passwords
# Reference: http://vlasenko.org/2011/04/27/removing-password-complexity-requirements-from-windows-server-2008-core/
$seccfg = [IO.Path]::GetTempFileName()
secedit /export /cfg $seccfg
(Get-Content $seccfg) | Foreach-Object {$_ -replace "PasswordComplexity\s*=\s*1", "PasswordComplexity=0"} | Set-Content $seccfg
secedit /configure /db $env:windir\security\new.sdb /cfg $seccfg /areas SECURITYPOLICY
del $seccfg
Write-Host "Complex Passwords have been disabled." -ForegroundColor Green

# Step 6: Enable Remote Desktop
# Reference: http://social.technet.microsoft.com/Forums/windowsserver/en-US/323d6bab-e3a9-4d9d-8fa8-dc4277be1729/enable-remote-desktop-connections-with-powershell
(Get-WmiObject Win32_TerminalServiceSetting -Namespace root\cimv2\TerminalServices).SetAllowTsConnections(1,1) 
(Get-WmiObject -Class "Win32_TSGeneralSetting" -Namespace root\cimv2\TerminalServices -Filter "TerminalName='RDP-tcp'").SetUserAuthenticationRequired(0) 

# Step 7: Enable WinRM Control
winrm quickconfig -q
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="512"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
sc config WinRM start= auto
Write-Host "WinRM has been configured and enabled." -ForegroundColor Green

# Step 8: Disable Windows Firewall
&netsh "advfirewall" "set" "allprofiles" "state" "off"
Write-Host "Windows Firewall has been disabled." -ForegroundColor Green

# Rename Administrator to vagrant instead
## Step 9: Create local vagrant user 
#$userDirectory = [ADSI]"WinNT://localhost"
#$user = $userDirectory.Create("User", "vagrant")
#$user.SetPassword("vagrant")
#$user.SetInfo()
#$user.UserFlags = 64 + 65536 # ADS_UF_PASSWD_CANT_CHANGE + ADS_UF_DONT_EXPIRE_PASSWD
#$user.SetInfo()
#$user.FullName = "vagrant"
#$user.SetInfo()
#&net "localgroup" "administrators" "/add" "vagrant"
#Write-Host "User: 'vagrant' has been created as a local administrator." -ForegroundColor Green

## Install Puppet
#$puppetTempDir = Join-Path $env:TEMP "puppet"
#$tempDir = Join-Path $puppetTempDir "puppetInstall"
#if (![System.IO.Directory]::Exists($tempDir)) {[System.IO.Directory]::CreateDirectory($tempDir)}
#$file = Join-Path $tempDir "puppet-3.3.0.msi"
#
#$url = "http://downloads.puppetlabs.com/windows/puppet-3.3.0.msi"
#Write-Host "Downloading $url to $file"
#$downloader = new-object System.Net.WebClient
#$downloader.DownloadFile($url, $file)
#
#$localcommand="\\localhost\root\cimv2:Win32_Product"
#$msi = [wmiclass]"$localcommand"
#$result = $msi.Install($file, "quiet=true", $true)
#Write-Host "Puppet installed." -ForegroundColor Green
#
#$PuppetInstallPath = "$env:SystemDrive\Program Files (x86)\Puppet Labs\Puppet\bin"
#if (!(Test-Path $PuppetInstallPath)) {$PuppetInstallPath = "$env:SystemDrive\Program Files\Puppet Labs\Puppet\bin";}
#
## get the PATH variable
## https://github.com/ferventcoder/vagrant-windows-puppet/blob/master/boxes/win7x64pro-vagrant/shell/InstallPuppet.ps1#L27-L40
#$envPath = $env:PATH
#if (!$envPath.ToLower().Contains($PuppetInstallPath.ToLower())) {
#    Write-Host "PATH environment variable does not have `'$PuppetInstallPath`' in it. Adding..."
#    $ActualPath = [Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine)
#    $StatementTerminator = ";"
#    $HasStatementTerminator = $ActualPath -ne $null -and $ActualPath.EndsWith($StatementTerminator)
#    If (!$HasStatementTerminator -and $ActualPath -ne $null) {$PuppetInstallPath = $StatementTerminator + $PuppetInstallPath}
#
#    [Environment]::SetEnvironmentVariable('Path', $ActualPath + $PuppetInstallPath, [System.EnvironmentVariableTarget]::Machine)
#}

Write-Host "Restarting Computer." -ForegroundColor Yellow
Restart-Computer
