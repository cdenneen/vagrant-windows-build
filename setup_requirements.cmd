echo 'Ensuring .NET 4.0 is installed'
@powershell -NoProfile -ExecutionPolicy Bypass -File "c:\vagrant\install_net4.ps1"
rmdir /S /Q c:\vagrantshared\resources\NetFx4

echo 'Ensuring Chocolatey is Installed'
@powershell -NoProfile -ExecutionPolicy Bypass -File "c:\vagrant\install_chocolatey.ps1"
