#Requires -Version 7.0

Write-Host 'PS Run Doctor interactive test script'
Write-Host "PowerShell version: $($PSVersionTable.PSVersion)"
Write-Host "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ''

$name = Read-Host 'Enter a name'
$continue = Read-Host 'Continue? Type Y to succeed'

Write-Host ''
Write-Host "Name entered: $name"
Write-Host "Confirmation entered: $continue"

if ($continue -ne 'Y') {
    Write-Error 'The test script failed because the confirmation was not Y.'
    exit 1
}

Write-Host 'The test script completed successfully.'
exit 0
