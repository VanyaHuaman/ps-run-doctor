#Requires -Version 7.0

$processingDate = Read-Host 'Processing date'
$confirm = Read-Host 'Continue?'

Write-Host "Date: $processingDate"
Write-Host "Confirm: $confirm"

if ($confirm -ne 'Y') {
    Write-Error 'Confirmation was not Y.'
    exit 1
}

exit 0
